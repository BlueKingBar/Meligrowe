---@meta _
-- globals we define are private to our plugin!
---@diagnostic disable: lowercase-global
---@diagnostic disable: undefined-global

-- this file will be reloaded if it changes during gameplay,
-- 	so only assign to values or define things here.

GrowUnstuck = GrowUnstuck or false --lock size to 1.0 toggle

--table print debug function
function dump(o, i)
	local count = i or 0
	local t = ""
	if count > 0 then
		for _ = 1, count do
			t = t .. "\t"
		end
	end

	if type(o) == "table" then
		local s = "\n" .. t .. "{ \n"
		for k, v in pairs(o) do
			if type(k) ~= "number" then
				k = '"' .. k .. '"'
			end
			s = s .. t .. "[" .. k .. "] = " .. dump(v, count + 1)
		end
		return s .. t .. "},\n"
	else
		return tostring(o) .. ",\n"
	end
end

--helps reset trait ticker mid-run (for CheckChamberTraits logic)
--runs if boon is added/switched mid-run, or per X rooms is changed mid-run
function setRoomGrowTraitHelper(level, divisor, trait)
	if level == nil or divisor == nil then
		return
	end

	trait.CurrentRoom = level - math.floor(level / divisor) * divisor
	trait.RoomsPerUpgrade.Amount = divisor
	trait.GrowTraitGrowthPerRoomDisplay = (config.growEveryXRooms or 2) * (config.sizeGrowthPerRoom or 0.0225)

	TraitUIUpdateText(trait)
end

-- Gets the relevant trait from the hero, helper function to reduce code duplication
function getGrowTrait()
	mode = "room"
	if HeroHasTrait("GrowTrait") then
		trait = GetHeroTrait("GrowTrait")
	elseif HeroHasTrait("HealthGrowTrait") then
		trait = GetHeroTrait("HealthGrowTrait")
		mode = "hp"
	elseif HeroHasTrait("HubGrowTrait") then
		trait = GetHeroTrait("HubGrowTrait")
		mode = "hub"
	end
	return trait, mode
end

function updateGrowDamage()
	local damage = 1.0
	local trait = getGrowTrait()

	if CurrentRun and CurrentRun.Hero then
		if trait then
			if config.statEnableDamage then
				damage = trait.GrowTraitValue or 1.0
				damage = math.max(damage, 0.35)
			end

			trait.DamageValue = damage
		end
	end
end

function updateGrowHealth()
	local health = 1.0
	local trait = getGrowTrait()

	if trait then
		if config.statEnableHealth then
			health = trait.GrowTraitValue or 1.0
			health = math.max(health, 0.1)
		end

		trait.MaxHealthMultiplier = health
	end

	ValidateMaxHealth()
	thread(UpdateHealthUI)
end

function updateGrowSpeed()
	local speed = 1.0
	local trait = getGrowTrait()

	if CurrentRun and CurrentRun.Hero and config.statEnableSpeed then
		if trait then
			speed = trait.GrowTraitValue or 1.0
			speed = math.max(speed, 0.5)
		end
	end

	--copied from blood drop method. who knew changing move/dash speed wouldn't be intuitive?
	--this first bit reverses any changes that were made previously
	if SessionMapState.GrowSpeedChange then
		ApplyUnitPropertyChanges(CurrentRun.Hero, SessionMapState.GrowSpeedChange, true, true)
	end
	local allPropertyChanges = {
		{
			UnitProperty = "Speed",
			ChangeType = "Multiply",
			ChangeValue = speed,
		},
		{
			WeaponNames = { "WeaponSprint" },
			WeaponProperty = "SelfVelocity",
			ChangeValue = 1100 * (speed - 1),
			ChangeType = "Add",
			ExcludeLinked = true,
		},
		{
			WeaponNames = { "WeaponSprint" },
			WeaponProperty = "SelfVelocityCap",
			ChangeValue = 740 * (speed - 1),
			ChangeType = "Add",
			ExcludeLinked = true,
		},
	}
	SessionMapState.GrowSpeedChange = allPropertyChanges
	ApplyUnitPropertyChanges(CurrentRun.Hero, SessionMapState.GrowSpeedChange)
