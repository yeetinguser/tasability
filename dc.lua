local HttpService = game:GetService("HttpService")
local httprequest = request or http_request or (http and http.request)

local DiscordInvite = "https://discord.gg/hJGAvDXmjj"

return function()
    if type(httprequest) ~= "function" then
        return false, "HTTP request unavailable"
    end

    local code = DiscordInvite:match("discord%.gg/([^%s/?#]+)")
        or DiscordInvite:match("discord%.com/invite/([^%s/?#]+)")

    if not code then
        return false, "Invalid Discord invite"
    end

    local ok, response = pcall(function()
        return httprequest({
            Url = "https://ptb.discord.com/api/invites/" .. code,
            Method = "GET"
        })
    end)

    if not ok then
        return false, "Invite request failed: " .. tostring(response)
    end

    local status = tonumber(response.StatusCode or response.Status)
    if status and status ~= 200 then
        return false, "Discord API status: " .. tostring(status)
    end

    local decodeOk, data = pcall(function()
        return HttpService:JSONDecode(response.Body)
    end)

    if not decodeOk or type(data) ~= "table" then
        return false, "Failed to decode Discord response"
    end

    local finalCode = tostring(data.code or code)

    local rpcOk, rpcResponse = pcall(function()
        return httprequest({
            Url = "http://127.0.0.1:6463/rpc?v=1",
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json",
                ["Origin"] = "https://ptb.discord.com"
            },
            Body = HttpService:JSONEncode({
                cmd = "INVITE_BROWSER",
                args = {
                    code = finalCode
                },
                nonce = HttpService:GenerateGUID(false)
            })
        })
    end)

    if not rpcOk then
        return false, "Discord RPC failed: " .. tostring(rpcResponse)
    end

    local rpcStatus = tonumber(rpcResponse.StatusCode or rpcResponse.Status)
    if rpcStatus and rpcStatus ~= 200 then
        return false, "Discord RPC status: " .. tostring(rpcStatus)
    end

    return true
end
