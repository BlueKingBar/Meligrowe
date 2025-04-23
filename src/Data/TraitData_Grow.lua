---@diagnostic disable: undefined-global

--insert trait description
local order = {
	"Id",
	"InheritFrom",
	"DisplayName",
	"Description",
}

local text_to_insert = sjson.to_object({
	Id = "GrowTrait",
	InheritFrom = "BaseBoon",
	DisplayName = "Increasing Heft",
	Description = "{#UpgradeFormat}{$TooltipData.ExtractData.CurrentMelSize:P} {#Prev}size. Every {#BoldFormat}{$TooltipData.ExtractData.TooltipRoomInterval} {$Keywords.EncounterPlural}{#Prev}, gains {#BoldFormatGraft}+{$TooltipData.ExtractData.MelSizeIncreasePerXRooms:F} {#Prev}size.",
}, order)

local text_to_insert2 = sjson.to_object({
	Id = "HealthGrowTrait",
	InheritFrom = "BaseBoon",
	DisplayName = "Healthy Heft",
	Description = "{#UpgradeFormat}{$TooltipData.ExtractData.CurrentMelSize:P} {#Prev}size. Changes with {!Icons.HealthUp}.",
}, order)

local text_to_insert3 = sjson.to_object({
	Id = "HubGrowTrait",
	InheritFrom = "BaseBoon",
	DisplayName = "Remote Control Heft",
	Description = "{#UpgradeFormat}{$TooltipData.ExtractData.CurrentMelSize:P} {#Prev}size. Press insert to set size control and other settings!",
}, order)

local textfile = rom.path.combine(rom.paths.Content, "Game/Text/en/TraitText.en.sjson")

sjson.hook(textfile, function(sjsonData)
	---@diagnostic disable-next-line: param-type-mismatch
	table.insert(sjsonData.Texts, text_to_insert)
	---@diagnostic disable-next-line: param-type-mismatch
	table.insert(sjsonData.Texts, text_to_insert2)
	---@diagnostic disable-next-line: param-type-mismatch
	table.insert(sjsonData.Texts, text_to_insert3)
end)

--insert pop-up text for growth
local orderPopUp = {
	"Id",
	"DisplayName",
}

local text_to_insert_pop_up = sjson.to_object({
	Id = "GrowPopUp",
	DisplayName = "Bigger...",
}, orderPopUp)

local text_to_insert_pop_up2 = sjson.to_object({
	Id = "ShrinkPopUp",
	DisplayName = "Smaller...",
}, orderPopUp)

local text_to_insert_pop_up3 = sjson.to_object({
	Id = "UnstuckEnablePopUp",
	DisplayName = "Unstuck on! Alt U (default) to disable!",
}, orderPopUp)

local text_to_insert_pop_up4 = sjson.to_object({
	Id = "UnstuckDisablePopUp",
	DisplayName = "Unstuck off!",
}, orderPopUp)

local textfilePopUp = rom.path.combine(rom.paths.Content, "Game/Text/en/HelpText.en.sjson")

sjson.hook(textfilePopUp, function(sjsonData)
	---@diagnostic disable-next-line: param-type-mismatch
	table.insert(sjsonData.Texts, text_to_insert_pop_up)
	---@diagnostic disable-next-line: param-type-mismatch
	table.insert(sjsonData.Texts, text_to_insert_pop_up2)
	---@diagnostic disable-next-line: param-type-mismatch
	table.insert(sjsonData.Texts, text_to_insert_pop_up3)
	---@diagnostic disable-next-line: param-type-mismatch
	table.insert(sjsonData.Texts, text_to_insert_pop_up4)
end)

--insert cancelable version of special surface damage animation

local orderAnim = {
	"Name",
	"InheritFrom",
	"GrannyAnimation",
	"GrannyAnimationSpeed",
	"CancelOnOwnerMove",
	"TimeModifierFraction",
	"ChainTo",
	"Frames",
}

local anim_to_insert = {
	Name = "MelinoeShrink",
	InheritFrom = "MelinoeBaseAnimation",
	GrannyAnimation = "Melinoe_NoWeapon_Base_GetHit_C_00",
	GrannyAnimationSpeed = 0.14,
	CancelOnOwnerMove = true, --changed!
	TimeModifierFraction = 1.00,
	ChainTo = "MelinoeIdleWeaponless",
	Frames = {
		{
			Frame = 0,
			FrameSpeed = 0.0,
		},
		{
			Frame = 4,
			FrameSpeed = 1.0,
		},
	},
}

local textfileAnim = rom.path.combine(rom.paths.Content, "Game/Animations/Model/Hero_Melinoe_Animation_HitReacts.sjson")

sjson.hook(textfileAnim, function(sjsonData)
	---@diagnostic disable-next-line: param-type-mismatch
	table.insert(sjsonData.Animations, anim_to_insert)
end)

