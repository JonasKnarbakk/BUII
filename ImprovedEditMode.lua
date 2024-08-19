local queueStatusButtonOverlayFrame = nil
local queueStatusButtonOverlayFrameHook = nil
local queueStatusButtonOverlayFrameHookEnabled = false
local editModeImprovedEnabled = false

local onHoverEnabled = {
  MainMenuBar = false,
  MultiBarLeft = false,
  MultiBarRight = false,
  MultiBarBottomLeft = false,
  MultiBarBottomRight = false,
  MultiBar5 = false,
  MultiBar6 = false,
  MultiBar7 = false,
  BagsBar = false,
  MicroMenu = false,
}

local hideMacroTextEnabled = {
  MainMenuBar = false,
  MultiBarLeft = false,
  MultiBarRight = false,
  MultiBarBottomLeft = false,
  MultiBarBottomRight = false,
  MultiBar5 = false,
  MultiBar6 = false,
  MultiBar7 = false,
}

local abbreviatedKeybindingsEnabled = {
  MainMenuBar = false,
  MultiBarLeft = false,
  MultiBarRight = false,
  MultiBarBottomLeft = false,
  MultiBarBottomRight = false,
  MultiBar5 = false,
  MultiBar6 = false,
  MultiBar7 = false,
}

local frameHookSet = {
  MainMenuBar = false,
  MultiBarLeft = false,
  MultiBarRight = false,
  MultiBarBottomLeft = false,
  MultiBarBottomRight = false,
  MultiBar5 = false,
  MultiBar6 = false,
  MultiBar7 = false,
  BagsBar = false,
  MicroMenu = false,
  EditModeSystemSettingsDialog = false,
}

local bagFrames = {
  MainMenuBarBackpackButton = true,
  BagBarExpandToggle = true,
  CharacterBag0Slot = true,
  CharacterBag1Slot = true,
  CharacterBag2Slot = true,
  CharacterBag3Slot = true,
  CharacterReagentBag0Slot = true,
}

local microMenuFrames = {
  CharacterMicroButton = true,
  ProfessionMicroButton = true,
  PlayerSpellsMicroButton = true,
  AchievementMicroButton = true,
  QuestLogMicroButton = true,
  GuildMicroButton = true,
  LFDMicroButton = true,
  CollectionsMicroButton = true,
  EJMicroButton = true,
  StoreMicroButton = true,
  MainMenuMicroButton = true,
}

local keybindMap = {
  ["Middle Mouse"] = "M3",
  ["Mouse Wheel Down"] = "MWD",
  ["Mouse Wheel Up"] = "MWU",
  ["Home"] = "Hm",
  ["Insert"] = "Ins",
  ["Page Down"] = "PD",
  ["Page Up"] = "PU",
  ["Spacebar"] = "SpB",
  ["CTRL-Num Pad 8"] = "G8",
  ["CTRL-Num Pad 7"] = "G7",
  ["c-Num Pad 8"] = "G8",
  ["c-Num Pad 7"] = "G7",
  ["Mouse Button 5"] = "M5",
  ["Mouse Button 4"] = "M4",
}

local keybindPatterns = {
  ["a%-"] = "A",           -- alt
  ["c%-"] = "C",           -- ctrl
  ["s%-"] = "S",           -- shift
  ["Mouse Button "] = "M", -- M4, M5
  ["Num Pad "] = "N",
}

-- Cache frequently used globals
local editModeManagerFrame = EditModeManagerFrame
local editModeSettingsDialog = EditModeSystemSettingsDialog
local mainMenuBar = MainMenuBar
local bagsBar = BagsBar
local microMenu = MicroMenu

-- extended settings
local enum_EditModeActionBarSetting_HideMacroText = 10
local enum_EditModeActionBarSetting_AbbreviateKeybindings = 11
local enum_EditModeActionBarSetting_BarVisibility = 12
local enum_ActionBarVisibleSetting_OnHover = 4
local enum_BagsBarSetting_BarVisibility = 3
local enum_MicroMenuSetting_BarVisibility = 3

local HUD_EDIT_MODE_SETTING_ACTION_BAR_VISIBLE_SETTING_ON_HOVER = "On Hover"
local HUD_EDIT_MODE_SETTING_ACTION_BAR_HIDE_MACRO_TEXT = "Hide Macro Text"
local HUD_EDIT_MODE_SETTING_ACTION_BAR_ABBREVIATE_KEYBINDINGS = "Abbreviate Keybindings"