end

--returns false if hero or trait are not found
function GrowTraitUpdate(args)
	local unit = nil
	local trait = nil
	local mode = nil

	if CurrentRun ~= nil and CurrentRun.Hero ~= nil then
		unit = CurrentRun.Hero
		trait, mode = getGrowTrait()
	end

	if unit == nil or trait == nil then
		return false
	end

	local growthPerRoom = config.sizeGrowthPerRoom
	local pitchPerRoom = config.voicePitchChangePerRoom

	if mode == "hub" then
		growthPerRoom = config.hubModeGrowth
		pitchPerRoom = config.hubModePitch
	end

	if mode == "hp" then
		local currentHP = CurrentRun.Hero.MaxHealth or 110
		local startHP = config.healthModeNormalSizeHP or 110
		local finalSize = config.healthModeBigSize or 1.9
		local finalPitch = config.healthModeBigPitch or -1.4

		if config.healthModeUseStartingHP then
			startHP = CurrentRun.Hero.trackedHP or startHP
		end

		--lerp size and pitch from set starting HP value to size/pitch at 400 and beyond
		trait.GrowTraitValue = (1 * (400 - currentHP) + finalSize * (currentHP - startHP)) / (400 - startHP)
		trait.BaseChipmunkValue = (finalPitch * (currentHP - startHP)) / (400 - startHP) --startPitch is zero, therefore startPitch * (400 - currentHP) == 0
	elseif mode == "room" then
		trait.GrowTraitValue = (config.startingSize or 1) + trait.GrowLevel * growthPerRoom
		trait.BaseChipmunkValue = (config.startingPitch or 0) + trait.GrowLevel * pitchPerRoom
	else
		trait.GrowTraitValue = 1 + trait.GrowLevel * growthPerRoom
		trait.BaseChipmunkValue = trait.GrowLevel * pitchPerRoom
	end

	if mode == "room" then
		growthPerRoomDisplay = growthPerRoom * (config.growEveryXRooms or 2)
	end

	if HeroHasTrait("CirceEnlargeTrait") then
		circeGrowMultiplier = 1.25 and trait.GrowTraitValue > 0 or 0.75
		chipmunkExtra = -0.2 and trait.GrowTraitValue > 0 or 0.3
		trait.GrowTraitValue = trait.GrowTraitValue * circeGrowMultiplier
		if mode == "room" then
			growthPerRoomDisplay = growthPerRoom * circeGrowMultiplier
		end
		trait.BaseChipmunkValue = trait.BaseChipmunkValue - 0.2
	end

	if HeroHasTrait("CirceShrinkTrait") then
		circeGrowMultiplier = 0.75 and trait.GrowTraitValue > 0 or 1.25
		chipmunkExtra = 0.3 and trait.GrowTraitValue > 0 or -0.2

		trait.GrowTraitValue = trait.GrowTraitValue * circeGrowMultiplier
		trait.GrowTraitValue = trait.GrowTraitValue * circeGrowMultiplier
		if mode == "room" then
			growthPerRoomDisplay = growthPerRoom * circeGrowMultiplier
		end
		trait.BaseChipmunkValue = trait.BaseChipmunkValue + chipmunkExtra
	end

	if config.voicePitchUseLowerLimit and config.voicePitchLowerLimit ~= nil then
		trait.BaseChipmunkValue = math.max(trait.BaseChipmunkValue, config.voicePitchLowerLimit)
	end

	if config.voicePitchUseUpperLimit and config.voicePitchUpperLimit ~= nil then
		trait.BaseChipmunkValue = math.min(trait.BaseChipmunkValue, config.voicePitchUpperLimit)
	end

	if config.sizeUseLowerLimit and config.sizeLowerLimit ~= nil then
		trait.GrowTraitValue = math.max(trait.GrowTraitValue, config.sizeLowerLimit)
	end

	if config.sizeUseUpperLimit and config.sizeUpperLimit ~= nil then
		trait.GrowTraitValue = math.min(trait.GrowTraitValue, config.sizeUpperLimit)
	end

	if trait.GrowTraitValue <= 0.1 then
		trait.GrowTraitValue = 0.1
	end

	local chipmunk = trait.BaseChipmunkValue
	local currentSize = trait.GrowTraitValue

	if args ~= nil and args.Transformed == true then
		--make voice deeper when in Dark Side. ignores set pitch cap.
		if chipmunk >= 0 then
			chipmunk = chipmunk - 0.8
		else
			--so basically diminishing returns (until chipmunk - 0.1 breaks even)
			local chipmunkScaling = -0.8 + chipmunk * 0.250
			chipmunk = math.min(chipmunk - 0.2, chipmunkScaling)
		end

		currentSize = currentSize * 1.1
	end

	CurrentRun.Hero.trackedScale = currentSize --this exists to allow dialogue to interact
	PreservedScale = currentSize --lets size transfer between boons

	if GrowUnstuck then
		currentSize = 1
	end

	local growthSpeed = 0.2

	if config.growthSpeed then
		if config.growthSpeed == "Instant" then
			growthSpeed = 0.0
		elseif config.growthSpeed == "Slow" then
			growthSpeed = 2.0
		end
	end

	SetAudioEffectState({ Name = "Chipmunk", Value = chipmunk })
	SetScale({ Id = unit.ObjectId, Fraction = currentSize, Duration = growthSpeed })
	unit.EffectVfxScale = currentSize

	updateGrowDamage()
	updateGrowHealth()
	updateGrowSpeed() --not related to the above growth speed. this one's the stat (mel's run speed)

	return true
