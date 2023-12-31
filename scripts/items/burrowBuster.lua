local this = {}
this.description = "Bombs will create a chain of explosions in rock clusters#+5 Bombs"
this.id = Isaac.GetItemIdByName("Burrow Buster Bombs")

function this:burrowBombEffect()
    local player = Isaac.GetPlayer(0);
    if player:HasCollectible(this.id) then
        local entities = Isaac.GetRoomEntities();
        for i = 1, #entities do

            --adds functionality to dr's remote and epic fetus
            if entities[i].Type == 1000 and entities[i].Variant == EffectVariant.ROCKET and this:isPlayerBomb(entities[i]) and entities[i]:ToEffect().Timeout == 0 then
                this:boom(entities[i])
            end
            
            if entities[i].Type == EntityType.ENTITY_BOMBDROP and this:isPlayerBomb(entities[i])  then
                local sprite = entities[i]:GetSprite()
                --If First frame
                if entities[i].FrameCount  == 1 and not (entities[i]:ToBomb().Flags > 0)  then --only swap anm2 if there are no other bomb modifiers
                    sprite:Load("gfx/burrowBuster.anm2",false)                                                                                 --this stopped working with other bomb types out of the blue, I didnt change anything,
                    sprite:LoadGraphics()                                                                                                      --the game will crash with AnimationData is NULL if the bomb has other modifiers 
                end
                
                --if about to explode
                if  (sprite:IsPlaying("Pulse") and sprite:GetFrame() == 58) then
                    this:boom(entities[i])
                end

            end
        end
    end
end

function this:isPlayerBomb(e)
    return e.SpawnerType == EntityType.ENTITY_PLAYER and e.SpawnerEntity~= nil and e.SpawnerEntity:ToPlayer():HasCollectible(this.id)
end

function this:boom(bomb)
    local trackArr = {}
    local room = game:GetRoom()
    local searchRange = 75
    local player = bomb.SpawnerEntity:ToPlayer()

    if player:HasCollectible(Isaac.GetItemIdByName("Bomber Boy")) then
        searchRange = 150
    elseif player:HasCollectible(Isaac.GetItemIdByName("Mr. Mega")) then
        searchRange = 85
    end
    
    local clear, hitPos = room:CheckLine(bomb.Position, bomb.Position + Vector(searchRange,0),3) --east
    if not clear then
        local dir = {1,-room:GetGridWidth(),room:GetGridWidth()}
        if ratPackUtils.chancep(50)then--randomize which backup direction is "perfered"
            dir = {1,room:GetGridWidth(),-room:GetGridWidth()}
        end

        this:gridExplosion(room:GetGridIndex(hitPos),room, dir, trackArr,player)
    end
    clear, hitPos = room:CheckLine(bomb.Position, bomb.Position - Vector(searchRange,0),3) --west
    if not clear then
        local dir = {-1,-room:GetGridWidth(),room:GetGridWidth()}
        if ratPackUtils.chancep(50)then--randomize which backup direction is "perfered"
            dir = {-1,room:GetGridWidth(),-room:GetGridWidth()}
        end
        this:gridExplosion(room:GetGridIndex(hitPos),room, dir, trackArr,player)
    end

    clear, hitPos = room:CheckLine(bomb.Position, bomb.Position - Vector(0,searchRange),3) --north
    if not clear then
        local dir = {-room:GetGridWidth(),-1,1}
        if ratPackUtils.chancep(50)then--randomize which backup direction is "perfered"
            dir = {-room:GetGridWidth(),1,-1}
        end
        this:gridExplosion(room:GetGridIndex(hitPos),room, dir, trackArr,player)
    end

    clear, hitPos = room:CheckLine(bomb.Position, bomb.Position + Vector(0,searchRange),3) --north
    if not clear then
        local dir = {room:GetGridWidth(),-1,1}
        if ratPackUtils.chancep(50)then--randomize which backup direction is "perfered"
            dir = {room:GetGridWidth(),1,-1}
        end
        this:gridExplosion(room:GetGridIndex(hitPos),room, dir, trackArr, player)
    end
    