--- Add a setting type to the EditModeSystemSettingsDialog for the given Frame
---@param settingIndex number index value of added setting, passed back in editModeSystemSettingsDialog_OnSettingValueChanged
---@param optionType number Enum option of type Enum.ChrCustomizationOptionType
---@param settingData table Setting data that will be passed to SetupSetting
local function addOptionToSettingsDialog(settingIndex, optionType, settingData)
  assert(type(settingIndex) == "number")
  assert(type(optionType) == "number")
  assert(type(settingData) == "table")

  local settingPool = editModeSettingsDialog:GetSettingPool(optionType)

  if (settingPool) then
    local settingFrame = settingPool:Acquire()
    settingFrame:SetPoint("TOPLEFT")
    settingFrame.layoutIndex = settingIndex
    settingFrame:Show()

    editModeSettingsDialog:Show();
    editModeSettingsDialog:Layout();
    settingFrame:SetupSetting(settingData)
  end
end

local function setupFrame(frame, frameName, frameTemplate, parent, point, overlayWidth, overlayHeight, onMouseDownFunc,
                          onMouseUpFunc, label, databaseName)
  if not frame then
    frame = CreateFrame("Frame", frameName, parent, frameTemplate)
    frame:SetSize(overlayWidth, overlayHeight)
    frame:SetPoint(point)
    frame.Selection:SetScript("OnMouseDown", onMouseDownFunc)
    frame.Selection:SetScript("OnMouseUp", onMouseUpFunc)
    frame.Selection.Label:SetText(label)
  end

  -- TODO: Implement support for layouts
  if BUIIDatabase[databaseName] then
    frame:GetParent():ClearAllPoints()
    frame:GetParent():SetPoint(BUIIDatabase[databaseName]["point"],
      UIParent,
      BUIIDatabase[databaseName]["relativePoint"],
      BUIIDatabase[databaseName]["xOffset"],
      BUIIDatabase[databaseName]["yOffset"])
  end

  return frame
end

local function resetFrame(frame, pointDefault, parentDefault, relativeToDefault)
  frame:GetParent():ClearAllPoints()
  frame:GetParent():SetPoint(pointDefault, parentDefault, relativeToDefault, 0, 0)
end

local function restorePosition(frame, databaseName)
  if BUIIDatabase[databaseName] then
    local point, _, relativePoint, xOffset, yOffset = frame:GetPoint()

    if point ~= BUIIDatabase[databaseName]["point"] or
        relativePoint ~= BUIIDatabase[databaseName]["relativePoint"] or
        xOffset ~= BUIIDatabase[databaseName]["xOffset"] or
        yOffset ~= BUIIDatabase[databaseName]["yOffset"] then
      frame:ClearAllPoints()
      frame:SetPoint(BUIIDatabase[databaseName]["point"],
        UIParent,
        BUIIDatabase[databaseName]["relativePoint"],
        BUIIDatabase[databaseName]["xOffset"],
        BUIIDatabase[databaseName]["yOffset"])
    end
  end
end

local function showFrameHighlight(frame)
  frame:Show()
  frame.Selection:ShowHighlighted()
end

local function hideFrameHighlight(frame)
  frame.Selection:Hide()
  frame.Selection.isSelected = false
  frame.Selection.isHighlighted = false
  frame:Hide()
end

local function onMouseDown(frame)
  editModeManagerFrame:SelectSystem(frame:GetParent())
  frame.Selection:ShowSelected()
  frame:GetParent():SetMovable(true)
  frame:GetParent():SetClampedToScreen(true)
  frame:GetParent():StartMoving()
end

local function onMouseUp(frame, databaseName, pointDefault, relativeToDefault, relativePointDefault)
  frame.Selection:ShowHighlighted()
  frame:GetParent():StopMovingOrSizing()
  frame:GetParent():SetMovable(false)
  frame:GetParent():SetClampedToScreen(false)

  local point, _, relativePoint, xOffset, yOffset = frame:GetParent():GetPoint()

  if not BUIIDatabase[databaseName] then
    BUIIDatabase[databaseName] = {
      point = pointDefault,
      relativeTo = relativeToDefault,
      relativePoint = relativePointDefault,
      xOffset = 0,
      yOffset = 0,
    }
  end

  BUIIDatabase[databaseName]["point"] = point
  BUIIDatabase[databaseName]["relativeTo"] = nil
  BUIIDatabase[databaseName]["relativePoint"] = relativePoint
  BUIIDatabase[databaseName]["xOffset"] = xOffset
  BUIIDatabase[databaseName]["yOffset"] = yOffset
end

