-- UI and error event handlers
-- Handles UI_ERROR_MESSAGE, MODIFIER_STATE_CHANGED

function GogoLoot._events.ui:HandleUIErrorMessage(events, evt, message)
    local lootState = GogoLoot._loot_state
    
    if message and (message == ERR_ITEM_MAX_COUNT or message == ERR_INV_FULL or string.match(strlower(message), "inventory") or string.match(strlower(message), "loot")) and not GogoLoot._utils.badErrors[message] then
        GogoLoot._utils.debug(message)
        if lootState.lootTicker then
            GogoLoot._utils.debug("Cancelled loot ticker [4]")
            lootState.lootTicker:Cancel()
            lootState.lootTicker = nil
        end
        -- Rely on Blizzard default window
    end
end

function GogoLoot._events.ui:HandleModifierStateChanged(events, evt)
    local lootState = GogoLoot._loot_state
    
    if not lootState.canLoot then
        if GetCVarBool("autoLootDefault") == IsModifiedClick("AUTOLOOTTOGGLE") then
            -- Rely on Blizzard default window
        end
    end
end

