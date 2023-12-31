local this = {}
this.id = Isaac.GetEntityTypeByName("Healer Fly")


function this:behavior(npc)
    local player = Isaac.GetPlayer(0);
    local data = npc:GetData()
    local sprite = npc:GetSprite();

    if(npc.State == NpcState.STATE_INIT) then
        --npc:PlaySound(SoundEffect.SOUND_INSECT_SWARM_LOOP, .5, 0, true, 1);
        SFXManager():Play(SoundEffect.SOUND_INSECT_SWARM_LOOP, .5, 0, true, 1,0)
        npc.State = NpcState.STATE_MOVE;
        data.GridCountdown = 0
        data.sped = .8
    end
    
    --MOVING
    if(npc.State == NpcState.STATE_MOVE) then
        data.sped = .8
        if data.npcState == "holding" then
            sprite:Play("FlyHolding")
        else
            sprite:Play("Fly")
        end

        --movement behavior
        if npc:HasEntityFlags(EntityFlag.FLAG_FEAR) then
            ratPackUtils.fearEffect(npc, player)
        else if npc:HasEntityFlags(EntityFlag.FLAG_CONFUSION) then
            ratPackUtils.confuseEffect(npc)
        else
            if(data.GridCountdown <= 0) then
                if data.npcState ~= "holding" then --only pick up a poop when there is a hurt enemy
                    if this:findHurtEnemy() ~= nil then
                        data.target = this:findNearestPoop(npc)
                    end
                else
                    data.target = this:findHurtEnemy()
                end
            end
            
            if data.target ~= nil then
                data.sped = .8
                if data.GridCountdown > 0  then -- after healing an entity, run away a short distance from that entity, then reset target
                    npc.Velocity = (npc.Position - data.target.Position):Normalized() *1.15 +npc.Velocity * data.sped;
                    data.GridCountdown = data.GridCountdown - 1
                    if(data.GridCountdown <= 0) then
                        data.target = nil
                    end
                elseif(npc.Position - data.target.Position):Length() < 35 then--when in range of a target, change npcState to interact with it
                    npc.State = NpcState.STATE_SPECIAL
                else
                    npc.Velocity = (data.target.Position - npc.Position):Normalized() *1.15 +npc.Velocity * data.sped;
                end
            else --if no one to heal and already grabbed a poop, wander around slowly
                data.sped = .2
                ratPackUtils.confuseEffect(npc,100)
            end
            
        end
        end
        
    end

    if npc.State == NpcState.STATE_SPECIAL then--Healing behavior
                                            --if healerFly has not grabbed a poop yet
        if data.npcState ~= "holding" then --once standing over a poop, grab it and then set state == holding
            if(sprite:IsPlaying("Grab") == false)then
                sprite:Play("Grab")
            end
            if sprite:GetFrame() == 11 then
                data.npcState = "holding"
                data.target:Hurt(1)
                npc.State = NpcState.STATE_MOVE
            end
        else --once standing over an enemy, heal it then set state = nil

            if npc:HasEntityFlags(EntityFlag.FLAG_POISON) then --if healerFly is poisoned, poison the target instead of healing it
                data.target:AddPoison(EntityRef(npc), 80,2)
            else
                npc:PlaySound(SoundEffect.SOUND_VAMP_GULP, 0.5, 0, false, 1)
                local vEffect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.HEART, 0, data.target.Position, Vector(0,0), nil);
                vEffect:ToEffect():SetTimeout(30);
                data.target:AddHealth(3)
            end
            --reset variables and set GridCountdown = 30 to make healerFly run away 
            data.npcState = nil
            data.GridCountdown = 50
            npc.State = NpcState.STATE_MOVE
        end
        
    end
end

function this:findHurtEnemy()
    for i, entity in pairs(Isaac.GetRoomEntities()) do
        if entity:IsEnemy() and entity.Type ~= this.id and entity:HasFullHealth() == false then
            return entity
        end
    end
    return nil
end

function this:findNearestPoop(npc) --return the closest intact poop to npc or nil if there are no poops
    local room = game:GetRoom()
    local result = nil
    
    for i=0, room:GetGridSize() do
        local gridEntity = room:GetGridEntity(i)
        if gridEntity then
            if gridEntity.Desc.Type == GridEntityType.GRID_POOP and gridEntity.State < 1000 and (result == nil or (npc.Position - gridEntity.Position):Length() < (npc.Position - result.Position):Length()) then
                result = gridEntity
            end
        end
    end
    return result
end

function this.Init()
    ratPackMod:AddCallback(ModCallbacks.MC_NPC_UPDATE, this.behavior, this.id)
end

return this