--- Called when EditMode is enabled
local function editMode_OnEnter()
  if InCombatLockdown() then return end
  showFrameHighlight(queueStatusButtonOverlayFrame)

  -- In edit mode action bars should be shown even if normally hidden
  for frameName in pairs(onHoverEnabled) do
    local frame = _G[frameName]
    if frame then
      frame:SetAlpha(1)
    end
  end
end

--- Called when EditMode is disabled
local function editMode_OnExit()
  if InCombatLockdown() then return end
  hideFrameHighlight(queueStatusButtonOverlayFrame)

  -- When exiting edit mode we need to hide aciton bars if they have onHoverEnabled
  for frameName, enabled in pairs(onHoverEnabled) do
    local frame = _G[frameName]
    if frame and enabled then
      frame:SetAlpha(0)
    end
  end
end

local function queueStatusButtonOverlayFrame_OnMouseDown()
  onMouseDown(queueStatusButtonOverlayFrame)
end

local function queueStatusButtonOverlayFrame_OnMouseUp()
  onMouseUp(queueStatusButtonOverlayFrame, "queue_status_button_position", "BOTTOMRIGHT", nil, "BOTTOMRIGHT")
end

local function queueStatusButtonOverlayFrame_OnUpdate()
  if queueStatusButtonOverlayFrameHookEnabled and not queueStatusButtonOverlayFrame.Selection.isSelected then
    restorePosition(queueStatusButtonOverlayFrame:GetParent(), "queue_status_button_position")
  end
end

local function setupQueueStatusButton()
  queueStatusButtonOverlayFrame = setupFrame(statusTrackingBarOverlayFrame, "BUIIQueueStatusButtonOverlay",
    "BUIIQueueStatusButtonEditModeSystemTemplate", QueueStatusButton, "BOTTOMRIGHT", QueueStatusButton:GetWidth(),
    QueueStatusButton:GetHeight(), queueStatusButtonOverlayFrame_OnMouseDown,
    queueStatusButtonOverlayFrame_OnMouseUp, "Queue Status Button", "queue_status_button_position")
  if not queueStatusButtonOverlayFrameHook then
    QueueStatusButton:HookScript("OnUpdate", queueStatusButtonOverlayFrame_OnUpdate)
    queueStatusButtonOverlayFrameHook = true
    queueStatusButtonOverlayFrameHookEnabled = true
  end
end

local function resetQueueStatusButton()
  resetFrame(queueStatusButtonOverlayFrame, "BOTTOMLEFT", MicroMenuContainer, "BOTTOMLEFT")
  queueStatusButtonOverlayFrameHookEnabled = false
end

--- Add the additional settings to MainMenuBar
local function settingsDialogMainMenuBarAddOptions()
  local hideMacroText = {
    setting = enum_EditModeActionBarSetting_HideMacroText,
    name = HUD_EDIT_MODE_SETTING_ACTION_BAR_HIDE_MACRO_TEXT,
    type = Enum.EditModeSettingDisplayType.Checkbox,
  }

  local hideMacroTextData = {
    displayInfo = hideMacroText,
    currentValue = hideMacroTextEnabled["MainMenuBar"] == true and 1 or 0,
    settingName = HUD_EDIT_MODE_SETTING_ACTION_BAR_HIDE_MACRO_TEXT
  }

  addOptionToSettingsDialog(enum_EditModeActionBarSetting_HideMacroText,
    Enum.ChrCustomizationOptionType.Checkbox,
    hideMacroTextData)

  local abbreviateKeybindings = {
    setting = enum_EditModeActionBarSetting_AbbreviateKeybindings,
    name = HUD_EDIT_MODE_SETTING_ACTION_BAR_ABBREVIATE_KEYBINDINGS,
    type = Enum.EditModeSettingDisplayType.Checkbox,
  }

  local abbreviateKeybindingsData = {
    displayInfo = abbreviateKeybindings,
    currentValue = abbreviatedKeybindingsEnabled["MainMenuBar"] == true and 1 or 0,
    settingName = HUD_EDIT_MODE_SETTING_ACTION_BAR_ABBREVIATE_KEYBINDINGS
  }

  addOptionToSettingsDialog(enum_EditModeActionBarSetting_AbbreviateKeybindings,
    Enum.ChrCustomizationOptionType.Checkbox,
    abbreviateKeybindingsData)

  local barVisibility = {
    setting = enum_EditModeActionBarSetting_BarVisibility,
    name = HUD_EDIT_MODE_SETTING_ACTION_BAR_VISIBLE_SETTING,
    type = Enum.EditModeSettingDisplayType.Dropdown,
    options = {
      {
        value = Enum.ActionBarVisibleSetting.Always,
        text = HUD_EDIT_MODE_SETTING_ACTION_BAR_VISIBLE_SETTING_ALWAYS
      },
      {
        value = Enum.ActionBarVisibleSetting.InCombat,
        text = HUD_EDIT_MODE_SETTING_ACTION_BAR_VISIBLE_SETTING_IN_COMBAT
      },
      {
        value = Enum.ActionBarVisibleSetting.OutOfCombat,
        text = HUD_EDIT_MODE_SETTING_ACTION_BAR_VISIBLE_SETTING_OUT_OF_COMBAT
      },
      {
        value = Enum.ActionBarVisibleSetting.Hidden,
        text = HUD_EDIT_MODE_SETTING_ACTION_BAR_VISIBLE_SETTING_HIDDEN
      },
      {
        value = enum_ActionBarVisibleSetting_OnHover,
        text = HUD_EDIT_MODE_SETTING_ACTION_BAR_VISIBLE_SETTING_ON_HOVER
      },
    }
  }

  local barVisibilityData = {
    displayInfo = barVisibility,
    currentValue = onHoverEnabled["MainMenuBar"] == true and enum_ActionBarVisibleSetting_OnHover or Enum.ActionBarVisibleSetting.Always,
    settingName = HUD_EDIT_MODE_SETTING_ACTION_BAR_VISIBLE_SETTING
  }

  addOptionToSettingsDialog(enum_EditModeActionBarSetting_BarVisibility,
    Enum.ChrCustomizationOptionType.Dropdown,
    barVisibilityData)
