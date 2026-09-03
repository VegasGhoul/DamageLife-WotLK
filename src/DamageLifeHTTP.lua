-- DamageLife HTTP compatibility layer
-- The addon side never opens sockets itself. A host integration may provide a
-- high-level async GET bridge; otherwise the companion cache remains the path.
local H = {}
H.backend = nil
H.backendName = nil
H.backendAsync = false

local function safeCall(fn, ...)
    if type(fn) ~= "function" then return false, "function-unavailable" end
    local ok, a, b, c, d = pcall(fn, ...)
    if not ok then return false, tostring(a) end
    return true, a, b, c, d
end

local function finish(callback, body, code, headers, err)
    if type(callback) ~= "function" then return true end
    local ok, callErr = pcall(callback, body, code, headers, err)
    if not ok then return false, tostring(callErr) end
    return true
end

function H.SetBridge(getFunction)
    if type(getFunction) ~= "function" then
        H.backend, H.backendName, H.backendAsync = nil, nil, false
        return false
    end
    H.backend, H.backendName, H.backendAsync = getFunction, "external-bridge", true
    return true
end

function H.Get(url, callback)
    if type(url) ~= "string" or url == "" then
        return false, "invalid-url"
    end
    if not H.backend then
        local bridge = rawget(_G, "DamageLifeHTTPBridge")
        if type(bridge) == "function" then H.SetBridge(bridge) end
    end
    if not H.backend then
        if callback then finish(callback, nil, nil, nil, "no-http-backend") end
        return false, "no-http-backend"
    end
    local ok, a, b = safeCall(H.backend, url, callback)
    if not ok then return false, a end
    if a == false then return false, b or "request-failed" end
    return true
end

function H.GetBackendName() return H.backendName end
function H.IsAvailable() return H.backend ~= nil end
function H.IsAsync() return H.backendAsync == true end

_G.DamageLifeHTTP = H
