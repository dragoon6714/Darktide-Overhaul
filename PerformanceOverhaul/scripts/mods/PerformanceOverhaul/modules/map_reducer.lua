local mod = get_mod("PerformanceOverhaul")

-- Map rendering reducer: hides pure-decorative level units. Classification is by hard
-- evidence only: a unit is hidden ONLY if it has NO script extensions at all
-- (ScriptUnit.extensions(unit) empty — every interactive object: pickup, door,
-- objective, destructible, health station, carries an extension), is not a "NavGate",
-- and (conservative) owns no lights. Purely local-visual; revert restores visibility.

local ScriptUnit = require("scripts/foundation/utilities/script_unit")

local counters = mod.counters

local mode = "off"
local hidden_units = {}
local num_hidden = 0

local function is_pure_decoration(unit, allow_light_fixtures)
	-- ScriptUnit.extensions returns the unit's extension map (script_unit.lua:56).
	local extensions = ScriptUnit.extensions(unit)

	if extensions and next(extensions) ~= nil then
		return false
	end

	-- Nav-relevant geometry check (pattern from destructible_extension.lua:246).
	if Unit.has_visibility_group(unit, "NavGate") then
		return false
	end

	if not allow_light_fixtures and Unit.num_lights(unit) > 0 then
		return false
	end

	return true
end

local function show_hidden()
	for unit in pairs(hidden_units) do
		if Unit.alive(unit) then
			Unit.set_unit_visibility(unit, true)
		end

		hidden_units[unit] = nil
	end

	num_hidden = 0
	counters.clutter_hidden = 0
end

local function scan_and_hide()
	show_hidden()

	if mode == "off" then
		return
	end

	-- Level accessor verified: scripts/managers/mission/mission_manager.lua:50;
	-- Level.units enumeration pattern from scripts/loading/expedition_spawner.lua:107.
	local mission_manager = Managers.state and Managers.state.mission
	local level = mission_manager and mission_manager:mission_level()

	if not level then
		return
	end

	local allow_light_fixtures = mode == "aggressive"
	local level_units = Level.units(level)

	for i = 1, #level_units do
		local unit = level_units[i]

		if Unit.alive(unit) and is_pure_decoration(unit, allow_light_fixtures) then
			Unit.set_unit_visibility(unit, false)

			hidden_units[unit] = true
			num_hidden = num_hidden + 1
		end
	end

	counters.clutter_hidden = num_hidden
	mod:info("map_reducer: hid %d decorative units (%s)", num_hidden, mode)
end

-- Target verified: scripts/game_states/game/state_gameplay.lua:11 StateGameplay.on_enter
-- — level units exist by gameplay start; hook_safe (observation only).
mod:hook_safe("StateGameplay", "on_enter", function()
	if mode ~= "off" then
		scan_and_hide()
	end
end)

-- Units die with the level; drop stale references when gameplay ends (the Unit.alive
-- guard in show_hidden makes this safe on a dying level).
mod:hook_safe("StateGameplay", "on_exit", function()
	show_hidden()
end)

local map_reducer = {}

map_reducer.apply = function(settings)
	mode = settings.map_reducer_mode or "off"

	scan_and_hide()
end

map_reducer.revert = function()
	mode = "off"

	show_hidden()
	mod:info("map_reducer: reverted, all units restored")
end

map_reducer.on_setting_changed = function(setting_id, value)
	if setting_id == "map_reducer_mode" then
		mode = value or "off"

		scan_and_hide()
	end
end

return map_reducer