end

--- Add the additional settings to MultiBar e.g any action bar that isn't the main one
---@param frameName table name of the MultiBar frame being edited
local function settingsDialogMultiBarAddOptions(frameName)
  local hideMacroText = {
    setting = enum_EditModeActionBarSetting_HideMacroText,
    name = HUD_EDIT_MODE_SETTING_ACTION_BAR_HIDE_MACRO_TEXT,
    type = Enum.EditModeSettingDisplayType.Checkbox,
  }
  local hideMacroTextData = {
    displayInfo = hideMacroText,
    currentValue = hideMacroTextEnabled[frameName] == true and 1 or 0,
    settingName = HUD_EDIT_MODE_SETTING_ACTION_BAR_HIDE_MACRO_TEXT
  }
  addOptionToSettingsDialog(enum_EditModeActionBarSetting_HideMacroText, Enum.ChrCustomizationOptionType.Checkbox,
    hideMacroTextData)

  local abbreviateKeybindings = {
    setting = enum_EditModeActionBarSetting_AbbreviateKeybindings,
    name = HUD_EDIT_MODE_SETTING_ACTION_BAR_ABBREVIATE_KEYBINDINGS,
    type = Enum.EditModeSettingDisplayType.Checkbox,
  }

  local abbreviateKeybindingsData = {
    displayInfo = abbreviateKeybindings,
    currentValue = abbreviatedKeybindingsEnabled[frameName] == true and 1 or 0,
    settingName = HUD_EDIT_MODE_SETTING_ACTION_BAR_ABBREVIATE_KEYBINDINGS
  }

  addOptionToSettingsDialog(enum_EditModeActionBarSetting_AbbreviateKeybindings,
    Enum.ChrCustomizationOptionType.Checkbox,
    abbreviateKeybindingsData)
end

--- Add the additional settings to BagsBar
local function settingsDialogBagBarAddOptions()
  local barVisibility = {
    setting = enum_BagsBarSetting_BarVisibility,
    name = HUD_EDIT_MODE_SETTING_ACTION_BAR_VISIBLE_SETTING,
    type = Enum.EditModeSettingDisplayType.Dropdown,
    options = {
      {
        value = Enum.ActionBarVisibleSetting.Always,
        text = HUD_EDIT_MODE_SETTING_ACTION_BAR_VISIBLE_SETTING_ALWAYS
      },
      {
        value = Enum.ActionBarVisibleSetting.InCombat,
        text = HUD_EDIT_MODE_SETTING_ACTION_BAR_VISIBLE_SETTING_IN_COMBAT
      },
      {
        value = Enum.ActionBarVisibleSetting.OutOfCombat,
        text = HUD_EDIT_MODE_SETTING_ACTION_BAR_VISIBLE_SETTING_OUT_OF_COMBAT
      },
      {
        value = Enum.ActionBarVisibleSetting.Hidden,
        text = HUD_EDIT_MODE_SETTING_ACTION_BAR_VISIBLE_SETTING_HIDDEN
      },
      {
        value = enum_ActionBarVisibleSetting_OnHover,
        text = HUD_EDIT_MODE_SETTING_ACTION_BAR_VISIBLE_SETTING_ON_HOVER
      },
    }
  }

  local barVisibilityData = {
    displayInfo = barVisibility,
    currentValue = onHoverEnabled["BagsBar"] == true and enum_ActionBarVisibleSetting_OnHover or Enum.ActionBarVisibleSetting.Always,
    settingName = HUD_EDIT_MODE_SETTING_ACTION_BAR_VISIBLE_SETTING
  }

  addOptionToSettingsDialog(enum_EditModeActionBarSetting_BarVisibility,
    Enum.ChrCustomizationOptionType.Dropdown,
    barVisibilityData)
