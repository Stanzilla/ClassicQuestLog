
local cql = ClassicQuestLog
local IsClassic = select(4, GetBuildInfo()) < 20000
-- settings: ShowTooltips, ShowLevels, UndockWindow, LockWindow, ShowResizeGrip, Height, SolidBackground

ClassicQuestLogSettings = {}
ClassicQuestLogCollapsedHeaders = {}

cql.quests = {}

BINDING_HEADER_CLASSIC_QUEST_LOG = "Classic Quest Log"
BINDING_NAME_CLASSIC_QUEST_LOG_TOGGLE = "Show/Hide Quest Log"

if IsClassic then
   function GetQuestLogCriteriaSpell()
      return
   end

   function GetNumQuestLogRewardCurrencies()
      return 0
   end

   function GetQuestLogRewardSkillPoints()
      return 0
   end

   function GetQuestLogRewardArtifactXP()
      return 0
   end

   function GetQuestLogRewardHonor()
      return 0
   end

   function GetQuestLogRewardTitle()
      return
   end

   function ProcessQuestLogRewardFactions()
      return
   end

   function GetQuestLogPortraitGiver()
      return
   end

   function GetQuestLink()
      return
   end
end

function cql:OnEvent(event)
   if event=="PLAYER_LOGIN" then
      local scrollFrame = cql.scrollFrame
      scrollFrame.update = cql.UpdateLogList
      HybridScrollFrame_CreateButtons(scrollFrame, "ClassicQuestLogListTemplate")
      -- hide our frame if default's popup detail log appears
      if QuestLogPopupDetailFrame then
         QuestLogPopupDetailFrame:HookScript("OnShow",function() cql:HideWindow() end)
      end
      cql:SetMinResize(667,300)
      cql:SetMaxResize(667,700)
      ClassicQuestLogSettings.Height = ClassicQuestLogSettings.Height or 496
      cql:SetHeight(ClassicQuestLogSettings.Height)
      cql.resizeGrip:SetShown(ClassicQuestLogSettings.ShowResizeGrip)

      cql:UpdateOverrides()
      cql:RegisterEvent("UPDATE_BINDINGS")
      cql:SetScript("OnSizeChanged",cql.OnSizeChanged)
      cql:UpdateDocking()
      if not ClassicQuestLogSettings.UseClassicSkin then
         if IsAddOnLoaded("ElvUI") then
            cql:SkinForElvUI()
         elseif IsAddOnLoaded("Aurora") then
            cql:SkinForAurora()
         end
      end
      cql:UpdateOptionsForSkins()
      cql:UpdateBackgrounds()
      if not IsAddOnLoaded("Blizzard_ObjectiveTracker") then
         cql:RegisterEvent("ADDON_LOADED")
      else
         cql:HandleObjectiveTracker()
      end
      hooksecurefunc("SelectQuestLogEntry",cql.UpdateLogList)
   elseif event=="UPDATE_BINDINGS" then
      cql:UpdateOverrides()
   elseif event=="QUEST_DETAIL" then
      cql:HideWindow()
   elseif event=="ADDON_LOADED" and IsAddOnLoaded("Blizzard_ObjectiveTracker") then
      cql:HandleObjectiveTracker()
   else
      local selected = GetQuestLogSelection()
      if selected==0 then
         cql:SelectFirstQuest()
      else
         cql:UpdateLogList()
         -- cql:SelectQuestIndex(selected)
      end
   end
end

-- this handler is only watched after HybridScrollFrame_CreateButtons, so that enough buttons are
-- made for the maximum height.
function cql:OnSizeChanged(width,height)
   if not height then
      height = cql:GetHeight()
   end
   ClassicQuestLogSettings.Height = height
   self.detail:SetHeight(height-93)
   self.scrollFrame:SetHeight(height-93)
   self:UpdateLogList()
end

function cql:OnShow()
   if WorldMapFrame:IsVisible() then
      ToggleWorldMap() -- can't have world map up at same time due to potential details frame being up
   end
   if QuestLogPopupDetailFrame and QuestLogPopupDetailFrame:IsVisible() then
      HideUIPanel(QuestLogPopupDetailFrame)
   end
   if QuestFrame:IsVisible() then
      HideUIPanel(QuestFrame)
   end
   local selected = GetQuestLogSelection()
   if not selected or selected==0 then
      cql:SelectFirstQuest()
   else
      cql:SelectQuestIndex(selected)
   end
   cql:OnSizeChanged()
   cql:RegisterEvent("QUEST_DETAIL")
   cql:RegisterEvent("QUEST_LOG_UPDATE")
   cql:RegisterEvent("QUEST_WATCH_LIST_CHANGED")
   cql:RegisterEvent("SUPER_TRACKED_QUEST_CHANGED")
   cql:RegisterEvent("GROUP_ROSTER_UPDATE")
   cql:RegisterEvent("PARTY_MEMBER_ENABLE")
   cql:RegisterEvent("PARTY_MEMBER_DISABLE")
   if not IsClassic then
      cql:RegisterEvent("QUEST_POI_UPDATE")
   end
   cql:RegisterEvent("QUEST_WATCH_UPDATE")
   cql:RegisterEvent("QUEST_ACCEPTED")
   cql:RegisterEvent("UNIT_QUEST_LOG_CHANGED")
   if not tContains(UISpecialFrames,"ClassicQuestLog") then
      tinsert(UISpecialFrames,"ClassicQuestLog")
   end
   cql.detail:ClearAllPoints()
   cql.detail:SetPoint("TOPRIGHT",-32,-63)
   PlaySound(PlaySoundKitID and "igQuestLogOpen" or SOUNDKIT.IG_QUEST_LOG_OPEN)
