---@meta _
-- globals we define are private to our plugin!
---@diagnostic disable: lowercase-global
---@diagnostic disable: undefined-global

-- here is where your mod sets up all the things it will do.
-- this file will not be reloaded if it changes during gameplay
-- 	so you will most likely want to have it reference
--	values and functions later defined in `reload.lua`.

OnAnyLoad({
	function(triggerArgs)
		local mapName = triggerArgs.name
		local roomData = RoomData[mapName]
		local hubRoomData = HubRoomData[mapName]

		--load sound banks used in runs in the hub area
		thread(loadGrowVoiceBanks, mapName, hubRoomData)
		thread(GrowModActivate, mapName, roomData, hubRoomData)
	end,
})

function loadGrowVoiceBanks(m, h)
	if h ~= nil or m == GameData.HubMapName then
		LoadVoiceBanks("MelinoeField", true)
	end
end

function GrowModActivate(m, r, h)
	if m == GameData.HubMapName or h ~= nil or r ~= nil then
		if
			CurrentRun ~= nil
			and CurrentRun.Hero ~= nil
			and not HeroHasTrait("GrowTrait")
			and not HeroHasTrait("HealthGrowTrait")
			and not HeroHasTrait("HubGrowTrait")
		then
			AddGrowTraitToHero({ init = true })
		end
	end
end

--puts the funny boon on you at the start of a run (over in reload.lua)
modutil.mod.Path.Wrap("StartNewRun", function(base, prevRun, args)
	local retVar = base(prevRun, args)
	local skipUICheck = false
	local keepSizeCheck = config.keepHubSizeIntoRun
	if prevRun == nil then --fix for crash on new save files
		skipUICheck = true
	end
	AddGrowTraitToHero({ skipUI = skipUICheck, init = true, preserveSize = keepSizeCheck })
	return retVar
end)

--puts the other funny boon on you when you respawn in the hub (boon selection logic handled in AddGrowTraitToHero)
--this originally was StartDeathLoop, but this gets called from it, ensuring it's executed before it waits for user inputs
modutil.mod.Path.Wrap("StartDeathLoopPresentation", function(base, currentRun)
	local keepSizeCheck = config.keepSizeInHub
	AddGrowTraitToHero({ init = true, preserveSize = keepSizeCheck, useRunEndSize = true })

	base(currentRun)
end)

--reloads MelinoeField voice banks so they work in hub
--[[modutil.mod.Path.Wrap("DeathAreaRoomTransition", function(base, source, args)
	base(source, args)

	LoadVoiceBanks({ Name = "MelinoeField" })
end)]]

--Applying in the same context as setup functions usually run (e.g. Circe's actual boons)
modutil.mod.Path.Wrap("ApplyTraitSetupFunctions", function(base, unit, args)
	base(unit, args)

	if not args or (args and not args.Context) then
		GrowTraitUpdate()
	end
end)

--ticks down boon for per encounter growth
modutil.mod.Path.Wrap("CheckChamberTraits", function(base)
	local retVal = base()
	CheckChamberTraits_wrap()
	return retVal
end)

--allows size change from Selene Install to apply even with this mod's changes
modutil.mod.Path.Wrap("SpellTransformStartPresentation", function(base, user, weaponData, functionArgs, triggerArgs)
	if GrowTraitUpdate({ Transformed = true }) == false then
		return base(user, weaponData, functionArgs, triggerArgs)
	end
	PlaySound({ Name = "/VO/MelinoeEmotes/EmoteAttackingAxe", Id = CurrentRun.Hero.ObjectId })
end)

--whoops your install ran out
modutil.mod.Path.Wrap("SpellTransformEndPresentation", function(base, user, weaponData, functionArgs, triggerArgs)
	if GrowTraitUpdate() == false then
		return base(user, weaponData, functionArgs, triggerArgs)
	end
	PlaySound({ Name = "/SFX/TimeSlowEnd", Id = CurrentRun.Hero.ObjectId })
	PlaySound({ Name = "/VO/MelinoeEmotes/EmoteGasping", Id = CurrentRun.Hero.ObjectId })
end)

--allows circe's boons to work with this mod
modutil.mod.Path.Wrap("CirceEnlarge", function(base, unit, args, roomArgs)
	base(unit, args, roomArgs)
	GrowTraitUpdate()
end)

--the other circe boon
modutil.mod.Path.Wrap("CirceShrink", function(base, unit, args, roomArgs)
	base(unit, args, roomArgs)
	GrowTraitUpdate()
end)

--allows max hp growth boon to update when max hp is changed
modutil.mod.Path.Wrap("ValidateMaxHealth", function(base, blockDelta)
	base(blockDelta)

	local hasChanged = false
	if not CurrentRun.Hero.trackedLastMaxHP then
		CurrentRun.Hero.trackedLastMaxHP = CurrentRun.Hero.MaxHealth
	elseif CurrentRun.Hero.trackedLastMaxHP ~= CurrentRun.Hero.MaxHealth then
		hasChanged = true
		CurrentRun.Hero.trackedLastMaxHP = CurrentRun.Hero.MaxHealth
	end

	if config.growthMode == "Max HP" and HeroHasTrait("HealthGrowTrait") and hasChanged then
		local dP = true

		if CurrentHubRoom ~= nil then
			local dP = false
		end
		GrowHero({ doPresentation = dP })
	end
end)

--keeps MelinoeField voice lines loaded in hub area when fishing (FishingPierStartPresentation loads them)
modutil.mod.Path.Wrap("FishingPierEndPresentation", function(base, source, args)
	base(source, args)

	LoadVoiceBanks({ Name = "MelinoeField" })
end)

--overrides between-act map animation to scale the melinoe figure based on her size
modutil.mod.Path.Wrap("BiomeMapPresentation", function(base, source, args)
	BiomeMapPresentation_wrap(source, args)
end)

--overrides dialogue screen behavior to scale melinoe's portrait
modutil.mod.Path.Wrap("DisplayTextLine", function(base, screen, source, line, parentLine, nextLine, args)
	DisplayTextLine_wrap(screen, source, line, parentLine, nextLine, args)
end)

--Makes preserving size into run work properly with Max HP scaling. Nabs the final size value a little early.
modutil.mod.Path.Wrap("RecordRunStats", function(base)
	base()

	RunEndScale = PreservedScale or 1.0
end)
