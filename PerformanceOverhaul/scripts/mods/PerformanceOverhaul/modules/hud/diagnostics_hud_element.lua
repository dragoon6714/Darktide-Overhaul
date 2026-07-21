local mod = get_mod("PerformanceOverhaul")

-- Diagnostics HUD element (AGENT.md §4.9). Loaded by the game's require via DMF's
-- add_require_path (dmf/scripts/mods/dmf/modules/gui/custom_hud_elements.lua), so this
-- file must return the class. Base class + update signature verified against
-- scripts/ui/hud/elements/hud_element_base.lua:10/:211.
local UIWorkspaceSettings = require("scripts/settings/ui/ui_workspace_settings")
local UIWidget = require("scripts/managers/ui/ui_widget")

local Definitions = {
	scenegraph_definition = {
		screen = UIWorkspaceSettings.screen,
		perf_overhaul_diag = {
			parent = "screen",
			size = { 520, 360 },
			vertical_alignment = "top",
			horizontal_alignment = "left",
			position = { 20, 180, 55 },
		},
	},
	widget_definitions = {
		diag_text = UIWidget.create_definition({
			{
				pass_type = "text",
				value = "",
				value_id = "text",
				style_id = "text_style",
				style = {
					font_type = "proxima_nova_bold",
					font_size = 16,
					text_vertical_alignment = "top",
					text_horizontal_alignment = "left",
					text_color = Color.terminal_text_body(255, true),
					offset = { 0, 0, 1 },
				},
			},
		}, "perf_overhaul_diag"),
	},
}

local PerfOverhaulDiagnostics = class("PerfOverhaulDiagnostics", "HudElementBase")

PerfOverhaulDiagnostics.init = function(self, parent, draw_layer, start_scale)
	PerfOverhaulDiagnostics.super.init(self, parent, draw_layer, start_scale, Definitions)
end

PerfOverhaulDiagnostics.update = function(self, dt, t, ui_renderer, render_settings, input_service)
	PerfOverhaulDiagnostics.super.update(self, dt, t, ui_renderer, render_settings, input_service)

	local widget = self._widgets_by_name.diag_text
	local visible = mod.diag_visible or false

	widget.visible = visible

	if visible then
		widget.content.text = mod.diag_text or ""
	end
end

return PerfOverhaulDiagnostics
