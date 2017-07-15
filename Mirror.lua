function Mirror_OnUpdate()
    if this.timer == nil then
        this:Hide()
        return
    end
    this:SetScale(ActionMirroringSettings.scale)
    ActionButton_OnUpdate(arg1)
    
    this:SetChecked(this.timer + arg1 <= ActionMirroringSettings.flashtime or this:isCurrent())
    
    if this.timer + arg1 > ActionMirroringSettings.timeout and not this:hold() then
        this:Hide()
    else
        this.timer = this.timer + arg1
    end
end
