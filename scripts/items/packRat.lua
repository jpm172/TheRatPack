local this = {}
this.description = "\2 Speed Down#Isaac gains a trash friend for every 7 coins, bombs, or keys Isaac has#Reduced to 4 coins, bombs, or keys if Isaac has the box{{Collectible198}} "
this.id = Isaac.GetItemIdByName("Pack Rat")
this.boxId = Isaac.GetItemIdByName("Box")
this.bffId = Isaac.GetItemIdByName("BFFS!")

this.garbageVariant = Isaac.GetEntityVariantByName("Garbage Friend")
this.boxVariant = Isaac.GetEntityVariantByName("Box Friend")
this.spikyVariant = Isaac.GetEntityVariantByName("Spiky Friend")

this.prevPickUpCount = 0
this.garbageCount = 0
this.meleeCount = 0
this.rangedCount = 0

this.hasBFF = false

function this:cache(player, flag)
    if player:HasCollectible(this.id) then
        if flag == CacheFlag.CACHE_SPEED then player.MoveSpeed = player.MoveSpeed -.2 end
        
        player:CheckFamiliar(this.garbageVariant, this.garbageCount, RNG())
        player:CheckFamiliar(this.boxVariant,this.rangedCount,RNG())
        player:CheckFamiliar(this.spikyVariant,this.meleeCount,RNG())
        
        this.hasBFF = player:HasCollectible(this.bffId)
        
    end
end

function this:packRatEffect()
    for i = 0, game:GetNumPlayers()-1 do
        local player = Isaac.GetPlayer(i)
        if player:HasCollectible(this.id) then
            local pickupCount = player:GetNumCoins() + player:GetNumBombs() + player:GetNumKeys()
            if pickupCount ~= this.prevPickUpCount then
                this:calculateFamiliarCount(pickupCount, player)
            end
            
            this.prevPickUpCount = pickupCount
        end
    end
end

--evenly distribute pickupCount to spawn the same amount of familiars each time
function this:calculateFamiliarCount(cnt, player)
    local threshold = 7

    if player:HasCollectible(this.boxId) then
        threshold = 4
    end
    
    local choice = 0

    local r = 0
    local m = 0
    local g = 0
    while cnt >= threshold and r + m + g < 30 do
        if choice == 0 then
            g = g + 1
        elseif choice == 1 then
            m = m + 1
        else
            r = r +1
        end
        cnt = cnt - threshold
        choice = (choice + 1)%3
    end
    
    this.garbageCount = g
    this.meleeCount = m
    this.rangedCount = r
end


function this:updateItem(player)
    if player:HasCollectible(this.id) then
        player:AddCacheFlags(CacheFlag.CACHE_SPEED)
        player:EvaluateItems()
    end
end

function this:awake(fam)
    fam:AddToFollowers()
end

--this makes garbage friend destroy enemy projectiles
function this:garbageFriendCol(fam, col,low)
    if col:ToProjectile() then
        col:Die()
    end
end

--make familiar find a random tile, drop down and release a slowing creep
function this:garbageBehavior(fam)
    local data = fam:GetData()
    local sprite = fam:GetSprite()
    
    if data.roomPos == nil or data.room ~= game:GetRoom():GetSpawnSeed() then
        data.roomPos = this:getRandomFreeTile()
        data.room = game:GetRoom():GetSpawnSeed()
        sprite:Play("Idle",true)
    end
    
    if (fam.Position - data.roomPos):Length() <= 20 and not sprite:IsPlaying("Land") then
        sprite:Play("Land",false)
    end

    if this.hasBFF then
        fam.Size = 20
    else
        fam.Size = 16
    end

    if sprite:IsEventTriggered("Land") then
        SFXManager():Play(SoundEffect.SOUND_MEAT_IMPACTS, .5, 0, false, 1)
        local creep = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.PLAYER_CREEP_BLACK, 0, fam.Position, Vector(0, 0), fam)

        if this.hasBFF then
            creep.SpriteScale = Vector(2.5,2.5)
        else
            creep.SpriteScale = Vector(2,2)
        end
        
        creep:Update()
        creep:ToEffect().Timeout = 9999
    end
    
    fam:FollowPosition(data.roomPos)
end

