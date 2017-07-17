function Mirror_OnUpdate()
    if this.timer == nil then
        this:Hide()
        return
    end
    this:SetScale(ActionMirroringSettings.scale)
    Mirror_OnUpdateButton(arg1)
    
    if this:isCurrent() then
        getglobal(this:GetName().."HighlightTexture"):SetVertexColor(unpack(ActionMirroringSettings.activeColor))
    end
    
    if this.timer + arg1 > ActionMirroringSettings.timeout and not this:hold() then
        this:Hide()
    else
        this.timer = this.timer + arg1
    end
    
    Mirror_UpdateState()
end

function Mirror_OnLoad()
    
    this.flashing = 0
    this.flashtime = 0
    Mirror_Update()
    this:RegisterEvent("PLAYER_ENTERING_WORLD")
    this:RegisterEvent("UPDATE_BONUS_ACTIONBAR")
    this:RegisterEvent("ACTIONBAR_PAGE_CHANGED")
    this:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
    this:RegisterEvent("UPDATE_BINDINGS")

    Mirror_UpdateHotkeys()
end

function Mirror_Update()
    -- Special case code for bonus bar buttons
    -- Prevents the button from updating if the bonusbar is still in an animation transition
    if ( this.isBonus and this.inTransition ) then
        Mirror_UpdateUsable()
        Mirror_UpdateCooldown()
        return
    end
    
    local icon = getglobal(this:GetName().."Icon")
    local buttonCooldown = getglobal(this:GetName().."Cooldown")
    local texture = GetActionTexture(this:GetID())
    if ( texture ) then
        icon:SetTexture(texture)
        icon:Show()
        this.rangeTimer = -1
        getglobal(this:GetName().."NormalTexture"):SetTexture("Interface\\Addons\\ActionMirroringFrame\\ButtonBorder")
        -- Save texture if the button is a bonus button, will be needed later
        if ( this.isBonus ) then
            this.texture = texture
        end
    else
        icon:Hide()
        buttonCooldown:Hide()
        this.rangeTimer = nil
        this:Hide()
    end
    Mirror_UpdateCount()
    if ( HasAction(this:GetID()) ) then
        this:RegisterEvent("ACTIONBAR_UPDATE_STATE")
        this:RegisterEvent("ACTIONBAR_UPDATE_USABLE")
        this:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
        this:RegisterEvent("UPDATE_INVENTORY_ALERTS")
        this:RegisterEvent("PLAYER_AURAS_CHANGED")
        this:RegisterEvent("PLAYER_TARGET_CHANGED")
        this:RegisterEvent("UNIT_INVENTORY_CHANGED")
        this:RegisterEvent("CRAFT_SHOW")
        this:RegisterEvent("CRAFT_CLOSE")
        this:RegisterEvent("TRADE_SKILL_SHOW")
        this:RegisterEvent("TRADE_SKILL_CLOSE")
        this:RegisterEvent("PLAYER_ENTER_COMBAT")
        this:RegisterEvent("PLAYER_LEAVE_COMBAT")
        this:RegisterEvent("START_AUTOREPEAT_SPELL")
        this:RegisterEvent("STOP_AUTOREPEAT_SPELL")

        this:Show()
        Mirror_UpdateState()
        Mirror_UpdateUsable()
        Mirror_UpdateCooldown()
        Mirror_UpdateFlash()
    else
        this:UnregisterEvent("ACTIONBAR_UPDATE_STATE")
        this:UnregisterEvent("ACTIONBAR_UPDATE_USABLE")
        this:UnregisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
        this:UnregisterEvent("UPDATE_INVENTORY_ALERTS")
        this:UnregisterEvent("PLAYER_AURAS_CHANGED")
        this:UnregisterEvent("PLAYER_TARGET_CHANGED")
        this:UnregisterEvent("UNIT_INVENTORY_CHANGED")
        this:UnregisterEvent("CRAFT_SHOW")
        this:UnregisterEvent("CRAFT_CLOSE")
        this:UnregisterEvent("TRADE_SKILL_SHOW")
        this:UnregisterEvent("TRADE_SKILL_CLOSE")
        this:UnregisterEvent("PLAYER_ENTER_COMBAT")
        this:UnregisterEvent("PLAYER_LEAVE_COMBAT")
        this:UnregisterEvent("START_AUTOREPEAT_SPELL")
        this:UnregisterEvent("STOP_AUTOREPEAT_SPELL")

        this:Hide()
    end

    -- Add a green border if button is an equipped item
    local border = getglobal(this:GetName().."Border")
    if ( IsEquippedAction(this:GetID()) ) then
        border:SetVertexColor(0, 1.0, 0, 0.35)
        border:Show()
    else
        border:Hide()
    end

    -- Update Macro Text
    local macroName = getglobal(this:GetName().."Name")
    macroName:SetText(GetActionText(this:GetID()))