end

--prevents BBB from applying to certain types of bombs
function this:isValidBombVariant(variant)
    if variant == BombVariant.BOMB_ROCKET or variant == BombVariant.BOMB_ROCKET_GIGA or variant == BombVariant.BOMB_GIGA then
        return false
    end
    return true
end

function this:contains(arr, element)
    for i = 1,#arr do
        if arr[i] == element then
            return true
        end
    end
    return false
end


--spawns bombs along a path of connected gridEntities
--dir is an array of potential directions to follow along, used to prevent the loop from back tracking
--dir[1] is the dominant direction, with dir[2] and dir[3] being the backup directions when the dominant path ends
--dir values: +1 = east, -1 = west, +gridWidth = south, -gridWidth = north

--trackArr is used to prevent multiple bombs from spawning on one tile since it is possible for paths to overlap
function this:gridExplosion(index, room, dir, trackArr, player)
    local explodeArr = {}
    local dirIndex = 1
    while index > 0 and index < room:GetGridSize() and #explodeArr < 20 do --while in bounds of the room and #explodeArr < MAX_BOMBS
        index = index + dir[dirIndex]
        if room:GetGridCollision(index) ~= 0 and this:isValidType(room:GetGridEntity(index)) and not this:contains(trackArr,index) then
            explodeArr[#explodeArr+1] = index
            trackArr[#trackArr+1] = index
            dirIndex = 1--if a valid grid index was found, reset to the original direction
        elseif dirIndex < #dir then
            index = index - dir[dirIndex]--go back to the previous valid spot
            dirIndex = dirIndex + 1 --chance direction
        else
            break--if all directions have been tried, end the loop
        end
    end
    
    local delay = 5
    if player:HasCollectible(Isaac.GetItemIdByName("Fast Bombs"))then
        delay = 1
    end
    for x = 1,#explodeArr do
        pos = room:GetGridPosition(explodeArr[x])
        bomb = player:FireBomb(pos,Vector(0,0),nil)
        bomb.SpawnerEntity = nil --this is for detonator functionality only, without this all the bombs spawned will insta-explode sometimes when using detontor
        bomb:GetData().BBspawnPos = pos
        bomb.Visible = false
        bomb:SetExplosionCountdown (x*delay)
    end
end


function this:isValidType(gridEntity)
    local type = gridEntity.Desc.Type
    if type == GridEntityType.GRID_WALL or type == GridEntityType.GRID_DOOR or type == GridEntityType.GRID_PIT then
        return false
    end
    return true
end

--this is to prevent the bombs from moving at all
--i tried using entityflags  but brimstone seems ignore entityflags with its knockback
function this:holdBomb(bomb)
    local data = bomb:GetData()
    if data.BBspawnPos ~= nil then
        bomb.Position = data.BBspawnPos
        bomb.Velocity = Vector(0,0)
    end
end

--Used for when bombs are exploded with detonator 
--need this work around since we need to do our gridExplosion right before the bomb explodes, and the detonator circumvents the first check
function this:detonate()
    local entities = Isaac.GetRoomEntities();
    for i = 1, #entities do
        if entities[i].Type == EntityType.ENTITY_BOMBDROP and this:isPlayerBomb(entities[i]) then
            this:boom(entities[i])
        end
    end
end



function this.Init()
    ratPackMod:AddCallback(ModCallbacks.MC_POST_UPDATE, this.burrowBombEffect)
    ratPackMod:AddCallback(ModCallbacks.MC_POST_BOMB_UPDATE,this.holdBomb )
    ratPackMod:AddCallback(ModCallbacks.MC_USE_ITEM,this.detonate,CollectibleType.COLLECTIBLE_REMOTE_DETONATOR)
end


return this