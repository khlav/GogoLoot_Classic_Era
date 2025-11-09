-- Group/party event handlers
-- Handles GROUP_ROSTER_UPDATE, PARTY_LOOT_METHOD_CHANGED

function GogoLoot._events.group:HandleGroupRosterUpdate(events, evt)
    local inGroup = IsInGroup()
    if inGroup ~= GogoLoot.isInGroup then
        GogoLoot.isInGroup = inGroup
        if inGroup then -- we have just joined a group
            if GetLootMethod() == "group" then
                GogoLoot:AnnounceNeeds()--SendChatMessage(string.format(GogoLoot.AUTO_ROLL_ENABLED, 1 == GogoLoot_Config.autoRollThreshold and "Need" or "Greed"), UnitInRaid("Player") and "RAID" or "PARTY")
            end
        else -- we left, clear group-specific settings
            GogoLoot_Config.players = {}
        end
    end
end

function GogoLoot._events.group:HandlePartyLootMethodChanged(events, evt)
    if GogoLoot:areWeMasterLooter() and GetLootMethod() == "master" then
        GogoLoot:BuildUI()
    elseif GetLootMethod() == "group" then
        GogoLoot:AnnounceNeeds()
    --    SendChatMessage(string.format(GogoLoot.AUTO_ROLL_ENABLED, 1 == GogoLoot_Config.autoRollThreshold and "Need" or "Greed"), UnitInRaid("Player") and "RAID" or "PARTY")
    end
end