end

--- Add the additional settings to MicroMenu
local function settingsDialogMicroMenuAddOptions()
  local barVisibility = {
    setting = enum_MicroMenuSetting_BarVisibility,
    name = HUD_EDIT_MODE_SETTING_ACTION_BAR_VISIBLE_SETTING,
    type = Enum.EditModeSettingDisplayType.Dropdown,
    options = {
      {
        value = Enum.ActionBarVisibleSetting.Always,
        text = HUD_EDIT_MODE_SETTING_ACTION_BAR_VISIBLE_SETTING_ALWAYS
      },
      {
        value = Enum.ActionBarVisibleSetting.InCombat,
        text = HUD_EDIT_MODE_SETTING_ACTION_BAR_VISIBLE_SETTING_IN_COMBAT
      },
      {
        value = Enum.ActionBarVisibleSetting.OutOfCombat,
        text = HUD_EDIT_MODE_SETTING_ACTION_BAR_VISIBLE_SETTING_OUT_OF_COMBAT
      },
      {
        value = Enum.ActionBarVisibleSetting.Hidden,
        text = HUD_EDIT_MODE_SETTING_ACTION_BAR_VISIBLE_SETTING_HIDDEN
      },
      {
        value = enum_ActionBarVisibleSetting_OnHover,
        text = HUD_EDIT_MODE_SETTING_ACTION_BAR_VISIBLE_SETTING_ON_HOVER
      },
    }
  }

  local barVisibilityData = {
    displayInfo = barVisibility,
    currentValue = onHoverEnabled["MicroMenu"] == true and enum_ActionBarVisibleSetting_OnHover or Enum.ActionBarVisibleSetting.Always,
    settingName = HUD_EDIT_MODE_SETTING_ACTION_BAR_VISIBLE_SETTING
  }

  addOptionToSettingsDialog(enum_EditModeActionBarSetting_BarVisibility,
    Enum.ChrCustomizationOptionType.Dropdown,
    barVisibilityData)
end

--- Hooked to EditModeSystemSettingsDialog:UpdateSettings
---@param self table EditModeSystemSettingsDialog
---@param systemFrame table The frame the settings belong to e.g MainMenuBar
local function editModeSystemSettingsDialog_OnUpdateSettings(self, systemFrame)
  if not editModeImprovedEnabled then return end

  if systemFrame == self.attachedToSystem then
    local currentFrameName = systemFrame:GetName()

    if currentFrameName == "MainMenuBar" then
      settingsDialogMainMenuBarAddOptions()
    elseif strfind(currentFrameName, "MultiBar") then
      settingsDialogMultiBarAddOptions(currentFrameName)
    elseif currentFrameName == "BagsBar" then
      settingsDialogBagBarAddOptions()
    elseif currentFrameName == "MicroMenuContainer" then
      settingsDialogMicroMenuAddOptions()
    end
  end
end

--- Used to give Show on Hover functionality to action bars
---@param self table Frame that triggered the OnEnter event
local function actionBar_OnEnter(self)
  if strfind(self:GetName(), "ActionButton") then
    if not onHoverEnabled["MainMenuBar"] then return end
    mainMenuBar:SetAlpha(1)
  elseif bagFrames[self:GetName()] then
    if not onHoverEnabled["BagsBar"] then return end
    bagsBar:SetAlpha(1)
  elseif microMenuFrames[self:GetName()] then
    if not onHoverEnabled["MicroMenu"] then return end
    microMenu:SetAlpha(1)
  else
    for actionBarName, enabled in pairs(onHoverEnabled) do
      if strfind(self:GetName(), actionBarName) and enabled then
        _G[actionBarName]:SetAlpha(1)
      end
    end
  end
end

