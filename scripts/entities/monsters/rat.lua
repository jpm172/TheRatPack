local this = {}
this.id = Isaac.GetEntityTypeByName("Rat")

local ratTail = Isaac.GetEntityVariantByName("Rat Tail")

function this:behavior(npc)
    local room = game:GetRoom()
    local data = npc:GetData()
    local target = npc:GetPlayerTarget();
    local sprite = npc:GetSprite();
    
    
    if(npc.State == NpcState.STATE_INIT) then
        npc.State = NpcState.STATE_MOVE
        data.biteCooldown = 0
        data.squeakCooldown = math.random(10,120)
        data.sped = math.random(75,85)/100 
        data.tailNum = math.random(2, 7)
        

        --spawns and connects all the tail segments
        if data.tail == nil then
            local prevTail = Isaac.Spawn(1000, ratTail, 0, npc.Position, Vector(0,0), npc)
            data.tail = prevTail
            prevTail.Parent = npc
            prevTail.DepthOffset = -1
            for i = 1, data.tailNum do
                local tail = Isaac.Spawn(1000, ratTail, 0, npc.Position, Vector(0,0), npc)
                local tailScale  = math.max(.5,(10 - i)/10)
                tail.DepthOffset = -(i +1)

                tail.SpriteScale = Vector(1,tailScale)
                tail.Parent = prevTail
                prevTail = tail
            end
        end
    end
   -- print(npc:GetColor())

    --MOVING
    if(npc.State == NpcState.STATE_MOVE) then
        local targetPos = target.Position
        --local hasPath, hitPos = room:CheckLine( npc.Position,targetPos + (npc.Position - targetPos):Resized(4), 0,1,false,false)
        local hasPath, hitPos = room:CheckLine( npc.Position,target.Position - (target.Position - npc.Position):Resized(target.Size+3), 0,1,false,false)
        
        if npc:HasEntityFlags(EntityFlag.FLAG_FEAR) then
            ratPackUtils.fearEffect(npc, target)
        else if npc:HasEntityFlags(EntityFlag.FLAG_CONFUSION) then
            ratPackUtils.confuseEffect(npc)
        else if not hasPath  then
                --look to clear the obstacle if the target is near the obstacle or there is no other path to the target
                if data.biteCooldown <= 0 and  ((targetPos - hitPos):Length() <= 120 or not npc.Pathfinder:HasPathToPos(targetPos))then
                    if data.obstacle == nil then
                        local e = room:GetGridEntityFromPos(hitPos+ (targetPos - npc.Position):Resized(40))--the gridEntity that is obstructing the rat
                        --if the obstacle has a weight >= 2, then tell rat to go destroy it
                        --this is to prevent the rat from destroying obstacles that arent really in the way (ie lone/sistered obstacles)
                        if e~= nil and e.CollisionClass ~= 0 and this:isValidType(e) and this:getObstacleWeight(e, room) >= 2   then
                            targetPos = e.Position
                            data.obstacle = e
                        end
                    else--if an obstacle has been found, have rat path towards it
                        targetPos = data.obstacle.Position
                        
                        if (targetPos - npc.Position):Length() < 45 then
                            npc.State = NpcState.STATE_SPECIAL
                        end
                        --this is a catch to prevent the rat from being stuck in a loop if the room geometery changes (ie reverse tower card)
                        if not npc.Pathfinder:HasPathToPos(targetPos)then
                            data.obstacle = nil
                        end
                    end
                else
                    --if the main search doesnt go through, reset to prevent loop
                    data.obstacle = nil
                end
                
                npc.Pathfinder:FindGridPath(targetPos, data.sped, 1, true)
                
            else
                npc.Velocity = (targetPos - npc.Position):Normalized() *1.15 +npc.Velocity * data.sped;
                data.obstacle = nil--if player has direct line of sight, reset the obstacle clearing system
            end
        end
        end
        
        local vertAnim ="Move Down"
        if(npc.Velocity.Y < 0) then--change what string goes into AnimWalkFrame depending on velocity
            vertAnim = "Move Up"
        end
        
        npc:AnimWalkFrame("Move Hori", vertAnim, 0.1)

        if data.squeakCooldown <= 0 then
            if ratPackUtils.chancep(50) then
                npc:PlaySound(SoundEffect.SOUND_LITTLE_HORN_GRUNT_1, 0.3,0 , false, 1.3)
            else
                npc:PlaySound(SoundEffect.SOUND_CUTE_GRUNT, 0.3,0 , false, 1.3);
            end
            
            data.squeakCooldown = math.random(10,120)
        end
        
        --buttPos is used to position the first tail segment properly
        if sprite:IsPlaying("Move Hori") then
            data.buttPos = Vector(-20,0)
            if sprite.FlipX == true then
                data.buttPos = Vector(20,0)
            end
        elseif sprite:IsPlaying("Move Down") then
            data.buttPos = Vector(0,-10)
        elseif sprite:IsPlaying("Move Up") then
            data.buttPos = Vector(0,10)    
        end
        data.biteCooldown = data.biteCooldown - 1
        data.squeakCooldown = data.squeakCooldown -1
    end

    --OBSTACLE CLEARING
    if npc.State == NpcState.STATE_SPECIAL then
        npc.Velocity = Vector(0,0)
        if(npc.Position.Y < data.obstacle.Position.Y) then
            if(sprite:IsPlaying("Attack Down") == false) then
                sprite:Play("Attack Down");
            end
        elseif  npc.Position.Y >= data.obstacle.Position.Y then
            if(sprite:IsPlaying("Attack Up") == false)then
                sprite:Play("Attack Up");
            end
        elseif sprite:IsPlaying("Attack Hori") == false then
            sprite:Play("Attack Hori");
        end

        --once finished with the attack animation, destroy obstacle and reset
        if sprite:IsFinished() then
            data.obstacle:Destroy()
            room:SetGridPath(data.obstacle:GetGridIndex(),0) --set the path to 0 at the obstacle so the rat will use the shortcut it just made
            data.obstacle = nil
            npc.State = NpcState.STATE_MOVE;
            data.biteCooldown = 90
        end
    end