end

-- no need to watch these events while log isn't on screen
function cql:OnHide()
   -- only keep this window in UISpecialFrames while it's up
   for i=#UISpecialFrames,1,-1 do
      if UISpecialFrames[i]=="ClassicQuestLog" then
         tremove(UISpecialFrames,i)
      end
   end
   cql:UnregisterEvent("QUEST_DETAIL")
   cql:UnregisterEvent("QUEST_LOG_UPDATE")
   cql:UnregisterEvent("QUEST_WATCH_LIST_CHANGED")
   cql:UnregisterEvent("SUPER_TRACKED_QUEST_CHANGED")
   cql:UnregisterEvent("GROUP_ROSTER_UPDATE")
   cql:UnregisterEvent("PARTY_MEMBER_ENABLE")
   cql:UnregisterEvent("PARTY_MEMBER_DISABLE")
   if not IsClassic then
      cql:UnregisterEvent("QUEST_POI_UPDATE")
   end
   cql:UnregisterEvent("QUEST_WATCH_UPDATE")
   cql:UnregisterEvent("QUEST_ACCEPTED")
   cql:UnregisterEvent("UNIT_QUEST_LOG_CHANGED")

   -- expand all headers when window hides so default doesn't lose track of collapsed quests
   local index = 1
   while index<=GetNumQuestLogEntries() do
      local _,_,_,isHeader,isCollapsed = GetQuestLogTitle(index)
      if isHeader and isCollapsed then
         ExpandQuestHeader(index)
      end
      index = index + 1
   end

   cql.optionsFrame:Hide() -- close options if it was open
   PlaySound(PlaySoundKitID and "igQuestLogClose" or SOUNDKIT.IG_QUEST_LOG_CLOSE)

   C_Timer.After(0,cql.UpdateDetailColors)
end

-- this shows the update frame whose purpose is to run UpdateLog below on the next frame
-- this prevents multiple events firing at once from recreating the log every event
function cql:UpdateLogList()
   cql.update:Show()
end

