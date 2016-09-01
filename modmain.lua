local handlers =
{
    F1 = 'torch',

    F2 = {'goldenaxe', 'axe'},
    F3 = {'goldenpickaxe', 'pickaxe'},
    F4 = {'goldenmachete', 'machete'},
    F5 = {'goldenshovel', 'shovel'},
    F6 = 'hammer',

    F7 = 'campfire',
    F8 = 'coldfire',

    F9 = function (p, i)
        if i and i.activeitem then
            i:DropItem(i.activeitem, true) -- all stack
        end
    end,

    F10 = function (p, i)
        local equipped = i:GetEquippedItem(GLOBAL.EQUIPSLOTS.HANDS)

        if equipped then
            i:Unequip(GLOBAL.EQUIPSLOTS.HANDS)
            i:GiveItem(equipped)
        end
    end,

    F11 = function (p, i)
        local eater = p.components.eater

        if i and i.activeitem then
            local action = GLOBAL.BufferedAction(p, i.activeitem, GLOBAL.ACTIONS.EAT)
            p:PushBufferedAction(action)
        end
    end
}

function ok(input, key)
    -- Machete exists only in Shipwrecked DLC
    local onlyInShipwrecked = (GLOBAL.TheSim:GetGameID() == "DST" or GLOBAL.IsDLCEnabled(GLOBAL.REIGN_OF_GIANTS)) and key == "F4"

    return ((GLOBAL.IsPaused()
        or input:IsKeyDown(GLOBAL.KEY_CTRL)
        or input:IsKeyDown(GLOBAL.KEY_SHIFT)
        or input:IsKeyDown(GLOBAL.KEY_ALT))
        or onlyInShipwrecked)
end

local player
function getPlayer()
    if player == nil then
        if GLOBAL.TheSim:GetGameID() == "DST" then
            player = GLOBAL.ThePlayer
        else
            player = GLOBAL.GetPlayer()
        end
    end
    return player
end

local recipe
function setRecipe(recipeName)
    if GLOBAL.TheSim:GetGameID() == "DST" then
        recipe = GLOBAL.GetValidRecipe(recipeName)
    else
        recipe =  GLOBAL.GetRecipe(recipeName)
    end
end

for key, item in pairs(handlers) do
    GLOBAL.TheInput:AddKeyDownHandler(GLOBAL['KEY_' .. key], function()
        local input     = GLOBAL.TheInput
        local builder   = getPlayer().components.builder
        local inventory = getPlayer().components.inventory
        local itemType  = type(item)

        if ok(GLOBAL.TheInput, key) then return end

        if itemType == 'function' then
            print("ACTION [ " .. key .. " ]")
            item(getPlayer(), inventory)
        else
            local existing = nil

            if itemType == 'table' then
                for key,specItem in ipairs(item) do
                    existing = inventory:FindItem(function(e) return e.prefab == specItem end)
                    if existing then
                        break
                    end
                end

            else
                existing = inventory:FindItem(function(e) return e.prefab == item end)
                setRecipe(item)
            end

            if existing then
                print("ACTION [" .. key .. "]")
                inventory:Equip(existing)
            else
                local accessible = builder.accessible_tech_trees
                local can_build  = nil
                local known      = nil
                local prebuilt   = nil
                local can_do     = nil

                if itemType == 'table' then

                    for key,specItem in ipairs(item) do
                        setRecipe(specItem)
                        can_build   = builder:CanBuild(specItem)
                        known       = builder:KnowsRecipe(specItem)
                        prebuilt    = builder:IsBuildBuffered(specItem)
                        can_do      = prebuilt or can_build and (known or GLOBAL.CanPrototypeRecipe(recipe.level, accessible))
                        if can_do then
                            break
                        end
                    end
                else
                    setRecipe(item)
                    can_build   = builder:CanBuild(item)
                    known       = builder:KnowsRecipe(item)
                    prebuilt    = builder:IsBuildBuffered(item)
                    can_do      = prebuilt or can_build and (known or GLOBAL.CanPrototypeRecipe(recipe.level, accessible))
                end

                if recipe.placer and can_do then
                    builder:MakeRecipe(recipe, GLOBAL.Vector3(getPlayer().Transform:GetWorldPosition()), getPlayer():GetRotation(), function()
                        if not known then
                            getPlayer().SoundEmitter:PlaySound("dontstarve/HUD/research_unlock")
                            builder:ActivateCurrentResearchMachine()
                            --builder:UnlockRecipe(item)
                        end
                    end)
                else
                    GLOBAL.DoRecipeClick(getPlayer(), recipe)
                end

            end
        end
    end)
end
