-- Shared state for loot event handling
-- Manages loot state variables used across multiple event handlers

-- Initialize event handler namespaces (must be done before other event files load)
if not GogoLoot._events then
    GogoLoot._events = {
        init = {},
        loot = {},
        roll = {},
        group = {},
        ui = {},
    }
end

local lootState = {
    canLoot = true,
    lootAPIOpen = false,
    lootTicker = nil,
}

-- Export state for use by event handlers
GogoLoot._loot_state = lootState