--custom voice line sets for changing size
GlobalVoiceLines.GrowBiggerVoiceLines = {
	{
		--Uses same requirements as picking up a boon.
		GameStateRequirements = {
			{
				Path = { "CurrentRun", "CurrentRoom", "Encounter", "Name" },
				IsNone = {
					"Shop",
					"DevotionTestF",
					"DevotionTestG",
					"DevotionTestH",
					"DevotionTestN",
					"DevotionTestO",
					"DevotionTestP",
					"ArtemisCombatIntro",
					"ArtemisCombatF",
					"ArtemisCombatF2",
					"ArtemisCombatG",
					"ArtemisCombatG2",
					"ArtemisCombatN",
					"ArtemisCombatN2",
					"HeraclesCombatN",
					"HeraclesCombatN2",
					"HeraclesCombatO",
					"HeraclesCombatO2",
					"HeraclesCombatP",
					"HeraclesCombatP2",
					"NemesisCombatF",
					"NemesisCombatG",
					"NemesisCombatH",
					"IcarusCombatO",
					"IcarusCombatO2",
					"IcarusCombatP",
					"IcarusCombatP2",
				},
			},
			{
				Path = { "CurrentRun", "CurrentRoom", "Name" },
				IsNone = {
					"TestAllThings",
					"F_Story01",
					"G_Story01",
					"H_Bridge01",
					"I_Story01",
					"N_Story01",
					"O_Story01",
					"P_Story01",
				},
			},
		},
		{
			GameStateRequirements = {
				{
					Path = { "CurrentRun", "Hero", "trackedScaleDiff" },
					Comparison = ">",
					Value = 0,
				},
			},
			{
				GameStateRequirements = {
					{
						Path = { "CurrentRun", "Hero", "trackedScale" },
						Comparison = ">=",
						Value = 1.6,
					},
				},

				--Queue = "Interrupt",
				BreakIfPlayed = true,
				RandomRemaining = true,
				PreLineWait = 0.65,
				SuccessiveChanceToPlay = 0.25,
				UsePlayerSource = true,
				--SkipCooldownCheckIfNonePlayed = true,
				--[[Cooldowns =
				{
					{ Name = "MelinoeGrewBiggerRecently", Time = 5 },
				},]]
				TriggerCooldowns = { "MelinoeAnyQuipSpeech", "MelCombatResolvedSpeech", Time = 3 },
				TriggerCooldownsImmediately = true,

				{ Cue = "/VO/Melinoe_3526", Text = "I'm huge...", PlayFirst = true },
				{ Cue = "/VO/MelinoeField_2054", Text = "I'm Titan-sized..." },
				{ Cue = "/VO/Melinoe_2597", Text = "How tall you've grown..." },
				{ Cue = "/VO/Melinoe_2598", Text = "You're a sight to behold." },
				{ Cue = "/VO/Melinoe_1410", Text = "How do I look?" },
				{ Cue = "/VO/Melinoe_0350", Text = "{#Emph}<Laugh>" },
				{ Cue = "/VO/Melinoe_0351", Text = "{#Emph}<Laugh>" },
				{ Cue = "/VO/MelinoeField_2052", Text = "What have I done..." },
				{ Cue = "/VO/Melinoe_2552", Text = "Become even stronger." },
				{ Cue = "/VO/MelinoeField_1600", Text = "Such power..." },
				{ Cue = "/VO/Melinoe_3594", Text = "Well look at you!" },
			},
			{

				--Queue = "Interrupt",
				BreakIfPlayed = true,
				RandomRemaining = true,
				PreLineWait = 0.65,
				--SuccessiveChanceToPlay = 0.33,
				UsePlayerSource = true,
				--SkipCooldownCheckIfNonePlayed = true,
				--[[Cooldowns =
				{
					{ Name = "MelinoeGrewBiggerRecently", Time = 5 },
				},]]
				TriggerCooldowns = { "MelinoeAnyQuipSpeech", "MelCombatResolvedSpeech", Time = 3 },
				TriggerCooldownsImmediately = true,

				{ Cue = "/VO/Melinoe_0200", Text = "Greater strength." },
				{ Cue = "/VO/Melinoe_0208", Text = "{#Emph}Hm!" },
				{ Cue = "/VO/Melinoe_0212", Text = "I grow strong." },
				{ Cue = "/VO/Melinoe_2359", Text = "Grow strong." },
				{ Cue = "/VO/Melinoe_2360", Text = "Grow and flourish." },
				{ Cue = "/VO/Melinoe_2304", Text = "Grow and thrive." },
				{ Cue = "/VO/Melinoe_0569", Text = "{#Emph}<Inhale>" },
				{ Cue = "/VO/Melinoe_3279", Text = "Wow..." },
				{ Cue = "/VO/MelinoeField_1895", Text = "That's potent..." },
				{ Cue = "/VO/MelinoeField_1896", Text = "{#Emph}Ooh..." },
				{ Cue = "/VO/MelinoeField_2050", Text = "Am I...? Oh." },
				{ Cue = "/VO/MelinoeField_2051", Text = "I feel a little off...", PlayFirst = true },
				{ Cue = "/VO/MelinoeField_1897", Text = "Felt that for sure..." },
				{ Cue = "/VO/Melinoe_1512", Text = "{#Emph}Ah-haha{#Prev}, wow..." },
				{ Cue = "/VO/Melinoe_1510", Text = "That's a feeling there..." },
				{ Cue = "/VO/Melinoe_1514", Text = "This feeling, {#Emph}augh..." },
				{ Cue = "/VO/Melinoe_1495", Text = "No getting used to {#Emph}that..." },
				{ Cue = "/VO/MelinoeField_0672", Text = "{#Emph}Mm{#Prev}, there we go." },
				{ Cue = "/VO/MelinoeField_0780", Text = "Something's changed in me..." },
				{ Cue = "/VO/MelinoeField_0294", Text = "I felt something..." },
				{ Cue = "/VO/MelinoeField_0295", Text = "A sudden surge..." },
				{ Cue = "/VO/Melinoe_1771", Text = "Felt that." },
				{ Cue = "/VO/MelinoeField_0618", Text = "Something's changed..." },
				{ Cue = "/VO/Melinoe_3593", Text = "You're getting stronger." },
				{ Cue = "/VO/Melinoe_3593_B", Text = "You're getting stronger." },
				{ Cue = "/VO/MelinoeField_0669", Text = "Feeling fine...." },
				{ Cue = "/VO/Melinoe_1522", Text = "Getting warmer..." },
			},
		},
		{
			GameStateRequirements = {
				{
					Path = { "CurrentRun", "Hero", "trackedScaleDiff" },
					Comparison = "<",
					Value = 0,
				},
			},
			{
				GameStateRequirements = {
					{
						Path = { "CurrentRun", "Hero", "trackedScale" },
						Comparison = "<=",
						Value = 0.75,
					},
				},

				--Queue = "Interrupt",
				BreakIfPlayed = true,
				RandomRemaining = true,
				PreLineWait = 0.65,
				SuccessiveChanceToPlay = 0.25,
				UsePlayerSource = true,
				--SkipCooldownCheckIfNonePlayed = true,
				--[[Cooldowns =
				{
					{ Name = "MelinoeGrewBiggerRecently", Time = 5 },
				},]]
				TriggerCooldowns = { "MelinoeAnyQuipSpeech", "MelCombatResolvedSpeech", Time = 3 },
				TriggerCooldownsImmediately = true,

				{ Cue = "/VO/MelinoeField_2053", Text = "Everything looks so big...", PlayFirst = true },
				{ Cue = "/VO/Melinoe_2598", Text = "You're a sight to behold." },
				{ Cue = "/VO/Melinoe_1410", Text = "How do I look?" },
				{ Cue = "/VO/Melinoe_0350", Text = "{#Emph}<Laugh>" },
				{ Cue = "/VO/Melinoe_0351", Text = "{#Emph}<Laugh>" },
				{ Cue = "/VO/MelinoeField_2052", Text = "What have I done..." },
			},
			{

				--Queue = "Interrupt",
				BreakIfPlayed = true,
				RandomRemaining = true,
				PreLineWait = 0.65,
				--SuccessiveChanceToPlay = 0.33,
				UsePlayerSource = true,
				--SkipCooldownCheckIfNonePlayed = true,
				--[[Cooldowns =
				{
					{ Name = "MelinoeGrewBiggerRecently", Time = 5 },
				},]]
				TriggerCooldowns = { "MelinoeAnyQuipSpeech", "MelCombatResolvedSpeech", Time = 3 },
				TriggerCooldownsImmediately = true,

				{ Cue = "/VO/Melinoe_0208", Text = "{#Emph}Hm!" },
				{ Cue = "/VO/Melinoe_0569", Text = "{#Emph}<Inhale>" },
				{ Cue = "/VO/Melinoe_3279", Text = "Wow..." },
				{ Cue = "/VO/MelinoeField_1895", Text = "That's potent..." },
				{ Cue = "/VO/MelinoeField_1896", Text = "{#Emph}Ooh..." },
				{ Cue = "/VO/MelinoeField_2050", Text = "Am I...? Oh." },
				{ Cue = "/VO/MelinoeField_2051", Text = "I feel a little off...", PlayFirst = true },
				{ Cue = "/VO/MelinoeField_1897", Text = "Felt that for sure..." },
				{ Cue = "/VO/Melinoe_1512", Text = "{#Emph}Ah-haha{#Prev}, wow..." },
				{ Cue = "/VO/Melinoe_1510", Text = "That's a feeling there..." },
				{ Cue = "/VO/Melinoe_1514", Text = "This feeling, {#Emph}augh..." },
				{ Cue = "/VO/Melinoe_1495", Text = "No getting used to {#Emph}that..." },
				{ Cue = "/VO/MelinoeField_0672", Text = "{#Emph}Mm{#Prev}, there we go." },
				{ Cue = "/VO/MelinoeField_0780", Text = "Something's changed in me..." },
				{ Cue = "/VO/MelinoeField_0294", Text = "I felt something..." },
				{ Cue = "/VO/MelinoeField_0295", Text = "A sudden surge..." },
				{ Cue = "/VO/Melinoe_1771", Text = "Felt that." },
				{ Cue = "/VO/MelinoeField_0618", Text = "Something's changed..." },
				{ Cue = "/VO/Melinoe_1947", Text = "{#Emph}Khh." },
				{ Cue = "/VO/Melinoe_1948", Text = "{#Emph}Ngh." },
				{ Cue = "/VO/Melinoe_1950", Text = "{#Emph}<Sigh>" },
				{ Cue = "/VO/Melinoe_0578", Text = "{#Emph}Hrm." },
			},
		},
	},
}