end

function GrowHero(args)
	local changeValue = 1
	local changeValueAbs = 0
	local sizeAbsolute = false
	local lastScale = nil
	if args then
		changeValue = args.changeValue or 1
		changeValueAbs = args.changeValue or 0
		sizeAbsolute = args.sizeAbsolute or false
	end
	if CurrentRun.Hero ~= nil then
		lastScale = CurrentRun.Hero.trackedScale --checks for size changes to affect presentation (grow vs. shrink)
		if HeroHasTrait("GrowTrait") then
			local trait = GetHeroTrait("GrowTrait")
			if trait.GrowLevel ~= nil then
				if not sizeAbsolute then
					trait.GrowLevel = trait.GrowLevel + changeValue
				else
					trait.GrowLevel = changeValueAbs
				end
			end
			GrowTraitUpdate()
		elseif HeroHasTrait("HealthGrowTrait") then
			--Just update size and play animation below. No logic needed to change size here.
			GrowTraitUpdate()
		elseif HeroHasTrait("HubGrowTrait") then
			local trait = GetHeroTrait("HubGrowTrait")
			if trait.GrowLevel ~= nil then
				if not sizeAbsolute then
					trait.GrowLevel = trait.GrowLevel + changeValue
				else
					trait.GrowLevel = changeValueAbs
				end
			end
			GrowTraitUpdate()
		end
	else
		return
	end

	local scaleDiff = CurrentRun.Hero.trackedScale - lastScale
	CurrentRun.Hero.trackedScaleDiff = scaleDiff

	if args and args.doPresentation == true then
		if not GrowUnstuck then
			if scaleDiff > 0 then
				--grow
				if config.playSFX == true then
					thread(function()
						PlaySound({ Name = "/SFX/Enemy Sounds/Wringer/WringerChargeUp", Id = CurrentRun.Hero.ObjectId })
						wait(0.02)
					end)
				end

				if config.showText == true then
					thread(
						InCombatTextArgs,
						{ TargetId = CurrentRun.Hero.ObjectId, Text = "GrowPopUp", PreDelay = 0.35, Duration = 1.5, Cooldown = 1.0 }
					)
				end
				if config.playAnimation == true then
					if config.altAnimation == true then
						SetAnimation({ Name = "MelinoeShrink", DestinationId = CurrentRun.Hero.ObjectId })
					else
						SetAnimation({ Name = "MelinoeBoonInteractPowerUp", DestinationId = CurrentRun.Hero.ObjectId })
					end
				end
				if config.showParticles == true then
					CreateAnimation({ Name = "HealthSparkleShower", DestinationId = CurrentRun.Hero.ObjectId })
				end
			elseif scaleDiff < 0 then
				--shrink
				if config.playSFX == true then
					thread(function()
						PlaySound({ Name = "/SFX/ThanatosHermesKeepsakeFail", Id = CurrentRun.Hero.ObjectId, Volume = 0.25 })
						wait(0.02)
					end)
				end

				if config.showText == true then
					thread(
						InCombatTextArgs,
						{ TargetId = CurrentRun.Hero.ObjectId, Text = "ShrinkPopUp", PreDelay = 0.35, Duration = 1.5, Cooldown = 1.0 }
					)
				end
				if config.playAnimation == true then
					SetAnimation({ Name = "MelinoeShrink", DestinationId = CurrentRun.Hero.ObjectId })
				end
				if config.showParticles == true then
					CreateAnimation({ Name = "HealthSparkleBurst", DestinationId = CurrentRun.Hero.ObjectId })
				end
			end

			if scaleDiff ~= 0 then
				if config.playVoiceLines == true then
					local globalVoiceLines = GlobalVoiceLines.GrowBiggerVoiceLines --this is actually all size change voice lines don't be fooled
					thread(PlayVoiceLines, globalVoiceLines, true)
				end

				if config.screenShake == true then
					ShakeScreen({ Speed = 1000, Distance = 2, Duration = 0.3 })
				end
				if config.controllerVibration == true then
					thread(DoRumble, { { ScreenPreWait = 0.02, LeftFraction = 0.3, Duration = 0.3 } })
				end
			end
		else
			thread(
				InCombatTextArgs,
				{
					TargetId = CurrentRun.Hero.ObjectId,
					Text = "UnstuckEnablePopUp",
					PreDelay = 0.35,
					Duration = 2.5,
					Cooldown = 1.0,
				}
			)
		end
	end