--- Used to give Show on Hover functionality to action bars
---@param self table Frame that triggered the OnLeave event
local function actionBar_OnLeave(self)
  if strfind(self:GetName(), "ActionButton") then
    if not onHoverEnabled["MainMenuBar"] then return end
    mainMenuBar:SetAlpha(0)
  elseif bagFrames[self:GetName()] then
    if not onHoverEnabled["BagsBar"] then return end
    bagsBar:SetAlpha(0)
  elseif microMenuFrames[self:GetName()] then
    if not onHoverEnabled["MicroMenu"] then return end
    microMenu:SetAlpha(0)
  else
    for actionBarName, enabled in pairs(onHoverEnabled) do
      if strfind(self:GetName(), actionBarName) and enabled then
        _G[actionBarName]:SetAlpha(0)
      end
    end
  end
end

--- Enables or disables abbreviated text on an action bar button
---@param frame table action bar button to set keybind text
---@param enabled boolean set abbreviated text otherwise set default
local function frameSetAbbreviatedText(frame, enabled)
  local hotkey = frame.HotKey
  local textConstant = hotkey:GetText()
  local text = hotkey:GetText()
  if enabled then
    for k, v in pairs(keybindPatterns) do
      text = text:gsub(k, v)
    end
  else
    for v, k in pairs(keybindPatterns) do
      text = text:gsub(k, v)
    end
  end
  hotkey:SetText(keybindMap[textConstant] or text)
end

--- When keybinds are updated we need to re-set the text if abbreviatedKeybindings are enabled
---@param self table Frame the action bar button that is updating its text
local function keybind_OnUpdateHotkey(self)
  if strfind(self:GetName(), "ActionButton") then
    if not abbreviatedKeybindingsEnabled["MainMenuBar"] then return end
    frameSetAbbreviatedText(self, true)
  else
    for actionBarName, enabled in pairs(abbreviatedKeybindingsEnabled) do
      if strfind(self:GetName(), actionBarName) and enabled then
        frameSetAbbreviatedText(self, true)
      end
    end
  end
end

--- Sets the hooks needed to enable On Hover for action bars
---@param frame table The action bar frame being configured
local function hookActionBarOnHoverEvent(frame)
  if frameHookSet[frame:GetName()] then
    return
  end

  -- Need to add OnEnter/OnLeave hooks on each button otherwise we only
  -- hover the action bar when the mouse is between buttons..
  if frame:GetName() == "MainMenuBar" then
    for i = 12, 1, -1 do
      _G["ActionButton" .. i]:HookScript("OnEnter", actionBar_OnEnter)
      _G["ActionButton" .. i]:HookScript("OnLeave", actionBar_OnLeave)
    end
  elseif strfind(frame:GetName(), "MultiBar") then
    for i = 12, 1, -1 do
      _G[frame:GetName() .. "Button" .. i]:HookScript("OnEnter", actionBar_OnEnter)
      _G[frame:GetName() .. "Button" .. i]:HookScript("OnLeave", actionBar_OnLeave)
    end
  elseif frame:GetName() == "BagsBar" then
    for bagFrameName in pairs(bagFrames) do
      local subframe = _G[bagFrameName]
      if subframe then
        subframe:HookScript("OnEnter", actionBar_OnEnter)
        subframe:HookScript("OnLeave", actionBar_OnLeave)
      end
    end
  elseif frame:GetName() == "MicroMenu" then
    for microMenuFrameName in pairs(microMenuFrames) do
      local subframe = _G[microMenuFrameName]
      if subframe then
        subframe:HookScript("OnEnter", actionBar_OnEnter)
        subframe:HookScript("OnLeave", actionBar_OnLeave)
      end
    end
  end

  frame:HookScript("OnEnter", actionBar_OnEnter)
  frame:HookScript("OnLeave", actionBar_OnLeave)

  frameHookSet[frame:GetName()] = true
end

--- When the onHoverEnabled table is updated this function should be called
--- to apply the settings if needed
local function onHoverSettings_OnUpdate()
  for frameName, enabled in pairs(onHoverEnabled) do
    local frame = _G[frameName]
    if frame then
      if enabled then
        if not editModeManagerFrame.editModeActive then
          frame:SetAlpha(0)
        end
        hookActionBarOnHoverEvent(frame)
      else
        frame:SetAlpha(1)
      end
    end
  end
end

--- When the hideMacroTextEnabled table is updated this function should be called
--- to apply the settings if needed
local function hideMacroTextSettings_OnUpdate()
  for frameName, enabled in pairs(hideMacroTextEnabled) do
    for i = 12, 1, -1 do
      if frameName == "MainMenuBar" then frameName = "Action" end
      local button = _G[frameName .. "Button" .. i .. "Name"]
      if button then
        if enabled then
          button:SetAlpha(0)
        else
          button:SetAlpha(1)
        end
      end
    end
  end
