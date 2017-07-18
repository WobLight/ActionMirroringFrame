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

local function DEBUG(s)
    if ActionMirroringFrame.debug then
       print(s)
    end
end
ActionMirroringFrame_eventHandler = {}
ActionMirroringFrame_eventHandler.ADDON_LOADED = function ()
    if arg1 == "ActionMirroringFrame" then
        if ActionMirroringSettings == nil then
            ActionMirroringSettings = {
                dataVersion = "1.2.1",
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
                costTip = true
            }
        elseif ActionMirroringSettings.dataVersion == "1.0.0" then
            ActionMirroringSettings.activeColor = {0,1,0}
            ActionMirroringSettings.clickColor = {1,0,0}
            ActionMirroringSettings.dataVersion = "1.2.1"
        elseif ActionMirroringSettings.dataVersion == "1.1.0" then
            if ActionMirroringSettings.activeColor[1] == 1 and
                    ActionMirroringSettings.activeColor[2] == 1 and
                    ActionMirroringSettings.activeColor[3] == 0 then
                ActionMirroringSettings.activeColor = {0,1,0}
            end
            if ActionMirroringSettings.activeColor[1] == 0.66 and
                    ActionMirroringSettings.activeColor[2] == 0.66 and
                    ActionMirroringSettings.activeColor[3] == 1 then
                ActionMirroringSettings.activeColor = {0,1,0}
            end
            ActionMirroringSettings.cooldownTip = true
            ActionMirroringSettings.costTip = true
            ActionMirroringSettings.dataVersion = "1.2.1"
        elseif ActionMirroringSettings.dataVersion == "1.1.1" then
            ActionMirroringSettings.cooldownTip = true
            ActionMirroringSettings.costTip = true
            ActionMirroringSettings.dataVersion = "1.2.1"
        elseif ActionMirroringSettings.dataVersion == "1.2.0" then
            if ActionMirroringSettings.orientation < 0 then
                ActionMirroringSettings.orientation = 3 - mod(ActionMirroringSettings.orientation +1)
            end
            ActionMirroringSettings.dataVersion = "1.2.1"
        end
            
        
        this.root = ActionMirroringFrame_new(this)
        this.root:SetPoint("CENTER", this, "CENTER")
        this:UnregisterEvent("ADDON_LOADED")
        
        print(" loaded. See /amf usage")
    end
end

function ActionMirroringFrame_onUseAction(amf, id)
    if amf.standby or CursorHasItem() or CursorHasSpell() or HasAction(id) == nil then
        return
    end
    local o = amf.root
    o:overflow(id)
    o:SetID(id)
    o.timer = 0
    o:Show()
    o:refresh()
end

function ActionMirroringFrame_Hook()
    if this.UseAction and UseAction == this.checked or this.preHook and UseAction == this.preHook.wrapped then
        return
    end
    
    local amf = this
    DEBUG("hook set.")
    local preHook = {}
    function preHook:wrapper(...)
        if self.wrapped ~= UseAction or CursorHasItem() or CursorHasSpell() then
            self.target(unpack(arg))
            return
        end
        DEBUG("testing old hook.")
        amf.hooked = nil
        self.target(unpack(arg))
        if amf.hooked then
            DEBUG("already hooked, dropping.")
            UseAction = self.target
            amf.checked = UseAction
            return
        end
        DEBUG("hooking...")
        local wrapped = self.target
        amf.UseAction = wrapped
        amf.checked = function(...)
            amf.hooked = true
            ActionMirroringFrame_onUseAction(amf,arg[1])
            wrapped(unpack(arg))
        end
        UseAction = amf.checked
        amf.standby = false
        DEBUG("hooking complete.")
        ActionMirroringFrame_onUseAction(amf,arg[1])
    end
    preHook.target = UseAction
    this.preHook = preHook
    preHook.wrapped = function(...) preHook:wrapper(unpack(arg)) end
    UseAction = preHook.wrapped
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
    self.next.timer = self.timer
    self.next.flashing = self.flashing;
    self.next.flashtime = self.flashtime;
    if self:isCurrent() then
      ActionMirroringFrame.current[self:GetID()] = self.next.id
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
  if ActionMirroringFrame.current[self:GetID()] == self.id then
    if IsCurrentAction(self:GetID()) then
      return true
    else
      ActionMirroringFrame.current[self:GetID()] = nil
      return false
    end
  elseif ActionMirroringFrame.current[self:GetID()] then
    return false
  end
  
  if IsCurrentAction(self:GetID()) and self.id == ActionMirroringFrame.root:getFirst(self:GetID()) then
    ActionMirroringFrame.current[self:GetID()] = self.id
    return true
  end
  return false
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
]]

local SETTINGS = {}

local function setToNumber(e, a)
    local i = SETTINGS[e].target or i
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
    timeout =       {setter = setToNumber},
    flashtime =     {setter = setToNumber},
    scale =         {setter = setToNumber},
    overflow =      {setter = setToNumber},
    overflowTime =  {setter = setToNumber},
    sticky =        {setter = switchSetting, target = "stickyActive"},
    cooldownTip =   {setter = switchSetting, target = "cooldownTip"},
    costTip =       {setter = switchSetting, target = "costTip"}
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
