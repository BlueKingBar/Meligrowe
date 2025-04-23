---@diagnostic disable: lowercase-global

rom.gui.add_imgui(function()
	if rom.ImGui.Begin("Meligrowe") then
		drawMenu()
		rom.ImGui.End()
	end
end)

rom.gui.add_to_menu_bar(function()
	if rom.ImGui.BeginMenu("Configure") then
		drawMenu()
		rom.ImGui.EndMenu()
	end
end)

function drawMenu()
	if rom.ImGui.CollapsingHeader("Growth Settings") then
		rom.ImGui.TextWrapped("Size Change Mode")
		local scalingModes = { "Per Encounter", "Max HP" }
		rom.ImGui.PushItemWidth(200)
		if rom.ImGui.BeginCombo("###mode", config.growthMode) then
			for _, option in ipairs(scalingModes) do
				if rom.ImGui.Selectable(option, (option == config.growthMode)) then
					config.growthMode = option
					rom.ImGui.SetItemDefaultFocus()
					AddGrowTraitToHero()
				end
			end
			rom.ImGui.EndCombo()
		end
		rom.ImGui.PopItemWidth()

		if config.growthMode == "Per Encounter" then
			local sliderCap = 3.5
			if config.dangerousSizesAllowed then
				sliderCap = 10.0
			end

			rom.ImGui.TextWrapped("Starting Size")
			--value, used = rom.ImGui.InputFloat("Times Normal Size##startSize", config.startingSize, 0.1, 3.5)
			value, used = rom.ImGui.SliderFloat("Times Normal Size##startSize", config.startingSize, 0.1, sliderCap, "%.1f")
			if used then
				config.startingSize = value
				config.sizeGrowthPerRoom = (config.finalSize - config.startingSize) / 40
				GrowTraitUpdate()
			end

			rom.ImGui.TextWrapped("Approximate Final Size")
			--value, used = rom.ImGui.InputFloat("Times Normal Size##endSize", config.finalSize, 0.1, 3.5)
			value, used = rom.ImGui.SliderFloat("Times Normal Size##endSize", config.finalSize, 0.1, sliderCap, "%.1f")
			if used then
				config.finalSize = value
				config.sizeGrowthPerRoom = (config.finalSize - config.startingSize) / 40
				GrowTraitUpdate()
			end
			rom.ImGui.PushStyleColor(rom.ImGuiCol.Text, 0.75, 0.75, 0, 1)
			rom.ImGui.TextWrapped("* Olympus runs have over 30% more rooms! Size change will be much greater there.")
			rom.ImGui.TextWrapped("* Sliders can go further with size limit settings below, but this can cause gameplay issues.")
			rom.ImGui.PopStyleColor()

			rom.ImGui.TextWrapped("Growth Per Room (Direct Control)")
			value, used = rom.ImGui.InputFloat("Times Normal Size##growthPerRoom", config.sizeGrowthPerRoom, -1, 1)
			if used then
				config.sizeGrowthPerRoom = value
				config.finalSize = 40 * config.sizeGrowthPerRoom + config.startingSize
				GrowTraitUpdate()
			end
			rom.ImGui.TextWrapped("* Adjusts Final Size automatically.")

			if config.startingSize > 3.5 or config.finalSize > 3.5 then
				rom.ImGui.Spacing()
				rom.ImGui.PushStyleColor(rom.ImGuiCol.Text, 0.75, 0, 0, 1)
				rom.ImGui.TextWrapped("Gameplay gets hard/impossible if you're too big! 3.5 or less recommended.")
				if config.startingSize > 6.0 or config.finalSize > 6.0 then
					rom.ImGui.TextWrapped(
						"Sizes over 6.0 can cause CRASHES, SOFTLOCKS, and CLIPPING OUT OF BOUNDS! Use the unstuck hotkey (Alt U Default) or quit to main menu if you screw up."
					)
				end
				rom.ImGui.PopStyleColor()
			end

			rom.ImGui.Separator()

			rom.ImGui.TextWrapped("Starting Voice Pitch")
			value, used = rom.ImGui.SliderFloat("Pitch Difference##startPitch", config.startingPitch, -2.0, 2.0, "%.1f")
			if used then
				config.startingPitch = value
				config.voicePitchChangePerRoom = (config.finalPitch - config.startingPitch) / 40
				GrowTraitUpdate()
			end

			rom.ImGui.TextWrapped("Approximate Final Voice Pitch")
			value, used = rom.ImGui.SliderFloat("Pitch Difference##endPitch", config.finalPitch, -2.0, 2.0, "%.1f")
			if used then
				config.finalPitch = value
				config.voicePitchChangePerRoom = (config.finalPitch - config.startingPitch) / 40
				GrowTraitUpdate()
			end
			rom.ImGui.PushStyleColor(rom.ImGuiCol.Text, 0.75, 0.75, 0, 1)
			rom.ImGui.TextWrapped("* Olympus runs have over 30% more rooms! Size change will be much greater there.")
			rom.ImGui.TextWrapped("* Voice pitch sounds very silly below -1.1 and above 0.5.")
			rom.ImGui.PopStyleColor()

			rom.ImGui.TextWrapped("Pitch Per Room (Direct Control)")
			value, used = rom.ImGui.InputFloat("Pitch Difference##pitchPerRoom", config.voicePitchChangePerRoom, -1, 1)
			if used then
				config.voicePitchChangePerRoom = value
				config.finalPitch = 40 * config.voicePitchChangePerRoom + config.startingPitch
				GrowTraitUpdate()
			end
			rom.ImGui.TextWrapped("Adjusts Final Size automatically.")

			rom.ImGui.Separator()

			rom.ImGui.TextWrapped("Grows after this many rooms.")
			value, used = rom.ImGui.SliderInt("Rooms##roomCount", config.growEveryXRooms, 1, 10)
			if used then
				config.growEveryXRooms = value
				if HeroHasTrait("GrowTrait") and CurrentRun ~= nil and CurrentRun.EncounterDepth then
					local trait = GetHeroTrait("GrowTrait")
					local divisor = value
					local level = trait.GrowLevel or 0
					setRoomGrowTraitHelper(level, divisor, trait)
				end
				GrowTraitUpdate()
			end
			rom.ImGui.TextWrapped("* Does not change speed of growth. More rooms = bigger bursts of growth.")
		end --End growth mode: Per Encounter

		if config.growthMode == "Max HP" then
			local sliderCap = 3.5
			if config.dangerousSizesAllowed then
				sliderCap = 10.0
			end

			value, checked = rom.ImGui.Checkbox("Starting HP is Default Size", config.healthModeUseStartingHP)
			if checked then
				config.healthModeUseStartingHP = value
			end

			if config.healthModeUseStartingHP == false then
				rom.ImGui.TextWrapped("Normal Size At")
				value, used = rom.ImGui.SliderInt("HP##startSizeHP", config.healthModeNormalSizeHP, 30, 110)
				if used then
					config.healthModeNormalSizeHP = value
					GrowTraitUpdate()
				end
			end

			rom.ImGui.TextWrapped("Size at 400 HP")
			value, used = rom.ImGui.SliderFloat("Times Normal Size##endSizeHP", config.healthModeBigSize, 0.1, sliderCap, "%.1f")
			if used then
				config.healthModeBigSize = value
				GrowTraitUpdate()
			end
			rom.ImGui.PushStyleColor(rom.ImGuiCol.Text, 0.75, 0.75, 0, 1)
			rom.ImGui.TextWrapped("* Sliders can go further with size limit settings below, but this can cause gameplay issues.")
			rom.ImGui.PopStyleColor()

			if config.healthModeBigSize > 3.5 then
				rom.ImGui.Spacing()

				rom.ImGui.PushStyleColor(rom.ImGuiCol.Text, 0.75, 0, 0, 1)
				rom.ImGui.TextWrapped("Gameplay gets hard/impossible if you're too big! 3.5 or less recommended.")
				if config.healthModeBigSize > 6.0 then
					rom.ImGui.TextWrapped(
						"Sizes over 6.0 can cause CRASHES, SOFTLOCKS, and CLIPPING OUT OF BOUNDS! Use the unstuck hotkey (Alt U Default) or quit to main menu if you screw up."
					)
				end
				rom.ImGui.PopStyleColor()
			end

			rom.ImGui.Separator()

			rom.ImGui.TextWrapped("Voice Pitch at 400 HP:")
			value, used = rom.ImGui.SliderFloat("Pitch Difference##endPitchHP", config.healthModeBigPitch, -2.0, 2.0, "%.1f")
			if used then
				config.healthModeBigPitch = value
				GrowTraitUpdate()
			end
			rom.ImGui.PushStyleColor(rom.ImGuiCol.Text, 0.75, 0.75, 0, 1)
			rom.ImGui.TextWrapped("* Voice pitch sounds very silly below -1.1 and above 0.5.")
			rom.ImGui.PopStyleColor()
		end --End growth mode: Max HP
	end --End Growth Settings
	rom.ImGui.Spacing()

	if rom.ImGui.CollapsingHeader("Limits") then
		value, checked = rom.ImGui.Checkbox("Limit Size (Lower)", config.sizeUseLowerLimit)
		if checked then
			config.sizeUseLowerLimit = value
		end

		if config.sizeUseLowerLimit == true then
			rom.ImGui.TextWrapped("Lower Size Limit:")
			value, used = rom.ImGui.SliderFloat("Times Normal Size##lowerSizeCap", config.sizeLowerLimit, 0.1, 1.0, "%.1f")
			if used then
				config.sizeLowerLimit = value
				GrowTraitUpdate()
			end
		end

		value, checked = rom.ImGui.Checkbox("Limit Size (Upper)", config.sizeUseUpperLimit)
		if checked then
			config.sizeUseUpperLimit = value
		end

		if config.sizeUseUpperLimit == true then
			local sliderCap = 3.5
			if config.dangerousSizesAllowed then
				sliderCap = 10.0
			end

			rom.ImGui.TextWrapped("Upper Size Limit:")
			value, used = rom.ImGui.SliderFloat("Times Normal Size##upperSizeCap", config.sizeUpperLimit, 1.0, sliderCap, "%.1f")
			if used then
				config.sizeUpperLimit = value
				GrowTraitUpdate()
			end
		end

		rom.ImGui.Separator()

		value, checked = rom.ImGui.Checkbox("Limit Pitch (Lower)", config.voicePitchUseLowerLimit)
		if checked then
			config.voicePitchUseLowerLimit = value
		end

		if config.voicePitchUseLowerLimit == true then
			rom.ImGui.TextWrapped("Lower Pitch Limit:")
			value, used = rom.ImGui.SliderFloat("Pitch Difference##lowerPitchCap", config.voicePitchLowerLimit, -2.0, 0, "%.1f")
			if used then
				config.voicePitchLowerLimit = value
				GrowTraitUpdate()
			end
		end

		value, checked = rom.ImGui.Checkbox("Limit Pitch (Upper)", config.voicePitchUseUpperLimit)
		if checked then
			config.voicePitchUseUpperLimit = value
		end

		if config.voicePitchUseUpperLimit == true then
			rom.ImGui.TextWrapped("Upper Pitch Limit:")
			value, used = rom.ImGui.SliderFloat("Pitch Difference##upperPitchCap", config.voicePitchUpperLimit, 0, 2.0, "%.1f")
			if used then
				config.voicePitchUpperLimit = value
				GrowTraitUpdate()
			end
		end

		value, checked = rom.ImGui.Checkbox("Allow Extreme Size Settings", config.dangerousSizesAllowed)
		if checked then
			config.dangerousSizesAllowed = value
		end

		rom.ImGui.TextWrapped("Enables very large size sliders. Can negatively effect gameplay.")
		rom.ImGui.PushStyleColor(rom.ImGuiCol.Text, 0.75, 0, 0, 1)
		rom.ImGui.TextWrapped(
			"Sizes over 6.0 can cause CRASHES, SOFTLOCKS, and CLIPPING OUT OF BOUNDS! Flashing particles are NOT EPILEPSY-FRIENDLY!"
		)

		if config.dangerousSizesAllowed == true then
			rom.ImGui.Spacing()
			rom.ImGui.TextWrapped(
				"Don't say I didn't warn you. Use the unstuck hotkey (Alt U Default) or quit to main menu if you screw up."
			)
		end
		rom.ImGui.PopStyleColor()
	end --End Limits
	rom.ImGui.Spacing()

	if rom.ImGui.CollapsingHeader("Growth Visual/Audio Toggles") then
		value, checked = rom.ImGui.Checkbox("Sound Effects", config.playSFX)
		if checked then
			config.playSFX = value
		end

		value, checked = rom.ImGui.Checkbox("Voice Lines", config.playVoiceLines)
		if checked then
			config.playVoiceLines = value
		end

		value, checked = rom.ImGui.Checkbox("Text Pop-Ups", config.showText)
		if checked then
			config.showText = value
		end
		rom.ImGui.TextWrapped("* Does not disable pop-up for unstuck feature.")

		value, checked = rom.ImGui.Checkbox("Model Animations", config.playAnimation)
		if checked then
			config.playAnimation = value
		end

		if config.playAnimation == true then
			value, checked = rom.ImGui.Checkbox("Alternate Growth Animation", config.altAnimation)
			if checked then
				config.altAnimation = value
			end
			rom.ImGui.TextWrapped('* Changes growth animation to the same as shrinking: staggering instead of "powering up".')
		end

		value, checked = rom.ImGui.Checkbox("Portrait Size Change", config.scalePortrait)
		if checked then
			config.scalePortrait = value
		end

		value, checked = rom.ImGui.Checkbox("Map Doll Size Change", config.scaleMapDoll)
		if checked then
			config.scaleMapDoll = value
		end

		value, checked = rom.ImGui.Checkbox("Particle Effects", config.showParticles)
		if checked then
			config.showParticles = value
		end

		value, checked = rom.ImGui.Checkbox("Controller Vibration", config.controllerVibration)
		if checked then
			config.controllerVibration = value
		end
		rom.ImGui.TextWrapped("* Needs vibration enabled in game settings to function.")

		value, checked = rom.ImGui.Checkbox("Screen Shake", config.screenShake)
		if checked then
			config.screenShake = value
		end
		rom.ImGui.TextWrapped("* Needs screen shake enabled in game settings to function.")

		rom.ImGui.TextWrapped("Size Change Speed (Animation)")
		local speedModes = { "Fast", "Instant", "Slow" }
		rom.ImGui.PushItemWidth(200)
		if rom.ImGui.BeginCombo("###speedMode", config.growthSpeed) then
			for _, option in ipairs(speedModes) do
				if rom.ImGui.Selectable(option, (option == config.growthSpeed)) then
					config.growthSpeed = option
					rom.ImGui.SetItemDefaultFocus()
				end
			end
			rom.ImGui.EndCombo()
		end
		rom.ImGui.PopItemWidth()
		rom.ImGui.TextWrapped("* Slow will hide the growth process better. Gaslight your friends! :)")

		value, checked = rom.ImGui.Checkbox("Hide Growth Boon in UI", config.hideBoon)
		if checked then
			config.hideBoon = value
			if CurrentRun and CurrentRun.Hero then
				local trait = nil
				local isPerRoom = false

				if HeroHasTrait("GrowTrait") then
					trait = GetHeroTrait("GrowTrait")
					isPerRoom = true
				elseif HeroHasTrait("HealthGrowTrait") then
					trait = GetHeroTrait("HealthGrowTrait")
				elseif HeroHasTrait("HubGrowTrait") then
					trait = GetHeroTrait("HubGrowTrait")
				end

				if trait then
					if isPerRoom then
						AddGrowTraitToHero({ remakeTrait = true })
					end
					trait.Hidden = value
					TraitUIUpdateText(trait)
				end
			end
		end
	end -- end Growth Visual/Audio Toggles
	rom.ImGui.Spacing()

	if rom.ImGui.CollapsingHeader("Change Stats with Growth") then
		value, checked = rom.ImGui.Checkbox("Move Speed", config.statEnableSpeed)
		if checked then
			config.statEnableSpeed = value
			updateGrowSpeed()
		end

		value, checked = rom.ImGui.Checkbox("Damage (% All Damage)", config.statEnableDamage)
		if checked then
			config.statEnableDamage = value
			updateGrowDamage()
		end

		value, checked = rom.ImGui.Checkbox("Max Health (% Increase)", config.statEnableHealth)
		if checked then
			config.statEnableHealth = value
			updateGrowHealth()
		end
		rom.ImGui.TextWrapped("* Max Health increase doesn't work with Max HP Growth.")
	end --end Change Stats with Growth
	rom.ImGui.Spacing()

	if rom.ImGui.CollapsingHeader("Preserve Size Changes") then
		value, checked = rom.ImGui.Checkbox("Keep Size Changes from Run into Hub (Crossroads)", config.keepSizeInHub)
		if checked then
			config.keepSizeInHub = value
		end

		value, checked = rom.ImGui.Checkbox("Keep Size Changes from Hub into Run", config.keepHubSizeIntoRun)
		if checked then
			config.keepHubSizeIntoRun = value
		end
		rom.ImGui.PushStyleColor(rom.ImGuiCol.Text, 0.75, 0.75, 0, 1)
		rom.ImGui.TextWrapped("* Hub into Run does not work with Max HP growth mode!")
		rom.ImGui.PopStyleColor()
		rom.ImGui.TextWrapped("* Both together allows growth over multiple runs. Careful about getting too big!")

		rom.ImGui.Separator()
	end
	rom.ImGui.Spacing() -- End Misc Size Settings

	if rom.ImGui.CollapsingHeader("Binds and Manual Control") then
		value, checked = rom.ImGui.Checkbox("Manual Size Control Enabled", config.sizeControl)
		if checked then
			if value == false then
				config.sizeControlInRuns = false
			end

			config.sizeControl = value
		end

		if config.sizeControl == true then
			value, used = rom.ImGui.InputFloat("Size Change (Hub Only)", config.hubModeGrowth, -1, 1)
			if used then
				config.hubModeGrowth = value
				GrowTraitUpdate()
			end
			value, used = rom.ImGui.InputFloat("Pitch Change (Hub Only)", config.hubModePitch, -1, 1)
			if used then
				config.hubModePitch = value
				GrowTraitUpdate()
			end
		end

		rom.ImGui.PushStyleColor(rom.ImGuiCol.Text, 0.75, 0.75, 0, 1)
		rom.ImGui.TextWrapped("* Hub only without below option.")
		rom.ImGui.PopStyleColor()

		value, checked = rom.ImGui.Checkbox("Manual Size Control Enabled in Runs", config.sizeControlInRuns)
		if checked then
			if value == true then
				config.sizeControl = true
			end

			config.sizeControlInRuns = value
		end
		rom.ImGui.TextWrapped("* Does not disable unstuck toggle if disabled.")
		rom.ImGui.PushStyleColor(rom.ImGuiCol.Text, 0.75, 0.75, 0, 1)
		rom.ImGui.TextWrapped("* Will change Max HP if Max HP grow mode enabled!")
		rom.ImGui.PopStyleColor()

		rom.ImGui.Separator()

		rom.ImGui.TextWrapped("Binds for manual control below.")
		rom.ImGui.PushStyleColor(rom.ImGuiCol.Text, 0.75, 0, 0, 1)
		rom.ImGui.TextWrapped(
			"* Avoid binding to non-letter keys if possible! If this menu crashes on load, delete your Meligrowe config file in ReturnOfModding\\config."
		)
		rom.ImGui.PopStyleColor()
		rom.ImGui.PushStyleColor(rom.ImGuiCol.Text, 0.75, 0.75, 0, 1)
		rom.ImGui.TextWrapped(
			"* Some key/modifier combos do not work due to overlap with engine functions and debug keybinds."
		)
		rom.ImGui.PopStyleColor()
		rom.ImGui.Text("                               Modifier             Key")

		local foundBindDifference = false
		local modifierKeys = { "None", "Alt", "Ctrl", "Shift" }
		for _, bindName in ipairs(BindNames) do
			local label = {
				unstuck = "Unstuck Toggle",
				reset = "Reset Size        ",
				bigger = "Grow                ",
				muchBigger = "Grow (5x)         ",
				smaller = "Shrink               ",
				muchSmaller = "Shrink (5x)        ",
			}

			--rom.ImGui.PushItemWidth(100)
			rom.ImGui.Text(label[bindName])
			--rom.ImGui.PopItemWidth()

			rom.ImGui.SameLine()

			rom.ImGui.PushItemWidth(100)
			local modName = "###" .. bindName .. "modifier"
			local modConfigName = bindName .. "Modifier"
			if rom.ImGui.BeginCombo(modName, config[modConfigName]) then
				for _, option in ipairs(modifierKeys) do
					if rom.ImGui.Selectable(option, (option == config[modConfigName])) then
						config[modConfigName] = option
						rom.ImGui.SetItemDefaultFocus()
					end
				end
				rom.ImGui.EndCombo()
			end
			rom.ImGui.PopItemWidth()

			rom.ImGui.SameLine()

			local keyName = "###" .. bindName .. "key"
			local keyConfigName = bindName .. "Key"
			rom.ImGui.PushItemWidth(130)
			pressed, value = rom.ImGui.Hotkey(keyName, keycodeMap[config[keyConfigName]])
			if pressed then
				local key = keycodeMap[value]
				config[keyConfigName] = key
			end
			rom.ImGui.PopItemWidth()

			local fullBindName = config[modConfigName] .. " " .. config[keyConfigName]
			local fullBindConfigName = bindName .. "Bind"

			if config[fullBindConfigName] ~= fullBindName then
				foundBindDifference = true
			end
		end

		local unsaved = false
		if foundBindDifference then
			unsaved = true
			rom.ImGui.PushStyleColor(rom.ImGuiCol.Button, 0.35, 0, 0, 1)
		end
		if unsaved == true then
			rom.ImGui.PushStyleColor(rom.ImGuiCol.Button, 0.35, 0, 0, 1)
		end
		rom.ImGui.BeginDisabled(not unsaved)
		save = rom.ImGui.Button("Save")
		rom.ImGui.EndDisabled()

		if save then
			for _, bindName in ipairs(BindNames) do
				local modConfigName = bindName .. "Modifier"
				local keyConfigName = bindName .. "Key"
				local fullBindName = config[modConfigName] .. " " .. config[keyConfigName]
				local fullBindConfigName = bindName .. "Bind"
				config[fullBindConfigName] = fullBindName
			end
			setBinds()
		end

		if unsaved then
			rom.ImGui.PushStyleColor(rom.ImGuiCol.Text, 0.5, 0, 0, 1)
			rom.ImGui.Text("Bindings are not saved!")
		end

		rom.ImGui.PopStyleColor(2)
	end
	rom.ImGui.Spacing() --End Binds and Manual Control

	if rom.ImGui.CollapsingHeader("Reset Settings to Default") then
		rom.ImGui.PushStyleColor(rom.ImGuiCol.Text, 0.75, 0, 0, 1)
		rom.ImGui.TextWrapped("Are you sure?")
		rom.ImGui.PopStyleColor()
		rom.ImGui.PushStyleColor(rom.ImGuiCol.Button, 0.75, 0, 0, 1)
		reset = rom.ImGui.Button("Reset")
		rom.ImGui.PopStyleColor()

		if reset then
			resetSettings()
		end
	end
	rom.ImGui.Spacing() --End Binds and Manual Control
end --drawMenu