end

function this:isValidType(gridEntity)
    local type = gridEntity.Desc.Type
    if (gridEntity:ToRock() and type ~= GridEntityType.GRID_ROCKB) or type == GridEntityType.GRID_POOP or type == GridEntityType.GRID_TNT then
        return true
    end

    return false
end

--this calculates how many non-destroyed gridEntities are surrounding gridEntity e
function this:getObstacleWeight(e,room)
    local result = 0
    local index = e:GetGridIndex()
    
    if room:GetGridCollision(index + 1) ~=0 then --east
        result = result + 1
    end
    if room:GetGridCollision(index - 1) ~=0 then--west
        result = result + 1
    end
    if room:GetGridCollision(index + room:GetGridWidth ()) ~=0 then--south
        result = result + 1
    end
    if room:GetGridCollision(index - room:GetGridWidth ()) ~=0 then--north
        result = result + 1
    end
    if room:GetGridCollision(index - room:GetGridWidth ()+1) ~=0 then--north east
        result = result + 1
    end
    if room:GetGridCollision(index - room:GetGridWidth ()-1) ~=0 then--north west
        result = result + 1
    end

    if room:GetGridCollision(index + room:GetGridWidth ()+1) ~=0 then -- south east
        result = result + 1
    end
    if room:GetGridCollision(index + room:GetGridWidth ()-1) ~=0 then --south west
        result = result + 1
    end

    return result
end

function this:tailBehavior(npc)--rat tail effect
    if npc.Variant == ratTail then

        if npc.SpawnerEntity == nil then --delete all tail segments upon death
            npc:Remove()
            return
        end
        npc:SetColor(npc.Parent:GetColor(),15,1)
        local vec =(npc.Parent.Position - npc.Position)
        if vec:Length() >= 7 then
            if npc.Parent:GetData().buttPos ~= nil then
                npc.Position = ratPackUtils.Lerp(npc.Position, npc.Parent.Position + npc.Parent:GetData().buttPos,.6)
            else
                npc.Position = ratPackUtils.Lerp(npc.Position, npc.Parent.Position,.5)
            end
            
            npc:GetSprite().Rotation = vec:Normalized():GetAngleDegrees()
            
        end
    end
  
end




function this.Init()
    ratPackMod:AddCallback(ModCallbacks.MC_NPC_UPDATE, this.behavior, this.id)
    ratPackMod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, this.tailBehavior)
end

return this