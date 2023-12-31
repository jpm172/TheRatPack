local this = {}
local spawnedLouse = false
this.description = "Isaac now has a rat tail that will fear any monsters that touch it#Grows in length each level#↑ +.5 Tears Up#0.5% chance for the Louse to spawn after taking damage"
this.id = Isaac.GetItemIdByName("Haircut")

local ratTail = Isaac.GetEntityVariantByName("Rat Tail")

function this:spawnTail(player)
    local data = player:GetData()
    if data.tail == nil then
        data.buttPos = Vector(0,-25)
        local prevTail = Isaac.Spawn(1000, ratTail, 0, player.Position, Vector(0,0), player)
        data.tail = prevTail
        prevTail.Parent = player
        prevTail.DepthOffset = -1

        local tailNum = math.min(50, 15 + (game:GetLevel():GetAbsoluteStage()*5))

        for i = 1, tailNum do
            local tail = Isaac.Spawn(1000, ratTail, 0, player.Position, Vector(0,0), player)
            tail.DepthOffset = -(i +1)
            tail.Parent = prevTail
            prevTail = tail
        end
        data.tailEnd = prevTail
    end
    
    if (data.tail.Position - player.Position):Length() >= 200 then--respawn the tail whenever player changes rooms
        data.tail.SpawnerEntity = nil
        data.tail:Remove()
        data.tail = nil
    end
    
    return data.tailEnd
end

function this:cache(player, flag)
    if player:HasCollectible(this.id) then
        if flag == CacheFlag.CACHE_FIREDELAY then player.MaxFireDelay = ratPackUtils.tearsUp(player.MaxFireDelay, .5) end --give player +.5 tears up 
    end
end

function this:takeDamage(player)
    if player:ToPlayer():HasCollectible(this.id) and spawnedLouse == false then
        if math.random(0, 200) == 1 then --0.5% chance of the louse spawning after taking damage
            Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TRINKET, TrinketType.TRINKET_LOUSE, player.Position, Vector(0,0), player)
            spawnedLouse = true
        end
    end
end

function this:updateItem(player)
    if player:HasCollectible(this.id) then
        player:AddCacheFlags(CacheFlag.CACHE_FIREDELAY)
        player:EvaluateItems()
    end
end

function this:fearEffect()
    for i = 0, game:GetNumPlayers()-1 do
        local player = Isaac.GetPlayer(i)
        if player:HasCollectible(this.id) then
            local tail = this:spawnTail(player)
            local counter = 0
            
            while tail ~= nil do
                if tail.Parent ~= nil then--since the player is connected to the tail, this comparison is need to prevent player from changing color
                    tail:SetColor(Color(.15,.15,.15,1,0,0,0) , 15, 1, false, false)
                    if counter % 5 == 0 then
                        for i, entity in ipairs(Isaac.FindInRadius(tail.Position,10,EntityPartition.ENEMY)) do
                            if  entity:IsVulnerableEnemy() and not entity:HasEntityFlags(EntityFlag.FLAG_FEAR) then
                                entity:AddFear(EntityRef(player), 45)
                            end
                        end
                    end
                    
                    --this puts the rat tail on the proper layer to make the hair appear on the back of isaacs head
                    if math.abs(tail.DepthOffset)  <= 8 then --only apply to the first few segments, otherwise isaac's hair will appear to defy gravity
                        local input = player:GetShootingInput()
                        if input:Length() <= .1 then --if player not shooting, get movement input
                            input = player:GetMovementInput()
                        end
                        if input.Y == -1 then
                            tail.DepthOffset = math.abs(tail.DepthOffset)
                        else
                            tail.DepthOffset = -math.abs(tail.DepthOffset)
                        end
                    end
                    
                end
                counter = counter + 1
                tail = tail.Parent
            end 
                
        end
    end
end



function this.Init()
    ratPackMod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, this.cache)
    ratPackMod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, this.takeDamage, EntityType.ENTITY_PLAYER)
    ratPackMod:AddCallback(ModCallbacks.MC_POST_UPDATE, this.fearEffect)
    ratPackMod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, this.updateItem)
end


return this