local this = {}
this.description = "+1 Black heart#Enemies spawned by other enemies will be poisoned"
this.id = Isaac.GetItemIdByName("Strange Snacks")

this.spawnedRottenHeart = false


function this:poisonEffect(npc)
    for i = 0, game:GetNumPlayers()-1 do
        player = Isaac.GetPlayer(i)
        --if the spawned npc has a parent and the npc is not a worm type enemy, poison the npc
        if player:HasCollectible(this.id) and npc:IsVulnerableEnemy() and npc.SpawnerEntity ~= nil and npc.Type ~= npc.SpawnerEntity.Type then 
            --levelNum = game:GetLevel():GetAbsoluteStage() -1 --increase poison damage by .05 up to 2.5
            --npc:AddPoison(EntityRef(player), 60, math.min(2.5,2+(levelNum/20)))
            npc:AddPoison(EntityRef(player), 60, 2)
        end
    end
end

function this.Init()
    ratPackMod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, this.poisonEffect)
end


return this