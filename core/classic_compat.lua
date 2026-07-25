-- Classic Era compatibility shims for GogoLoot

-- Classic Era compatible GetLootMethod override
-- In Classic Era, GetLootMethod() doesn't exist and CVars don't work
-- Detect loot method by checking for master looter presence (isML flag) rather than just threshold
if not GetLootMethod or type(GetLootMethod) ~= "function" then
    function GetLootMethod()
        local threshold = GetLootThreshold()

        if not IsInGroup() and not IsInRaid() then
            return "freeforall"
        end

        if IsInRaid() then
            for i = 1, GetNumGroupMembers() do
                local name, _, _, _, _, _, _, _, _, _, isML = GetRaidRosterInfo(i)
                if isML and name then return "master" end
            end
            return (threshold and threshold > 0) and "group" or "freeforall"
        end

        if IsInGroup() then
            if UnitIsGroupLeader("player") then
                return (threshold and threshold > 0) and "master" or "freeforall"
            else
                return (threshold and threshold > 0) and "group" or "freeforall"
            end
        end

        return "freeforall"
    end
end

-- IsAddOnLoaded was moved to the C_AddOns namespace in a client update;
-- restore the old global so callers don't need to change.
if (not IsAddOnLoaded or type(IsAddOnLoaded) ~= "function") and C_AddOns and C_AddOns.IsAddOnLoaded then
    IsAddOnLoaded = C_AddOns.IsAddOnLoaded
end

