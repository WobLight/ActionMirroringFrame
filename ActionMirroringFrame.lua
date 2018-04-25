local function rotate(this, r)
    function c(x,y)
        local sin = math.sin(r)
        local cos = math.cos(r)
        return (x*cos - y * sin)/2+0.5, -(x*sin + y * cos)/2 + 0.5
    end
    local ulx, uly = c(-1,1)
    local llx, lly = c(-1,-1)
    local urx, ury = c(1,1)
    local lrx, lry = c(1,-1)
    this:SetTexCoord(
        ulx,uly,
        llx,lly,
        urx,ury,
        lrx,lry)
end

local function updateHandleRotation(handle)
    rotate(handle,math.pi/2 * ActionMirroringSettings.orientation)
end

function ActionMirroringFrame_SetOrientation(o)
    if o < 0 then
        o = 4 - o
    end
    if o < 0 or o > 3 then
        return
    end
    ActionMirroringSettings.orientation = o
    this:GetParent().root:updateOrientation()
end

function ActionMirroringFrame_onClick()
    ActionMirroringFrame_SetOrientation(mod(ActionMirroringSettings.orientation + 1,4))
    updateHandleRotation(getglobal(this:GetName() .. "Tex"))
end

local function print(s)
    if strfind(s,"\n",strfind(s,"\n",strfind(s,"\n",strfind(s,"\n")))) then
        local _,_,s,r= strfind(s,"^(.-)\n(.*)$")
        DEFAULT_CHAT_FRAME:AddMessage("|cffffff88ActionMirroringFrame|r|cffffff00 "..s)
        _,_,s,r= strfind(r,"^(.-)\n(.*)$")
        local tail
        while s do
            tail = r
            DEFAULT_CHAT_FRAME:AddMessage("|cffffff00 "..s)
            _,_,s,r= strfind(r,"^(.-)\n(.*)$")
        end
        if tail ~= "" then
            DEFAULT_CHAT_FRAME:AddMessage("|cffffff00 "..tail)
        end
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cffffff88ActionMirroringFrame|r|cffffff00 "..s)
    end
end

local function DEBUG(s, ...)
    if ActionMirroringFrame.debug then
        if arg.n > 0 then
            s = format(s, unpack(arg))
        end
        print(s)
    end
end

local ActionMirroringSettingsDefaults = {
    dataVersion = "1.2.2",
    timeout = 1.00, -- time before hiding after an action is used
    flashtime = 0.20, -- duration of hightlight when an action is used
    scale = 1.00, -- frame scale, to change it size
    overflow = 2, -- create additional frames when actions are used closely
    overflowTime = 0.66, -- time window to overflow
    stickyActive = true, -- will prevent active actions from hiding
    orientation = 3,
    activeColor = {0,1,0},
    clickColor = {1,0,0},
    cooldownTip = true,
    costTip = true,
    cooldownTipThreshold = 1.5
}

ActionMirroringFrame_eventHandler = {}
ActionMirroringFrame_eventHandler.ADDON_LOADED = function ()
    if arg1 == "ActionMirroringFrame" then
        if ActionMirroringSettings == nil then
            ActionMirroringSettings = ActionMirroringSettingsDefaults
        else
            if ActionMirroringSettings.dataVersion == "1.1.0" then
                if ActionMirroringSettings.activeColor[1] == 1 and
                        ActionMirroringSettings.activeColor[2] == 1 and
                        ActionMirroringSettings.activeColor[3] == 0 then
                    ActionMirroringSettings.activeColor = nil
                end
                if ActionMirroringSettings.activeColor[1] == 0.66 and
                        ActionMirroringSettings.activeColor[2] == 0.66 and
                        ActionMirroringSettings.activeColor[3] == 1 then
                    ActionMirroringSettings.activeColor = nil
                end
            end
            if ActionMirroringSettings.orientation < 0 then
                ActionMirroringSettings.orientation = 3 - mod(ActionMirroringSettings.orientation +1, 4)
            end
            for k,v in ActionMirroringSettingsDefaults do
                if ActionMirroringSettings[k] == nil then
                    ActionMirroringSettings[k] = v
                end
            end
            ActionMirroringSettings.dataVersion = "1.2.2"
        end
            
        
        this.root = ActionMirroringFrame_new(this)
        this.root:SetPoint("CENTER", this, "CENTER")
        this:UnregisterEvent("ADDON_LOADED")
        
        print(" loaded. See /amf usage")
    end
