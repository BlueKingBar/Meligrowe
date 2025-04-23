---@diagnostic disable: undefined-global
---@diagnostic disable: lowercase-global
---@diagnostic disable: deprecated

function DisplayTextLine_wrap( screen, source, line, parentLine, nextLine, args )

	args = args or {}
	local rawText = line.Text
	local text = nil

	-- Look up the text line without the '/VO/' prefix
	if line.Cue then
		local helpTextId = line.Cue
		if line.Cue ~= "/EmptyCue" then
			helpTextId = string.sub( line.Cue, 5 )
		end
		rawText = nil
		text = helpTextId
		if not HasDisplayName({ Text = helpTextId }) then
			rawText = line.Text
			text = nil
		end
	end

	screen.LastLineStartTime = _worldTime

	local cue = line.Cue

	if line.Source ~= nil then
		source = EnemyData[line.Source] or LootData[line.Source] or ConsumableData[line.Source]
	elseif line.UsePlayerSource then
		source = CurrentRun.Hero
	end

	local speakerName = line.SpeakerNameplateId or line.Speaker or source.Speaker or source.Name	
	
	-- Always prioritize line data over source data
	local lineHistoryName = line.LineHistoryName or line.SpeakerNameplateId or line.Speaker or source.LineHistoryName or source.Speaker or source.Name
	local speakerSource = EnemyData[speakerName] or LootData[speakerName]
	local speakerSourceSubtitleColor = nil
	if speakerSource ~= nil then
		speakerSourceSubtitleColor = speakerSource.NarrativeFadeInColor or speakerSource.SubtitleColor
	end
	local lineHistorySubtitleColor = line.SubtitleColor or speakerSourceSubtitleColor or source.NarrativeFadeInColor or source.SubtitleColor
	table.insert( CurrentRun.LineHistory, { SpeakerName = lineHistoryName, SourceName = source.Name, Text = text, RawText = rawText,
		SubtitleColor = lineHistorySubtitleColor } )

	local portrait = line.Portrait or source.Portrait
	local speakerLabelOffsetY = line.SpeakerLabelOffsetY or source.SpeakerLabelOffsetY or 5

	for id, v in pairs( AudioState.ActiveSpeechIds ) do
		StopSound({ Id = id, Duration = 0.15 })
	end

	StopStatusAnimation( source, StatusAnimations.WantsToTalk )

	local anchorId = nil
	local textColor = nil
	local narrationTextOffsetX = 0
	local narrationTextOffsetY = 0
	local narrationBoxOffsetX = 0
	local exitAnimation = nil
	local textShadowColor = {0.890, 0.871, 0.851, 1.0}

	local speechSource = source

	if portrait ~= nil and not line.SkipPortrait then
		-- Dialogue with portrait
		if screen.ContextArtId == nil then
			screen.ContextArtId = CreateScreenObstacle({ Name = "BlankObstacle", X = ScreenCenterX, Y = ScreenCenterY, Group = args.Group or screen.DefaultGroup })
		end
		if screen.PortraitId == nil then
            screen.PortraitId = CreateScreenObstacle({ Name = "BlankObstacle", X = ScreenCenterX - 490, Y = ScreenCenterY + 105, Group = args.Group or screen.DefaultGroup })
		end
		AltAspectRatioFramesShow()
		if screen.CurrentPortrait ~= nil and screen.CurrentPortrait ~= portrait then
			SetAnimation({ DestinationId = screen.PortraitId, Name = screen.CurrentPortrait.."_Exit" })
			waitUnmodified( line.PortraitExitWait or 0.3 )
		end
		if screen.CurrentContextArt == nil and not line.SkipContextArt and not parentLine.SkipContextArt and not source.SkipContextArt then
			local currentRoom = (CurrentHubRoom or CurrentRun.CurrentRoom)
			local roomData = RoomData[currentRoom.Name] or HubRoomData[currentRoom.Name]
			local contextArt = line.NarrativeContextArt or source.NarrativeContextArt or roomData.NarrativeContextArt
			local contextArtFlippable = roomData.NarrativeContextArtFlippable or source.NarrativeContextArtFlippable
			if contextArt ~= nil then
				screen.CurrentContextArt = contextArt
				SetAnimation({ DestinationId = screen.ContextArtId, Name = screen.CurrentContextArt.."_In" })
				if( RandomChance(0.5) and contextArtFlippable and not parentLine.DoNotFlipContextArt ) then
					FlipHorizontal({ Id = screen.ContextArtId })
				end
			end
		end
		if screen.ContextArtId ~= nil and line.NarrativeContextArt ~= nil then
			screen.CurrentContextArt = line.NarrativeContextArt
			SetAnimation({ DestinationId = screen.ContextArtId, Name = screen.CurrentContextArt.."_In" })
		end
		local prevPortrait = screen.CurrentPortrait
		screen.CurrentPortrait = portrait

        --MODDED START

		if config.scalePortrait == true then
			local sizeChange = 1.0
			local posX = ScreenCenterX - 490
			local posY = ScreenCenterY + 105

			print (screen.CurrentPortrait or "No Portrait.")
			if CurrentRun and CurrentRun.Hero and CurrentRun.Hero.trackedScale and line.UsePlayerSource then
				if CurrentRun.Hero.trackedScale >= 1 then
					local shit = 2
					local fuck = 2
					--basically shit and fuck affect how fast portrait scale grows with actual size
					--shit divides scaling before she hits 1.25, fuck divides scaling after.
					--so like if shit = 3, 0.25 * 3 + 1, or 1.75x size, is where she hits 1.25x portrait
					--and if fuck = 6, then she grows half as much after that point
					if CurrentRun.Hero.trackedScale > 0.25 * shit + 1 then
						sizeChange = 1 + (CurrentRun.Hero.trackedScale - 1 + fuck / 4 - shit / 4) / fuck
						--scale from TOP of screen once portrait gets bigger than 1.25x
						posY = posY + math.floor(-108.75 + (sizeChange - 1.25) * 330) -- -108.75 is -((sizeChange - 1.0) * 435) at 1.25
					else
						sizeChange = 1 + (CurrentRun.Hero.trackedScale - 1) / shit
						posY = posY - math.floor((sizeChange - 1.0) * 435) -- keep position consistent to bottom of screen
					end
				else
					sizeChange = 1 + (CurrentRun.Hero.trackedScale - 1)
					posY = posY - math.floor((sizeChange - 1.0) * 435) -- keep position consistent to bottom of screen
				end

				print("Size : "..tostring(sizeChange))
			end

			SetScale({ Id = screen.PortraitId, Fraction = sizeChange })
			Teleport({ Id = screen.PortraitId, OffsetX = posX, OffsetY = posY })
		end

        --MODDED END

		SetAnimation({ DestinationId = screen.PortraitId, Name = screen.CurrentPortrait })
		if source.OnPortraitSetFunctionName ~= nil then
			CallFunctionName( source.OnPortraitSetFunctionName, source, source.OnPortraitSetFunctionArgs, screen, line )
		end
		speechSource = { Name = source.Name, ObjectId = screen.PortraitId }
		narrationBoxOffsetX = 198
		if screen.DialogueGlowBackgroundId == nil then
			screen.DialogueGlowBackgroundId = CreateScreenObstacle({ Name = "BlankObstacle", X = ScreenCenterX + 200, Y = ScreenCenterY + 300, Group = args.Group or screen.DefaultGroup })
			SetAnimation({ DestinationId = screen.DialogueGlowBackgroundId, Name = "DialogueSpeechBubbleBackgroundGlow" })
			SetAlpha({ Id = screen.DialogueGlowBackgroundId, Fraction = 0 })
			SetAlpha({ Id = screen.DialogueGlowBackgroundId, Fraction = 1, Duration = 0.25  })
		end
		if source.PortraitEnterSound ~= nil then
			if not screen.PlayedPortraitEnterSounds[source.PortraitEnterSound] then
				PlaySound({ Name = source.PortraitEnterSound })
				screen.PlayedPortraitEnterSounds[source.PortraitEnterSound] = true
			end
		end

	end

	if line.PreContentSound ~= nil then
		PlaySound({ Name = line.PreContentSound })
	end
	if line.Emote ~= nil and screen.PortraitId ~= nil then
		CreateAnimation({ Name = line.Emote, DestinationId = screen.PortraitId, OffsetX = source.EmoteOffsetX, OffsetY = source.EmoteOffsetY })
	end

	local speakerNameId = nil
	local promptOffsetY = 425

	if portrait ~= nil and not (line.IsNarration or parentLine.IsNarration) then
		-- Speech bubble
		if screen.BackgroundId == nil then
			local boxAnimation = line.BoxAnimation or source.BoxAnimation or "DialogueSpeechBubble"
			screen.BackgroundId = CreateScreenObstacle({ Name = boxAnimation, X = ScreenCenterX + (line.BoxOffsetX or narrationBoxOffsetX), Y = ScreenCenterY + (line.BoxOffsetY or 264), Group = args.Group or screen.DefaultGroup })
		end
		exitAnimation = line.BoxExitAnimation or source.BoxExitAnimation or "DialogueSpeechBubbleOut"
		textColor = line.TextColor or source.NarrativeTextColor or Color.DialogueText

		if line.Append then
			Destroy({ Ids = { screen.NameplateId, screen.NameplateDescriptionId } })
			screen.NameplateId = nil
			screen.NameplateDescriptionId = nil
		end

		if screen.NameplateId == nil then
			screen.NameplateId = CreateScreenObstacle({ Name = "BlankObstacle", X = ScreenCenterX - 12, Y = ScreenCenterY + 103, Group = args.Group or screen.DefaultGroup })
		end
		if screen.NameplateDescriptionId == nil then
			screen.NameplateDescriptionId = CreateScreenObstacle({ Name = "BlankObstacle", X = ScreenCenterX - 8, Y = ScreenCenterY + 146, Group = args.Group or screen.DefaultGroup })
		end

		CreateTextBox(MergeTables({
			Id = screen.NameplateId,
			Text = speakerName,
			FontSize = 32,
			OffsetY = speakerLabelOffsetY + GetLocalizedValue( 0, LocalizationData.Narrative.SpeakerDisplayName.LangOffsetY ),
			Font = "CaesarDressing",
			Color = source.NameplateSpeakerNameColor or Color.DialogueSpeakerName,
			ShadowBlur = 1, ShadowColor = {0,0,0,0}, ShadowOffset={0, 3},
			Justification = "CENTER",
		}, LocalizationData.Narrative.SpeakerDisplayName ))

		CreateTextBox(MergeTables({
			Id = screen.NameplateDescriptionId,
			Text = speakerName,
			FontSize = 22,
			OffsetY = 3 + GetLocalizedValue( 0, LocalizationData.Narrative.SpeakerDescription.LangOffsetY ),
			Font = "P22UndergroundSCMedium",
			Color = source.NameplateDescriptionColor or {120, 220, 180, 192},
			UseDescription = true,
		}, LocalizationData.Narrative.SpeakerDescription ))

	else
		-- Narration
		if screen.BackgroundId == nil then
			screen.BackgroundId = CreateScreenObstacle({ Name = "NarrationBubble", X = ScreenCenterX + (line.BoxOffsetX or narrationBoxOffsetX), Y = ScreenCenterY + (line.BoxOffsetY or 304), Group = args.Group or screen.DefaultGroup })
		end
		if line.BoxAnimation ~= nil then
			SetAnimation({ Name = line.BoxAnimation, DestinationId = screen.BackgroundId })
		end
		exitAnimation = line.BoxExitAnimation or "NarrationBubbleOut"
		textColor = Color.NarrationText
		textShadowColor = {0,0,0, 1.0}
		narrationTextOffsetX = 0
		narrationTextOffsetY = 15
		promptOffsetY = 440
	end

	if line.Append then
		ModifyTextBox({
			Id = screen.BackgroundId,
			Text = text,
			RawText = rawText,
			Append = true,
		})
	else
		local fadeInSource = source
		local fadeInColor = source.NarrativeFadeInColor or source.SubtitleColor
		if line.Speaker ~= nil then
			fadeInSource = EnemyData[line.Speaker] or HeroData
		end
		if not fadeInColor then
			fadeInSource = fadeInSource.NarrativeFadeInColor or fadeInSource.SubtitleColor or { -255, -255, -255, -255 }
		end
		if fadeInColor == nil then
			fadeInColor = { -255, -255, -255, -255 }
		end
		local fadeInProperties =
		{
			CharacterFadeTime = 0.0125,
			CharacterFadeInterval = 0.001,
			CharacterFadeColorLag = 0.055,
			CharacterFadeRed = fadeInColor[1] / 255,
			CharacterFadeGreen = fadeInColor[2] / 255,
			CharacterFadeBlue = fadeInColor[3] / 255,
		}
		if fadeInSource.DisableCharacterFadeColorLag then
			fadeInProperties = 
			{
				CharacterFadeTime = 0.0125,
				CharacterFadeInterval = 0.001,
			}
		end
		local data = ShallowCopyTable( ScreenData.Dialog.ComponentData.DialogueText.TextArgs )
		data.LineSpacingBottom = GetLocalizedValue( data.LineSpacingBottom, data.LangLineSpacingBottom )
		data.Id = screen.BackgroundId
		data.Text = text
		data.RawText = rawText
		data.Width = line.TextWidth or 833
		data.OffsetX = line.TextOffsetX or (-397 + narrationTextOffsetX)
		data.OffsetY = GetLocalizedValue( line.TextOffsetY or (45 + narrationTextOffsetY), line.LangTextOffsetY )
		data.FontSize = line.FontSize or 24
		data.VerticalJustification = line.VerticalJustification or "CENTER"
		data.Color = line.TextColor or textColor
		data.ShadowColor = textShadowColor
		data.DataProperties = fadeInProperties
		CreateTextBox( data )
	end

	local anchorIds = { screen.BackgroundId, screen.NameplateId, screen.NameplateDescriptionId }
	Destroy({ Id = screen.PromptId })
	screen.PromptId = CreateScreenObstacle({ Name = "BlankObstacle", X = ScreenCenterX + 390 + narrationBoxOffsetX, Y = ScreenCenterY + promptOffsetY, Group = args.Group or screen.DefaultGroup })
	table.insert( anchorIds, screen.PromptId )

	ModifySubtitles({ SuppressLyrics = true })

	local listenStartTime = _worldTime

	local speechId = PlaySpeechCue( cue, nil, nil, "Interrupt", false )
	if speechId > 0 then
		CurrentRun.CurrentRoom.SpeechRecord[cue] = (CurrentRun.CurrentRoom.SpeechRecord[cue] or 0) + 1
		-- Extra back-compat due to GameState.PatchedSpeechRecords2 somehow missing some cases
		if GameState.SpeechRecord[cue] ~= nil and type(GameState.SpeechRecord[cue]) == "boolean" then
			GameState.SpeechRecord[cue] = 1
		end
		if CurrentRun.SpeechRecord[cue] ~= nil and type(CurrentRun.SpeechRecord[cue]) == "boolean" then
			CurrentRun.SpeechRecord[cue] = 1
		end
		GameState.SpeechRecord[cue] = (GameState.SpeechRecord[cue] or 0) + 1
		CurrentRun.SpeechRecord[cue] = (CurrentRun.SpeechRecord[cue] or 0) + 1
	end
	if source.SpeakingAnimation ~= nil and line.Portrait == nil and speechId ~= nil and speechId > 0 then
		SetAnimation({ DestinationId = screen.PortraitId, Name = source.SpeakingAnimation, SoundId = speechId })
		thread( CancelSpeakingAnimation, screen, source, cue )
	end
	if not line.AutoAdvance and not GetConfigOptionValue({ Name = "AutoAdvanceNarration" }) then
		thread( ShowContinueArrow, screen, source, cue )
	end

	waitUnmodified(0.04)
	-- Workaround for FMOD bug, after a long play-session VO played in 2D can become inaudible.  Pausing and unpausing the sound fixes it.
	PauseSound({ Id = speechId, Duration = 0 })
	ResumeSound({ Id = speechId, Duration = 0 })
	waitUnmodified( line.InputDelay or 0.17 ) -- Minimum input advance delay

	local advanceControls = { "Confirm", "Select", "ContinueText", }
	
	ToggleCombatControl( advanceControls, true )

	if line.AutoAdvance or GetConfigOptionValue({ Name = "AutoAdvanceNarration" }) then
		thread( AutoAdvanceNarration, screen, source, cue )
	end

	local notifyName = nil
	if IsEmpty( choiceMap ) then
		notifyName = "NarrativeLineNextInput"
		NotifyOnControlPressed({ Names = advanceControls, Notify = notifyName })
		waitUntil( notifyName )
	else
		RemoveInputBlock({ Name = "PlayTextLines" })
		EnableGamepadCursor( screen.Name )
		notifyName = "NarrativeLineChoiceInput"
		NotifyOnInteract({ Ids = GetAllKeys( choiceMap ), Notify = notifyName })
		screen.AllowAdvancedTooltip = true
		--NotifyOnControlPressed({ Names = hotkeyControls, Notify = notifyName })
		waitUntil( notifyName )
		screen.AllowAdvancedTooltip = false
		local selectedId = NotifyResultsTable[notifyName]
		selectedChoice = choiceMap[selectedId]
		AddInputBlock({ Name = "PlayTextLines" })
		DisableGamepadCursor( screen.Name )
	end
	ModifySubtitles({ SuppressLyrics = false })

	killTaggedThreads( NarrativeThreadName )
	killWaitUntilThreads( cue )

	GameState.TextLinePanelCount[parentLine.Name] = (GameState.TextLinePanelCount[parentLine.Name] or 0) + 1
	local listenEndTime = _worldTime
	local listenElapsedTime = listenEndTime - listenStartTime
	if listenElapsedTime < NarrativeConstantData.ListenSkipThreshold then
		GameState.TextLinePanelSkipCount[parentLine.Name] = (GameState.TextLinePanelSkipCount[parentLine.Name] or 0) + 1
	end

	if nextLine ~= nil and nextLine.Append then
		-- Do nothing
	else
		DestroyTextBox({ Ids = anchorIds })
		SetAnimation({ DestinationId = screen.BackgroundId, Name = exitAnimation })
		if line.PortraitExitAnimation ~= nil then
			SetAnimation({ DestinationId = screen.PortraitId, Name = line.PortraitExitAnimation })
			screen.CurrentPortrait = nil
		end
		if screen.CurrentContextArt ~= nil and ( line.PostLineRemoveContextArt or (nextLine ~= nil and nextLine.IsNarration) ) then
			SetAnimation({ DestinationId = screen.ContextArtId, Name = screen.CurrentContextArt.."_Out" })
			screen.CurrentContextArt = nil
		end
		if screen.DialogueGlowBackgroundId ~= nil then
			-- SetAnimation({ DestinationId = screen.DialogueGlowBackgroundId, Name = "DialogueSpeechBubbleBackgroundGlowFade" })
			SetAlpha({ Id = screen.DialogueGlowBackgroundId, Fraction = 0, Duration = 0.12 })
			screen.DialogueGlowBackgroundId = nil
		end
	end

	waitUnmodified(0.12)
	if nextLine ~= nil and nextLine.Append then
		-- Do nothing
	else
		Destroy({ Ids = anchorIds })
		screen.BackgroundId = nil
		screen.NameplateId = nil
		screen.NameplateDescriptionId = nil
		if choiceBackground ~= nil then
			Destroy({ Id = choiceBackground })
		end
	end

	StopSound({ Id = speechId, Duration = 0.15 })

	if selectedChoice ~= nil then
		PlaySound({ Name = "/SFX/Menu Sounds/IrisMenuBack" })
		selectedChoice.Name = parentLine.Name..selectedChoice.ChoiceText
		PlayTextLine( screen, selectedChoice, line, line, source )
	end

	return true

end