-- called from the OnUpdate of cql.update
function cql:UpdateLog()
   cql.update:Hide() -- immediately stop the OnUpdate
   -- gather quests into a working table (cql.quests) to skip over collapsed headers
   wipe(cql.quests)
   cql.expanded = nil

   -- first add all non-hidden headers and quests to cql.quests table
   -- (btw this circuitous method is to future-proof it against future hidden quests; blizzard's
   -- code seems to imply it's possible for a header to contain both hidden and non-hidden quests)
   local numQuests = 0
   for index=1,GetNumQuestLogEntries() do
      local questTitle, level, suggestedGroup, isHeader, isCollapsed, isComplete, frequency, questID, startEvent, displayQuestID, isOnMap, hasLocalPOI, isTask, isBounty, isStory, isHidden = GetQuestLogTitle(index)
      if not isHidden then
         table.insert(cql.quests,{index,questTitle,level,suggestedGroup,isHeader,isCollapsed,isComplete,frequency,questID})
         if not isHeader then
            numQuests = numQuests + 1
         end
      end
   end

   -- next remove any quest headers that have no quests
   local hasQuests
   for index=#cql.quests,1,-1 do
      if cql.quests[index][5] then -- this is a header
		 if not hasQuests then -- with no quests beneath it
            tremove(cql.quests,index) -- remove the header
         end
         hasQuests = nil -- reset flag to look for quests
      else
         hasQuests = true -- this is a quest, keep the header this is beneath
      end
   end

   -- next flag quests to be removed due to collapsed headers (can't tremove since have to loop forward)
   local skipping
   for index=1,#cql.quests do
      if cql.quests[index][5] then -- this is a header
         skipping = ClassicQuestLogCollapsedHeaders[cql.quests[index][2]] -- [2] is questTitle
         cql.quests[index][6] = skipping -- update isCollapsed to reflect our version (which is independent of default's state)
         if not skipping then
            cql.expanded = true -- at least one header is expanded (for all quest +/- choice)
         end
      elseif skipping then
         cql.quests[index] = false
      end
   end
   -- then strip out flagged quests (doing this afterwards since we need to tremove backwards)
   for index=#cql.quests,1,-1 do
      if cql.quests[index]==false then
         tremove(cql.quests,index)
      end
   end

   -- if player is in a war campaign then add a fake header
   local warCampaignHeader = cql:GetWarCampaignHeader()
   if warCampaignHeader then
		tinsert(cql.quests,1,{0,warCampaignHeader,0,nil,true,false,false,nil,0}) -- insert a fake quest log index at top of list
   end

   -- finally update scrollframe

   local numEntries = #cql.quests
   local scrollFrame = cql.scrollFrame
   local offset = HybridScrollFrame_GetOffset(scrollFrame)
   local buttons = scrollFrame.buttons
   local selectedIndex = GetQuestLogSelection()

   cql.count.text:SetText(format("%s \124cffffffff%d/%d",QUESTS_COLON,numQuests,MAX_QUESTLOG_QUESTS))

   for i=1, #buttons do
      local index = i + offset
	  local button = buttons[i]

	  if ( index <= numEntries ) then
         local entry, questTitle, level, suggestedGroup, isHeader, isCollapsed, isComplete, frequency, questID = unpack(cql.quests[index])

         button.index = entry -- this is the questLogIndex
         button.questID = questID
         button.isHeader = isHeader
         button.isCollapsed = isCollapsed
         button.questTitle = questTitle

         button.normalText:SetWidth(275)
         local maxWidth = 275 -- we may shrink normalText to accomidate check and tag icons

         local color = isHeader and QuestDifficultyColors["header"] or GetQuestDifficultyColor(level)
         if not isHeader and selectedIndex==entry then
            button:SetNormalFontObject("GameFontHighlight")
            button.selected:SetVertexColor(color.r,color.g,color.b)
            button.selected:Show()
         else
            button:SetNormalFontObject(color.font)
            button.selected:Hide()
         end

         if isHeader then
            button:SetText(questTitle)
            button.check:Hide()
            button.tag:Hide()
			button.groupMates:Hide()
			if entry==0 then -- for fake entries (war campaign) show alliance/horde icon instead of +/- button
				local icon = UnitFactionGroup("player")=="Alliance" and "Interface\\WorldStateFrame\\AllianceIcon" or "Interface\\WorldStateFrame\\HordeIcon"
				button:SetNormalTexture(icon)
				button:SetHighlightTexture(icon)
			else
				button:SetNormalTexture(isCollapsed and "Interface\\Buttons\\UI-PlusButton-Up" or "Interface\\Buttons\\UI-MinusButton-Up")
				button:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Hilight")
			end
         else
            if ClassicQuestLogSettings.ShowLevels then
               button:SetText(format("  [%d] %s",level,questTitle))
            else
               button:SetText(format("  %s",questTitle))
            end
            button:SetNormalTexture("")
            button:SetHighlightTexture("")
            -- if quest is tracked, show check and shorted max normalText width
            if IsQuestWatched(entry) then
               maxWidth = maxWidth - 16
               button.check:Show()
            else
               button.check:Hide()
            end
            -- display an icon to note what type of quest it is
            -- tag. daily icon can be alone or before other icons except for COMPLETED or FAILED
            local tagID
            local questTagID, tagName = GetQuestTagInfo(questID)
            if isComplete and isComplete<0 then
               tagID = "FAILED"
            elseif isComplete and isComplete>0 then
               tagID = "COMPLETED"
            elseif questTagID and questTagID==QUEST_TAG_ACCOUNT then
               local factionGroup = GetQuestFactionGroup(questID)
               if factionGroup then
                  tagID = "ALLIANCE"
                  if factionGroup==LE_QUEST_FACTION_HORDE then
                     tagID = "HORDE"
                  end
               else
                  tagID = QUEST_TAG_ACCOUNT;
               end
            elseif frequency==LE_QUEST_FREQUENCY_DAILY and (not isComplete or isComplete==0) then
               tagID = "DAILY"
            elseif frequency==LE_QUEST_FREQUENCY_WEEKLY and (not isComplete or isComplete==0) then
               tagID = "WEEKLY"
            elseif questTagID then
               tagID = questTagID
            end
            button.tagID = nil
            button.tag:Hide()
            if tagID then -- this is a special type of quest
               maxWidth = maxWidth - 16
               local tagCoords = QUEST_TAG_TCOORDS[tagID]
               if tagCoords then
                  button.tagID = tagID
                  button.tag:SetTexCoord(unpack(tagCoords))
                  button.tag:Show()
               end
            end

            -- If not a header see if any nearby group mates are on this quest
            local partyMembersOnQuest = 0
            for j=1,GetNumSubgroupMembers() do
               if IsUnitOnQuest(entry,"party"..j) then
                  partyMembersOnQuest = partyMembersOnQuest + 1
               end
            end
            if partyMembersOnQuest>0 then
               button.groupMates:SetText("["..partyMembersOnQuest.."]")
               button.partyMembersOnQuest = partyMembersOnQuest
               button.groupMates:Show()
            else
               button.partyMembersOnQuest = nil
               button.groupMates:Hide()
            end

         end

         -- limit normalText width to the maxWidth
         button.normalText:SetWidth(min(maxWidth,button.normalText:GetStringWidth()))

         button:Show()
      else
         button:Hide()
      end
   end

   if numEntries==0 then
      cql.scrollFrame:Hide()
      cql.emptyLog:Show()
      cql.detail:Hide()
   else
      cql.scrollFrame:Show()
      cql.emptyLog:Hide()
      cql.scrollFrame.expandAll:SetNormalTexture(cql.expanded and "Interface\\Buttons\\UI-MinusButton-Up" or "Interface\\Buttons\\UI-PlusButton-Up")
   end

   cql:UpdateControlButtons()

   HybridScrollFrame_Update(scrollFrame, 16*numEntries, 16)

   cql:UpdateQuestDetail()
   cql:UpdateDetailColors()
end

-- this updates the detail pane of the currently selected quest
function cql:UpdateQuestDetail()
   local index = GetQuestLogSelection()
   if ( index == 0 ) then
      cql.selectedIndex = nil
      ClassicQuestLogDetailScrollFrame:Hide()
   elseif index>0 and index<=GetNumQuestLogEntries() then
      local _,_,_,isHeader,_,_,_,questID = GetQuestLogTitle(index)
      if not isHeader then
         ClassicQuestLogDetailScrollFrame:Show()
         ClassicQuestLog.questID = questID
         QuestInfo_Display(QUEST_TEMPLATE_LOG, ClassicQuestLogDetailScrollChildFrame)
         ClassicQuestLog.SealMaterialBG:Hide()
         -- if a different questID being viewed, scroll to top of detail pane
         if questID ~= cql.lastViewedQuestID then
            ClassicQuestLogDetailScrollFrameScrollBar:SetValue(0)
            cql.lastViewedQuestID = questID
         end
      end
   end
   -- show portrait off to side of window if one is available
   local questPortrait, questPortraitText, questPortraitName, questPortraitMount = GetQuestLogPortraitGiver();
   if (questPortrait and questPortrait ~= 0 and QuestLogShouldShowPortrait()) then
      -- only show quest portrait if it's not already shown
	  if QuestNPCModel:GetParent()~=ClassicQuestLog or not QuestNPCModel:IsVisible() or cql.questPortrait~=questPortrait then
		QuestFrame_ShowQuestPortrait(ClassicQuestLog, questPortrait, questPortraitMount, questPortraitText, questPortraitName, -3, -42)
         cql.questPortrait = questPortrait
      end
   else
      QuestFrame_HideQuestPortrait()
   end
end

--[[ list entry handling ]]

function cql:ListEntryOnClick()
   local index = self.index
   if self.index==0 then
		return -- this is a fake header/war campaign; don't do anything
		elseif self.isHeader then
      ClassicQuestLogCollapsedHeaders[self.questTitle] = not ClassicQuestLogCollapsedHeaders[self.questTitle] or nil
   else
      if IsModifiedClick("CHATLINK") and ChatEdit_GetActiveWindow() then
         local link = GetQuestLink(self.questID)
         if link then
            ChatEdit_InsertLink(link)
         end
      elseif IsModifiedClick("QUESTWATCHTOGGLE") then
         cql:ToggleWatch(index)
      else
         cql:SelectQuestIndex(index)
      end
   end
   cql:UpdateLogList()
end

function cql:ToggleWatch(index)
   if not index then
      index = GetQuestLogSelection()
   end
   if index>0 then
      if IsQuestWatched(index) then -- already watched, remove from watch
         RemoveQuestWatch(index)
      else -- not watched, see if there's room to add, add if so
         if GetNumQuestWatches() >= MAX_WATCHABLE_QUESTS then
            UIErrorsFrame:AddMessage(format(QUEST_WATCH_TOO_MANY,MAX_WATCHABLE_QUESTS),1,0.1,0.1,1)
         else
            AddQuestWatch(index)
         end
      end
      QuestWatch_Update()
   end
end

-- tooltip
function cql:ListEntryOnEnter()
   local index = self.index

   if self.isHeader or not ClassicQuestLogSettings.ShowTooltips or not index then
      return
   end

   GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
   GameTooltip:AddLine((GetQuestLogTitle(index)),1,.82,0)

   local title, level, suggestedGroup, isHeader, isCollapsed, isComplete, frequency, questID, startEvent, displayQuestID, isOnMap, hasLocalPOI = GetQuestLogTitle(self.index)

   -- quest tag tooltip info (shameless copy-paste from QuestMapFrame.lua)
   local tagID, tagName = GetQuestTagInfo(questID);
   if ( tagName ) then
      local factionGroup = GetQuestFactionGroup(questID);
      -- Faction-specific account quests have additional info in the tooltip
      if ( tagID == QUEST_TAG_ACCOUNT and factionGroup ) then
         local factionString = FACTION_ALLIANCE;
         if ( factionGroup == LE_QUEST_FACTION_HORDE ) then
            factionString = FACTION_HORDE;
         end
         tagName = format("%s (%s)", tagName, factionString);
      end
      GameTooltip:AddLine(tagName, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
      if ( QUEST_TAG_TCOORDS[tagID] ) then
         local questTypeIcon;
         if ( tagID == QUEST_TAG_ACCOUNT and factionGroup ) then
            questTypeIcon = QUEST_TAG_TCOORDS["ALLIANCE"];
            if ( factionGroup == LE_QUEST_FACTION_HORDE ) then
               questTypeIcon = QUEST_TAG_TCOORDS["HORDE"];
            end
         else
            questTypeIcon = QUEST_TAG_TCOORDS[tagID];
         end
         GameTooltip:AddTexture("Interface\\QuestFrame\\QuestTypeIcons", unpack(questTypeIcon));
      end
   end
   if ( frequency == LE_QUEST_FREQUENCY_DAILY ) then
      GameTooltip:AddLine(DAILY, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
      GameTooltip:AddTexture("Interface\\QuestFrame\\QuestTypeIcons", unpack(QUEST_TAG_TCOORDS["DAILY"]));
   elseif ( frequency == LE_QUEST_FREQUENCY_WEEKLY ) then
      GameTooltip:AddLine(WEEKLY, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
      GameTooltip:AddTexture("Interface\\QuestFrame\\QuestTypeIcons", unpack(QUEST_TAG_TCOORDS["WEEKLY"]));
   end
   if ( isComplete and isComplete < 0 ) then
      GameTooltip:AddLine(FAILED, RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b);
      GameTooltip:AddTexture("Interface\\QuestFrame\\QuestTypeIcons", unpack(QUEST_TAG_TCOORDS["FAILED"]));
   end

   -- list members on quest if they exist
   if self.partyMembersOnQuest then
      GameTooltip:AddLine(PARTY_QUEST_STATUS_ON,1,.82,0)
      for j=1,GetNumSubgroupMembers() do
         if IsUnitOnQuest(index,"party"..j) then
            GameTooltip:AddLine(GetUnitName("party"..j),.9,.9,.9)
         end
      end
   end

   -- description
   if isComplete and isComplete>0 then
      if ( IsBreadcrumbQuest and IsBreadcrumbQuest(self.questID) ) then
         GameTooltip:AddLine(GetQuestLogCompletionText(self.index), 1, 1, 1, true);
      else
         GameTooltip:AddLine(QUEST_WATCH_QUEST_READY, 1, 1, 1, true);
      end
   else
      local _, objectiveText = GetQuestLogQuestText(index)
      GameTooltip:AddLine(objectiveText,.85,.85,.85,true)
      local requiredMoney = GetQuestLogRequiredMoney(index)
      local numObjectives = GetNumQuestLeaderBoards(index)
      for i=1,numObjectives do
         local text, objectiveType, finished = GetQuestLogLeaderBoard(i,index)
         if ( text ) then
            local color = HIGHLIGHT_FONT_COLOR
            if ( finished ) then
               color = GRAY_FONT_COLOR
            end
            GameTooltip:AddLine(QUEST_DASH..text, color.r, color.g, color.b, true)
         end
      end
      if ( requiredMoney > 0 ) then
         local playerMoney = GetMoney()
         local color = HIGHLIGHT_FONT_COLOR
         if ( requiredMoney <= playerMoney ) then
            playerMoney = requiredMoney
            color = GRAY_FONT_COLOR
         end
         GameTooltip:AddLine(QUEST_DASH..GetMoneyString(playerMoney).." / "..GetMoneyString(requiredMoney), color.r, color.g, color.b);
      end

   end


   GameTooltip:Show()
end

--[[ selection ]]

function cql:SelectQuestIndex(index)

   SelectQuestLogEntry(index)

   StaticPopup_Hide("ABANDON_QUEST")
   StaticPopup_Hide("ABANDON_QUEST_WITH_ITEMS")
   SetAbandonQuest()

   cql:UpdateLogList()
end

-- selects the first quest in the log (if any)
function cql:SelectFirstQuest()
   for i=1,GetNumQuestLogEntries() do
      if not select(4,GetQuestLogTitle(i)) then
         cql:SelectQuestIndex(i)
         return
      end
   end
   cql:SelectQuestIndex(0) -- if we reached here, select nothing
end

--[[ control buttons ]]

function cql:UpdateControlButtons()
   local selectionIndex = GetQuestLogSelection()
   if selectionIndex==0 then
      cql.abandon:Disable()
      cql.push:Disable()
      cql.track:Disable()
   else
      local questID = select(8,GetQuestLogTitle(selectionIndex))
      cql.abandon:SetEnabled(GetAbandonQuestName() and CanAbandonQuest(questID))
      cql.push:SetEnabled(GetQuestLogPushable() and IsInGroup())
      cql.track:Enable()
   end
end

function cql:ExpandAllOnClick()
   if not cql.expanded then
      wipe(ClassicQuestLogCollapsedHeaders)
   else
      for i=1,GetNumQuestLogEntries() do
         local questTitle,_,_,isHeader = GetQuestLogTitle(i)
         if isHeader then
            ClassicQuestLogCollapsedHeaders[questTitle] = true
         end
      end
   end
   cql:UpdateLogList()
end

--[[ map button ]]

function cql:ShowMap()
   cql:HideWindow() -- can't let map quest details fight with our details
   local selectionIndex = GetQuestLogSelection()
   if selectionIndex==0 then
      ToggleWorldMap()
   else
      local questID = select(8,GetQuestLogTitle(selectionIndex))
      if not WorldMapFrame:IsVisible() then
         ToggleWorldMap()
      end
      if not IsClassic then
         QuestMapFrame_ShowQuestDetails(questID)
      end
   end
end

--[[ overrides ]]

-- if a user sets a key in Key Bindings -> AddOns -> Classic Quest Log, then
-- we leave the default binding and micro button alone.
-- if no key is set, we override the default's binding and hook the macro button

function cql:UpdateOverrides()
   local key = GetBindingKey("CLASSIC_QUEST_LOG_TOGGLE")
   if key then -- and ClassicQuestLogSettings.AltBinding then
      ClearOverrideBindings(cql)
      cql.overridingKey = nil
   else -- there's no binding for addon, so override the default stuff
      -- hook the ToggleQuestLog (if it's not been hooked before)
      if not cql.oldToggleQuestLog then
         cql.oldToggleQuestLog = ToggleQuestLog
         function ToggleQuestLog(...)
            if cql.overridingKey then
               cql:ToggleWindow() -- to toggle our window if overriding
               return
            else
               return cql.oldToggleQuestLog(...) -- and default stuff if they clear overriding
            end
         end
      end
      -- now see if default toggle quest binding has changed
      local newKey = GetBindingKey("TOGGLEQUESTLOG")
      if cql.overridingKey~=newKey and newKey then
         ClearOverrideBindings(cql)
         SetOverrideBinding(cql,false,newKey,"CLASSIC_QUEST_LOG_TOGGLE")
         cql.overridingKey = newKey
      end
   end
end

function cql:ToggleWindow()
   cql[cql:IsVisible() and "HideWindow" or "ShowWindow"](self)
end

function cql:HideWindow()
   if ClassicQuestLogSettings.UndockWindow then
      ClassicQuestLog:Hide()
   else
      HideUIPanel(ClassicQuestLog)
   end
end

function cql:ShowWindow()
   if ClassicQuestLogSettings.UndockWindow then
      ClassicQuestLog:Show()
   else
      ShowUIPanel(ClassicQuestLog)
   end
end

--[[ options frame ]]

-- one-time set up options
for var,info in pairs({
   UndockWindow={"Undock Window","Allow the quest log to be dragged around the screen instead of docked to the left with other default UI panels."},
   LockWindow={"Lock Window Position","Prevent dragging the window unless Shift is held."},
   ShowResizeGrip={"Show Resize Grip","Show a resize grip across the bottom of the quest log to resize the height of the window."},
   ShowLevels={"Show Quest Levels","Show the level of each quest in the log."},
   ShowTooltips={"Show Quest Tooltips","When the mouse is over a quest in the log, show a brief synopsis of the quest and the meaning of any icons associated with the quest."},
   SolidBackground={"Dark Background","Use a solid dark background behind both the quest log and quest details."},
   UseClassicSkin={"Use Classic Skin","Use the original UI textures and colors.\n\nNote: This will NOT change the behavior of addons outside of Classic Quest Log. If detail text is white due to an addon (like Aurora) it will remain white regardless of this option.\n\nThis option requires a reload."},
}) do
   local button = cql.optionsFrame[var]
   button.var = var
   button.text:SetFontObject("GameFontHighlight")
   button.text:SetText(info[1])
   button.tooltipTitle = info[1]
   button.tooltipBody = info[2]
   button:SetHitRectInsets(-2,-2-button.text:GetStringWidth(),-2,-2)
end
cql.optionsFrame.TitleText:SetText(OPTIONS)
cql.optionsFrame.CloseButton:SetScript("OnKeyDown",function(self,key)
   if key==GetBindingKey("TOGGLEGAMEMENU") then
      cql.optionsFrame:Hide()
      self:SetPropagateKeyboardInput(false)
   else
      self:SetPropagateKeyboardInput(true)
   end
end)

function cql:ToggleOptions()
   local frame = cql.optionsFrame
   if frame:IsVisible() then
      frame:Hide()
   else
      frame:Show()
      frame:SetFrameStrata("DIALOG")
      cql:OptionsUpdate()
   end
end

function cql:OptionOnEnter()
   if self.tooltipTitle then
      GameTooltip:SetOwner(self,"ANCHOR_LEFT")
      GameTooltip:AddLine(self.tooltipTitle,1,1,1)
      GameTooltip:AddLine(self.tooltipBody,1,0.82,0,true)
      GameTooltip:SetBackdropColor(0,0,0,1)
      GameTooltip:Show()
   end
end

function cql:OptionOnClick()
   if self.var=="UndockWindow" then
      local enable = self:GetChecked()
      cql:ToggleWindow()
      ClassicQuestLogSettings.UndockWindow = enable
      cql:UpdateDocking()
      cql:ToggleWindow()
      cql:ToggleOptions()
   else
      ClassicQuestLogSettings[self.var] = self:GetChecked() and true
      if self.var=="ShowLevels" then
         cql:UpdateLogList()
      elseif self.var=="UseClassicSkin" then
         StaticPopupDialogs["CQL_UNSKIN"] = { button1 = YES, button2 = NO, timeout = 30, whileDead = 1, hideOnEscape = 1, text = "Changing the option 'Use Classic Skin' requires a reload to take effect. Do you want to reload the UI now?", OnAccept=ReloadUI }
         StaticPopup_Show("CQL_UNSKIN")
      end
   end
   cql:OptionsUpdate()
end

function cql:OptionsUpdate()
   for _,var in ipairs({"UndockWindow","LockWindow","ShowResizeGrip","ShowLevels","ShowTooltips","SolidBackground","UseClassicSkin"}) do
      cql.optionsFrame[var]:SetChecked(ClassicQuestLogSettings[var] and true)
   end
   if ClassicQuestLogSettings.UndockWindow then
      cql.optionsFrame.LockWindow:Enable()
      cql.optionsFrame.LockWindow.text:SetTextColor(1,1,1)
   else
      cql.optionsFrame.LockWindow:Disable()
      cql.optionsFrame.LockWindow.text:SetTextColor(0.5,0.5,0.5)
   end
   cql.resizeGrip:SetShown(ClassicQuestLogSettings.ShowResizeGrip)
   cql:UpdateBackgrounds()
end

function cql:UpdateDocking()
   local dock = not ClassicQuestLogSettings.UndockWindow
   cql:SetAttribute("UIPanelLayout-defined",dock)
   cql:SetAttribute("UIPanelLayout-enabled",dock)
   cql:SetAttribute("UIPanelLayout-area","left")
   cql:SetAttribute("UIPanelLayout-pushable",5)
   cql:SetAttribute("UIPanelLayout-width",680)
   cql:SetAttribute("UIPanelLayout-whileDead",true)
end

function cql:UpdateBackgrounds()
   if ClassicQuestLogSettings.SolidBackground then
      --cql.detail.DetailBG:SetColorTexture(0.9,0.72,0.45)
      cql.detail.DetailBG:SetColorTexture(0.075,0.075,0.075)
      cql.scrollFrame.BG:SetColorTexture(0.075,0.075,0.075)
   else
      cql.detail.DetailBG:SetTexture("Interface\\QuestFrame\\QuestBG")
      cql.detail.DetailBG:SetTexCoord(0,0.5859375,0,0.65625)
      cql.scrollFrame.BG:SetTexture("Interface\\QuestFrame\\QuestBookBG")
      cql.scrollFrame.BG:SetTexCoord(0,0.5859375,0,0.65625)
   end
   cql:UpdateDetailColors()
end

-- called during PLAYER_LOGIN to change options dialog depending on potential skins
function cql:UpdateOptionsForSkins()
   if IsAddOnLoaded("ElvUI") or IsAddOnLoaded("Aurora") then
      cql.optionsFrame.UseClassicSkin:Show()
      cql.optionsFrame:SetHeight(cql.optionsFrame:GetHeight()+24)
   end
end

-- in the unlikely event Blizzard_ObjectiveTracker is not loaded when a player logs in
-- this function runs only after it's loaded (checked at PLAYER_LOGIN or ADDON_LOADED)
function cql:HandleObjectiveTracker()
   cql:UnregisterEvent("ADDON_LOADED")
   -- hook clicking of quest objective to summon classic quest log instead of world map
   hooksecurefunc(QUEST_TRACKER_MODULE,"OnBlockHeaderClick",function(self, block, mouseButton)
      if IsModifiedClick("CHATLINK") and ChatEdit_GetActiveWindow() then
         return -- user was linking quest to chat
      end
      if mouseButton~="RightButton" then
         if IsModifiedClick("QUESTWATCHTOGGLE") then
            return -- user was untracking a quest
         end
         local questLogIndex = GetQuestLogIndexByID(block.id)
         if not (IsQuestComplete(block.id) and GetQuestLogIsAutoComplete(questLogIndex)) then
            HideUIPanel(WorldMapFrame)
            cql:ShowWindow()
         end
      end
   end)
end

--[[ detail text recoloring ]]

-- for SolidBackground option, this table (indexed by FontString reference) contains the
-- original color of each region before it was recolored. Once an entry is in the table
-- it should not be updated!
cql.RecoloredFontStrings = {}

-- called during cql:UpdateLog() and 0.1 seconds after cql:OnHide()
function cql:UpdateDetailColors()
   -- if the log is on screen with the "Solid Background" option
   if cql:IsVisible() and ClassicQuestLogSettings.SolidBackground then
      -- the bulk of the text will be recursively colored
      cql:RecurseRecolor(QuestInfoQuestType)
      cql:RecurseRecolor(QuestInfoGroupSize)
      cql:RecurseRecolor(QuestInfoObjectivesText)
      cql:RecurseRecolor(QuestInfoDescriptionText)
      cql:RecurseRecolor(QuestInfoRewardsFrame)
      -- these three headers use the morpheus font and can be directly recolored
      cql:RecolorDetailText(QuestInfoTitleHeader,0.8,0.8,0.8)
      cql:RecolorDetailText(QuestInfoDescriptionHeader,0.8,0.8,0.8)
      cql:RecolorDetailText(QuestInfoRewardsFrame.Header,0.8,0.8,0.8)
      -- now recolor QuestInfoObjectivesFrame which has special handling
      cql:RecolorObjectivesText()
   elseif next(cql.RecoloredFontStrings) then -- if the detail text has been recolored, un-recolor it
      -- go through table and SetTextColor back to the saved color
      for fontstring,color in pairs(cql.RecoloredFontStrings) do
         fontstring:SetTextColor(unpack(color))
      end
      -- and wipe the table
      wipe(cql.RecoloredFontStrings)
   end
end

-- completed objectives are greyed out so this section is handled differently
local completedSuffix = "%("..COMPLETE.."%)$" -- to save some garbage creation
function cql:RecolorObjectivesText()
   local index = 1
   local fontstring
   repeat
      fontstring = _G["QuestInfoObjective"..index]
      if fontstring then
         if (fontstring:GetText() or ""):match(completedSuffix) then
            cql:RecolorDetailText(fontstring,0.55,0.55,0.55)
         else
            cql:RecolorDetailText(fontstring,1,1,1)
         end
      end
      index = index + 1
   until not fontstring
end

-- this only ever gets called if SolidBackground is enabled; it colors the fontstring
-- after saving its original color (if it hasn't already been saved)
function cql:RecolorDetailText(fontstring,r,g,b,a)
   local font,height,flags = fontstring:GetFont()
   if flags=="OUTLINE" or fontstring:GetParent().NameFrame then
      return -- don't recolor outlined text (numbers) and text within NameFrames (item text)
   end
   -- if this fontstring's color hasn't been saved yet, store it in RecoloredFontStrings
   if not cql.RecoloredFontStrings[fontstring] then
      cql.RecoloredFontStrings[fontstring] = {fontstring:GetTextColor()}
   end
   fontstring:SetTextColor(r,g,b,a)
   fontstring:SetShadowColor(0,0,0,0) -- remove shadow too (this doesn't get restored but it's ok)
end

-- this accepts one or more frames and then recolors all FontStrings within the frame
-- or its descendents; TODO: reduce garbage creation (not a big deal, but kinda annoying)
function cql:RecurseRecolor(...)
  for i=1,select("#",...) do
    local object = select(i,...)
    if object:GetObjectType()=="FontString" then -- if a fontstring found
      cql:RecolorDetailText(object,1,0.82,0.5) -- color it pale gold
    elseif object.GetRegions then -- otherwise if this element has child regions
      for _,region in ipairs({object:GetRegions()}) do
        if region:GetObjectType()=="FontString" then
          cql:RecolorDetailText(region,1,0.82,0.5)
        end
      end
      cql:RecurseRecolor(object:GetChildren())
    end
  end
end

--[[ skinning ]]

-- called if ElvUI is enabled, skins the window for it
function cql:SkinForElvUI()
   local E, L, P, G = unpack(ElvUI)
   local S = E:GetModule("Skins")
   cql:StripTextures()
   cql:SetTemplate("Transparent")
   S:HandleCloseButton(cql.CloseButton)
   for k,v in pairs({"abandon","push","track","options","close"}) do
      S:HandleButton(cql[v])
   end
   cql.detail:StripTextures()
   cql.scrollFrame:StripTextures()
   S:HandleScrollBar(cql.detail.ScrollBar)
   S:HandleScrollBar(cql.scrollFrame.scrollBar)
   cql.Inset:StripTextures()
   S:HandleButton(cql.count,true)
   S:HandleButton(cql.scrollFrame.expandAll)
   cql.optionsFrame:StripTextures()
   cql.optionsFrame:SetTemplate("Opaque")
   S:HandleCloseButton(cql.optionsFrame.CloseButton)
   for k,v in pairs({"UndockWindow","LockWindow","ShowResizeGrip","ShowLevels","ShowTooltips","SolidBackground","UseClassicSkin"}) do
      S:HandleCheckBox(cql.optionsFrame[v])
   end
end

-- called if Aurora is enabled, skins the window for it
function cql:SkinForAurora()
   local F, C = unpack(Aurora or FreeUI)
   local function strip(frame)
      for k,v in pairs({frame:GetRegions()}) do
         if v:GetObjectType()=="Texture" then
            v:Hide()
         end
      end
   end
   F.ReskinPortraitFrame(cql,true)
   cql.portraitIcon:Hide()
   strip(cql.scrollFrame)
   strip(cql.detail)
   F.ReskinScroll(cql.scrollFrame.scrollBar)
   F.ReskinScroll(cql.detail.ScrollBar)
   cql.detail.DetailBG:SetAlpha(0)
   cql.scrollFrame.BG:SetAlpha(0)
   strip(cql.count)
   strip(cql.scrollFrame.expandAll)
   for k,v in pairs({"abandon","push","track","options","close"}) do
      F.Reskin(cql[v])
   end
   strip(cql.optionsFrame)
   F.SetBD(cql.optionsFrame)
   F.SetBD(cql.optionsFrame) -- again to make it darker
   for k,v in pairs({"UndockWindow","LockWindow","ShowResizeGrip","ShowLevels","ShowTooltips","SolidBackground","UseClassicSkin"}) do
      F.ReskinCheck(cql.optionsFrame[v])
   end
   F.ReskinClose(cql.optionsFrame.CloseButton)
   cql.optionsFrame.SolidBackground:Disable()
   cql.optionsFrame.SolidBackground.text:SetTextColor(0.5,0.5,0.5)
end

-- returns the chapter title of the current war campaign if the player is on a war campaign
function cql:GetWarCampaignHeader()
   if not C_CampaignInfo then return end
	local warCampaignID = C_CampaignInfo.GetCurrentCampaignID()
	if warCampaignID then
		local warCampaignInfo = C_CampaignInfo.GetCampaignInfo(warCampaignID)
		if warCampaignInfo and warCampaignInfo.visibilityConditionMatched and not warCampaignInfo.complete then
			local campaignChapterID = C_CampaignInfo.GetCurrentCampaignChapterID()
			if campaignChapterID then
				local campaignChapterInfo = C_CampaignInfo.GetCampaignChapterInfo(campaignChapterID)
				return campaignChapterInfo.name
			end
		end
	end
end