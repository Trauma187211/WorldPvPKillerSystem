------------------------------------------------------------
-- MAIN EVENT FRAME
------------------------------------------------------------
local frame = CreateFrame("Frame")
frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

------------------------------------------------------------
-- GET ZONE NAME
------------------------------------------------------------
local function GetZoneName()
    local zone = GetZoneText()
    if zone and zone ~= "" then
        return zone
    end
    return "Unknown Zone"
end

------------------------------------------------------------
-- KILL STREAK SYSTEM
------------------------------------------------------------
local killStreaks = {}
local lastKillTime = {}

local STREAK_TIMEOUT = 30 -- seconds before streak resets

local function AnnounceStreak(player, streak)
    local msg = ""

    if streak == 2 then msg = player .. " is on a |cff00ff00Double Kill!|r"
    elseif streak == 3 then msg = player .. " is on a |cff00ff00Triple Kill!|r"
    elseif streak == 4 then msg = player .. " is on a |cff00ff00Quad Kill!|r"
    elseif streak == 5 then msg = player .. " is on a |cffff0000Rampage!|r"
    elseif streak == 10 then msg = player .. " is |cffff0000GODLIKE!|r"
    else msg = player .. " is on a kill streak of " .. streak
    end

    print(msg)
end

------------------------------------------------------------
-- TITLE SYSTEM
------------------------------------------------------------
local function GetTitleForStreak(streak)
    if streak >= 30 then
        return "|cffff0000Grim Reaper|r"
    elseif streak >= 20 then
        return "|cffff0000Death Dealer|r"
    elseif streak >= 15 then
        return "|cffff0000Executioner|r"
    elseif streak >= 10 then
        return "|cffff0000Slaughterer|r"
    elseif streak >= 6 then
        return "|cffff0000Mass Murderer|r"
    elseif streak >= 3 then
        return "|cffff0000Serial Killer|r"
    elseif streak >= 1 then
        return "|cffff0000Murderer|r"
    else
        return nil
    end
end

------------------------------------------------------------
-- WARNING SYSTEM
------------------------------------------------------------
local function AnnounceWarning(player, title, zone)
    print("|cffff0000WARNING:|r A " .. title .. " has emerged in " .. zone .. "! (" .. player .. ")")
end

------------------------------------------------------------
-- HANDLE KILL (streak + title)
------------------------------------------------------------
local function HandleKill(player)
    local now = GetTime()

    -- Reset streak if too much time passed
    if lastKillTime[player] and (now - lastKillTime[player] > STREAK_TIMEOUT) then
        killStreaks[player] = 0
    end

    killStreaks[player] = (killStreaks[player] or 0) + 1
    lastKillTime[player] = now

    -- Announce streak
    AnnounceStreak(player, killStreaks[player])

    -- Announce title
    local title = GetTitleForStreak(killStreaks[player])
    if title then
        print(player .. " has earned the title: " .. title)

        -- Zone warning
        local zone = GetZoneName()
        AnnounceWarning(player, title, zone)
    end
end


------------------------------------------------------------
-- COMBAT LOG HANDLER
------------------------------------------------------------
local function OnCombatLogEvent()
    local _, event, _, sourceGUID, sourceName, sourceFlags,
          _, destGUID, destName, destFlags = CombatLogGetCurrentEventInfo()

    -- Only care about actual kills
    if event ~= "PARTY_KILL" then return end

    -- Check if killer is a player
    local killerIsPlayer = bit.band(sourceFlags, COMBATLOG_OBJECT_TYPE_PLAYER) > 0

    -- Check if victim is a player
    local victimIsPlayer = bit.band(destFlags, COMBATLOG_OBJECT_TYPE_PLAYER) > 0

    if killerIsPlayer and victimIsPlayer then
        local zone = GetZoneName()
        print("PvP Kill Detected:", sourceName, "killed", destName, "in", zone)
        HandleKill(sourceName)
    end
end

frame:SetScript("OnEvent", OnCombatLogEvent)

