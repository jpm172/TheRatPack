local this = {}
this.description = "Raise a swarm of friendly rats to fight for you"
this.id = Isaac.GetItemIdByName("Book of Mischief")
local rat = Isaac.GetEntityTypeByName("Rat")
local ratArr = {}

function this:use(c,r,player)
    local enemyCount = 0
    local amt = 4
    
    for i, entity in pairs(Isaac.GetRoomEntities()) do
        if entity:IsVulnerableEnemy() and not EntityRef(entity).IsFriendly then
            enemyCount = enemyCount + 1
            if enemyCount %4 == 0 then
                amt = amt +1
            end
            if entity:IsBoss() then
                amt = amt + 2
            end
        end
    end

    --spawn a wave of friendly rats around the player
    for i = 1, amt do
        pos = Vector(math.random(-80,80),math.random(-80,80))
        entity = Isaac.Spawn(rat, 0, 0, Isaac.GetFreeNearPosition(player.Position + pos, 100), Vector(0,0), nil)
        entity:AddCharmed(EntityRef(player),9999)
        entity:AddEntityFlags(EntityFlag.FLAG_FRIENDLY)
        entity.HitPoints = 14 + (game:GetLevel():GetAbsoluteStage() -1)
        entity.MaxHitPoints = .1--this to reduce the contact damage done by the friendly rat
                                --entity.ContactDamage does nothing unless == 0, it seems that friendly contact damage scales with max health only
        ratArr[#ratArr+1] = entity
    end
    
    return true --return true to do the active item animation
end

--remove all Friendly flags after exiting game to prevent rats spawned from the book becoming persistent
function this:exit()
    for i, entity in ipairs(ratArr) do
        entity:ClearEntityFlags(EntityFlag.FLAG_FRIENDLY)
    end
    ratArr = {}
end



function this.Init()
    ratPackMod:AddCallback(ModCallbacks.MC_USE_ITEM, this.use, this.id)
   ratPackMod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT,this.exit)
end


return this