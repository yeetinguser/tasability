local HttpService = game:GetService("HttpService")

local httprequest = request or http_request or (http and http.request)

local Discord = {}

local function getInviteCode(invite)
    if type(invite) ~= "string" then
        return nil, "invite must be a string"
    end

    local code = invite:match("discord%.gg/([^%s/?#]+)")
        or invite:match("discord%.com/invite/([^%s/?#]+)")
        or invite

    code = tostring(code):gsub("%s+", "")

    if code == "" then
        return nil, "invalid invite"
    end

    return code
end

local function getInviteData(code)
    if type(httprequest) ~= "function" then
        return nil, "HTTP request function unavailable"
    end

    local ok, response = pcall(function()
        return httprequest({
            Url = "https://ptb.discord.com/api/invites/" .. tostring(code),
            Method = "GET",
        })
    end)

    if not ok then
        return nil, "invite request failed: " .. tostring(response)
    end

    if type(response) ~= "table" then
        return nil, "invalid invite response"
    end

    local status = tonumber(response.StatusCode or response.Status)
    if status and status ~= 200 then
        return nil, "invite API status: " .. tostring(status)
    end

    if type(response.Body) ~= "string" or response.Body == "" then
        return nil, "empty invite API response"
    end

    local okDecode, data = pcall(function()
        return HttpService:JSONDecode(response.Body)
    end)

    if not okDecode or type(data) ~= "table" then
        return nil, "failed to decode invite data"
    end

    return data
end

function Discord.Join(invite)
    local code, err = getInviteCode(invite)
    if not code then
        return false, err
    end

    local inviteData
    inviteData, err = getInviteData(code)

    if not inviteData then
        return false, err
    end

    local finalCode = tostring(inviteData.code or code)

    local ok, response = pcall(function()
        return httprequest({
            Url = "http://127.0.0.1:6463/rpc?v=1",
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json",
                ["Origin"] = "https://ptb.discord.com",
            },
            Body = HttpService:JSONEncode({
                cmd = "INVITE_BROWSER",
                args = {
                    code = finalCode,
                },
                nonce = HttpService:GenerateGUID(false),
            }),
        })
    end)

    if not ok then
        return false, "Discord RPC failed: " .. tostring(response)
    end

    local status = type(response) == "table"
        and tonumber(response.StatusCode or response.Status)
        or nil

    if status and status ~= 200 then
        return false, "Discord RPC status: " .. tostring(status)
    end

    return true, "Discord invite request sent"
end

return Discord