end

function AddGrowTraitToHero(args)
	local init = false
	local skipUI = false --this stops new save files from crashing.
	local preserveSize = false --allows keeping size from run to hub or vice versa
	local useRunEndSize = false --flags specifically run end for the above. kind of a spaghetti bugfix thing.
	local remakeTrait = false --Hidden doesn't play nice with ShowInHUD. have to remake the trait to hide it.

	if args then
		init = args.init
		skipUI = args.skipUI
		preserveSize = args.preserveSize
		useRunEndSize = args.useRunEndSize
		remakeTrait = args.remakeTrait
	end

	--initialize tracking values if they don't exist regardless of args
	CurrentRun.Hero.trackedScale = CurrentRun.Hero.trackedScale or config.startingSize or 1.0 --this exists to allow dialogue to interact and presentation to detect grow vs. shrink
	CurrentRun.Hero.trackedScaleDiff = CurrentRun.Hero.trackedScaleDiff or 0 --supplemental to the above
	CurrentRun.Hero.trackedHP = CurrentRun.Hero.trackedHP or CurrentRun.Hero.MaxHealth --remember HP from run start for certain maxHP mode settings

	if preserveSize then
		--used to keep persistent scale
		if useRunEndSize == true then
			CurrentRun.Hero.preservedScale = RunEndScale or PreservedScale or CurrentRun.Hero.trackedScale
		else
			CurrentRun.Hero.preservedScale = PreservedScale or CurrentRun.Hero.trackedScale
		end
	end

	--use init if starting a new run. resets certain tracking variables
	if init == true then
		if not preserveSize then
			CurrentRun.Hero.trackedScale = config.startingSize or 1.0
		end
		CurrentRun.Hero.trackedScaleDiff = 0
		CurrentRun.Hero.trackedHP = CurrentRun.Hero.MaxHealth
	end

	local traitName = "GrowTrait"

	if CurrentHubRoom ~= nil then
		traitName = "HubGrowTrait"
	elseif config.growthMode == "Max HP" then
		traitName = "HealthGrowTrait"
		if init == true then
			if config.healthModeUseStartingHP then
				CurrentRun.Hero.trackedScale = 1.0
			else
				local currentHP = CurrentRun.Hero.trackedHP
				local startHP = config.healthModeNormalSizeHP or 110
				local finalSize = config.healthModeBigSize or 1.9

				--lerp size to make sure start size is recorded correctly
				CurrentRun.Hero.trackedScale = (1 * (400 - currentHP) + finalSize * (currentHP - startHP)) / (400 - startHP)
			end
		end
	end

	local traitsToCheck = { "HubGrowTrait", "GrowTrait", "HealthGrowTrait" }
	local traitWasRemoved = false
	local stacksToKeep = 0
	local roomCounter = 0

	for _, traitCheck in pairs(traitsToCheck) do
		if traitCheck ~= traitName then
			if HeroHasTrait(traitCheck) then
				RemoveTrait(CurrentRun.Hero, traitCheck, { SkipUIUpdate = skipUI })
				traitWasRemoved = true
			end
		elseif remakeTrait == true then
			if HeroHasTrait(traitCheck) then
				local trait = GetHeroTrait(traitCheck)
				stacksToKeep = trait.GrowLevel or 0
				roomCounter = trait.CurrentRoom or 0
				RemoveTrait(CurrentRun.Hero, traitCheck, { SkipUIUpdate = skipUI })
			end
		end
	end

	if HeroHasTrait(traitName) then
		return
	end

	local tD = GetProcessedTraitData({
		Unit = CurrentRun.Hero,
		TraitName = traitName,
		Rarity = "Common",
	})

	--anti-crash for hub area
	tD.Name = traitName
	tD.TraitOrderingValueCache = -1

	tD.Hidden = config.hideBoon
	if config.hideBoon == true and remakeTrait == true then
		tD.ShowInHUD = nil
	end

	--[[if traitName == "GrowTrait" then
		if tD.RoomsPerUpgrade then
			tD.RoomsPerUpgrade.Amount = config.growEveryXRooms or 2
		end
	end]]

	AddTraitToHero({
		TraitData = tD,
		SkipNewTraitHighlight = true,
		SkipQuestStatusCheck = true,
		SkipActivatedTraitUpdate = true,
		SkipUIUpdate = skipUI,
	})

	if HeroHasTrait("GrowTrait") and traitName == "GrowTrait" then
		local trait = GetHeroTrait("GrowTrait")

		if trait.RoomsPerUpgrade then
			trait.RoomsPerUpgrade.Amount = config.growEveryXRooms or 2
		end

		trait.GrowTraitGrowthPerRoomDisplay = (config.sizeGrowthPerRoom or 0.0225) * (config.growEveryXRooms or 2)

		if remakeTrait == true then
			trait.GrowLevel = stacksToKeep
			trait.CurrentRoom = roomCounter
			TraitUIUpdateText(trait)
			GrowHero({ sizeAbsolute = true, changeValue = stacksToKeep })
		end
	end

	if HeroHasTrait("HubGrowTrait") and traitName == "HubGrowTrait" and remakeTrait == true then
		local trait = GetHeroTrait("HubGrowTrait")

		trait.GrowLevel = stacksToKeep
		GrowHero({ sizeAbsolute = true, changeValue = stacksToKeep })
	end

	--if boon was switched or added mid-run, set GrowLevel and room counter to their appropriate levels
	if traitWasRemoved and HeroHasTrait("GrowTrait") and traitName == "GrowTrait" and CurrentRun.EncounterDepth then
		local trait = GetHeroTrait("GrowTrait")
		local divisor = config.growEveryXRooms or 2
		local level = CurrentRun.EncounterDepth - 2
		trait.GrowLevel = math.floor(level / divisor) * divisor --round down to closest multiple of X rooms
		setRoomGrowTraitHelper(math.max(0, level), divisor, trait) --depth is 2 more than encounters cleared.
	end

	--add grow stacks to make size roughly match preserved (this makes size reset work as intended)
	if preserveSize == true then
		local trait = nil
		local m = nil
		if HeroHasTrait("GrowTrait") then
			trait = GetHeroTrait("GrowTrait")
			m = "room"
		elseif HeroHasTrait("HubGrowTrait") then
			trait = GetHeroTrait("HubGrowTrait")
			m = "hub"
		end

		if trait and m then
			local perStack = config.sizeGrowthPerRoom
			if m == "hub" then
				perStack = config.hubModeGrowth
			end

			if perStack ~= 0 then
				--[[local unrounded = (CurrentRun.Hero.preservedScale - 1) / perStack

				if unrounded >= 0 then
					trait.GrowLevel = math.floor(unrounded + 0.5)
				else --makes sure rounding doesn't fuck up when negative
					unrounded = -unrounded
					unrounded = math.floor(unrounded + 0.5)
					unrounded = -unrounded
					trait.GrowLevel = unrounded
				end]]

				local growLevel = (CurrentRun.Hero.preservedScale - 1) / perStack
				GrowHero({ sizeAbsolute = true, changeValue = growLevel })
			end
		end
	end

	GrowTraitUpdate()
