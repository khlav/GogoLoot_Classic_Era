-- Event handling for GogoLoot
-- Main event dispatcher that delegates to specialized event handlers

-- Note: GogoLoot._events is initialized in core/events/state.lua

function GogoLoot:EventHandler(events, evt, arg, message, a, b, c, ...)
    --GogoLoot._utils.debug(evt)
    
    if ("ADDON_LOADED" == evt) then
        GogoLoot._events.init:HandleAddonLoaded(events, evt, arg)
    elseif "LOOT_READY" == evt then
        GogoLoot._events.loot:HandleLootReady(events, evt)
    elseif ("LOOT_OPENED" == evt) then
        GogoLoot._events.loot:HandleLootOpened(events, evt)
    elseif "LOOT_CLOSED" == evt then
        GogoLoot._events.loot:HandleLootClosed(events, evt)
    elseif "LOOT_SLOT_CLEARED" == evt then
        GogoLoot._events.loot:HandleLootSlotCleared(events, evt)
    elseif "START_LOOT_ROLL" == evt then
        GogoLoot._events.roll:HandleStartLootRoll(events, evt, arg)
    elseif "LOOT_BIND_CONFIRM" == evt then
        GogoLoot._events.loot:HandleLootBindConfirm(events, evt, arg)
    elseif "UI_ERROR_MESSAGE" == evt then
        GogoLoot._events.ui:HandleUIErrorMessage(events, evt, message)
    elseif "GROUP_ROSTER_UPDATE" == evt then
        GogoLoot._events.group:HandleGroupRosterUpdate(events, evt)
    elseif "PARTY_LOOT_METHOD_CHANGED" == evt then
        GogoLoot._events.group:HandlePartyLootMethodChanged(events, evt)
    elseif "MODIFIER_STATE_CHANGED" == evt then
        GogoLoot._events.ui:HandleModifierStateChanged(events, evt)
    elseif "PLAYER_ENTERING_WORLD" == evt then
        GogoLoot._events.init:HandlePlayerEnteringWorld(events, evt)
    elseif "PLAYER_LOGIN" == evt then
        GogoLoot._events.init:HandlePlayerLogin(events, evt)
    end
end
