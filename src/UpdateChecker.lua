-- DamageLife GitHub Update Checker
local U = {}
U.CURRENT_VERSION = "1.3.4.14"
U.REPOSITORY = "VegasGhoul/DamageLife-WotLK"
U.RELEASES_URL = "https://api.github.com/repos/"..U.REPOSITORY.."/releases/latest"
U.RELEASE_PAGE = "https://github.com/"..U.REPOSITORY.."/releases/latest"
U.lastResult = nil

local function parts(v)
    local a = {}
    for n in tostring(v or ""):gmatch("%d+") do a[#a+1] = tonumber(n) or 0 end
    while #a < 4 do a[#a+1] = 0 end
    return a
end

function U.CompareVersions(a,b)
    local A,B = parts(a),parts(b)
    for i=1,4 do
        if A[i] > B[i] then return 1 end
        if A[i] < B[i] then return -1 end
    end
    return 0
end

function U.ApplyReleaseMetadata(tagName,name,htmlUrl,assetUrl,publishedAt,prerelease)
    local v = tostring(tagName or ""):gsub("^v","")
    if v == "" then return false end
    U.lastResult = {
        latestVersion=v,
        name=name or "",
        htmlUrl=htmlUrl or U.RELEASE_PAGE,
        assetUrl=assetUrl or "",
        publishedAt=publishedAt or "",
        prerelease=prerelease and true or false,
        available=U.CompareVersions(v,U.CURRENT_VERSION) > 0
    }
    return true
end

local cache = rawget(_G,"DamageLifeUpdateCache")
if type(cache) == "table" and cache.latestVersion then
    U.ApplyReleaseMetadata(cache.latestVersion,cache.latestName,cache.releaseURL,cache.assetURL,cache.publishedAt,cache.prerelease)
    if U.lastResult then U.lastResult.source=cache.source or "cache" end
end

function U.GetStatus() return U.lastResult end
function U.GetCurrentVersion() return U.CURRENT_VERSION end
function U.GetReleasePage() return U.RELEASE_PAGE end
function U.GetLatestVersion() return U.lastResult and U.lastResult.latestVersion or nil end
function U.IsUpdateAvailable() return U.lastResult and U.lastResult.available or false end

_G.DamageLifeUpdateChecker = U