--make familiar find a random tile, drop down and start shooting in random directions
function this:boxBehavior(fam)
    local data = fam:GetData()
    local sprite = fam:GetSprite()
    
    if data.roomPos == nil or data.room ~= game:GetRoom():GetSpawnSeed() then
        data.shootCooldown = 30
        data.roomPos = this:getRandomFreeTile()
        data.room = game:GetRoom():GetSpawnSeed()
        sprite:Play("Idle",false)
        fam.State = NpcState.STATE_IDLE
    end
    
    if fam.State == NpcState.STATE_ATTACK then

        if data.shootCooldown <= 0 then
            if not sprite:IsPlaying("Shoot") then
                sprite:Play("Shoot",true)
            end

            if sprite:IsEventTriggered("Shoot") then 
                for i = 0, 2 do
                    local proj = Isaac.Spawn(EntityType.ENTITY_TEAR, 3, 1, fam.Position, Vector(-6,0):Rotated(math.random(0, 360)), nil):ToTear()
                    proj.CollisionDamage = 2
                    proj.SpriteScale = Vector(.6,.6)
                    if this.hasBFF then
                        proj.CollisionDamage = 3.5
                        proj.SpriteScale = Vector(.9,.9)
                    end
                end
                data.shootCooldown = math.random( 20, 70)
            end
        end
        data.shootCooldown = data.shootCooldown -1
    else
        if (fam.Position - data.roomPos):Length() <= 20 and not sprite:IsPlaying("Land")  then
            sprite:Play("Land",false)
        end

        if sprite:IsFinished("Land") then
            fam.State = NpcState.STATE_ATTACK
        end
    end

    fam:FollowPosition(data.roomPos)
end

--make familiar find a random tile, drop down and attack any monsters that pass nearby, but only chase up to a certain distance from the landing point
function this:spikyBehavior(fam)
    local data = fam:GetData()
    local sprite = fam:GetSprite()

    if data.roomPos == nil or data.room ~= game:GetRoom():GetSpawnSeed() then
        data.roomPos = this:getRandomFreeTile()
        data.room = game:GetRoom():GetSpawnSeed()
        sprite:Play("Idle",false)
        fam.State = NpcState.STATE_IDLE
    end

    local targetPos = data.roomPos

    if this.hasBFF then
        fam.Size = 20
        fam.CollisionDamage = 2.5
    else
        fam.Size = 16
        fam.CollisionDamage = 1
    end
    
    
    if fam.State == NpcState.STATE_ATTACK then
        local check = this:GetFirstEnemy(data.roomPos)
        if check then
            targetPos = check
        end
    else
        if (fam.Position - data.roomPos):Length() <= 20 and not sprite:IsPlaying("Land")  then
            sprite:Play("Land",false)
        end

        if sprite:IsFinished("Land") then
            fam.State = NpcState.STATE_ATTACK
        end
    end

    fam:FollowPosition(targetPos)
end

function this:GetFirstEnemy(pos)
    for i, entity in ipairs(Isaac.FindInRadius(pos,100,EntityPartition.ENEMY)) do
        if  entity:IsVulnerableEnemy() then
            return entity.Position
        end
    end
    return nil
end


function this:getRandomFreeTile()
    room = game:GetRoom()
    return room:FindFreePickupSpawnPosition(room:GetGridPosition(math.random(0,room:GetGridSize())), 200, true, false)
end


function this.Init()
    ratPackMod:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, this.garbageBehavior, this.garbageVariant)
    ratPackMod:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, this.boxBehavior, this.boxVariant)
    ratPackMod:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, this.spikyBehavior, this.spikyVariant)
    
    ratPackMod:AddCallback(ModCallbacks.MC_FAMILIAR_INIT, this.awake, this.garbageVariant)
    ratPackMod:AddCallback(ModCallbacks.MC_FAMILIAR_INIT, this.awake, this.boxVariant)
    ratPackMod:AddCallback(ModCallbacks.MC_FAMILIAR_INIT, this.awake, this.spikyVariant)
    
    
    ratPackMod:AddCallback(ModCallbacks.MC_PRE_FAMILIAR_COLLISION, this.garbageFriendCol,this.garbageVariant)
    ratPackMod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, this.cache)
    ratPackMod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, this.cache)
    ratPackMod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, this.updateItem)
    ratPackMod:AddCallback(ModCallbacks.MC_POST_UPDATE, this.packRatEffect)
    
    --ratPackUtils.debugItemSpawn(this.id)
end


return this