if data.is_demo then
  return
end

-- This auto-generates barrel items and fill/empty recipes for every fluid defined that doesn't have "auto_barrel = false".

-- The technology the barrel unlocks will be added to
local technology_name = "fluid-handling"
-- The base empty barrel item
local empty_barrel_name = "empty-barrel"

-- Item icon masks
local barrel_side_mask = "__base__/graphics/icons/fluid/barreling/barrel-side-mask.png"
local barrel_hoop_top_mask = "__base__/graphics/icons/fluid/barreling/barrel-hoop-top-mask.png"

-- Recipe icon masks
local barrel_empty = "__base__/graphics/icons/fluid/barreling/barrel-empty.png"
local barrel_empty_side_mask = "__base__/graphics/icons/fluid/barreling/barrel-empty-side-mask.png"
local barrel_empty_top_mask = "__base__/graphics/icons/fluid/barreling/barrel-empty-top-mask.png"
local barrel_fill = "__base__/graphics/icons/fluid/barreling/barrel-fill.png"
local barrel_fill_side_mask = "__base__/graphics/icons/fluid/barreling/barrel-fill-side-mask.png"
local barrel_fill_top_mask = "__base__/graphics/icons/fluid/barreling/barrel-fill-top-mask.png"

-- Alpha used for barrel masks
local side_alpha = 0.75
local top_hoop_alpha = 0.75
-- Fluid required per barrel recipe
local fluid_per_barrel = 250
-- Crafting energy per barrel fill recipe
local energy_per_fill = 1
-- Crafting energy per barrel empty recipe
local energy_per_empty = 1
-- If the fill/empty recipes effect production statistics
local hide_barreling_from_production_stats = true


local function get_technology(name)
  local technologies = data.raw["technology"]
  if technologies then
    return technologies[name]
  end
  return nil
end

local function get_item(name)
  local items = data.raw["item"]
  if items then
    return items[name]
  end
  return nil
end

local function get_recipes_for_barrel(name)
  local recipes = data.raw["recipe"]
  if recipes then
    return recipes["fill-" .. name], recipes["empty-" .. name]
  end
  return nil
end

-- Generates the icons definition for a barrel item with the provided name and fluid definition using the provided empty barrel base icon
local function generate_barrel_item_icons(name, fluid, empty_barrel_item)
  local side_tint = util.table.deepcopy(fluid.base_color)
  side_tint.a = side_alpha
  local top_hoop_tint = util.table.deepcopy(fluid.flow_color)
  top_hoop_tint.a = top_hoop_alpha

  return
  {
    {
      icon = empty_barrel_item.icon
    },
    {
      icon = barrel_side_mask,
      tint = side_tint
    },
    {
      icon = barrel_hoop_top_mask,
      tint = top_hoop_tint
    }
  }
end

-- Generates a barrel item with the provided name and fluid definition using the provided empty barrel stack size
local function create_barrel_item(name, fluid, empty_barrel_item)
  local result =
  {
    type = "item",
    name = name,
    localised_name = {"item-name.filled-barrel", {"fluid-name." .. fluid.name}},
    icons = generate_barrel_item_icons(name, fluid, empty_barrel_item),
    flags = {"goes-to-main-inventory"},
    subgroup = "fill-barrel",
    order = "b[" .. name .. "]",
    stack_size = empty_barrel_item.stack_size
  }

  data:extend({result})
  return result
end

local function get_or_create_barrel_item(name, fluid, empty_barrel_item)
  local existing_item = get_item(name)
  if existing_item then
    return existing_item
  end

  return create_barrel_item(name, fluid, empty_barrel_item)
end

-- Generates the icons definition for a fill-barrel recipe with the provided barrel name and fluid definition
local function generate_fill_barrel_icons(name, fluid)
  local side_tint = util.table.deepcopy(fluid.base_color)
  side_tint.a = side_alpha
  local top_hoop_tint = util.table.deepcopy(fluid.flow_color)
  top_hoop_tint.a = top_hoop_alpha

  return
  {
    {
      icon = "__base__/graphics/icons/fluid/barreling/barrel-fill.png"
    },
    {
      icon = barrel_fill_side_mask,
      tint = side_tint
    },
    {
      icon = barrel_fill_top_mask,
      tint = top_hoop_tint
    },
    {
      icon = fluid.icon,
      scale = 0.5,
      shift = {4, -8}
    }
  }
end

-- Generates the icons definition for a empty-barrel recipe with the provided barrel name and fluid definition
local function generate_empty_barrel_icons(name, fluid)
  local side_tint = util.table.deepcopy(fluid.base_color)
  side_tint.a = side_alpha
  local top_hoop_tint = util.table.deepcopy(fluid.flow_color)
  top_hoop_tint.a = top_hoop_alpha

  return
  {
    {
      icon = "__base__/graphics/icons/fluid/barreling/barrel-empty.png"
    },
    {
      icon = barrel_empty_side_mask,
      tint = side_tint
    },
    {
      icon = barrel_empty_top_mask,
      tint = top_hoop_tint
    },
    {
      icon = fluid.icon,
      scale = 0.5,
      shift = {7, 8}
    }
  }