end


function Mirror_OnEvent(event)
    if ( event == "ACTIONBAR_SLOT_CHANGED" ) then
        if ( arg1 == 0 or arg1 == this:GetID() ) then
            Mirror_Update()
        end
        return
    end
    if ( event == "PLAYER_ENTERING_WORLD" or event == "ACTIONBAR_PAGE_CHANGED" ) then
        Mirror_Update()
        return
    end
    if ( event == "UPDATE_BONUS_ACTIONBAR" ) then
        if ( this.isBonus ) then
            Mirror_Update()
        end
        return
    end
    if ( event == "UPDATE_BINDINGS" ) then
        Mirror_UpdateHotkeys()
        return
    end

    -- All event handlers below this line are only set when the button has an action

    if ( event == "PLAYER_TARGET_CHANGED" or event == "PLAYER_AURAS_CHANGED" ) then
        Mirror_UpdateUsable()
        Mirror_UpdateHotkeys()
    elseif ( event == "UNIT_INVENTORY_CHANGED" ) then
        if ( arg1 == "player" ) then
            Mirror_Update()
        end
    elseif ( event == "ACTIONBAR_UPDATE_STATE" ) then
        Mirror_UpdateState()
    elseif ( event == "ACTIONBAR_UPDATE_USABLE" or event == "UPDATE_INVENTORY_ALERTS" or event == "ACTIONBAR_UPDATE_COOLDOWN" ) then
        Mirror_UpdateUsable()
        Mirror_UpdateCooldown()
    elseif ( event == "CRAFT_SHOW" or event == "CRAFT_CLOSE" or event == "TRADE_SKILL_SHOW" or event == "TRADE_SKILL_CLOSE" ) then
        Mirror_UpdateState()
    elseif ( event == "PLAYER_ENTER_COMBAT" ) then
        if ( IsAttackAction(this:GetID()) ) then
            Mirror_StartFlash()
        end
    elseif ( event == "PLAYER_LEAVE_COMBAT" ) then
        if ( IsAttackAction(this:GetID()) ) then
            Mirror_StopFlash()
        end
    elseif ( event == "START_AUTOREPEAT_SPELL" ) then
        if ( IsAutoRepeatAction(this:GetID()) ) then
            Mirror_StartFlash()
        end
    elseif ( event == "STOP_AUTOREPEAT_SPELL" ) then
        if ( Mirror_IsFlashing() and not IsAttackAction(this:GetID()) ) then
            Mirror_StopFlash()
        end
    end
end

function Mirror_UpdateFlash()
    local id = this:GetID()
    if ( (IsAttackAction(id) and IsCurrentAction(id)) or IsAutoRepeatAction(id) ) then
        Mirror_StartFlash()
    else
        Mirror_StopFlash()
    end
end

function Mirror_UpdateHotkeys()
    local button = this:GetID()
    local bar = 6 - math.floor((button-1)/12)
    if bar == 4 then
        bar = 3
    elseif bar == 3 then
        bar = 4
    end
    local actionButtonType = (bar < 1 or button <= 12) and "ACTIONBUTTON" or ("MULTIACTIONBAR"..bar.."BUTTON")
    local hotkey = getglobal(this:GetName().."HotKey")
    local action = actionButtonType..(mod(button -1,12)+1)
    local key = GetBindingText(GetBindingKey(action), "KEY_", 1)
    if ( key == "" ) then
        hotkey:SetText("")
        if ( ActionHasRange(button) ) then
            if ( IsActionInRange(button) ) then
                hotkey:SetText(RANGE_INDICATOR)
                hotkey:SetTextHeight(8)
                hotkey:SetPoint("TOPRIGHT", this:GetName(), "TOPRIGHT", -3, 5)         
            end
        end
    else
        hotkey:SetText(key)
    end
