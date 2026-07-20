-- preFX v0.1 - pre-insert-fx boilerplate - @sonoCircuit

local mod = require 'core/mods'


--------------------------- variables ---------------------------

-- replace with your own strings
local m = {}
m.name = "preFX" -- UI
m.addr = "/prefx/" -- osc address
m.param = function(id) return "prefx_"..id end -- param prefix

-- table of all param id's. important: 'state' comes last!
-- this is required to bang the params post init.
local paramslist = {"routing", "drive", "state"}


--------------------------- osc msgs ---------------------------

local function initalize()
  osc.send({ "localhost", 57120 }, m.addr.."init")
end

local function free()
  osc.send({ "localhost", 57120 }, m.addr.."free")
end

local function set_state(state)
  osc.send({ "localhost", 57120 }, m.addr.."set_state", {state - 1})
end

local function set_bus(bus)
  osc.send({ "localhost", 57120 }, m.addr.."set_bus", {bus - 1})
end

local function set_param(key, val)
  osc.send({ "localhost", 57120 }, m.addr.."set_param", {key, val})
end


--------------------------- params ---------------------------
local function bang_params()
  for _, prm in ipairs(paramslist) do
    params:lookup_param(m.param(prm)):bang()
  end
end

local function add_params()
  params:add_group(m.param("group"), m.name, 4)

  params:add_option(m.param("state"), "state", {"off", "on"}, 1)
  params:set_action(m.param("state"), function(state) set_state(state) end)

  params:add_option(m.param("routing"), "routing", {"pre-eng", "post-eng"}, 1)
  params:set_action(m.param("routing"), function(bus) set_bus(bus) end)

---------------------------/ user zone /---------------------------
  params:add_separator(m.param("settings"), "settings")

  -- add all params required by your synthdef. 
  params:add_control(m.param("drive"), "drive", controlspec.new(0, 1, "lin", 0, 0), function(param) return util.round(param:get() * 100, 1).."%" end)
  params:set_action(m.param("drive"), function(val) set_param('drive', val) end) -- use set_param('myArg', val) to set the sc params

---------------------------------/---------------------------------

  -- manually bang params to avoid using params:bang() as we don't want to bang all script params post init.
  bang_params()

end


--------------------------- mod zone ---------------------------

mod.hook.register("system_post_startup", m.name.." post startup", initalize)
mod.hook.register("script_post_init", m.name.." post init", add_params)
mod.hook.register("script_post_cleanup", m.name.." cleanup", free)
