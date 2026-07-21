return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`Performance Overhaul` encountered an error loading the Darktide Mod Framework.")

		new_mod("PerformanceOverhaul", {
			mod_script       = "PerformanceOverhaul/scripts/mods/PerformanceOverhaul/PerformanceOverhaul",
			mod_data         = "PerformanceOverhaul/scripts/mods/PerformanceOverhaul/PerformanceOverhaul_data",
			mod_localization = "PerformanceOverhaul/scripts/mods/PerformanceOverhaul/PerformanceOverhaul_localization",
		})
	end,
	packages = {},
}
