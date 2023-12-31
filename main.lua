ratPackMod = RegisterMod("rat pack",1)
ratPackVersion = "1.0"
game = Game()
ratPackUtility = include ('scripts.ratPackUtils')


ratPackContent = {
    items = {
        haircut                 = include('scripts.items.haircut'),
        packRat                 = include('scripts.items.packRat'),
        strangeSnacks           = include('scripts.items.strangeSnacks'),
        BoM                     = include('scripts.items.bookOfMischief'),
        burrowBuster            = include('scripts.items.burrowBuster'),
    },
    entities = {
        rat                     = include('scripts.entities.monsters.rat'),
        --infestedRat             = include('scripts.entities.monsters.infestedRat'),
        healerFly               = include('scripts.entities.monsters.healerFly'),
    },
    }


print("tBoI The Rat Pack: Loading ")

for type, r in pairs(ratPackContent) do
    if r.noAutoload == nil then
        for name, class in pairs(r) do
            if EID then --attaches descriptions to content if EID mod is installed
                if type == "items" then
                    EID:addCollectible(class.id, class.description)
                elseif type == "trinkets" then
                    EID:addTrinket(class.id, class.description)
                end
            end
            
            if class.Init then
                class.Init()
            end
        end
    end
end



print("The rat pack version",ratPackVersion, "has loaded!")