end

function CheckChamberTraits_wrap()
	if not HeroHasTrait("GrowTrait") then
		return
	end

	local trait = GetHeroTrait("GrowTrait")

	if trait.CurrentRoom == 0 then
		GrowHero({ changeValue = (config.growEveryXRooms or 2), doPresentation = true })
	end

	--[[imitating condition structure from Eris keepsake (funny bell of damage)
	if currentEncounter == currentRoom.Encounter or currentEncounter == MapState.EncounterOverride then
		if trait.CurrentRoom == trait.RoomsPerUpgrade.Amount - 1  then
				GrowHero({ changeValue = (config.growEveryXRooms or 2), doPresentation = true })
		end
	end]]
end

function resetSettings()
	config.growthMode = "Per Encounter"
	config.startingSize = 1.00
	config.sizeGrowthPerRoom = 0.0225
	config.finalSize = 1.9
	config.startingPitch = 0
	config.voicePitchChangePerRoom = -0.027
	config.finalPitch = -1.1
	config.growEveryXRooms = 2
	config.healthModeUseStartingHP = false
	config.healthModeNormalSizeHP = 70
	config.healthModeBigSize = 1.90
	config.healthModeBigPitch = -1.1
	config.hubModeGrowth = 0.0225
	config.hubModePitch = -0.027
	config.voicePitchUseLowerLimit = false
	config.voicePitchUseUpperLimit = false
	config.voicePitchLowerLimit = -1.1
	config.voicePitchUpperLimit = 0.5
	config.sizeUseLowerLimit = false
	config.sizeUseUpperLimit = true
	config.sizeLowerLimit = 0.1
	config.sizeUpperLimit = 3.5
	config.dangerousSizesAllowed = false
	config.keepSizeInHub = true
	config.keepHubSizeIntoRun = false
	config.sizeControl = true
	config.sizeControlInRuns = false
	config.playSFX = true
	config.playVoiceLines = true
	config.showText = true
	config.playAnimation = true
	config.showParticles = true
	config.controllerVibration = true
	config.screenShake = true
	config.hideBoon = false
	config.scalePortrait = true
	config.scaleMapDoll = true
	config.growthSpeed = "Fast"
	config.altAnimation = false
	config.statEnableSpeed = false
	config.statEnableDamage = false
	config.statEnableHealth = false
	config.unstuckBind = "Alt U"
	config.unstuckModifier = "Alt"
	config.unstuckKey = "U"
	config.resetBind = "Alt J"
	config.resetModifier = "Alt"
	config.resetKey = "J"
	config.biggerBind = "None O"
	config.biggerModifier = "None"
	config.biggerKey = "O"
	config.muchBiggerBind = "Alt O"
	config.muchBiggerModifier = "Alt"
	config.muchBiggerKey = "O"
	config.smallerBind = "None P"
	config.smallerModifier = "None"
	config.smallerKey = "P"
	config.muchSmallerBind = "Alt P"
	config.muchSmallerModifier = "Alt"
	config.muchSmallerKey = "P"
	AddGrowTraitToHero({ remakeTrait = true })
	setBinds()
end
