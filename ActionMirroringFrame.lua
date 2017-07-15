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

function ActionMirroringFrame_onClick()
    ActionMirroringSettings.orientation = mod(ActionMirroringSettings.orientation + 1,4)
    this:GetParent().root:updateOrientation()
    updateHandleRotation(getglobal(this:GetName() .. "Tex"))
end


local function print(s)
    DEFAULT_CHAT_FRAME:AddMessage("|cffffff88ActionMirroringFrame|r|cffffff00 "..s)
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
                dataVersion = "1.0.0",
                timeout = 1.00, -- time before hiding after an action is used
                flashtime = 0.20, -- duration of hightlight when an action is used
                scale = 1.00, -- frame scale, to change it size
                overflow = 2, -- create additional frames when actions are used closely
                overflowTime = 0.66, -- time window to overflow
                stickyActive = true, -- will prevent active actions from hiding
                orientation = -1
            }
        end
        
        this.root = ActionMirroringFrame_new(this)
        this.root:SetPoint("CENTER", this, "CENTER")
        this:UnregisterEvent("ADDON_LOADED")
        
        print(" loaded. See /amf usage")
    end
end

function ActionMirroringFrame_onUseAction(amf, id)
    if amf.standby or CursorHasItem() or CursorHasSpell() then
        return
    end
    local o = amf.root
    o:overflow(id)
    o:SetID(id)
    o.timer = 0
    o:Show()
    o:Click()
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
    local o = CreateFrame("CheckButton", parent:GetName() .. parent.id, parent, "MirrorTemplate")
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
    if self:isCurrent() then
      ActionMirroringFrame.current[self:GetID()] = self.next.id
    end
    self.next:Show()
    self.next:Click()
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
    if self.next then
        local a = math.pi/2 * ActionMirroringSettings.orientation
        self.next:SetPoint("CENTER", self, "CENTER", self:GetWidth() * math.sin(a), self:GetHeight() * math.cos(a))
        self.next:updateOrientation()
    end
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
]]

local function setToNumber(s, a)
    if a == "" then
        print(s.." is "..ActionMirroringSettings[s])
        return
    end
    local n = tonumber(a)
    if n then
        ActionMirroringSettings[s] = n
        print(s.." setted to "..ActionMirroringSettings[s])
    else
        print(ActionMirroringFrame_Usage)
    end
end

local function find(e, t)
    for _,v in t do
        if v == e then
            return true
        end
    end
end

local function CommandParser(msg, editbox)
    local _,_,command, rest = string.find(msg,"^(%S*)%s*(.-)$")
    if command == "standby" then
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
    elseif find(command, {"timeout", "flashtime", "scale", "overflow", "overflowTime"}) then
        setToNumber(command, rest)
    elseif command == "sticky" then
        if rest == "true" then
            ActionMirroringSettings.sticky = true
        elseif rest == "" then
            ActionMirroringSettings.sticky = not ActionMirroringSettings.sticky
        else
            ActionMirroringSettings.sticky = false
        end
        print("sticky set to "..(ActionMirroringSettings.sticky and "active" or "disabled"))
    else
        print(ActionMirroringFrame_Usage)
    end
end
SLASH_ACTIONMIRRORINGFRAME1 = "/actionmirroringframe"
SLASH_ACTIONMIRRORINGFRAME2 = "/amf"
SlashCmdList["ACTIONMIRRORINGFRAME"] = CommandParser