-- the trait itself
GrowTraits = {
	GrowTrait = {
		Name = "GrowTrait",
		Icon = "Boon_Circe_02",
		BaseChipmunkValue = config.startingPitch,
		GrowTraitValue = config.startingSize or 1,
		DamageValue = 1.0,
		MaxHealthMultiplier = 1.0,
		AddOutgoingDamageModifiers = {
			UseTraitValue = "DamageValue",
			IsMultiplier = true,
		},
		--Per Encounter Data
		GrowTraitGrowthPerRoomDisplay = {
			BaseValue = (config.sizeGrowthPerRoom or 0.0225) * (config.growEveryXRooms or 2),
			DecimalPlaces = 4,
		},
		GrowLevel = 0,
		--important UI/per room interaction stuff
		Hidden = config.hideBoon or false,
		ShowInHUD = true,
		CurrentRoom = 0,
		RoomsPerUpgrade = {
			Amount = { BaseValue = config.growEveryXRooms or 2 },
			ReportValues = {
				ReportedRoomsPerUpgrade = "Amount",
			},
		},
		ExtractValues = {
			{
				Key = "GrowTraitGrowthPerRoomDisplay",
				ExtractAs = "MelSizeIncreasePerXRooms",
				Format = "Percent",
				DecimalPlaces = 4,
			},
			{
				SkipAutoExtract = true,
				Key = "GrowTraitValue",
				ExtractAs = "CurrentMelSize",
				Format = "PercentDelta",
				DecimalPlaces = 4,
			},
			{
				Key = "ReportedRoomsPerUpgrade",
				ExtractAs = "TooltipRoomInterval",
			},
		},
	},
	HealthGrowTrait = {
		Name = "HealthGrowTrait",
		Icon = "Boon_Circe_02",
		BaseChipmunkValue = config.startingPitch,
		GrowTraitValue = config.startingSize or 1,
		DamageValue = 1.0,
		AddOutgoingDamageModifiers = {
			UseTraitValue = "DamageValue",
			IsMultiplier = true,
		},
		--important UI stuff
		Hidden = config.hideBoon or false,
		ExtractValues = {
			{
				SkipAutoExtract = true,
				Key = "GrowTraitValue",
				ExtractAs = "CurrentMelSize",
				Format = "PercentDelta",
				DecimalPlaces = 4,
			},
		},
	},
	HubGrowTrait = {
		Name = "HubGrowTrait",
		Icon = "Boon_Circe_02",
		BaseChipmunkValue = 0,
		GrowTraitValue = 1,
		DamageValue = 1.0,
		MaxHealthMultiplier = 1.0,
		AddOutgoingDamageModifiers = {
			UseTraitValue = "DamageValue",
			IsMultiplier = true,
		},
		GrowLevel = 0,
		--important UI stuff
		Hidden = config.hideBoon or false,
		ExtractValues = {
			{
				SkipAutoExtract = true,
				Key = "GrowTraitValue",
				ExtractAs = "CurrentMelSize",
				Format = "PercentDelta",
				DecimalPlaces = 4,
			},
		},
	},
}

local spicyLine = { Cue = "/VO/Melinoe_1526", Text = "{#Emph}Whew {#Prev}that's hot..." }

if config.spicy == true then
	table.insert(GlobalVoiceLines.GrowBiggerVoiceLines[1][1][2], spicyLine)
end

--add trait to the game
for key, growTrait in pairs(GrowTraits) do
	TraitData[key] = growTrait
end

--retain this value between upgrades and such
table.insert(PersistentTraitKeys, "GrowLevel")
