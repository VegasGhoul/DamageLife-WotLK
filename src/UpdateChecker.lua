-- DamageLife peer version checker for WoW 3.3.5a.
--
-- This is intentionally NOT an Internet/GitHub updater. Standard WoW 3.3.5a
-- addon Lua cannot perform arbitrary HTTPS requests. Instead, DamageLife
-- exchanges its installed version with other DamageLife users through the
-- built-in hidden addon-message channel, similar to the version-check model
-- used by established WoW UI addons.
local _, DL = ...
DL = DL or {}

local U = {}
U.CURRENT_VERSION = "1.3.4.13"
U.ADDON_NAME = "DamageLife"
U.PREFIX = "DLifeVer"
U.REPOSITORY = "VegasGhoul/DamageLife-WotLK"
U.RELEASE_PAGE = "https://github.com/" .. U.REPOSITORY .. "/releases/latest"
U.lastResult = nil
U.lastPeer = nil
U.lastRequest = 0
U.requestCooldown = 15
U.noticeCooldown = 60
U.lastNoticeTime = 0
U.lastDirectName = nil
U.lastDirectRequest = 0
U.directRequestCooldown = 20
U.lastManualCheck = 0
U.manualPending = {}
U.manualDeadline = 0
U.manualSent = 0
U.manualResponses = 0
U.manualSummaryShown = false

local function getCurrentVersion()
    if GetAddOnMetadata then
        return tostring(GetAddOnMetadata(U.ADDON_NAME, "Version") or U.CURRENT_VERSION)
    end
    return U.CURRENT_VERSION
end

