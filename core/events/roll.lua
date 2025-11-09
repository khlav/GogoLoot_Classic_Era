-- Auto-roll event handlers
-- Handles START_LOOT_ROLL

function GogoLoot._events.roll:HandleStartLootRoll(events, evt, arg)
    local rollid = tonumber(arg)
    if rollid and GogoLoot_Config.autoRoll then
        local itemLink = GetLootRollItemLink(rollid)
        if itemLink then
            GogoLoot._utils.debug(itemLink)
            local data = {string.find(itemLink,"|?c?f?f?(%x*)|?H?([^:]*):?(%d+):?(%d*):?(%d*):?(%d*):?(%d*):?(%d*):?(%-?%d*):?(%-?%d*):?(%d*):?(%d*):?(%-?%d*)|?h?%[?([^%[%]]*)%]?|?h?|?r?")}
            GogoLoot._utils.debug(data[5])
            local itemID = tonumber(data[5])
            if itemID then
                if not itemLink or strlen(itemLink) < 8 then
                    GogoLoot._utils.debug("Invalid item link")
                    return -- likely gold TODO: CHECK THIS
                end
                local ItemInfoCache = GogoLoot._loot_core.ItemInfoCache
                local ItemIDCache = GogoLoot._loot_core.ItemIDCache
                if itemLink and not ItemInfoCache[itemLink] then
                    ItemIDCache[itemLink] = {string.find(itemLink,"|?c?f?f?(%x*)|?H?([^:]*):?(%d+):?(%d*):?(%d*):?(%d*):?(%d*):?(%d*):?(%-?%d*):?(%-?%d*):?(%d*):?(%d*):?(%-?%d*)|?h?%[?([^%[%]]*)%]?|?h?|?r?")}
                    local itemID = ItemIDCache[itemLink][5]
                    if itemID then
                        local itemInfo = {GetItemInfoInstant(itemID)}
                        if itemInfo and itemInfo[1] then -- itemID is first return value, check if we got valid data
                            ItemInfoCache[itemLink] = itemInfo
                        end
                        -- If itemInfo is nil, don't cache it - will retry next time this item is seen
                    end
                end
                if (not itemBindings[itemID]) or itemBindings[itemID] ~= 1 then -- not bind on pickup
                    if ItemInfoCache[itemLink] and (not GogoLoot_Config.ignoredItemsSolo[itemID]) and (not internalIgnoreList[itemID]) and ((ItemInfoCache[itemLink][12] ~= 9 -- recipes
                        and (not (ItemInfoCache[itemLink][12] == 15 and ItemInfoCache[itemLink][13] == 2)) -- pets
                        and (not (ItemInfoCache[itemLink][12] == 15 and ItemInfoCache[itemLink][13] == 5)) -- mounts
                    ) or (GogoLoot_Config.professionRollDisable and itemBindings[itemID] ~= 1)) then
                        -- we should auto need or greed this
                        
                        -- find desired roll behavior for item type
                        local rarity = GogoLoot._utils.colorToRarity[data[3]]
                        local action = nil

                        if rarity == 2 then -- green
                            if GogoLoot_Config.autoGreenRolls then
                                if GogoLoot_Config.autoGreenRolls == "need" then
                                    action = 1
                                elseif GogoLoot_Config.autoGreenRolls == "greed" then
                                    action = 2
                                end
                            end
                        elseif rarity == 3 then -- blue
                            if GogoLoot_Config.autoBlueRolls then
                                if GogoLoot_Config.autoBlueRolls == "need" then
                                    action = 1
                                elseif GogoLoot_Config.autoBlueRolls == "greed" then
                                    action = 2
                                end
                            end
                        elseif rarity == 4 then -- epic
                            if GogoLoot_Config.autoPurpleRolls then
                                if GogoLoot_Config.autoPurpleRolls == "need" then
                                    action = 1
                                elseif GogoLoot_Config.autoPurpleRolls == "greed" then
                                    action = 2
                                end
                            end
                        end

                        if action then
                            GogoLoot._utils.debug("Rolling on loot: " .. tostring(rollid) .. " thresh: " .. tostring(action))
                            RollOnLoot(rollid, action)
                        end
                    end
                end
            end
        end
    end
    --print(arg)
    --print(message)
end

