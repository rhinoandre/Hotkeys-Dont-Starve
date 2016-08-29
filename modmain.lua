local handlers =
{
  T = 'torch',
  
  A = 'axe',
  P = 'pickaxe',
  M = 'machete',
  S = 'shovel',
  H = 'hammer',
  
  C = 'campfire',
  O = 'coldfire',
  
  J = function (p, i)
    if i and i.activeitem then
      i:DropItem(i.activeitem, true) -- all stack
    end
  end,
  
  U = function (p, i)
    local equipped = i:GetEquippedItem(GLOBAL.EQUIPSLOTS.HANDS)
  
    if equipped then
      i:Unequip(GLOBAL.EQUIPSLOTS.HANDS)
      i:GiveItem(equipped)
    end
  end,
  
  Y = function (p, i)
    local eater = p.components.eater
    
    if i and i.activeitem then
      local action = GLOBAL.BufferedAction(p, i.activeitem, GLOBAL.ACTIONS.EAT)
      p:PushBufferedAction(action)
    end
  end
}

function ok(input)
  return not (GLOBAL.IsPaused()
    or input:IsKeyDown(GLOBAL.KEY_CTRL)
    or input:IsKeyDown(GLOBAL.KEY_SHIFT)
    or input:IsKeyDown(GLOBAL.KEY_ALT))
end

for key, item in pairs(handlers) do
  GLOBAL.TheInput:AddKeyDownHandler(GLOBAL['KEY_' .. key], function()
    local input  = GLOBAL.TheInput
	  local player = GLOBAL.GetPlayer()

    local builder   = player.components.builder
    local inventory = player.components.inventory

    if not ok(GLOBAL.TheInput) then return end

    if type(item) == 'function' then
      print("ACTION [ " .. key .. " ]")
      item(player, inventory)
    else
      local existing = inventory:FindItem(function(e) return e.prefab == item end)
      local recipe   = GLOBAL.GetRecipe(item)
      
      if existing then
        inventory:Equip(existing)
      elseif recipe then
        local accessible = builder.accessible_tech_trees
        local can_build  = builder:CanBuild(item)
        local known      = builder:KnowsRecipe(item)
        local prebuilt   = builder:IsBuildBuffered(item)
        local can_do     = prebuilt or can_build and (known or GLOBAL.CanPrototypeRecipe(recipe.level, accessible))

	      if recipe.placer and can_do then
    	    builder:MakeRecipe(recipe, GLOBAL.Vector3(player.Transform:GetWorldPosition()), player:GetRotation(), function()
            if not known then
              player.SoundEmitter:PlaySound("dontstarve/HUD/research_unlock")
              builder:ActivateCurrentResearchMachine()
              builder:UnlockRecipe(item)
            end
          end)
        else
          GLOBAL.DoRecipeClick(player, recipe)
        end

      end
    end
  end)
end