local function parts(v)
    local a = {}
    for n in tostring(v or ""):gmatch("%d+") do
        a[#a + 1] = tonumber(n) or 0
    end
    while #a < 4 do a[#a + 1] = 0 end
    return a
end

function U.CompareVersions(a, b)
    local A, B = parts(a), parts(b)
    for i = 1, 4 do
        if A[i] > B[i] then return 1 end
        if A[i] < B[i] then return -1 end
    end
    return 0
end

function U.GetCurrentVersion()
    U.CURRENT_VERSION = getCurrentVersion()
    return U.CURRENT_VERSION
end

function U.GetReleasePage() return U.RELEASE_PAGE end
function U.GetStatus() return U.lastResult end

local function rememberManualPeer(sender, version)
    if not U.manualPending or U.manualDeadline <= 0 then return end
    U.manualPending[sender] = tostring(version or "")
    U.manualResponses = (U.manualResponses or 0) + 1
    if U.CompareVersions(version, U.GetCurrentVersion()) > 0 then
        notifyNewerVersion(version, sender)
    end
end

local function finishManualCheck(force)
    if not U.manualDeadline or U.manualDeadline <= 0 then return false end
    local now = GetTime and GetTime() or 0
    if not force and now < U.manualDeadline then return false end
    if U.manualSummaryShown then return true end
    U.manualSummaryShown = true
    local count, newer, same, older = 0, 0, 0, 0
    for sender, version in pairs(U.manualPending or {}) do
        count = count + 1
        local cmp = U.CompareVersions(version, U.GetCurrentVersion())
        if cmp > 0 then newer = newer + 1
        elseif cmp == 0 then same = same + 1
        else older = older + 1 end
    end
    if count == 0 then
        chatMessage("проверка завершена: ответов от других DamageLife не получено. Для открытого мира выберите другого игрока целью или наведите на него курсор; автоматического канала для ближайших игроков в WoW 3.3.5a нет.")
    else
        chatMessage("проверка завершена: ответов " .. count .. "; совпадает " .. same .. "; новее " .. newer .. "; старее " .. older .. ".")
        for sender, version in pairs(U.manualPending or {}) do
            local cmp = U.CompareVersions(version, U.GetCurrentVersion())
            chatMessage(tostring(sender) .. " — DamageLife " .. tostring(version) .. " " ..
                (cmp > 0 and "(НОВЕЕ)" or cmp == 0 and "(совпадает)" or "(старее)"))
        end
    end
    U.manualDeadline = 0
    return true
end

function U.ApplyReleaseMetadata(tagName, name, htmlUrl, assetUrl, publishedAt, prerelease)
    local v = tostring(tagName or ""):gsub("^v", "")
    if v == "" then return false end
    U.lastResult = {
        latestVersion = v,
        name = name or "",
        htmlUrl = htmlUrl or U.RELEASE_PAGE,
        assetUrl = assetUrl or "",
        publishedAt = publishedAt or "",
        prerelease = prerelease and true or false,
        available = U.CompareVersions(v, U.GetCurrentVersion()) > 0,
        source = "github"
    }
    return true
end

local function isActiveBattleground()
    if not GetBattlefieldStatus then return false end
    for i = 1, 3 do
        local status = GetBattlefieldStatus(i)
        if status == "active" then return true end
    end
    return false
end

local function getBroadcastChannel()
    if isActiveBattleground() then return "BATTLEGROUND" end
    if GetNumRaidMembers and GetNumRaidMembers() > 0 then return "RAID" end
    if GetNumPartyMembers and GetNumPartyMembers() > 0 then return "PARTY" end
    if IsInGuild and IsInGuild() then return "GUILD" end
    return nil
end

local function isPlayerUnit(unit)
    return unit and UnitExists and UnitExists(unit) and UnitIsPlayer and UnitIsPlayer(unit)
end

local function getUnitName(unit)
    if not isPlayerUnit(unit) or not UnitName then return nil end
    local name = UnitName(unit)
    if not name or name == "" then return nil end
    return name
end

local function requestDirectPlayer(unit, force)
    local name = getUnitName(unit)
    if not name or not SendAddonMessage then return false end
    local playerName = UnitName and UnitName("player") or ""
    if name == playerName then return false end
    local now = GetTime and GetTime() or 0
    if not force and U.lastDirectName == name and now - (U.lastDirectRequest or 0) < U.directRequestCooldown then return false end
    U.lastDirectName, U.lastDirectRequest = name, now
    SendAddonMessage(U.PREFIX, "REQ:" .. U.GetCurrentVersion(), "WHISPER", name)
    return true
end

local function chatMessage(text)
    local chat = DEFAULT_CHAT_FRAME or ChatFrame1
    if chat and chat.AddMessage then chat:AddMessage("|cffd8a84eDamageLife|r: " .. text) end
end

local function notifyNewerVersion(version, sender)
    local current = U.GetCurrentVersion()
    if U.CompareVersions(version, current) <= 0 then return end
    local now = GetTime and GetTime() or 0
    if DamageLifeDB and DamageLifeDB.updateNoticeVersion == version then return end
    if (U.lastNoticeTime or 0) > 0 and now - U.lastNoticeTime < U.noticeCooldown then return end
    if DamageLifeDB then DamageLifeDB.updateNoticeVersion = version end
    U.lastNoticeTime, U.lastPeer = now, sender or "unknown"
    U.lastResult = {latestVersion=version, available=true, source="peer", sender=sender or "unknown"}
    chatMessage("обнаружена новая версия |cff66ff66" .. tostring(version) .. "|r (у Вас " .. tostring(current) .. "). Обновление доступно на GitHub.")
end

function U.RequestPeerCheck(force)
    if not SendAddonMessage then return false end
    local sent, now = false, GetTime and GetTime() or 0
    local version = U.GetCurrentVersion()
    if force then
        wipe(U.manualPending)
        U.manualDeadline = now + 2.5
        U.manualSent, U.manualResponses, U.manualSummaryShown = 0, 0, false
    end
    if force or now - (U.lastRequest or 0) >= U.requestCooldown then
        local channel = getBroadcastChannel()
        if channel then
            U.lastRequest = now
            SendAddonMessage(U.PREFIX, "REQ:" .. version, channel)
            sent = true
            U.manualSent = U.manualSent + 1
        end
    end
    local directSeen = {}
    local function requestUnique(unit)
        local name = getUnitName(unit)
        if not name or directSeen[name] then return false end
        directSeen[name] = true
        return requestDirectPlayer(unit, force)
    end
    for _, unit in ipairs({"target", "mouseover", "focus"}) do
        if requestUnique(unit) then sent = true; U.manualSent = U.manualSent + 1 end
    end
    for i = 1, 5 do
        if requestUnique("arena" .. i) then sent = true; U.manualSent = U.manualSent + 1 end
    end
    if force then
        U.lastManualCheck = now
        if sent then
            chatMessage("проверка игроков запущена. Ожидаю ответы 2.5 сек...")
        else
            U.manualDeadline = 0
            chatMessage("не найден доступный игрок или общий канал. В открытом мире выберите игрока целью/наведите на него курсор; без этого WoW 3.3.5a не предоставляет канала ближайших игроков.")
        end
    end
    return sent
end

function U.OnAddonMessage(prefix, message, channel, sender)
    if prefix ~= U.PREFIX or not message or not sender then return end
    local playerName = UnitName and UnitName("player") or ""
    if sender == playerName then return end
    if message == "REQ" or message:sub(1, 4) == "REQ:" then
        local version = U.GetCurrentVersion()
        if SendAddonMessage and channel then
            if channel == "WHISPER" then SendAddonMessage(U.PREFIX, "VER:" .. version, "WHISPER", sender)
            else SendAddonMessage(U.PREFIX, "VER:" .. version, channel) end
        end
        return
    end
    local version = message:match("^VER:(.+)$")
    if version then
        rememberManualPeer(sender, version)
        notifyNewerVersion(version, sender)
    end
end

function U.SetRepository(owner, repo)
    if not owner or not repo or owner == "" or repo == "" then return false end
    U.REPOSITORY = tostring(owner) .. "/" .. tostring(repo)
    U.RELEASE_PAGE = "https://github.com/" .. U.REPOSITORY .. "/releases/latest"
    return true
end

U.frame = CreateFrame("Frame")
U.frame:RegisterEvent("PLAYER_ENTERING_WORLD")
U.frame:RegisterEvent("GROUP_ROSTER_UPDATE")
U.frame:RegisterEvent("CHAT_MSG_ADDON")
U.frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
U.frame:RegisterEvent("PLAYER_TARGET_CHANGED")
U.frame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
U.frame:SetScript("OnEvent", function(_, event, ...)
    if event == "CHAT_MSG_ADDON" then
        U.OnAddonMessage(...)
    elseif event == "PLAYER_TARGET_CHANGED" or event == "UPDATE_MOUSEOVER_UNIT" then
        U.RequestPeerCheck(false)
    elseif event == "PLAYER_ENTERING_WORLD" or event == "GROUP_ROSTER_UPDATE" or event == "ZONE_CHANGED_NEW_AREA" then
        if event == "PLAYER_ENTERING_WORLD" then
            if U.frame._dlTimer then return end
            U.frame._dlTimer = true
            local elapsed = 0
            U.frame:SetScript("OnUpdate", function(self, delta)
                elapsed = elapsed + delta
                if elapsed >= 3 then
                    self:SetScript("OnUpdate", nil)
                    self._dlTimer = nil
                    U.RequestPeerCheck(true)
                end
            end)
        else
            U.RequestPeerCheck(false)
        end
    end
end)

U.frame:SetScript("OnUpdate", function()
    if U.manualDeadline and U.manualDeadline > 0 then finishManualCheck(false) end
end)

if RegisterAddonMessagePrefix then RegisterAddonMessagePrefix(U.PREFIX) end
_G.DamageLifeUpdateChecker = U
