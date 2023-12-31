ratPackUtils = {}

-- Usage
-- Utils.chancep(20) will return true with 20% probability
function ratPackUtils.chancep(percentage)
    return math.random(0, 100) <= percentage
end


-- Usage
-- Utils.fearEffect(npc,target) will make the npc run away from target, while avoiding get stuck in corners/obstacles
function ratPackUtils.fearEffect(npc, target, searchRange, frameCountCheck)
    searchRange = 200 or searchRange
    frameCountCheck = 30 or frameCountCheck
    data = npc:GetData()

    if npc:CollidesWithGrid() or data.fearEffectPos ~= nil then
        if data.fearEffectPos == nil  then
            data.fearEffectPos = Isaac.GetFreeNearPosition(npc.Position, searchRange); -- get a position nearby for npc to run to
        end

        npc.Pathfinder:FindGridPath(data.fearEffectPos, data.sped, 1, false)

        if npc.FrameCount %frameCountCheck == 0 then --set fearEffectPos to nil to reset pathing and allow npc to run away again
            data.fearEffectPos = nil
        end
    else
        npc.Velocity = (npc.Position - target.Position):Normalized() *1.15 +npc.Velocity * data.sped;-- default to running away from target
    end
end

function ratPackUtils.confuseEffect(npc, frameCountCheck)
    frameCountCheck = frameCountCheck or 10
    local data = npc:GetData()

    if npc.FrameCount % frameCountCheck == 0 or npc:CollidesWithGrid() then
        data.confusedEffectPos = nil
    end
    data.confusedEffectPos = data.confusedEffectPos or RandomVector()*math.random(2,4)

    npc.Velocity = data.confusedEffectPos *data.sped

end



function ratPackUtils.canAttack(npc)
    return npc:HasEntityFlags(EntityFlag.FLAG_FEAR | EntityFlag.FLAG_CONFUSION) == false 
end


function ratPackUtils.tearsUp(firedelay, val)
    local currentTears = 30 / (firedelay + 1)
    local newTears = currentTears + val
    return math.max((30 / newTears) - 1, -0.99)
end

function ratPackUtils.round(value)
    return math.floor(value+.5)
end


function ratPackUtils.debugSpawn(id, variant)
    local alreadySpawned = false
    for i, entity in pairs(Isaac.GetRoomEntities()) do
        if entity.Type == id then
            alreadySpawned = true
        end
    end
    
    if not alreadySpawned then
        Isaac.Spawn(id, variant, 0, Vector(320,350), Vector(0,0), nil)
    end
end

function ratPackUtils.debugItemSpawn(id, isTrinket)
    isTrinket = isTrinket or false
    local player = Isaac.GetPlayer(0)
    if player then
        if isTrinket then
            if not player:HasTrinket(id) then
                Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TRINKET, id, Vector(320,300), Vector(0,0), nil)
            end
        elseif not player:HasCollectible(id) then
            Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, id, Vector(320,300), Vector(0,0), nil)
        end
    end
end

function ratPackUtils.Lerp(vec1, vec2, percent)
    return vec1 * (1 - percent) + vec2 * percent
end

function ratPackUtils.printScreen(str, pos)
    local screenPos = Isaac.WorldToScreen(pos)
    Isaac.RenderText(str, screenPos.X,screenPos.Y,1,1,1,1)
end



return ratUtils