end


function Mirror_OnUpdateButton(elapsed)

    local hotkey = getglobal(this:GetName().."HotKey")
    local button = this:GetID()

    if ( hotkey:GetText() == RANGE_INDICATOR ) then
        if ( IsActionInRange(button) == 1 ) then
            hotkey:Hide()
        else
            hotkey:Show()
        end
    end

    if ( Mirror_IsFlashing() ) then
        this.flashtime = this.flashtime - elapsed
        if ( this.flashtime <= 0 ) then
            local overtime = -this.flashtime
            if ( overtime >= ATTACK_BUTTON_FLASH_TIME ) then
                overtime = 0
            end
            this.flashtime = ATTACK_BUTTON_FLASH_TIME - overtime

            local flashTexture = getglobal(this:GetName().."Flash")
            if ( flashTexture:IsVisible() ) then
                flashTexture:Hide()
            else
                flashTexture:Show()
            end
        end
    end
    
    -- Handle range indicator
    if ( this.rangeTimer ) then
        this.rangeTimer = this.rangeTimer - elapsed

        if ( this.rangeTimer <= 0 ) then
            local count = getglobal(this:GetName().."HotKey")
            if ( IsActionInRange( this:GetID()) == 0 ) then
                count:SetVertexColor(1.0, 0.1, 0.1)
            else
                count:SetVertexColor(0.6, 0.6, 0.6)
            end
            this.rangeTimer = TOOLTIP_UPDATE_TIME
        end
    end

    if ( not this.updateTooltip ) then
        return
    end

    this.updateTooltip = this.updateTooltip - elapsed
    if ( this.updateTooltip > 0 ) then
        return
    end
end


function Mirror_StartFlash()
    this.flashing = 1
    this.flashtime = 0
    Mirror_UpdateState()
end

function Mirror_StopFlash()
    this.flashing = 0
    getglobal(this:GetName().."Flash"):Hide()
    Mirror_UpdateState()
end

function Mirror_IsFlashing()
    if ( this.flashing == 1 ) then
        return 1
    else
        return nil
    end
end

function Mirror_UpdateState()
    this:SetChecked(this.timer <= ActionMirroringSettings.flashtime or this:isCurrent())
end

function Mirror_UpdateUsable()
    local icon = getglobal(this:GetName().."Icon")
    local normalTexture = getglobal(this:GetName().."NormalTexture")
    local isUsable, notEnoughMana = IsUsableAction(this:GetID())
    if ( isUsable ) then
        icon:SetVertexColor(1.0, 1.0, 1.0)
        normalTexture:SetVertexColor(1.0, 1.0, 1.0)
    elseif ( notEnoughMana ) then
        icon:SetVertexColor(0.5, 0.5, 1.0)
        normalTexture:SetVertexColor(0.5, 0.5, 1.0)
    else
        icon:SetVertexColor(0.4, 0.4, 0.4)
        normalTexture:SetVertexColor(1.0, 1.0, 1.0)
    end
end

function Mirror_UpdateCount()
    local text = getglobal(this:GetName().."Count")
    if ( IsConsumableAction(this:GetID()) ) then
        text:SetText(GetActionCount(this:GetID()))
    else
        text:SetText("")
    end
end

function Mirror_UpdateCooldown()
    local cooldown = getglobal(this:GetName().."Cooldown")
    local start, duration, enable = GetActionCooldown(this:GetID())
    CooldownFrame_SetTimer(cooldown, start, duration, enable)
end

function Mirror_Refresh(self)
    local oldthis = this
    this = self
    Mirror_UpdateFlash()
    Mirror_Update()
    ActionButton_UpdateState()
    Mirror_UpdateHotkeys(this.buttonType)
    getglobal(this:GetName().."HighlightTexture"):SetVertexColor(unpack(ActionMirroringSettings.clickColor))
    this = oldthis
end
