-- UI and error event handlers
-- Handles UI_ERROR_MESSAGE, MODIFIER_STATE_CHANGED

function GogoLoot._events.ui:HandleUIErrorMessage(events, evt, message)
    local lootState = GogoLoot._loot_state
    
    if message and (message == ERR_ITEM_MAX_COUNT or message == ERR_INV_FULL or string.match(strlower(message), "inventory") or string.match(strlower(message), "loot")) and not GogoLoot._utils.badErrors[message] then
        GogoLoot._utils.debug(message)
        
        -- Don't cancel the ticker - let it continue processing other items
        -- The delayed slot verification in loot_master.lua will catch the failure
        -- and mark the correct player (it has access to targetPlayerName)
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