end

--- When the abbreviatedKeybindingsEnabled table is updated this function should be called
--- to apply the settings if needed
local function abbreviatedKeybinginsSettings_OnUpdate()
  for frameName, enabled in pairs(abbreviatedKeybindingsEnabled) do
    for i = 12, 1, -1 do
      if frameName == "MainMenuBar" then frameName = "Action" end
      local button = _G[frameName .. "Button" .. i]
      if button then
        frameSetAbbreviatedText(button, enabled)
        if not button.BUIIOnUpdateHotkeyHooked then
          hooksecurefunc(button, "UpdateHotkeys", keybind_OnUpdateHotkey)
          button.BUIIOnUpdateHotkeyHooked = true
        end
      end
    end
  end
end

--- Called when a setting value changes
---@param self table EditModeSystemSettingsDialog frame
---@param setting number Enum of the setting getting changed
---@param value number New value for the setting that is changing
local function editModeSystemSettingsDialog_OnSettingValueChanged(self, setting, value)
  -- print("editModeSystemSettingsDialog_OnSettingValueChanged: setting ", setting, " value ", value)
  local currentFrame = self.attachedToSystem
  local currentFrameName = currentFrame:GetName()

  -- TODO: refactor this crap
  if currentFrameName == "MainMenuBar" then
    if setting == enum_EditModeActionBarSetting_HideMacroText then
      hideMacroTextEnabled["MainMenuBar"] = value == 1 and true or false
      hideMacroTextSettings_OnUpdate()
    elseif setting == enum_EditModeActionBarSetting_AbbreviateKeybindings then
      abbreviatedKeybindingsEnabled["MainMenuBar"] = value == 1 and true or false
      abbreviatedKeybinginsSettings_OnUpdate()
    elseif setting == enum_EditModeActionBarSetting_BarVisibility and value == Enum.ActionBarVisibleSetting.Always then
      onHoverEnabled["MainMenuBar"] = false
      onHoverSettings_OnUpdate()
    elseif setting == enum_EditModeActionBarSetting_BarVisibility and value == Enum.ActionBarVisibleSetting.InCombat then
      onHoverEnabled["MainMenuBar"] = false
      onHoverSettings_OnUpdate()
      print("In Combat MainMenuBar Not supported yet")
    elseif setting == enum_EditModeActionBarSetting_BarVisibility and value == Enum.ActionBarVisibleSetting.OutOfCombat then
      onHoverEnabled["MainMenuBar"] = false
      onHoverSettings_OnUpdate()
      print("Out of Combat MainMenuBar Not supported yet")
      -- currentFrame:Show()
      -- -- Hack to fix currentValue of Dropdown not updating
      local children = { self.Settings:GetChildren() }
      for i, child in ipairs(children) do
        print(i, child:GetObjectType(), child:GetDebugName(), child.Label:GetText())
        print(child.Label:GetText())
        if child.Label:GetText() == "Bar Visible" then
          print("YEP")
          child.Dropdown.Text:SetText("NEW TEXT")
        end
      end
    elseif setting == enum_EditModeActionBarSetting_BarVisibility and value == Enum.ActionBarVisibleSetting.Hidden then
      onHoverEnabled["MainMenuBar"] = false
      onHoverSettings_OnUpdate()
      print("Hidden MainMenuBar Not supported yet")
      -- currentFrame.visibility = "Hidden"
      -- currentFrame:SetShown(false)
      -- currentFrame:Hide()
    elseif setting == enum_EditModeActionBarSetting_BarVisibility and value == enum_ActionBarVisibleSetting_OnHover then
      onHoverEnabled["MainMenuBar"] = true
      onHoverSettings_OnUpdate()
    end
  elseif strfind(currentFrameName, "MultiBar") then
    if setting == enum_EditModeActionBarSetting_HideMacroText then
      hideMacroTextEnabled[currentFrameName] = true
      hideMacroTextSettings_OnUpdate()
    elseif setting == enum_EditModeActionBarSetting_AbbreviateKeybindings then
      abbreviatedKeybindingsEnabled[currentFrameName] = value == 1 and true or false
      abbreviatedKeybinginsSettings_OnUpdate()
    elseif setting == Enum.EditModeActionBarSetting.VisibleSetting and value == enum_ActionBarVisibleSetting_OnHover then
      onHoverEnabled[currentFrameName] = true
      onHoverSettings_OnUpdate()
    elseif setting == Enum.EditModeActionBarSetting.VisibleSetting then
      onHoverEnabled[currentFrameName] = false
      onHoverSettings_OnUpdate()
    end
  elseif currentFrameName == "BagsBar" then
    if setting == enum_BagsBarSetting_BarVisibility and value == enum_ActionBarVisibleSetting_OnHover then
      onHoverEnabled[currentFrameName] = true
      onHoverSettings_OnUpdate()
    elseif setting == enum_BagsBarSetting_BarVisibility then
      onHoverEnabled[currentFrameName] = false
      onHoverSettings_OnUpdate()
    end
  elseif currentFrameName == "MicroMenuContainer" then
    if setting == enum_MicroMenuSetting_BarVisibility and value == enum_ActionBarVisibleSetting_OnHover then
      onHoverEnabled["MicroMenu"] = true
      onHoverSettings_OnUpdate()
    elseif setting == enum_BagsBarSetting_BarVisibility then
      onHoverEnabled["MicroMenu"] = false
      onHoverSettings_OnUpdate()
    end
  end

  BUIIDatabase["edit_mode_on_hover_enabled"] = onHoverEnabled
  BUIIDatabase["edit_mode_hide_macro_text_enabled"] = hideMacroTextEnabled
  BUIIDatabase["edit_mode_abbreviate_keybindings_enabled"] = abbreviatedKeybindingsEnabled
