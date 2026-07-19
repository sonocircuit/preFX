-- preFX v0.1 - boilerplate pre-insert-fx - @sonoCircuit

local mod = require 'core/mods'

--------------------------- variables --------------------------
-- table of params without "prefx_" prefix. important: 'state' comes last!
local paramslist = {"routing", "drive", "state"}


--------------------------- osc msgs ---------------------------

local function init_prefx()
  osc.send({ "localhost", 57120 }, "/prefx/init")
end

local function free_prefx()
  osc.send({ "localhost", 57120 }, "/prefx/free")
end

local function set_state(state)
  osc.send({ "localhost", 57120 }, "/prefx/set_state", {state - 1})
end

local function set_bus(bus)
  osc.send({ "localhost", 57120 }, "/prefx/set_bus", {bus - 1})
end

-- key (string) corresponds to synthDef arg > set in params:set_action()
local function set_param(key, val)
  osc.send({ "localhost", 57120 }, "/prefx/set_param", {key, val})
end

--------------------------- params ---------------------------
local function bang_params()
  for _, prm in ipairs(paramslist) do
    params:lookup_param("prefx_"..prm):bang()
  end
end

local function add_prefx()
  params:add_group("prefx_group", "preFX", 4)

  params:add_option("prefx_state", "state", {"off", "on"}, 1)
  params:set_action("prefx_state", function(state) set_state(state) end)

  params:add_option("prefx_routing", "routing", {"pre-eng", "post-eng"}, 1)
  params:set_action("prefx_routing", function(bus) set_bus(bus) end)

  -----------------------------------------------------------------------------
  params:add_separator("prefx_settings", "settings")

  -- add all params required by your synthdef. 
  params:add_control("prefx_drive", "drive", controlspec.new(0, 1, "lin", 0, 0), function(param) return util.round(param:get() * 100, 1).."%" end)
  params:set_action("prefx_drive", function(val) set_param('drive', val) end)

  -----------------------------------------------------------------------------
  -- manually bang params.
  -- do not use params:bang() as we don't want to bang all script params post init.
  bang_params()

end

--------------------------- mod zone ---------------------------

mod.hook.register("system_post_startup", "preFX post startup", init_prefx)
mod.hook.register("script_post_init", "preFX post init", add_prefx)
mod.hook.register("script_post_cleanup", "preFX cleanup", free_prefx)
