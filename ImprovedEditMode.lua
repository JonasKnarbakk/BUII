local queueStatusButtonOverlayFrame = nil
local queueStatusButtonOverlayFrameHook = nil
local queueStatusButtonOverlayFrameHookEnabled = false
local editModeImprovedEnabled = false

local onHoverEnabled = {
  MainMenuBar = false,
  MultiBarLeft = false,
  MultiBarRight = false,
  MultiBarBottonLeft = false,
  MultiBarBottonRight = false,
  MultiBar5 = false,
  MultiBar6 = false,
  MultiBar7 = false,
  BagsBar = false,
}

local hideMacroTextEnabled = {
  MainMenuBar = false,
  MultiBarLeft = false,
  MultiBarRight = false,
  MultiBarBottonLeft = false,
  MultiBarBottonRight = false,
  MultiBar5 = false,
  MultiBar6 = false,
  MultiBar7 = false,
}

local frameHookSet = {
  MainMenuBar = false,
  MultiBarLeft = false,
  MultiBarRight = false,
  MultiBarBottonLeft = false,
  MultiBarBottonRight = false,
  MultiBar5 = false,
  MultiBar6 = false,
  MultiBar7 = false,
  BagsBar = false,
  EditModeSystemSettingsDialog = false,
}

local bagFrames = {
  MainMenuBarBackpackButton = true,
  CharacterBag0Slot = true,
  CharacterBag1Slot = true,
  CharacterBag2Slot = true,
  CharacterBag3Slot = true,
  CharacterReagentBag0Slot = true,
}

-- Cache frequently used globals
local editModeSettingsDialog = EditModeSystemSettingsDialog
local mainMenuBar = MainMenuBar
local bagsBar = BagsBar

-- extended settings
local enum_EditModeActionBarSetting_HideMacroText = 10
local enum_EditModeActionBarSetting_BarVisibility = 11
local enum_ActionBarVisibleSetting_OnHover = 4
local enum_BagsBarSetting_BarVisibility = 3

local HUD_EDIT_MODE_SETTING_ACTION_BAR_VISIBLE_SETTING_ON_HOVER = "On Hover"
local HUD_EDIT_MODE_SETTING_ACTION_BAR_HIDE_MACRO_TEXT = "Hide Macro Text"

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
  EditModeManagerFrame:SelectSystem(frame:GetParent())
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
    currentValue = 0,
    settingName = HUD_EDIT_MODE_SETTING_ACTION_BAR_HIDE_MACRO_TEXT
  }

  addOptionToSettingsDialog(enum_EditModeActionBarSetting_HideMacroText,
    Enum.ChrCustomizationOptionType.Checkbox,
    hideMacroTextData)

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
    currentValue = 0,
    settingName = HUD_EDIT_MODE_SETTING_ACTION_BAR_VISIBLE_SETTING
  }

  addOptionToSettingsDialog(enum_EditModeActionBarSetting_BarVisibility,
    Enum.ChrCustomizationOptionType.Dropdown,
    barVisibilityData)
end

--- Add the additional settings to MultiBar e.g any action bar that isn't the main one
local function settingsDialogMultiBarAddOptions()
  local hideMacroText = {
    setting = enum_EditModeActionBarSetting_HideMacroText,
    name = HUD_EDIT_MODE_SETTING_ACTION_BAR_HIDE_MACRO_TEXT,
    type = Enum.EditModeSettingDisplayType.Checkbox,
  }
  local hideMacroTextData = {
    displayInfo = hideMacroText,
    currentValue = 0,
    settingName = HUD_EDIT_MODE_SETTING_ACTION_BAR_HIDE_MACRO_TEXT
  }
  addOptionToSettingsDialog(enum_EditModeActionBarSetting_HideMacroText, Enum.ChrCustomizationOptionType.Checkbox,
    hideMacroTextData)
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
    currentValue = 0,
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

  -- TODO: Need to fix taint produced when pressing "Action Bar Settings" after a bit
  if systemFrame == self.attachedToSystem then
    local currentFrameName = systemFrame:GetName()

    if currentFrameName == "MainMenuBar" then
      settingsDialogMainMenuBarAddOptions()
    elseif strfind(currentFrameName, "MultiBar") then
      settingsDialogMultiBarAddOptions()
    elseif currentFrameName == "BagsBar" then
      settingsDialogBagBarAddOptions()
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
  else
    for actionBarName, enabled in pairs(onHoverEnabled) do
      if strfind(self:GetName(), actionBarName) and enabled then
        _G[actionBarName]:SetAlpha(0)
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
        subframe:HookScript("OnLeave", actionBar_OnEnter)
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
        frame:SetAlpha(0)
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
      hideMacroTextEnabled["MainMenuBar"] = true
      hideMacroTextSettings_OnUpdate()
      -- for i = 12, 1, -1 do
      --   local button = _G["ActionButton" .. i .. "Name"]
      --   button:SetAlpha(1 - value)
      -- end
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
      -- for i = 12, 1, -1 do
      --   local button = _G[currentFrameName .. "Button" .. i .. "Name"]
      --   button:SetAlpha(1 - value)
      -- end
    elseif setting == Enum.EditModeActionBarSetting.VisibleSetting and value == enum_ActionBarVisibleSetting_OnHover then
      onHoverEnabled[currentFrameName] = true
      onHoverSettings_OnUpdate()
      -- hookActionBarOnHoverEvent(currentFrame)
    elseif setting == Enum.EditModeActionBarSetting.VisibleSetting then
      onHoverEnabled[currentFrameName] = false
      onHoverSettings_OnUpdate()
      -- currentFrame:SetAlpha(1)
    end
  elseif currentFrameName == "BagsBar" then
    if setting == enum_BagsBarSetting_BarVisibility and value == enum_ActionBarVisibleSetting_OnHover then
      onHoverEnabled[currentFrameName] = true
      onHoverSettings_OnUpdate()
    elseif setting == enum_BagsBarSetting_BarVisibility then
      onHoverEnabled[currentFrameName] = false
      onHoverSettings_OnUpdate()
    end
  end

  BUIIDatabase["edit_mode_on_hover_enabled"] = onHoverEnabled
  BUIIDatabase["edit_mode_hide_macro_text_enabled"] = hideMacroTextEnabled
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