end

--- Register nessecary hooks for Edit Mode Setttings
local function setupEditModeSystemSettingsDialog()
  if not frameHookSet["EditModeSystemSettingsDialog"] then
    hooksecurefunc(editModeSettingsDialog, "UpdateSettings", editModeSystemSettingsDialog_OnUpdateSettings)
    hooksecurefunc(editModeSettingsDialog, "OnSettingValueChanged", editModeSystemSettingsDialog_OnSettingValueChanged)
    frameHookSet["EditModeSystemSettingsDialog"] = true

    -- Add the On Hover option for MultiBar frames
    local actionBarDropdownOptions = EditModeSettingDisplayInfoManager.systemSettingDisplayInfo
        [Enum.EditModeSystem.ActionBar][Enum.EditModeActionBarSetting.VisibleSetting + 1].options
    local extraOption = {
      value = enum_ActionBarVisibleSetting_OnHover,
      text = HUD_EDIT_MODE_SETTING_ACTION_BAR_VISIBLE_SETTING_ON_HOVER
    }
    table.insert(actionBarDropdownOptions, extraOption)

    -- local mainActionBarSettings = EDIT_MODE_MODERN_SYSTEM_MAP[Enum.EditModeSystem.ActionBar][Enum.EditModeActionBarSystemIndices.MainBar].settings
    -- -- local key = "Enum.EditModeActionBarSetting.VisibleSetting"
    -- table.insert(mainActionBarSettings, Enum.ActionBarVisibleSetting.Always)
  end
end

--- Enable Improved EditMode module
function BUII_ImprovedEditModeEnable()
  setupQueueStatusButton()
  setupEditModeSystemSettingsDialog()

  if BUIIDatabase["edit_mode_on_hover_enabled"] then
    onHoverEnabled = BUIIDatabase["edit_mode_on_hover_enabled"]
    onHoverSettings_OnUpdate()
  end

  if BUIIDatabase["edit_mode_hide_macro_text_enabled"] then
    hideMacroTextEnabled = BUIIDatabase["edit_mode_hide_macro_text_enabled"]
    hideMacroTextSettings_OnUpdate()
  end

  if BUIIDatabase["edit_mode_abbreviate_keybindings_enabled"] then
    abbreviatedKeybindingsEnabled = BUIIDatabase["edit_mode_abbreviate_keybindings_enabled"]
    abbreviatedKeybinginsSettings_OnUpdate()
  end

  EventRegistry:RegisterCallback("EditMode.Enter", editMode_OnEnter, "BUII_ImprovedEditMode_OnEnter")
  EventRegistry:RegisterCallback("EditMode.Exit", editMode_OnExit, "BUI_ImprovedEditMode_OnExit")

  editModeImprovedEnabled = true
end

--- Disable Improved EditMode module
function BUII_ImprovedEditModeDisable()
  resetQueueStatusButton()

  EventRegistry:UnregisterCallback("EditMode.Enter", "BUII_ImprovedEditMode_OnEnter")
  EventRegistry:UnregisterCallback("EditMode.Exit", "BUI_ImprovedEditMode_OnExit")

  editModeImprovedEnabled = false
end
