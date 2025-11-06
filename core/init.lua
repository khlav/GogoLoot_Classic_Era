-- Initialization code for GogoLoot

function GogoLoot:Initialize(events)
    -- Register slash commands
    GogoLoot:RegisterCommands()

    -- Register events
    UIParent:UnregisterEvent("LOOT_BIND_CONFIRM") -- ensure our event hook runs before UIParent
    events:RegisterEvent("LOOT_BIND_CONFIRM")
    UIParent:RegisterEvent("LOOT_BIND_CONFIRM")
    events:RegisterEvent("LOOT_READY")
    events:RegisterEvent("LOOT_OPENED")
    events:RegisterEvent("LOOT_CLOSED")
    events:RegisterEvent("LOOT_SLOT_CLEARED")
    events:RegisterEvent("MODIFIER_STATE_CHANGED")
    events:RegisterEvent("UI_ERROR_MESSAGE")
    events:RegisterEvent("BAG_UPDATE")
    events:RegisterEvent("PLAYER_ENTERING_WORLD")
    events:RegisterEvent("PARTY_LOOT_METHOD_CHANGED")
    events:RegisterEvent("GROUP_ROSTER_UPDATE")
    events:RegisterEvent("START_LOOT_ROLL")
    events:RegisterEvent("PLAYER_LOGIN")

    -- Set loot threshold
    LootFrame.selectedQuality = GetLootThreshold()

    -- Fix for MasterLootFrame showing stale items
    -- Blizzard bug: MasterLootFrame retains anchor points after being hidden,
    -- causing it to display outdated items when it reappears
    if MasterLootFrame then
        hooksecurefunc(MasterLootFrame, 'Hide', function(self)
            self:ClearAllPoints()
        end)
        
        -- Also hook Show() to validate slot data when frame is displayed
        -- This prevents stale items from showing, especially during combat
        hooksecurefunc(MasterLootFrame, 'Show', function(self)
            -- Validate the slot that MasterLootFrame is trying to show
            if self.lootSlot then
                local texture, item, quantity, quality, locked = GetLootSlotInfo(self.lootSlot)
                -- If slot is invalid or doesn't exist, hide the frame immediately
                -- Use a small delay to ensure it works even during combat
                if not texture or not item then
                    C_Timer.After(0.01, function()
                        if MasterLootFrame and MasterLootFrame:IsShown() then
                            -- Double-check the slot is still invalid
                            if MasterLootFrame.lootSlot then
                                local checkTexture, checkItem = GetLootSlotInfo(MasterLootFrame.lootSlot)
                                if not checkTexture or not checkItem then
                                    MasterLootFrame:Hide()
                                end
                            else
                                MasterLootFrame:Hide()
                            end
                        end
                    end)
                end
            end
        end)
    end

    -- Add gray and white quality buttons to loot threshold dropdown
    UnitPopupItemQuality0DescButtonMixin = CreateFromMixins(UnitPopupItemQuality2DescButtonMixin);

    function UnitPopupItemQuality0DescButtonMixin:GetText()
    	return ITEM_QUALITY0_DESC;
    end

    function UnitPopupItemQuality0DescButtonMixin:GetID()
    	return 0;
    end

    UnitPopupItemQuality1DescButtonMixin = CreateFromMixins(UnitPopupItemQuality2DescButtonMixin);

    function UnitPopupItemQuality1DescButtonMixin:GetText()
    	return ITEM_QUALITY1_DESC;
    end

    function UnitPopupItemQuality1DescButtonMixin:GetID()
    	return 1;
    end

    local UnitPopupLootThresholdButtonMixinGetButtons = UnitPopupLootThresholdButtonMixin.GetButtons
    function UnitPopupLootThresholdButtonMixin:GetButtons()
        local buttons = UnitPopupLootThresholdButtonMixinGetButtons(self)
        table.insert(buttons, UnitPopupItemQuality1DescButtonMixin)
        table.insert(buttons, UnitPopupItemQuality0DescButtonMixin)

        --Fixup button ids to be in some sort of sane order, fixes an issue in the default UI.
        table.sort(buttons, function (a, b)
            if (b.GetID == nil) then
                return a.GetID ~= nil;
            elseif (a.GetID == nil) then
                return false;
            else
                return a.GetID() < b.GetID();
            end
        end);

        return buttons;
    end
end