end

local currentAction
local currentError

function ActionMirroringFrame_onUseAction(amf, id)
    amf.currentAction = id
    if amf.standby or CursorHasItem() or CursorHasSpell() or HasAction(id) == nil then
        return
    end
    local o = amf.root
    o:overflow(id)
    o:SetID(id)
    o.spell = currentAction.spell
    o.inventory = currentAction.inventory
    o.timer = 0
    if IsCurrentAction(id) and not (ActionMirroringFrame.current[id] and ActionMirroringFrame.current[id]:IsShown()) then
        ActionMirroringFrame.current[id] = o
    end
    o:Show()
    o:refresh()
end

local function GetSpellID(sn)
    sn = strlower(sn)
    if not rank then
        name = sn
    end
    
    local i,a,r,f = 1, GetSpellName(1,BOOKTYPE_SPELL)
    while a do
        if strlower(format("%s(%s)", a, r or "")) == sn then
            return i
        elseif strlower(a) == sn then
            f = i
        elseif f then
            return f
        end
        i = i+1
        a,r = GetSpellName(i,BOOKTYPE_SPELL)
    end
    return f
end

function ActionMirroringFrame_onSpellUsed(idx, name)
    if SM_UpdateActionSpell and SM_UpdateAction then
        SM_UpdateActionSpell(GetActionText(idx), "regular", "/cast "..name)
        SM_UpdateAction()
    end
    if currentAction then
        currentAction.inventory = nil
        currentAction.container = nil
        currentAction.spell = GetSpellID(name)
    end
end

function ActionMirroringFrame_onInventoryUsed(idx, slot)
    if SM_UpdateActionSpell and SM_UpdateAction then
        SM_UpdateActionSpell(GetActionText(idx), "regular", format("/run UseInventoryItem(%d)", slot))
        SM_UpdateAction()
    end
    if currentAction then
        currentAction.spell = nil
        currentAction.container = nil
        currentAction.inventory = slot
    end
end

function ActionMirroringFrame_onContainerUsed(idx, bag, slot)
    if SM_UpdateActionSpell and SM_UpdateAction then
        SM_UpdateActionSpell(GetActionText(idx), "regular", format("/run UseContainerItem(%d,%d)", bag, slot))
        SM_UpdateAction()
    end
    if currentAction then
        currentAction.spell = nil
        currentAction.inventory = nil
        currentAction.container = {bag = bag, slot = slot, link = GetContainerItemLink(bag, slot)}
    end
end


local hooks = {}

local Hook = {}

function Hook:new(fname, pre, post)
    local o = {wrapped = getglobal(fname), fname = fname, shared = hooks[fname], pre = pre, post = post}
    setmetatable(o, {__index = Hook, __call = Hook.call})
    return o
end

function Hook:lock()
    if not self.shared.lock then
        self.shared.lock = self
    end
    return self.shared.lock == self
end

function Hook:unlock()
    if self.shared.lock == self then
        self.shared.lock = nil
    end
end

function Hook:call(...)
    if not self:lock() then
        self.shared.ok = true
        return self.wrapped(unpack(arg))
    end
    self.shared.ok = false
    if self.pre then
        self.pre(unpack(arg))
    end
    local r = self.wrapped(unpack(arg))
    if self.post then
        self.post(unpack(arg))
    end
    if getglobal(self.fname) == self and not self.tested then
        if self.shared.ok then
            DEBUG("%s was already hooked, dropping.", self.fname)
            self.shared.checked = self.wrapped
            setglobal(self.fname, self.wrapped)
        end
        self.tested = true
    end
    self:unlock()
    return r
end

function ActionMirroringFrame_Hook(fn, fs, fc)
    if not hooks[fn] then
        hooks[fn] = {}
    end
    local hook = hooks[fn]
    if getglobal(fn) == hook.checked or (getmetatable(getglobal(fn)) or {}).__index == Hook then
        return
    end
    setglobal(fn,Hook:new(fn, fs, fc))
    DEBUG("%s hook set.", fn)
end