end

-- Creates a recipe to fill the provided barrel item with the provided fluid
local function create_fill_barrel_recipe(item, fluid)
  local recipe =
  {
    type = "recipe",
    name = "fill-" .. item.name,
    localised_name = {"recipe-name.fill-barrel", {"fluid-name." .. fluid.name}},
    category = "crafting-with-fluid",
    energy_required = energy_per_fill,
    subgroup = "fill-barrel",
    order = "b[fill-" .. item.name .. "]",
    enabled = false,
    icons = generate_fill_barrel_icons(item, fluid),
    ingredients =
    {
      {type = "fluid", name = fluid.name, amount = fluid_per_barrel},
      {type = "item", name = empty_barrel_name, amount = 1},
    },
    results=
    {
      {type = "item", name = item.name, amount = 1}
    },
    hide_from_stats = hide_barreling_from_production_stats
  }

  data:extend({recipe})
  return recipe
end

-- Creates a recipe to empty the provided full barrel item producing the provided fluid
local function create_empty_barrel_recipe(item, fluid)
  local recipe =
  {
    type = "recipe",
    name = "empty-" .. item.name,
    localised_name = {"recipe-name.empty-filled-barrel", {"fluid-name." .. fluid.name}},
    category = "crafting-with-fluid",
    energy_required = energy_per_empty,
    subgroup = "empty-barrel",
    order = "c[empty-" .. item.name .. "]",
    enabled = false,
    icons = generate_empty_barrel_icons(item, fluid),
    ingredients =
    {
      {type = "item", name = item.name, amount = 1}
    },
    results=
    {
      {type = "fluid", name = fluid.name, amount = fluid_per_barrel},
      {type = "item", name = empty_barrel_name, amount = 1}
    },
    hide_from_stats = hide_barreling_from_production_stats
  }

  data:extend({recipe})
  return recipe
end

local function get_or_create_barrel_recipes(item, fluid)
  local fill_recipe, empty_recipe = get_recipes_for_barrel(item.name)

  if not fill_recipe then
    fill_recipe = create_fill_barrel_recipe(item, fluid)
  end
  if not empty_recipe then
    empty_recipe = create_empty_barrel_recipe(item, fluid)
  end

  return fill_recipe, empty_recipe
end

-- Adds the provided barrel recipe and fill/empty recipes to the technology as recipe unlocks if they don't already exist
local function add_barrel_to_technology(item, fill_recipe, empty_recipe, technology)
  local unlock_key = "unlock-recipe"
  local effects = technology.effects

  if not effects then
    technology.effects = {}
    effects = technology.effects
  end

  local add_item = true
  local add_fill_recipe = true
  local add_empty_recipe = true

  for k,v in pairs(effects) do
    if k == unlock_key then
      local recipe = v.recipe
      if recipe == item.name then
        add_item = false
      elseif recipe == fill_recipe.name then
        add_fill_recipe = false
      elseif recipe == empty_recipe.name then
        add_empty_recipe = false
      end
    end
  end

  if add_fill_recipe then
    table.insert(effects, {type = unlock_key, recipe = fill_recipe.name})
  end
  if add_empty_recipe then
    table.insert(effects, {type = unlock_key, recipe = empty_recipe.name})
  end
end

local function get_disabled_reason(fluids, technology, empty_barrel_item)
  if not fluids then
    return "there are no fluids"
  end

  if not technology then
    return "the " .. technology_name .. " technology doesn't exist"
  end

  if not empty_barrel_item then
    return "the " .. empty_barrel_name .. " item doesn't exist"
  end

  if not empty_barrel_item.icon then
    return "the " .. empty_barrel_name .. " item singular-icon definition doesn't exist"
  end
end

local function process_fluids(fluids, technology, empty_barrel_item)
  if not fluids or not technology or not empty_barrel_item or not empty_barrel_item.icon then
    log("Auto barrel generation is disabled: " .. get_disabled_reason(fluids, technology, empty_barrel_item) .. ".")
  end

  for name,fluid in pairs(fluids) do
    -- Allow fluids to opt-out
    if (fluid.auto_barrel == nil or fluid.auto_barrel) and fluid.icon then

      local barrel_name = fluid.name .. "-barrel"

      -- check if a barrel already exists for this fluid if not - create one
      local barrel_item = get_or_create_barrel_item(barrel_name, fluid, empty_barrel_item)

      -- check if the barrel has a recipe if not - create one
      local barrel_fill_recipe, barrel_empty_recipe = get_or_create_barrel_recipes(barrel_item, fluid)

      -- check if the barrel recipe exists in the unlock list of the technology if not - add it
      add_barrel_to_technology(barrel_item, barrel_fill_recipe, barrel_empty_recipe, technology)
    end
  end
end

process_fluids(data.raw["fluid"], get_technology(technology_name), get_item(empty_barrel_name))