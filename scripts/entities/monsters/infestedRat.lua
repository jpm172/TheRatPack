local this = {}
this.id = Isaac.GetEntityTypeByName("Infested Rat")

function this:behavior(npc)
    local data = npc:GetData();
    local sprite = npc:GetSprite();

    --SPAWNING
    if data.spawned ~= true then
        data.timer = math.random(0, 200); -- 25 ticks == ~ 1 second
        npc.Velocity = Vector(0,0);
        npc:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK| EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK ); --prevents rat from moving
        data.spawned = true;
    end

    if data.timer <= 0 then
        if(ratPackUtils.canAttack(npc)) then
            sprite:Play("Shoot",true)
        end
        data.timer = math.random(75, 300)
    end

    if sprite:IsEventTriggered("Shoot") then
        Game():Spawn(Isaac.GetEntityTypeByName("Attack Fly"), 0, Vector(npc.Position.X, npc.Position.Y - 10), Vector(math.random(-3,3),math.random(-3,3)), npc,0,1)
    end

    data.timer = data.timer - 1;
end

--Use Lytebringer's video 16 & 28, but change the entity.Type to EntityType.ENTITY_PROJECTILE, tear=entity:ToTear() to proj=entity:ToProjectile(), and use entity.Parent checks to restrict the projectile changes to the custom enemy.

function this.Init()
    ratPackMod:AddCallback(ModCallbacks.MC_NPC_UPDATE, this.behavior, this.id)
   -- Isaac.Spawn(this.id, 0, 2, Vector(320,350), Vector(0,0), nil)
end

return this

