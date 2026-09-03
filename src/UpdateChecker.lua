-- DamageLife Update Checker 1.3.4.14
-- Ultra-light state machine for WoW 3.3.5a.
--
-- IMPORTANT:
-- Stock WoW 3.3.5a addon Lua has no arbitrary HTTPS client. This module does
-- NOT create sockets, poll every N minutes, or perform synchronous networking.
-- A host/relay integration may register one asynchronous function through
-- DamageLifeUpdateChecker.SetHTTPBackend().
--
-- Performance policy:
--   * no OnUpdate
--   * no periodic timer
--   * one check per 12h at most
--   * never check during combat/BG
--   * tiny GitHub response is parsed and immediately released
--   * no automatic file replacement/download

local _, DL = ...
DL = DL or {}
local U = {}

U.CURRENT_VERSION = "1.3.4.14"
U.REPOSITORY = "VegasGhoul/DamageLife-WotLK"
U.RELEASE_PAGE = "https://github.com/" .. U.REPOSITORY .. "/releases/latest"
U.RELEASES_URL = "https://api.github.com/repos/" .. U.REPOSITORY .. "/releases/latest"
U.CHECK_INTERVAL = 43200 -- 12 hours; deliberately not 10-30 minutes.
U.lastResult = nil
U.lastError = nil
U.checking = false
U.backend = nil
U.backendName = nil
U.backendAsync = false

local function parts(v)
    local a = {}
    for n in tostring(v or ""):gmatch("%d+") do
        a[#a + 1] = tonumber(n) or 0
        if #a == 4 then break end
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

local function dbState()
    DamageLifeDB = DamageLifeDB or {}
    DamageLifeDB.update = DamageLifeDB.update or {}
    return DamageLifeDB.update
end

local function jsonString(body, key)
    if type(body) ~= "string" then return nil end
    local value = body:match('"' .. key .. '"%s*:%s*"(.-)"')
    if not value then return nil end
    return value:gsub('\\"', '"'):gsub('\\/', '/'):gsub('\\n', '\n'):gsub('\\r', '\r'):gsub('\\t', '\t'):gsub('\\\\', '\\')
end

local function jsonBool(body, key)
    return type(body) == "string" and body:match('"' .. key .. '"%s*:%s*true') ~= nil
end

function U.ApplyReleaseMetadata(tagName, name, htmlUrl, assetUrl, publishedAt, prerelease, source, checkedAt)
    local version = tostring(tagName or ""):gsub("^v", "")
    if version == "" then return false end
    U.lastResult = {
        latestVersion = version,
        name = name or "",
        htmlUrl = htmlUrl or U.RELEASE_PAGE,
        assetUrl = assetUrl or "",
        publishedAt = publishedAt or "",
        prerelease = prerelease and true or false,
        available = U.CompareVersions(version, U.CURRENT_VERSION) > 0,
        source = source or "backend",
        checkedAt = checkedAt or time()
    }
    local db = dbState()
    db.latestVersion = version
    db.latestName = name or ""
    db.releaseURL = htmlUrl or U.RELEASE_PAGE
    db.assetURL = assetUrl or ""
    db.publishedAt = publishedAt or ""
    db.prerelease = prerelease and true or false
    db.checkedAt = U.lastResult.checkedAt
    db.source = source or "backend"
    return true
end

function U.ParseReleaseJSON(body, code)
    local numericCode = tonumber(code)
    if numericCode and numericCode ~= 200 then return false, "http-status-" .. tostring(numericCode) end
    if type(body) ~= "string" or body == "" then return false, "empty-response" end
    local tag = jsonString(body, "tag_name")
    if not tag then return false, "tag-name-missing" end
    return U.ApplyReleaseMetadata(
        tag,
        jsonString(body, "name") or "",
        jsonString(body, "html_url") or U.RELEASE_PAGE,
        "",
        jsonString(body, "published_at") or "",
        jsonBool(body, "prerelease"),
        "github-relay",
        time()
    )
end

function U.SetHTTPBackend(fn, name, isAsync)
    if type(fn) ~= "function" or not isAsync then
        U.backend, U.backendName, U.backendAsync = nil, nil, false
        return false
    end
    U.backend = fn
    U.backendName = name or "relay"
    U.backendAsync = true
    return true
end

function U.GetBackendName() return U.backendName end
function U.HasBackend() return U.backend ~= nil and U.backendAsync end
function U.GetCurrentVersion() return U.CURRENT_VERSION end
function U.GetRepository() return U.REPOSITORY end
function U.GetReleasePage() return U.RELEASE_PAGE end
function U.GetLatestVersion() return U.lastResult and U.lastResult.latestVersion end
function U.GetStatus() return U.lastResult end
function U.IsUpdateAvailable() return U.lastResult and U.lastResult.available or false end
function U.IsChecking() return U.checking end
function U.GetLastError() return U.lastError end

local function inRestrictedState()
    if UnitAffectingCombat and UnitAffectingCombat("player") then return true end
    if IsInInstance then
        local inInstance, instanceType = IsInInstance()
        if inInstance and (instanceType == "pvp" or instanceType == "arena") then return true end
    end
    return false
end

function U.RequestCheck(callback, force)
    if not U.backend or not U.backendAsync then
        U.lastError = "no-async-backend"
        if callback then callback(false, U.lastError) end
        return false, U.lastError
    end
    if U.checking then return false, "check-in-progress" end

    local now = time()
    local db = dbState()
    if not force and db.checkedAt and now - db.checkedAt < U.CHECK_INTERVAL then
        return false, "cooldown"
    end
    if inRestrictedState() then return false, "restricted-state" end

    U.checking = true
    local ok, err = pcall(U.backend, U.RELEASES_URL, function(body, code, headers, requestError)
        U.checking = false
        local parsed, parseError = U.ParseReleaseJSON(body, code)
        if not parsed then
            U.lastError = requestError or parseError or "invalid-response"
            if callback then callback(false, U.lastError) end
            return
        end
        if callback then callback(true, nil, U.lastResult) end
    end)
    if not ok then
        U.checking = false
        U.lastError = tostring(err)
        if callback then callback(false, U.lastError) end
        return false, U.lastError
    end
    if ok == false then
        U.checking = false
        U.lastError = tostring(err or "request-failed")
        return false, U.lastError
    end
    return true
end

function U.AutoCheck()
    if not U.HasBackend() then return false, "no-async-backend" end
    return U.RequestCheck(nil, false)
end

-- Restore only the tiny data needed for the UI; no polling timer is created.
do
    local db = dbState()
    if db.latestVersion and db.latestVersion ~= "" then
        U.ApplyReleaseMetadata(db.latestVersion, db.latestName, db.releaseURL, db.assetURL, db.publishedAt, db.prerelease, db.source or "cache", db.checkedAt or 0)
    end
end

-- One-shot login hook. It does nothing in a normal stock client because no
-- async backend exists. A host integration can register the backend before login.
local loginFrame = CreateFrame("Frame")
loginFrame:RegisterEvent("PLAYER_LOGIN")
loginFrame:SetScript("OnEvent", function()
    loginFrame:UnregisterEvent("PLAYER_LOGIN")
    if not U.HasBackend() then return end
    U.AutoCheck()
end)

_G.DamageLifeUpdateChecker = U