function ActionMirroringFrame_ActionHook(amf)
    ActionMirroringFrame_Hook("UseAction",
        function (id)
            currentAction = {id = id, old = currentAction}
        end,
        function (id)
            ActionMirroringFrame_onUseAction(amf,id)
            currentAction = currentAction.old
        end
    )
end

function ActionMirroringFrame_ContainerHook()
    ActionMirroringFrame_Hook("UseContainerItem",
        function (bag, slot)
            if currentAction then
                ActionMirroringFrame_onContainerUsed(currentAction.id,bag, slot)
            end
        end
    )
end

function ActionMirroringFrame_InventoryHook()
    ActionMirroringFrame_Hook("UseInventoryItem",
        function (slot)
            if currentAction then
                ActionMirroringFrame_onInventoryUsed(currentAction.id, slot)
            end
        end
    )
end

function ActionMirroringFrame_SpellHook()
    ActionMirroringFrame_Hook("CastSpellByName",
        function (sn)
            if currentAction then
                ActionMirroringFrame_onSpellUsed(currentAction.id, sn)
            end
        end
    )
end
            
function ActionMirroringFrame_new(parent)
    local o = CreateFrame("Frame", parent:GetName() .. parent.id, parent, "MirrorTemplate")
    o.id = parent.id
    parent.id = parent.id + 1
    return o
end

function ActionMirroringFrame_hold(self)
  local o = ActionMirroringFrame.root
  return self:isCurrent() and ActionMirroringSettings.stickyActive
end

function ActionMirroringFrame_overflow(self, nid)
  local sid = self:GetID()
  if self:IsShown() and sid ~= 0 and sid ~= nid and (ActionMirroringSettings.overflow > self.id or self:isCurrent() and ActionMirroringSettings.stickyActive) then
    if self.next == nil then
      self.next = ActionMirroringFrame_new(self:GetParent())
      self:updateOrientation()
    end
    self.next:overflow()
    self.next:SetID(self:GetID())
    self.next.spell = self.spell
    self.next.inventory = self.inventory
    self.next.timer = self.timer
    self.next.flashing = self.flashing
    self.next.flashtime = self.flashtime
    if self:isCurrent() then
        ActionMirroringFrame.current[self:GetID()] = self.next
    end
    self.next:Show()
    self.next:refresh()
  end
end

function ActionMirroringFrame_getFirst(self,id)
  if self:GetID() == id then
    return self.id
  end
  if self.next then
    return self.next:getFirst(id)
  end
  return -1
end

function ActionMirroringFrame_updateOrientation(self)
    local orientation = ActionMirroringSettings.orientation
    if self.next then
        local a = math.pi/2 * orientation
        self.next:SetPoint("CENTER", self, "CENTER", (self:GetWidth() +3) * math.sin(a), (self:GetHeight() +3) * math.cos(a))
        self.next:updateOrientation()
    end
    Mirror_changeTipsPosition(getglobal(self:GetName() .. "CooldownTip"), orientation +1)
end

function ActionMirroringFrame_isCurrent(self)
    if not IsCurrentAction(self:GetID()) then
        ActionMirroringFrame.current[self:GetID()] = nil
        return false
    end
    return ActionMirroringFrame.current[self:GetID()] == self
end

local ActionMirroringFrame_Usage = [[
Usage:

* Command line options (/amf, /actionmirroringframe):
    * usage   display usage instructions
    * standby [true|false]  disable/enable the mirroring frame for this session
    * show [true|false]  show/hide the movable handle, the handle can be clicked to change overflow growth direction
    * timeout <seconds> (1.00)  activation show duration
    * flashtime <seconds> (0.20)  activation hightlight duration
    * scale <coefficient> (1.00)  scale of the frame
    * overflow <num> (2)  number of extra mirrors
    * overflowTime <seconds> (0.66)  time withing the mirror will overflow
    * sticky [true|false] (true)  if true, active actions will now timeout (e.g. casting actions)
    * color cast|click show hud to pick a color for mirrors' states
        * cast: color for actions in progress
        * click: color for mirrors' flashing
    * cooldownTip [true|false] show/hide cooldown time over mirrors
    * costTip [true|false] show/hide missing mana/rage/energy over mirrors
    * cooldownTipThreshold <seconds> (1.5) hide tip for cooldowns lesser than cooldownTipThreshold
]]

