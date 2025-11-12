-- Loot event handlers
-- Handles LOOT_READY, LOOT_OPENED, LOOT_CLOSED, LOOT_SLOT_CLEARED, LOOT_BIND_CONFIRM

-- Constants for loot processing timing
local MASTER_LOOT_DELAY = 0.1 -- Delay before starting master loot processing (allows Blizzard to update)
local LOOT_TICKER_INTERVAL = 0.05 -- Interval between loot processing ticks
local LOOT_TICKER_MAX_ITERATIONS = 64 -- Maximum number of ticker iterations

-- Helper function to cancel the loot ticker with optional debug reason
local function cancelLootTicker(lootState, reason)
    if lootState.lootTicker then
        if reason then
            GogoLoot._utils.debug("Cancelled loot ticker [" .. reason .. "]")
        end
        lootState.lootTicker:Cancel()
        lootState.lootTicker = nil
    end
end

-- Validate and hide MasterLootFrame if it's showing stale data
-- This is especially important during combat when timing can be off
local function validateMasterLootFrame()
    if not (MasterLootFrame and MasterLootFrame:IsShown()) then
        return
    end
    
    local slotValid = false
    if MasterLootFrame.lootSlot then
        local texture, item = GetLootSlotInfo(MasterLootFrame.lootSlot)
        slotValid = texture and item
    end
    
    if not slotValid then
        MasterLootFrame:Hide()
    end
end

-- Build player index mapping for all current loot slots
-- Returns a table mapping slotIndex -> {[playerName] = candidateIndex}
local function buildPlayerIndexForSlots(numLootItems)
    local playerIndex = {}
    for slotIndex = numLootItems, 1, -1 do
        -- Validate slot exists and has valid loot data before querying candidates
        local texture, item, quantity, quality, locked = GetLootSlotInfo(slotIndex)
        if texture and item then  -- Slot has valid loot
            playerIndex[slotIndex] = {}
            for i = 1, GetNumGroupMembers() do
                local playerAtIndex = GetMasterLootCandidate(slotIndex, i)
                if playerAtIndex then
                    playerIndex[slotIndex][strlower(playerAtIndex)] = i
                end
            end
        end
    end
    return playerIndex
end

-- Check if remaining items are retryable (item info not available) or manual handling
-- Returns true if any items are retryable (should continue ticking), false if only manual handling items remain
local function hasRetryableItems(numLootItems)
    local ItemInfoCache = GogoLoot._loot_core.ItemInfoCache
    
    for slotIndex = numLootItems, 1, -1 do
        local lootLink = GetLootSlotLink(slotIndex)
        if lootLink and strlen(lootLink) >= 8 then
            -- Check if item info is available
            if not ItemInfoCache[lootLink] then
                -- Item info not available - this is retryable
                return true
            end
        end
    end
    
    -- All remaining items have item info available - they're manual handling items
    return false
end

-- Process master loot slots in reverse order (highest index first to minimize slot shifts)
-- Processes ALL slots instead of stopping at first problem
-- Returns: itemsProcessed (number of items successfully processed via GiveMasterLoot)
local function processMasterLootSlots(numLootItems, playerIndex, validPreviouslyHack)
    local itemsProcessed = 0
    
    for slotIndex = numLootItems, 1, -1 do
        -- Double-check slot still exists (might have been auto-looted by previous iterations)
        if slotIndex <= GetNumLootItems() and playerIndex[slotIndex] then
            local result = GogoLoot:VacuumSlot(slotIndex, playerIndex[slotIndex], validPreviouslyHack)
            if result == false then
                -- Item was successfully processed (GiveMasterLoot was called)
                itemsProcessed = itemsProcessed + 1
            end
            -- If result == true, item needs retry or manual handling - continue processing other slots
        end
    end
    
    return itemsProcessed
end

-- Main loot processing step for master looter mode
-- Returns true if processing should stop, false to continue
local function doLootStep(lootState, validPreviouslyHack)
    -- Periodically check and hide MasterLootFrame if it's showing stale data
    validateMasterLootFrame()
    
    local numLootItems = GetNumLootItems()
    
    -- Check if no items remain
    if numLootItems == 0 then
        cancelLootTicker(lootState, "no items")
        return true
    end
    
    -- Build player index for all current slots in reverse order (highest to lowest)
    local playerIndex = buildPlayerIndexForSlots(numLootItems)
    
    -- Process all slots in reverse order (highest index first to minimize slot shifts)
    local itemsProcessed = processMasterLootSlots(numLootItems, playerIndex, validPreviouslyHack)
    
    -- Check if we're done (no items left after processing)
    local remainingItems = GetNumLootItems()
    if remainingItems == 0 then
        cancelLootTicker(lootState, "all items processed")
        return true
    end
    
    -- Determine if we should continue ticking
    -- Note: GiveMasterLoot() is async, so items might not be removed immediately
    -- We track both: itemsProcessed (GiveMasterLoot called) and itemsRemoved (actually gone)
    local itemsRemoved = numLootItems - remainingItems
    local madeProgress = itemsProcessed > 0 or itemsRemoved > 0
    local hasRetryable = hasRetryableItems(remainingItems)
    
    -- Continue ticking if we made progress OR there are retryable items
    -- Only stop if we made NO progress AND only manual handling items remain
    if madeProgress or hasRetryable then
        return false
    end
    
    -- No progress made and no retryable items - only manual handling items remain
    cancelLootTicker(lootState, "only manual handling items remain")
    return true