local SETTINGS = {}

local function setToNumber(e, a)
    local i = SETTINGS[e].target or e
    if a == "" then
        print(e.." is "..ActionMirroringSettings[s])
        return
    end
    local n = tonumber(a)
    if n then
        ActionMirroringSettings[i] = n
        print(e.." setted to "..ActionMirroringSettings[i])
    else
        print(ActionMirroringFrame_Usage)
    end
end

local function switchSetting(e,r)
    local i = SETTINGS[e].target or i
    if r == "true" then
        ActionMirroringSettings[i] = true
    elseif r == "" then
        ActionMirroringSettings[i] = not ActionMirroringSettings[i]
    else
        ActionMirroringSettings[i] = false
    end
    print(e.." is "..(ActionMirroringSettings[i] and "active" or "disabled"))
end

local function bind(f,a)
    return function(...) f(a, unpack(arg)) end
end

SETTINGS = 
{
    timeout =               {setter = setToNumber},
    flashtime =             {setter = setToNumber},
    scale =                 {setter = setToNumber},
    overflow =              {setter = setToNumber},
    overflowTime =          {setter = setToNumber},
    sticky =                {setter = switchSetting, target = "stickyActive"},
    cooldownTip =           {setter = switchSetting, target = "cooldownTip"},
    costTip =               {setter = switchSetting, target = "costTip"},
    cooldownTipThreshold =  {setter = setToNumber}
}

local function CommandParser(msg, editbox)
    local _,_,command, rest = string.find(msg,"^(%S*)%s*(.-)$")
    if SETTINGS[command] then
        SETTINGS[command].setter(command,rest)
    elseif command == "standby" then
        if rest ~= "" then
            ActionMirroringFrame.standby = rest == "true"
        else
            ActionMirroringFrame.standby = not ActionMirroringFrame.standby
        end
        print(ActionMirroringFrame.standby and "is on standby." or "is active.")
    elseif command == "show" then
        if rest == "true" then
            ActionMirroringFrameHandle:Show()
            updateHandleRotation(ActionMirroringFrameHandleTex)
        elseif rest == "" then
            if ActionMirroringFrameHandle:IsShown() then
                ActionMirroringFrameHandle:Hide()
            else
                ActionMirroringFrameHandle:Show()
                updateHandleRotation(ActionMirroringFrameHandleTex)
            end
        else
            ActionMirroringFrameHandle:Hide()
        end
    elseif command == "color" then
        if rest == "cast" then
            ColorPickerFrame:SetColorRGB(unpack(ActionMirroringSettings.activeColor))
            local old = ActionMirroringSettings.activeColor
            ColorPickerFrame.cancelFunc = function() ActionMirroringSettings.activeColor = old end
            ColorPickerFrame.func = function() ActionMirroringSettings.activeColor = {ColorPickerFrame:GetColorRGB()} end
            ColorPickerFrame.opacityFunc = nil
            ColorPickerFrame:Show()
        elseif rest == "click" then
            ColorPickerFrame:SetColorRGB(unpack(ActionMirroringSettings.clickColor))
            local old = ActionMirroringSettings.clickColor
            ColorPickerFrame.cancelFunc = function() ActionMirroringSettings.clickColor = old end
            ColorPickerFrame.func = function() ActionMirroringSettings.clickColor = {ColorPickerFrame:GetColorRGB()} end
            ColorPickerFrame.opacityFunc = nil
            ColorPickerFrame:Show()
        else
            print(ActionMirroringFrame_Usage)
        end
    else
        print(ActionMirroringFrame_Usage)
    end
end
SLASH_ACTIONMIRRORINGFRAME1 = "/actionmirroringframe"
SLASH_ACTIONMIRRORINGFRAME2 = "/amf"
SlashCmdList["ACTIONMIRRORINGFRAME"] = CommandParser

local CAST_OLD = SlashCmdList["CAST"]
SlashCmdList["CAST"] = function (...)
    local old = CastSpellByName
    local triggered = false
    CastSpellByName = function (...)
        old(unpack(arg))
        triggered = true
    end
    CAST_OLD(unpack(arg))
    if not triggered then
        ActionMirroringFrame_onSpellUsed(arg[1])
    end
end