end

-- Handle solo looting (non-master looter)
local function handleSoloLoot()
    local numLootItems = GetNumLootItems()
    for i = 1, numLootItems do
        GogoLoot:VacuumSlotSolo(i)
    end
    -- Rely on Blizzard default window for manual loot
end

-- Handle master looter loot processing
local function handleMasterLooterLoot(lootState)
    lootState.canLoot = false
    local validPreviouslyHack = {}
    lootState.failedPlayers = {} -- Track players with full bags

    -- Wait a brief moment for Blizzard to update the Master Looter frame
    C_Timer.After(MASTER_LOOT_DELAY, function()
        -- Cancel any existing ticker before starting a new one
        cancelLootTicker(lootState, "starting new loot processing")
        
        GogoLoot._utils.debug("There is loot, continuing timer...")
        lootState.lootTicker = C_Timer.NewTicker(LOOT_TICKER_INTERVAL, function()
            local shouldStop = doLootStep(lootState, validPreviouslyHack)
            if shouldStop then
                cancelLootTicker(lootState)
                -- Reset canLoot when ticker stops (allows manual retry)
                lootState.canLoot = true
            end
        end, LOOT_TICKER_MAX_ITERATIONS)
    end)
end

-- Check if loot should be processed by GogoLoot
local function shouldProcessLoot()
    -- Check if autoloot is enabled (via CVar or modifier key)
    if GetCVarBool("autoLootDefault") == IsModifiedClick("AUTOLOOTTOGGLE") then
        return false -- Autoloot disabled, rely on Blizzard default window
    end
    
    -- Check if addon is enabled
    if not GogoLoot_Config.enabled then
        return false -- GogoLoot disabled, rely on Blizzard default window
    end
    
    return true
end

function GogoLoot._events.loot:HandleLootReady(events, evt)
    GogoLoot._loot_state.lootAPIOpen = true
end

function GogoLoot._events.loot:HandleLootOpened(events, evt)
    local lootState = GogoLoot._loot_state
    
    -- Guard clause: early return if we can't loot
    if not lootState.canLoot then
        return
    end
    
    -- Clear any stale MasterLootFrame when new loot arrives
    if MasterLootFrame and MasterLootFrame:IsShown() then
        MasterLootFrame:Hide()
    end
    GogoLoot._utils.debug("LootReady! " .. evt)
    
    -- Guard clause: early return if we shouldn't process loot
    if not shouldProcessLoot() then
        return
    end
    
    -- Route to appropriate handler based on master looter status
    if GogoLoot:areWeMasterLooter() then
        handleMasterLooterLoot(lootState)
    else
        handleSoloLoot()
    end
end

function GogoLoot._events.loot:HandleLootClosed(events, evt)
    local lootState = GogoLoot._loot_state
    lootState.lootAPIOpen = false
    lootState.canLoot = true
    lootState.failedPlayers = nil -- Clear failed players tracking
    cancelLootTicker(lootState, "loot closed")
end

function GogoLoot._events.loot:HandleLootSlotCleared(events, evt)
    -- Hide MasterLootFrame when slots are cleared to prevent stale data
    -- This happens when items are auto-looted via GiveMasterLoot()
    -- Use C_Timer to ensure it works even during combat restrictions
    C_Timer.After(0, validateMasterLootFrame)
end

function GogoLoot._events.loot:HandleLootBindConfirm(events, evt, arg)
    -- Rely on Blizzard default window
    --[[if GogoLoot_Config.autoConfirm then
        local id = select(1, GetLootSlotInfo(arg))
        if id and (not internalIgnoreList[id]) and (not GogoLoot_Config.ignoredItemsMaster[id]) and (not GogoLoot_Config.ignoredItemsSolo[id]) then -- items from config UI
            lastItemHidden = true
            ConfirmLootSlot(arg)
        else
            lastItemHidden = false
        end
    end]]--
end

