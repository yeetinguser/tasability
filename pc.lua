-- config
local TASConfig = {
    FPS = 120, -- Client FPS cap. This can be higher than the TAS recording/playback FPS.
    TASRecordingFPS = 60, -- TAS samples recorded per second. Client FPS can be higher. Playback uses this saved FPS.
    AllowClientObjectManipulation = true, -- Allow recording and playback of client objects (CO).
    CORecordingRadius = 250, -- Client-object recording radius in studs. 0 = unlimited. Only COs inside this radius are sampled.
    PlaybackInputs = true, -- Sets if you want replays to playback your inputs when playing them (AHK connection is required for mouse scroll playback)
    PlaybackMouseLocation = true, -- Sets if you want replays to move your mouse when playing them (glitchy when loading checkpoints)
    RoundDigits = 15, -- Rounds all numbers when writing, to greatly decrease file size (set to 50 to disable rounding)
    ReplayStartTime = 1, -- Number of seconds to wait before starting to read the replay
    FrameBacktrackCount = 1000, -- Number of frames to backtrack when frozen to see which keys are currently pressed. Increase as much as your computer can handle
    MinimumJSONFPS = 1/60, -- Lowest you want your FPS to go while encoding/decoding (higher = faster encoding/decoding, lower = better fps) 1/30: 30 fps, 1/60: 60 fps
    ReplayCodecTimeBudget = 0.003, -- Max seconds of codec work before yielding back to Roblox.
    BypassAntiExploit = false, -- If this is true games with anti cheat (like beans) will not kick you, but there is a chance animations will be broken

    -- Inputs that will not be recorded
    InputBlacklist = {
        ["Q"] = true; ["T"] = true; ["F"] = true; ["G"] = true; ["E"] = true;
        ["U"] = true; ["Z"] = true; ["R"] = true; ["V"] = true;
    },

    -- Color codes for the color code frame
    ColorCodes = {
        WaitingForInput = Color3.new(1,1,0);
        Recording = Color3.new(1,0,0);
        Reading = Color3.new(0,0,5,1);
        Idle = Color3.new(1,1,1);
        Frozen = Color3.new(0,1,1);
        None = Color3.new(0,0,0);
    },

    -- data roblox cursor xD
    Cursors = {
        ArrowFarCursor = {
            Icon = "rbxasset://textures/Cursors/KeyboardMouse/ArrowFarCursor.png";
            Size = UDim2.fromOffset(64,64);
            Offset = Vector2.new(4, 4);
        };
        MouseLockedCursor = {
            Icon = "rbxasset://textures/MouseLockedCursor.png";
            Size = UDim2.fromOffset(32,32);
            Offset = Vector2.new(-16,-16);
        };
    },

    Version = "V1.2.5",
    ReplayFileBeginning = "{\"Replay\":" ,
    ReplayFileEnding = "}",
    AHKConnectionFolderPath = "Replayability+_AHK",
    AHKConnectionRequestPath = "Replayability+_AHK/Request",
    TASCompressionLevel = 3, -- Save-only Zstd level. Lower = faster save, higher = smaller file. Playback is unaffected.
    FIRST_RECORD_FIX = "CO_READY_BEFORE_WRITE__KEEP_CO_ON_RESET__READ_FROM_DISK_AFTER_SAVE",
}

local TASServices = {
    UserInputService = game:GetService("UserInputService"), RunService = game:GetService("RunService"), HttpService = game:GetService("HttpService"),
    ContextActionService = game:GetService("ContextActionService"), GuiService = game:GetService("GuiService"), VirtualInputManager = game:GetService("VirtualInputManager"),
    Player = game.Players.LocalPlayer, Mouse = nil, random = math.random, min = math.min, max = math.max, floor = math.floor, ceil = math.ceil,
    PlayerModule = nil, ShiftLockBoundKeys = nil, ShiftLockEnabled = false, GuiInset = nil,
}
TASServices.Mouse = TASServices.Player:GetMouse()
TASServices.PlayerModule = TASServices.Player.PlayerScripts:WaitForChild("PlayerModule")
TASServices.ShiftLockBoundKeys = TASServices.PlayerModule:WaitForChild("CameraModule"):WaitForChild("MouseLockController"):WaitForChild("BoundKeys")
TASServices.GuiInset = TASServices.GuiService:GetGuiInset()
local TASPaths = {
    pathVisualsEnabled = false, pathLines = {}, pathStartText = nil, pathEndText = nil, ReplayNeedsReload = true, LastLoadedPath = nil,
    ExecutionTick = tick(), PlaceId = game.PlaceId, FolderPath = nil, ReplayPath = nil,
}
TASPaths.FolderPath = "Tasability\\"..tostring(TASPaths.PlaceId)
TASPaths.ReplayPath = nil -- No replay file is created automatically; choose/create one from Files.
local TASCharacter = {Character=nil, Humanoid=nil, RootPart=nil, DefaultGravity=nil, DefaultJumpPower=nil, DefaultWalkSpeed=nil, Resolution=nil, ConsoleMessage=print}
local TASRuntime = {
    Reading=false, Paused=false, Writing=false, Saving=false, AnimateDisabled=false, Checkpoints={}, RenderSteppedConnections={}, SteppedConnections={},
    PlaybackPressedKeys={}, ReplayTable={}, RecordingTable={}, RecordingFPSCapActive=false, RecordingReplayFPS=nil,
    ActiveReplayFPS=TASConfig.TASRecordingFPS, ReplaySourceFPS=TASConfig.TASRecordingFPS,
    ReplaySaveState={Version=0, Encoded=nil, EncodedVersion=-1}, SaveGeneration=0, PlaybackAccumulator=0, PlaybackSourcePosition=1,
    RecordingAccumulator=0, RecordingInterval=0, PlaybackInterval=0, ReplayRootWasAnchored=false, ReplayTableIndex=0, AnimationQueue={}, ForceAnimationSync=false, RunSpeed=0, ClimbSpeed=0,
    HumanoidStateQueue={}, InputBeganQueue={}, InputEndedQueue={}, Cursor=Instance.new("ImageLabel"), CursorIcon=nil, CursorSize=nil,
    CursorOffset=nil, Dead=false, CameraCFrame=workspace.CurrentCamera.CFrame, Pressed={}, IgnoreGameProcessed=false,
}
local TASFreeze = {
    Frozen=false, FreezeFrame=1, SeekDirection=0, SeekDirectionMultiplier=1, SeekAccumulator=0,
    ReplayCharacterCollisionStates=nil, ReplayAnimateScript=nil, ReplayAnimateScriptDisabled=nil, FrozenCameraFollowsReplay=false,
    FrozenMouseBehavior=nil, PendingRecordingStart=false, PendingReadingStart=false, COInitializationQueued=false,
    FrozenCameraType=nil, FrozenCameraBindName="TasabilityFrozenCamera", FrozenCharacterBindName="TasabilityFrozenCharacter", FrozenCameraCFrame=nil, FrozenHeldCO=false,
    ResumeCFrame=nil, ResumeVelocity=nil, ResumeRotVelocity=nil, ResumeHumanoidState=nil, ResumeAnimPose=nil, ResumeAnimSpeed=nil, ResumeShiftLockEnabled=nil, PhysicsOverrideActive=false,
    FrozenAnimTrack=nil, FrozenAnimName=nil, FrozenAnimTime=nil, FrozenAnimSpeed=nil,
}
local TASPause = {PausedCharacterCFrame=nil, PausedCameraCFrame=nil, PausedCameraType=nil, PausedCameraBindName="TasabilityPausedCamera", PendingRecordingFlush=false, CachedAnimateScript=nil, PlaybackWarmCache={}}
local function ClearPlaybackWarmCache()
    local processFreezeFrame = TASPause.PlaybackWarmCache.ProcessFreezeFrame
    table.clear(TASPause.PlaybackWarmCache)
    TASPause.PlaybackWarmCache.ProcessFreezeFrame = processFreezeFrame
end
local TASFunctions = {}
local TASAnimation = {pose="Standing", currentAnimSpeed=1.0, currentAnimName="idle", currentAnimTrack=nil}
local TASTracer = {TracerEnabled=false, TracerLines={}, TracerLandingLines={}, TRACER_STEPS=30, TRACER_LOOKAHEAD=0.5, TRACER_LANDING_SIZE=7, TRACER_LANDING_THICKNESS=2}
local TASUtilityFunctions = {}
-- Converting inputs
-- To add to this table, use https://docs.microsoft.com/en-us/windows/win32/inputdev/virtual-key-codes
local InputCodes = {
	["A"] = 0x41;
	["B"] = 0x42;
	["C"] = 0x43;
	["D"] = 0x44;
	["E"] = 0x45;
	["F"] = 0x46;
	["G"] = 0x47;
	["H"] = 0x48;
	["I"] = 0x49;
	["J"] = 0x4A;
	["K"] = 0x4B;
	["L"] = 0x4C;
	["M"] = 0x4D;
	["N"] = 0x4E;
	["O"] = 0x4F;
	["P"] = 0x50;
	["Q"] = 0x51;
	["R"] = 0x52;
	["S"] = 0x53;
	["T"] = 0x54;
	["U"] = 0x55;
	["V"] = 0x56;
	["W"] = 0x57;
	["X"] = 0x58;
	["Y"] = 0x59;
	["Z"] = 0x5A;
	["Space"] = 0x20;
	["LeftShift"] = 0x10;
	["RightShift"] = 0x10;
    ["Comma"] = 0xBC;
    ["Period"] = 0xBE
}

-- Compatibility
mouse1press = mouse1press or mouse1down
mouse2press = mouse2press or mouse2down
mouse1release = mouse1release or mouse1up
mouse2release = mouse2release or mouse2up
keypress = keypress or keydown
keyrelease = keyrelease or keyup

-- Variables used in Animate script

-- Other
local GUIParent = TASServices.Player:WaitForChild("PlayerGui")
local json
do -- Overwriting JSON
	json = (function()
																			--
																			-- json.lua
																			--
																			-- Copyright (c) 2020 rxi
																			--
																			-- Permission is hereby granted, free of charge, to any person obtaining a copy of
																			-- this software and associated documentation files (the "Software"), to deal in
																			-- the Software without restriction, including without limitation the rights to
																			-- use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
																			-- of the Software, and to permit persons to whom the Software is furnished to do
																			-- so, subject to the following conditions:
																			--
																			-- The above copyright notice and this permission notice shall be included in all
																			-- copies or substantial portions of the Software.
																			--
																			-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
																			-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
																			-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
																			-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
																			-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
																			-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
																			-- SOFTWARE.
																			--

																			local json = { _version = "0.1.2" }
																			
																			local t = tick()
																			local currentstr
																			local lasti
																			local function checkwait(i)
																				if tick() - t > TASConfig.MinimumJSONFPS then
																					lasti = lasti or i
																					if i >= lasti then
																						local Type = (type(currentstr) == "table" and "En") or (type(currentstr) == "string" and "De")
																						if Type then
																							TASCharacter.ConsoleMessage(Type.."coding... ("..tostring(i).."/"..tostring(#currentstr)..")")
																						end
																						game:GetService("RunService").Stepped:Wait()
																						t = tick()
																						lasti = i
																					end
																				end
																			end

																			-------------------------------------------------------------------------------
																			-- Encode
																			-------------------------------------------------------------------------------

																			

																			local encode

																			local escape_char_map = {
																				[ "\\" ] = "\\",
																				[ "\"" ] = "\"",
																				[ "\b" ] = "b",
																				[ "\f" ] = "f",
																				[ "\n" ] = "n",
																				[ "\r" ] = "r",
																				[ "\t" ] = "t",
																			}

																			local escape_char_map_inv = { [ "/" ] = "/" }
																			for k, v in pairs(escape_char_map) do
																				escape_char_map_inv[v] = k
																			end


																			local function escape_char(c)
																				return "\\" .. (escape_char_map[c] or string.format("u%04x", c:byte()))
																			end


																			local function encode_nil(val)
																				return "null"
																			end


																			local function encode_table(val, stack)
																				local res = {}
																				stack = stack or {}

																				-- Circular reference?
																				if stack[val] then error("circular reference") end

																				stack[val] = true

																				if rawget(val, 1) ~= nil or next(val) == nil then
																					-- Treat as array -- check keys are valid and it is not sparse
																					local n = 0
																					for k in pairs(val) do
																						if type(k) ~= "number" then
																							error("invalid table: mixed or invalid key types")
																						end
																						n = n + 1
																					end
																					if n ~= #val then
																						error("invalid table: sparse array")
																					end
																					-- Encode
																					for i, v in ipairs(val) do
																						checkwait(i)
																						res[#res + 1] = encode(v, stack)
																					end
																					stack[val] = nil
																					
																					return "[" .. table.concat(res, ",") .. "]"

																				else
																					-- Treat as an object
																					local i = 0
																					for k, v in pairs(val) do
																						i = i + 1
																						if type(k) ~= "string" then
																							error("invalid table: mixed or invalid key types")
																						end
																						checkwait(i)
																						res[#res + 1] = encode(k, stack) .. ":" .. encode(v, stack)
																					end
																					stack[val] = nil
																					
																					return "{" .. table.concat(res, ",") .. "}"
																				end
																			end


																			local function encode_string(val)
																				return '"' .. val:gsub('[%z\1-\31\\"]', escape_char) .. '"'
																			end


																			local function encode_number(val)
																				-- Check for NaN, -inf and inf
																				if val ~= val or val <= -math.huge or val >= math.huge then
																					error("unexpected number value '" .. tostring(val) .. "'")
																				end
																				return string.format("%.14g", val)
																			end


																			local type_func_map = {
																				[ "nil"     ] = encode_nil,
																				[ "table"   ] = encode_table,
																				[ "string"  ] = encode_string,
																				[ "number"  ] = encode_number,
																				[ "boolean" ] = tostring,
																			}


																			encode = function(val, stack)
																				local t = type(val)
																				local f = type_func_map[t]
																				if f then
																					t = tick()
																					return f(val, stack)
																				end
																				error("unexpected type '" .. t .. "'")
																			end


																			function json.encode(val)
																				currentstr = val
																				lasti = nil
																				return ( encode(val) )
																			end


																			-------------------------------------------------------------------------------
																			-- Decode
																			-------------------------------------------------------------------------------

																			local parse

																			local function create_set(...)
																				local res = {}
																				for i = 1, select("#", ...) do
																					res[ select(i, ...) ] = true
																				end
																				return res
																			end

																			local space_chars   = create_set(" ", "\t", "\r", "\n")
																			local delim_chars   = create_set(" ", "\t", "\r", "\n", "]", "}", ",")
																			local escape_chars  = create_set("\\", "/", '"', "b", "f", "n", "r", "t", "u")
																			local literals      = create_set("true", "false", "null")

																			local literal_map = {
																				[ "true"  ] = true,
																				[ "false" ] = false,
																				[ "null"  ] = nil,
																			}


																			local function next_char(str, idx, set, negate)
																				for i = idx, #str do
																					if set[str:sub(i, i)] ~= negate then
																						return i
																					end
																				end
																				return #str + 1
																			end


																			local function decode_error(str, idx, msg)
																				local line_count = 1
																				local col_count = 1
																				for i = 1, idx - 1 do
																					col_count = col_count + 1
																					if str:sub(i, i) == "\n" then
																						line_count = line_count + 1
																						col_count = 1
																					end
																				end
																				error( string.format("%s at line %d col %d", msg, line_count, col_count) )
																			end



																			local function codepoint_to_utf8(n)
																				-- http://scripts.sil.org/cms/scripts/page.php?site_id=nrsi&id=iws-appendixa
																				local f = math.floor
																				if n <= 0x7f then
																					return string.char(n)
																				elseif n <= 0x7ff then
																					return string.char(f(n / 64) + 192, n % 64 + 128)
																				elseif n <= 0xffff then
																					return string.char(f(n / 4096) + 224, f(n % 4096 / 64) + 128, n % 64 + 128)
																				elseif n <= 0x10ffff then
																					return string.char(f(n / 262144) + 240, f(n % 262144 / 4096) + 128,
																						f(n % 4096 / 64) + 128, n % 64 + 128)
																				end
																				error( string.format("invalid unicode codepoint '%x'", n) )
																			end


																			local function parse_unicode_escape(s)
																				local n1 = tonumber( s:sub(1, 4),  16 )
																				local n2 = tonumber( s:sub(7, 10), 16 )
																				-- Surrogate pair?
																				if n2 then
																					return codepoint_to_utf8((n1 - 0xd800) * 0x400 + (n2 - 0xdc00) + 0x10000)
																				else
																					return codepoint_to_utf8(n1)
																				end
																			end


																			local function parse_string(str, i)
																				local res = ""
																				local j = i + 1
																				local k = j

																				while j <= #str do
																					local x = str:byte(j)

																					if x < 32 then
																						decode_error(str, j, "control character in string")

																					elseif x == 92 then -- `\`: Escape
																						res = res .. str:sub(k, j - 1)
																						j = j + 1
																						local c = str:sub(j, j)
																						if c == "u" then
																							local hex = str:match("^[dD][89aAbB]%x%x\\u%x%x%x%x", j + 1)
																								or str:match("^%x%x%x%x", j + 1)
																								or decode_error(str, j - 1, "invalid unicode escape in string")
																							res = res .. parse_unicode_escape(hex)
																							j = j + #hex
																						else
																							if not escape_chars[c] then
																								decode_error(str, j - 1, "invalid escape char '" .. c .. "' in string")
																							end
																							res = res .. escape_char_map_inv[c]
																						end
																						k = j + 1

																					elseif x == 34 then -- `"`: End of string
																						res = res .. str:sub(k, j - 1)
																						return res, j + 1
																					end

																					j = j + 1
																					checkwait(i)
																				end

																				decode_error(str, i, "expected closing quote for string")
																			end


																			local function parse_number(str, i)
																				local x = next_char(str, i, delim_chars)
																				local s = str:sub(i, x - 1)
																				local n = tonumber(s)
																				if not n then
																					decode_error(str, i, "invalid number '" .. s .. "'")
																				end
																				checkwait(i)
																				return n, x
																			end


																			local function parse_literal(str, i)
																				local x = next_char(str, i, delim_chars)
																				local word = str:sub(i, x - 1)
																				if not literals[word] then
																					decode_error(str, i, "invalid literal '" .. word .. "'")
																				end
																				checkwait(i)
																				return literal_map[word], x
																			end


																			local function parse_array(str, i)
																				local res = {}
																				local n = 1
																				i = i + 1
																				while 1 do
																					local x
																					i = next_char(str, i, space_chars, true)
																					-- Empty / end of array?
																					if str:sub(i, i) == "]" then
																						i = i + 1
																						break
																					end
																					-- Read token
																					x, i = parse(str, i)
																					res[n] = x
																					n = n + 1
																					-- Next token
																					i = next_char(str, i, space_chars, true)
																					local chr = str:sub(i, i)
																					i = i + 1
																					checkwait(i)
																					if chr == "]" then break end
																					if chr ~= "," then decode_error(str, i, "expected ']' or ','") end
																				end
																				return res, i
																			end


																			local function parse_object(str, i)
																				local res = {}
																				i = i + 1
																				while 1 do
																					local key, val
																					i = next_char(str, i, space_chars, true)
																					-- Empty / end of object?
																					if str:sub(i, i) == "}" then
																						i = i + 1
																						break
																					end
																					-- Read key
																					if str:sub(i, i) ~= '"' then
																						decode_error(str, i, "expected string for key")
																					end
																					key, i = parse(str, i)
																					-- Read ':' delimiter
																					i = next_char(str, i, space_chars, true)
																					if str:sub(i, i) ~= ":" then
																						decode_error(str, i, "expected ':' after key")
																					end
																					i = next_char(str, i + 1, space_chars, true)
																					-- Read value
																					val, i = parse(str, i)
																					-- Set
																					res[key] = val
																					-- Next token
																					i = next_char(str, i, space_chars, true)
																					local chr = str:sub(i, i)
																					i = i + 1
																					--ConsoleMessage(tick() - t, 1/60)
																					checkwait(i)
																					if chr == "}" then break end
																					if chr ~= "," then decode_error(str, i, "expected '}' or ','") end
																				end
																				return res, i
																			end


																			local char_func_map = {
																				[ '"' ] = parse_string,
																				[ "0" ] = parse_number,
																				[ "1" ] = parse_number,
																				[ "2" ] = parse_number,
																				[ "3" ] = parse_number,
																				[ "4" ] = parse_number,
																				[ "5" ] = parse_number,
																				[ "6" ] = parse_number,
																				[ "7" ] = parse_number,
																				[ "8" ] = parse_number,
																				[ "9" ] = parse_number,
																				[ "-" ] = parse_number,
																				[ "t" ] = parse_literal,
																				[ "f" ] = parse_literal,
																				[ "n" ] = parse_literal,
																				[ "[" ] = parse_array,
																				[ "{" ] = parse_object,
																			}


																			parse = function(str, idx)
																				local chr = str:sub(idx, idx)
																				local f = char_func_map[chr]
																				if f then
																					return f(str, idx)
																				end
																				decode_error(str, idx, "unexpected character '" .. chr .. "'")
																			end


																			function json.decode(str)
																				t = tick()
																				currentstr = str
																				lasti = nil
																				if type(str) ~= "string" then
																					error("expected argument of type string, got " .. type(str))
																				end
																				local res, idx = parse(str, next_char(str, 1, space_chars, true))
																				idx = next_char(str, idx, space_chars, true)
																				if idx <= #str then
																					decode_error(str, idx, "trailing garbage")
																				end
																				return res
																			end


																			return json
	end)()
end

-- Functions
-- General Functions



local function clearTracerObjects()
    for _, line in pairs(TASTracer.TracerLines) do
        pcall(function() line:Remove() end)
    end
    for _, line in pairs(TASTracer.TracerLandingLines) do
        pcall(function() line:Remove() end)
    end
    TASTracer.TracerLines = {}
    TASTracer.TracerLandingLines = {}
end

local function ensureTracerLandingCross()
    while #TASTracer.TracerLandingLines < 2 do
        local ok, line = pcall(function()
            local l = Drawing.new("Line")
            l.Thickness = TASTracer.TRACER_LANDING_THICKNESS
            l.Visible = false
            return l
        end)
        if not ok then
            TASCharacter.ConsoleMessage("Tracer: failed to create landing marker")
            return false
        end
        table.insert(TASTracer.TracerLandingLines, line)
    end
    return true
end

local function updateTracer()
    if not TASTracer.TracerEnabled then
        clearTracerObjects()
        return
    end

    if not Drawing then
        TASCharacter.ConsoleMessage("Tracer: Drawing API not supported")
        TASTracer.TracerEnabled = false
        return
    end

    if not TASCharacter.RootPart or not TASCharacter.RootPart.Parent then return end

    local cam = workspace.CurrentCamera
    if not cam then return end

    local stepCount = math.max(1, math.floor(tonumber(TASTracer.TRACER_STEPS) or 30))
    local lookahead = math.max(0.01, tonumber(TASTracer.TRACER_LOOKAHEAD) or 0.5)
    local dt = lookahead / stepCount
    local gravity = Vector3.new(0, -workspace.Gravity, 0)

    while #TASTracer.TracerLines < stepCount do
        local ok, line = pcall(function()
            local l = Drawing.new("Line")
            l.Thickness = 2
            l.Visible = false
            return l
        end)
        if ok then
            table.insert(TASTracer.TracerLines, line)
        else
            TASCharacter.ConsoleMessage("Tracer: Drawing.new failed")
            return
        end
    end

    if not ensureTracerLandingCross() then
        for _, line in ipairs(TASTracer.TracerLandingLines) do
            line.Visible = false
        end
    end

    local points = table.create(stepCount + 1)
    local pos = TASCharacter.RootPart.Position
    local vel = TASCharacter.RootPart.AssemblyLinearVelocity
    points[1] = pos

    local state = TASCharacter.Humanoid and TASCharacter.Humanoid:GetState()
    local onGround = state == Enum.HumanoidStateType.Running
        or state == Enum.HumanoidStateType.RunningNoPhysics
        or state == Enum.HumanoidStateType.Landed

    local landingPosition = nil
    local landingSegment = stepCount

    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = {TASCharacter.Character}
    rayParams.IgnoreWater = true

    for i = 1, stepCount do
        if onGround then
            pos = pos + vel * dt
        else
            vel = vel + gravity * dt
            pos = pos + vel * dt

            -- Stop simulation at the FIRST surface hit.
            local from = points[i]
            local delta = pos - from
            if delta.Magnitude > 0.001 then
                local hit = workspace:Raycast(from, delta, rayParams)
                if hit and hit.Instance and hit.Instance.CanCollide then
                    landingPosition = hit.Position
                    points[i + 1] = hit.Position
                    landingSegment = i
                    break
                end
            end
        end

        points[i + 1] = pos
    end

    -- If no collision happened inside the lookahead, optionally project the
    -- final point down and use that as the landing marker only. The visible
    -- trajectory itself still ends at the final simulated point.
    if not landingPosition and not onGround then
        local finalPoint = points[#points]
        local floorHit = workspace:Raycast(
            finalPoint + Vector3.new(0, 2, 0),
            Vector3.new(0, -2048, 0),
            rayParams
        )
        if floorHit and floorHit.Instance and floorHit.Instance.CanCollide then
            landingPosition = floorHit.Position
        end
    end

    -- Hide every unused segment first.
    for i = landingSegment + 1, #TASTracer.TracerLines do
        TASTracer.TracerLines[i].Visible = false
    end

    local visibleSegments = math.min(landingSegment, #points - 1)
    local denom = math.max(1, visibleSegments - 1)

    for i = 1, visibleSegments do
        local line = TASTracer.TracerLines[i]
        if not line then continue end

        local s1, on1 = cam:WorldToViewportPoint(points[i])
        local s2, on2 = cam:WorldToViewportPoint(points[i + 1])

        if on1 and on2 then
            line.From = Vector2.new(s1.X, s1.Y)
            line.To = Vector2.new(s2.X, s2.Y)

            local t = (i - 1) / denom
            line.Color = Color3.fromRGB(
                math.floor(70 + 185 * t),
                math.floor(245 - 170 * t),
                70
            )
            line.Visible = true
        else
            line.Visible = false
        end
    end

    -- Landing cross.
    if landingPosition and #TASTracer.TracerLandingLines >= 2 then
        local center, visible = cam:WorldToViewportPoint(landingPosition + Vector3.new(0, 0.08, 0))
        if visible then
            local p = Vector2.new(center.X, center.Y)

            TASTracer.TracerLandingLines[1].From = p + Vector2.new(-TASTracer.TRACER_LANDING_SIZE, -TASTracer.TRACER_LANDING_SIZE)
            TASTracer.TracerLandingLines[1].To = p + Vector2.new(TASTracer.TRACER_LANDING_SIZE, TASTracer.TRACER_LANDING_SIZE)
            TASTracer.TracerLandingLines[2].From = p + Vector2.new(-TASTracer.TRACER_LANDING_SIZE, TASTracer.TRACER_LANDING_SIZE)
            TASTracer.TracerLandingLines[2].To = p + Vector2.new(TASTracer.TRACER_LANDING_SIZE, -TASTracer.TRACER_LANDING_SIZE)

            TASTracer.TracerLandingLines[1].Color = Color3.fromRGB(255, 255, 255)
            TASTracer.TracerLandingLines[2].Color = Color3.fromRGB(255, 255, 255)
            TASTracer.TracerLandingLines[1].Thickness = TASTracer.TRACER_LANDING_THICKNESS
            TASTracer.TracerLandingLines[2].Thickness = TASTracer.TRACER_LANDING_THICKNESS
            TASTracer.TracerLandingLines[1].Visible = true
            TASTracer.TracerLandingLines[2].Visible = true
        else
            TASTracer.TracerLandingLines[1].Visible = false
            TASTracer.TracerLandingLines[2].Visible = false
        end
    else
        if TASTracer.TracerLandingLines[1] then TASTracer.TracerLandingLines[1].Visible = false end
        if TASTracer.TracerLandingLines[2] then TASTracer.TracerLandingLines[2].Visible = false end
    end
end

-- Hook into existing RenderStepped connections
TASRuntime.RenderSteppedConnections.GhostAndTracer = function()
    if TASTracer.TracerEnabled then
        updateTracer()
    elseif #TASTracer.TracerLines > 0 or #TASTracer.TracerLandingLines > 0 then
        clearTracerObjects()
    end
end


-- Fast conversion functions for better performance
local function FastTableToCFrame(t)
	return CFrame.new(t[1], t[2], t[3], t[4], t[5], t[6], t[7], t[8], t[9], t[10], t[11], t[12])
end

local function FastTableToVector3(t)
	return Vector3.new(t[1], t[2], t[3])
end

local function FastTableToVector2(t)
	return Vector2.new(t[1], t[2])
end
do
	TASUtilityFunctions.RandomString = function()
		local str = ""
		for _ = 1, TASServices.random(1, 20) do
			local t = TASServices.random(1, 3)
			if t == 1 then
				str = str .. string.char(TASServices.random(97, 122))
			elseif t == 2 then
				str = str .. string.char(TASServices.random(65, 90))
			else
				str = str .. string.char(TASServices.random(48, 57))
			end
		end
		return str
	end
	TASUtilityFunctions.RoundNumber = function(Number,Digits)
		local Mult = 10^TASServices.max(tonumber(Digits) or 0,0)
		return TASServices.floor(Number*Mult+0.5)/Mult
	end
	TASUtilityFunctions.Vector3ToTable = function(V3)
		return {V3.X,V3.Y,V3.Z}
	end
	TASUtilityFunctions.TableToVector3 = function(Table)
		return Vector3.new(Table[1], Table[2], Table[3])
	end
	Vector2ToTable = function(V2)
		return {V2.X,V2.Y}
	end
	TableToVector2 = function(Table)
		return Vector2.new(Table[1], Table[2])
	end
	TASUtilityFunctions.CFrameToTable = function(CF)
		return {CF:GetComponents()}
	end
	TASUtilityFunctions.TableToCFrame = function(Table)
		return CFrame.new(Table[1], Table[2], Table[3], Table[4], Table[5], Table[6], Table[7], Table[8], Table[9], Table[10], Table[11], Table[12])
	end
	RoundTable = function(Table,Digits)
		local RoundedTable = {}
		local mult = 10^TASServices.max(tonumber(Digits) or 0, 0)
		if mult == 1 then
			for i = 1, #Table do RoundedTable[i] = Table[i] end
		else
			for i = 1, #Table do
				local Number = Table[i]
				RoundedTable[i] = TASServices.floor(Number * mult + 0.5) / mult
			end
		end
		return RoundedTable
	end
	TASUtilityFunctions.FindListIndex = function(Table,Search)
		for Index,Value in pairs(Table) do
			if Value == Search then
				return Index
			end
		end
	end
	TASUtilityFunctions.WaitForInput = function()
		local KeyPressed = Instance.new("BindableEvent")
		local InputBeganConnection
		InputBeganConnection = TASServices.UserInputService.InputBegan:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.Keyboard then
				TASServices.RunService.RenderStepped:Wait()
				KeyPressed:Fire()
			end
		end)
		KeyPressed.Event:Wait()
		InputBeganConnection:Disconnect()
		KeyPressed:Destroy()
	end
end

local function ReleaseAllPlaybackKeys()
    for _, Code in pairs(TASRuntime.PlaybackPressedKeys) do
        if Code == "b1" then mouse1release()
        elseif Code == "b2" then mouse2release()
        elseif type(Code) == "number" then keyrelease(Code)
        end
    end
    TASRuntime.PlaybackPressedKeys = {}
end

local function BeginPlaybackPause()
    if not TASRuntime.Reading then return end

    ReleaseAllPlaybackKeys()
    TASRuntime.PlaybackAccumulator = 0

    if TASCharacter.Character and TASCharacter.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = TASCharacter.Character.HumanoidRootPart
        TASPause.PausedCharacterCFrame = hrp.CFrame
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
        hrp.Velocity = Vector3.zero
        hrp.RotVelocity = Vector3.zero
    else
        TASPause.PausedCharacterCFrame = nil
    end

    local cam = workspace.CurrentCamera
    if cam then
        TASPause.PausedCameraCFrame = cam.CFrame
        TASPause.PausedCameraType = cam.CameraType
        cam.CameraType = Enum.CameraType.Scriptable
    else
        TASPause.PausedCameraCFrame = nil
        TASPause.PausedCameraType = nil
    end

    pcall(function()
        TASServices.RunService:UnbindFromRenderStep(TASPause.PausedCameraBindName)
        TASServices.RunService:BindToRenderStep(TASPause.PausedCameraBindName, Enum.RenderPriority.Camera.Value + 10, function()
            if not TASRuntime.Paused or not TASRuntime.Reading then return end
            local currentCam = workspace.CurrentCamera
            if currentCam and TASPause.PausedCameraCFrame then
                currentCam.CameraType = Enum.CameraType.Scriptable
                currentCam.CFrame = TASPause.PausedCameraCFrame
            end
        end)
    end)
end

local function HoldPlaybackPausedState()
    if not TASRuntime.Reading or not TASRuntime.Paused then return end

    if TASCharacter.Character and TASCharacter.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = TASCharacter.Character.HumanoidRootPart
        if TASPause.PausedCharacterCFrame then
            hrp.CFrame = TASPause.PausedCharacterCFrame
        end
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
        hrp.Velocity = Vector3.zero
        hrp.RotVelocity = Vector3.zero
        if TASCharacter.Humanoid then
            TASCharacter.Humanoid.PlatformStand = true
        end
    end

    local cam = workspace.CurrentCamera
    if cam and TASPause.PausedCameraCFrame then
        cam.CameraType = Enum.CameraType.Scriptable
        cam.CFrame = TASPause.PausedCameraCFrame
    end
end

local function EndPlaybackPause()
    pcall(function()
        TASServices.RunService:UnbindFromRenderStep(TASPause.PausedCameraBindName)
    end)

    local cam = workspace.CurrentCamera
    if cam and TASPause.PausedCameraType then
        cam.CameraType = TASPause.PausedCameraType
    end

    TASPause.PausedCharacterCFrame = nil
    TASPause.PausedCameraCFrame = nil
    TASPause.PausedCameraType = nil
end



local MainFrame
local KeyboardOverlayThemes
local currentTheme
local StatusPill

-- Used by the delayed settings watcher too, so it must live outside the GUI-local scope.
local function _tasKeyName(v)
    if typeof(v) == "EnumItem" then
        return v.Name
    end
    return tostring(v or "Unknown")
end

-- ── Services ─────────────────────────────────────────────────────────────────
local function __BuildGUI() -- GUI scope: isolate GUI locals in their own function
TweenService = game:GetService("TweenService")

-- ── Font ─────────────────────────────────────────────────────────────────────
UIFont = Font.fromEnum(Enum.Font.Code)
UIFontBold = Font.fromEnum(Enum.Font.GothamBold)
pcall(function()
    UIFont = Font.fromEnum(Enum.Font.GothamMedium)
    UIFontBold = Font.fromEnum(Enum.Font.GothamBold)
end)

-- ── Utilities ────────────────────────────────────────────────────────────────
function tw(obj, props, dur, style)
    TweenService:Create(
        obj,
        TweenInfo.new(dur or 0.22, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        props
    ):Play()
end

function mk(cls, props)
    local inst = Instance.new(cls)
    for k, v in pairs(props) do inst[k] = v end
    return inst
end

-- ══════════════════════════════════════════════════════════════════════════════
--  THEME SYSTEM
-- ══════════════════════════════════════════════════════════════════════════════

ThemeBindings = {} -- {inst, property, themeKey}

Theme = {
    -- Layered backgrounds (deep → surface)
    bg_deep     = Color3.fromRGB(10, 10, 14),
    bg_window   = Color3.fromRGB(15, 15, 21),
    bg_inline   = Color3.fromRGB(21, 21, 28),
    bg_panel    = Color3.fromRGB(28, 28, 35),
    bg_element  = Color3.fromRGB(35, 35, 42),
    bg_hover    = Color3.fromRGB(44, 44, 54),

    -- Accent
    accent      = Color3.fromRGB(100, 175, 255),
    accent_dim  = Color3.fromRGB(30, 60, 100),
    accent_glow = Color3.fromRGB(75, 145, 225),

    -- Borders (the layered system from )
    border      = Color3.fromRGB(8, 8, 12),    -- innermost, dark
    outline     = Color3.fromRGB(30, 30, 40),   -- outer stroke

    -- Text
    txt         = Color3.fromRGB(215, 215, 228),
    txt_muted   = Color3.fromRGB(115, 115, 138),
    txt_dim     = Color3.fromRGB(55, 55, 70),
    txt_shadow  = Color3.fromRGB(0, 0, 0),

    -- Status
    red    = Color3.fromRGB(220, 60, 60),
    green  = Color3.fromRGB(60, 220, 100),
    cyan   = Color3.fromRGB(60, 200, 220),
    yellow = Color3.fromRGB(220, 200, 60),
}

ThemePresets = {
    ["Midnight Blue"] = {
        accent = Color3.fromRGB(100, 175, 255), accent_dim = Color3.fromRGB(30, 60, 100),
        accent_glow = Color3.fromRGB(75, 145, 225),
        bg_deep = Color3.fromRGB(10, 10, 14), bg_window = Color3.fromRGB(15, 15, 21),
        bg_inline = Color3.fromRGB(21, 21, 28), bg_panel = Color3.fromRGB(28, 28, 35),
        bg_element = Color3.fromRGB(35, 35, 42), border = Color3.fromRGB(8, 8, 12),
        outline = Color3.fromRGB(30, 30, 40),
    },
    ["Neon Green"] = {
        accent = Color3.fromRGB(80, 255, 120), accent_dim = Color3.fromRGB(25, 80, 40),
        accent_glow = Color3.fromRGB(60, 200, 90),
        bg_deep = Color3.fromRGB(8, 10, 8), bg_window = Color3.fromRGB(12, 16, 12),
        bg_inline = Color3.fromRGB(18, 22, 18), bg_panel = Color3.fromRGB(24, 30, 24),
        bg_element = Color3.fromRGB(30, 38, 30), border = Color3.fromRGB(6, 10, 6),
        outline = Color3.fromRGB(28, 42, 28),
    },
    ["Blood Red"] = {
        accent = Color3.fromRGB(255, 50, 50), accent_dim = Color3.fromRGB(85, 20, 20),
        accent_glow = Color3.fromRGB(200, 45, 45),
        bg_deep = Color3.fromRGB(12, 8, 8), bg_window = Color3.fromRGB(18, 12, 12),
        bg_inline = Color3.fromRGB(26, 16, 16), bg_panel = Color3.fromRGB(34, 20, 20),
        bg_element = Color3.fromRGB(42, 26, 26), border = Color3.fromRGB(10, 6, 6),
        outline = Color3.fromRGB(45, 25, 25),
    },
    ["Purple Haze"] = {
        accent = Color3.fromRGB(180, 100, 255), accent_dim = Color3.fromRGB(55, 28, 90),
        accent_glow = Color3.fromRGB(145, 75, 215),
        bg_deep = Color3.fromRGB(11, 9, 16), bg_window = Color3.fromRGB(17, 13, 24),
        bg_inline = Color3.fromRGB(24, 18, 34), bg_panel = Color3.fromRGB(32, 24, 44),
        bg_element = Color3.fromRGB(40, 30, 54), border = Color3.fromRGB(9, 7, 14),
        outline = Color3.fromRGB(38, 28, 55),
    },
    ["Teal"] = {
        accent = Color3.fromRGB(0, 210, 180), accent_dim = Color3.fromRGB(0, 65, 55),
        accent_glow = Color3.fromRGB(0, 170, 140),
        bg_deep = Color3.fromRGB(7, 11, 11), bg_window = Color3.fromRGB(11, 17, 17),
        bg_inline = Color3.fromRGB(17, 24, 24), bg_panel = Color3.fromRGB(22, 32, 32),
        bg_element = Color3.fromRGB(28, 40, 40), border = Color3.fromRGB(5, 9, 9),
        outline = Color3.fromRGB(24, 42, 40),
    },
    ["Gold"] = {
        accent = Color3.fromRGB(255, 200, 60), accent_dim = Color3.fromRGB(90, 70, 18),
        accent_glow = Color3.fromRGB(215, 165, 45),
        bg_deep = Color3.fromRGB(13, 11, 7), bg_window = Color3.fromRGB(19, 17, 11),
        bg_inline = Color3.fromRGB(27, 23, 15), bg_panel = Color3.fromRGB(35, 29, 19),
        bg_element = Color3.fromRGB(43, 35, 23), border = Color3.fromRGB(10, 8, 5),
        outline = Color3.fromRGB(48, 38, 20),
    },
    ["Monochrome"] = {
        accent = Color3.fromRGB(200, 200, 200), accent_dim = Color3.fromRGB(55, 55, 55),
        accent_glow = Color3.fromRGB(160, 160, 160),
        bg_deep = Color3.fromRGB(9, 9, 9), bg_window = Color3.fromRGB(15, 15, 15),
        bg_inline = Color3.fromRGB(22, 22, 22), bg_panel = Color3.fromRGB(30, 30, 30),
        bg_element = Color3.fromRGB(38, 38, 38), border = Color3.fromRGB(6, 6, 6),
        outline = Color3.fromRGB(35, 35, 35),
    },
}

function applyTheme(inst, prop, key)
    inst[prop] = Theme[key]
    table.insert(ThemeBindings, {inst, prop, key})
end

function refreshAllTheme()
    for _, b in ipairs(ThemeBindings) do
        if b[1] and b[1].Parent then
            pcall(function() b[1][b[2]] = Theme[b[3]] end)
        end
    end
end

function setThemePreset(name)
    local p = ThemePresets[name]
    if not p then return end
    for k, v in pairs(p) do Theme[k] = v end
    refreshAllTheme()
end

StatsHudEnabled = false
StatsHudGui = nil
 
function createStatsHud()
    if StatsHudGui then StatsHudGui:Destroy() end
 
    local gui = Instance.new("ScreenGui")
    gui.Name = "TAS_StatsHud"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 9998
    gui.IgnoreGuiInset = true
    gui.Parent = TASServices.Player.PlayerGui
 
    -- Main frame
    local frame = Instance.new("Frame")
    frame.Name = "StatsFrame"
    frame.Size = UDim2.new(0, 290, 0, 310)
    frame.Position = UDim2.new(0, 10, 1, -320)
    frame.BackgroundColor3 = Theme.bg_deep
    frame.BorderSizePixel = 2
    frame.BorderColor3 = Theme.border
    frame.Parent = gui
 
    -- Outline stroke
    local stroke = Instance.new("UIStroke")
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.LineJoinMode = Enum.LineJoinMode.Miter
    stroke.Color = Theme.outline
    stroke.Thickness = 1
    stroke.Parent = frame
 
    -- Accent line at top
    local accentLine = Instance.new("Frame")
    accentLine.Size = UDim2.new(1, 0, 0, 2)
    accentLine.Position = UDim2.new(0, 0, 0, 0)
    accentLine.BackgroundColor3 = Theme.accent
    accentLine.BorderSizePixel = 0
    accentLine.ZIndex = 3
    accentLine.Parent = frame
 
    local accentGrad = Instance.new("UIGradient")
    accentGrad.Rotation = 90
    accentGrad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(65, 65, 65)),
    }
    accentGrad.Parent = accentLine
 
    -- Title
    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1, 0, 0, 18)
    titleLbl.Position = UDim2.new(0, 8, 0, 4)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = "STATS HUD"
    titleLbl.TextColor3 = Theme.accent
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextSize = 11
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Parent = frame
 
    local titleShadow = Instance.new("UIStroke")
    titleShadow.LineJoinMode = Enum.LineJoinMode.Miter
    titleShadow.Color = Theme.txt_shadow
    titleShadow.Parent = titleLbl
 
    -- Separator below title
    local sep = Instance.new("Frame")
    sep.Size = UDim2.new(1, -16, 0, 1)
    sep.Position = UDim2.new(0, 8, 0, 22)
    sep.BackgroundColor3 = Theme.outline
    sep.BorderSizePixel = 0
    sep.Parent = frame
 
    -- Content area
    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -16, 1, -30)
    content.Position = UDim2.new(0, 8, 0, 26)
    content.BackgroundTransparency = 1
    content.BorderSizePixel = 0
    content.Parent = frame
 
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 2)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = content
 
    -- Auto-resize
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        frame.Size = UDim2.new(0, 290, 0, layout.AbsoluteContentSize.Y + 34)
        frame.Position = UDim2.new(0, 10, 1, -(layout.AbsoluteContentSize.Y + 44))
    end)

    -- Collect themed instances for live sync
    local themedInstances = {
        {frame,      "BackgroundColor3", "bg_deep"},
        {frame,      "BorderColor3",     "border"},
        {stroke,     "Color",            "outline"},
        {accentLine, "BackgroundColor3", "accent"},
        {titleLbl,   "TextColor3",       "accent"},
        {titleShadow,"Color",            "txt_shadow"},
        {sep,        "BackgroundColor3", "outline"},
    }

    -- Track all header labels and dividers for sync
    local headerLabels = {}
    local dividers = {}
    local bodyLabels = {}

    -- ── Label factory ─────────────────────────────────────────────
    local function makeHeader(text)
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 0, 16)
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.TextColor3 = Theme.accent
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 10
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = content
        local s = Instance.new("UIStroke")
        s.LineJoinMode = Enum.LineJoinMode.Miter
        s.Color = Theme.txt_shadow
        s.Parent = lbl
        table.insert(headerLabels, lbl)
        table.insert(themedInstances, {lbl, "TextColor3", "accent"})
        table.insert(themedInstances, {s,   "Color",      "txt_shadow"})
        return lbl
    end
 
    local function makeLabel(name, defaultText)
        local lbl = Instance.new("TextLabel")
        lbl.Name = name
        lbl.Size = UDim2.new(1, 0, 0, 15)
        lbl.BackgroundTransparency = 1
        lbl.Text = defaultText
        lbl.RichText = true
        lbl.TextColor3 = Theme.txt
        lbl.Font = Enum.Font.GothamMedium
        lbl.TextSize = 12
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = content
        local s = Instance.new("UIStroke")
        s.LineJoinMode = Enum.LineJoinMode.Miter
        s.Color = Theme.txt_shadow
        s.Parent = lbl
        table.insert(bodyLabels, lbl)
        table.insert(themedInstances, {lbl, "TextColor3", "txt"})
        table.insert(themedInstances, {s,   "Color",      "txt_shadow"})
        return lbl
    end
 
    local function makeDivider()
        local div = Instance.new("Frame")
        div.Size = UDim2.new(1, 0, 0, 1)
        div.BackgroundColor3 = Theme.outline
        div.BackgroundTransparency = 0.5
        div.BorderSizePixel = 0
        div.Parent = content
        table.insert(dividers, div)
        table.insert(themedInstances, {div, "BackgroundColor3", "outline"})
    end
 
    -- ── Build labels ─────────────────────────────────────────────
    makeHeader("POSITION")
    local posX   = makeLabel("PosX",   "X: 0.000")
    local posY   = makeLabel("PosY",   "Y: 0.000")
    local posZ   = makeLabel("PosZ",   "Z: 0.000")
    makeDivider()
    makeHeader("VELOCITY")
    local velX   = makeLabel("VelX",   "X: 0.000")
    local velY   = makeLabel("VelY",   "Y: 0.000")
    local velZ   = makeLabel("VelZ",   "Z: 0.000")
    local velMag = makeLabel("VelMag", "Magnitude: 0.000")
    makeDivider()
    makeHeader("ROTATION")
    local rotX   = makeLabel("RotX",   "Pitch: 0.00°")
    local rotY   = makeLabel("RotY",   "Yaw:   0.00°")
    local rotZ   = makeLabel("RotZ",   "Roll:  0.00°")
    makeDivider()
    makeHeader("CHARACTER")
    local stateLabel = makeLabel("State", "State: None")
    local floorLabel = makeLabel("Floor", "Floor: None")
    local jumpLabel  = makeLabel("Jump",  "JumpPower: 50")
    local wsLabel    = makeLabel("WS",    "WalkSpeed: 16")
    local gravLabel  = makeLabel("Grav",  "Gravity: 196.2")
    makeDivider()
    makeHeader("REPLAY")
    local frameLabel = makeLabel("Frame", "Frame: 0 / 0")
    local timeLabel  = makeLabel("Time",  "Time:  0.00s")
    local zoomLabel  = makeLabel("Zoom",  "Zoom:  0.00")
    makeDivider()
    makeHeader("CSYNC")
    local coPartLabel  = makeLabel("COParts", "Tracked: 0")
    local coFrameLabel = makeLabel("COState", "CO State: idle")
 
    -- ── Update loop ──────────────────────────────────────────────
    local hudAccumulator = 0
    local updateConn = TASServices.RunService.RenderStepped:Connect(function(dt)
        if not StatsHudEnabled or not StatsHudGui then return end
        if not TASCharacter.RootPart or not TASCharacter.Humanoid then return end
        hudAccumulator = hudAccumulator + (dt or 0)
        if hudAccumulator < (1 / 15) then return end
        hudAccumulator = 0
 
        local pos = TASCharacter.RootPart.Position
        posX.Text = string.format("X: <font color='#ff8080'>%.4f</font>", pos.X)
        posY.Text = string.format("Y: <font color='#80ff80'>%.4f</font>", pos.Y)
        posZ.Text = string.format("Z: <font color='#8080ff'>%.4f</font>", pos.Z)
 
        local vel = TASCharacter.RootPart.Velocity
        velX.Text   = string.format("X: <font color='#ff8080'>%.4f</font>", vel.X)
        velY.Text   = string.format("Y: <font color='#80ff80'>%.4f</font>", vel.Y)
        velZ.Text   = string.format("Z: <font color='#8080ff'>%.4f</font>", vel.Z)
        velMag.Text = string.format("Magnitude: <font color='#ffdc50'>%.4f</font>", vel.Magnitude)
 
        local rx, ry, rz = TASCharacter.RootPart.CFrame:ToOrientation()
        rotX.Text = string.format("Pitch: <font color='#ff8080'>%.2f°</font>", math.deg(rx))
        rotY.Text = string.format("Yaw:   <font color='#80ff80'>%.2f°</font>", math.deg(ry))
        rotZ.Text = string.format("Roll:  <font color='#8080ff'>%.2f°</font>", math.deg(rz))
 
        local stateStr = tostring(TASCharacter.Humanoid:GetState()):gsub("Enum.HumanoidStateType.", "")
        local sc = "#ffffff"
        if stateStr == "Jumping" or stateStr == "Freefall" then sc = "#80ff80"
        elseif stateStr == "Running" then sc = "#ffdc50"
        elseif stateStr == "Climbing" then sc = "#ff9650"
        elseif stateStr == "Dead" then sc = "#ff5050" end
        stateLabel.Text = string.format("State: <font color='%s'>%s</font>", sc, stateStr)
 
        local floorMat = tostring(TASCharacter.Humanoid.FloorMaterial):gsub("Enum.Material.", "")
        floorLabel.Text = string.format("Floor: <font color='#aaaaff'>%s</font>", floorMat)
        jumpLabel.Text  = string.format("JumpPower: <font color='#c8c8ff'>%.1f</font>", TASCharacter.Humanoid.JumpPower)
        wsLabel.Text    = string.format("WalkSpeed: <font color='#c8c8ff'>%.1f</font>", TASCharacter.Humanoid.WalkSpeed)
        gravLabel.Text  = string.format("Gravity: <font color='#c8c8ff'>%.2f</font>", workspace.Gravity)
 
        local totalFrames = #TASRuntime.ReplayTable
        local cf = TASFreeze.Frozen and TASUtilityFunctions.RoundNumber(TASFreeze.FreezeFrame, 0) or (TASRuntime.Reading and TASRuntime.ReplayTableIndex or 0)
        frameLabel.Text = string.format("Frame: <font color='#64afff'>%d / %d</font>", cf, totalFrames)
        timeLabel.Text  = string.format("Time:  <font color='#64afff'>%.2fs</font>", cf / math.max(TASRuntime.ReplaySourceFPS or TASConfig.TASRecordingFPS or 1, 1))
 
        local zoom = TASFunctions.GetZoom()
        zoomLabel.Text = string.format("Zoom:  <font color='#64afff'>%.2f</font>", zoom)
 
        -- CSync info
        local partCount = (CO and CO.GetPartCount) and CO.GetPartCount() or 0
        coPartLabel.Text = string.format("Tracked: <font color='#64afff'>%d</font> parts", partCount)
        local coStatus = "idle"
        if TASRuntime.Writing then coStatus = "recording"
        elseif TASRuntime.Reading then coStatus = "playing"
        elseif TASFreeze.Frozen then coStatus = "frozen" end
        coFrameLabel.Text = string.format("CO State: <font color='#64afff'>%s</font>", coStatus)
    end)
 
    getgenv().StatsHudConnection = updateConn

    -- ── Theme sync ───────────────────────────────────────────────
    -- Re-apply all themed properties whenever refreshAllTheme() runs.
    -- We hook into ThemeBindings by registering our instances directly.
    for _, entry in ipairs(themedInstances) do
        local inst, prop, key = entry[1], entry[2], entry[3]
        table.insert(ThemeBindings, {inst, prop, key})
    end

    StatsHudGui = gui
    TASCharacter.ConsoleMessage("Stats HUD enabled")
end
 
function destroyStatsHud()
    if getgenv().StatsHudConnection then
        getgenv().StatsHudConnection:Disconnect()
        getgenv().StatsHudConnection = nil
    end
    if StatsHudGui then
        -- Remove stale HUD entries from ThemeBindings to avoid dead-instance buildup
        local alive = {}
        for _, b in ipairs(ThemeBindings) do
            if b[1] and b[1].Parent then
                table.insert(alive, b)
            end
        end
        ThemeBindings = alive
        StatsHudGui:Destroy()
        StatsHudGui = nil
    end
    TASCharacter.ConsoleMessage("Stats HUD disabled")
end
-- Global user settings shared across all places. Replay files remain per-place.
TASSettingsRootFolder = "Tasability"
TasSettingsPath = TASSettingsRootFolder .. "\\Settings.json"
TASLegacySettingsPath = TASPaths.FolderPath .. "\\Settings.json"
TasSettings = rawget(_G, "TasSettings") or {}
_G.TasSettings = TasSettings

function _tasApplySavedThemeAccent(cfg)
    if type(cfg) ~= "table" then return end
    if cfg.ThemePreset and ThemePresets[cfg.ThemePreset] then
        setThemePreset(cfg.ThemePreset)
    end
    if type(cfg.AccentHex) == "string" and cfg.AccentHex ~= "" then
        local ok, col = pcall(function() return Color3.fromHex(cfg.AccentHex) end)
        if ok and col then
            Theme.accent = col
            Theme.accent_dim = Color3.fromRGB(math.floor(col.R*255*0.30), math.floor(col.G*255*0.30), math.floor(col.B*255*0.30))
            Theme.accent_glow = Color3.fromRGB(math.floor(col.R*255*0.80), math.floor(col.G*255*0.80), math.floor(col.B*255*0.80))
            refreshAllTheme()
        end
    end
end

function LoadTasSettings()
    local sourcePath = TasSettingsPath
    if not isfile(sourcePath) and isfile(TASLegacySettingsPath) then
        -- One-time migration from the old per-place Settings.json into the
        -- global Tasability\Settings.json location.
        sourcePath = TASLegacySettingsPath
        pcall(function()
            local legacyRaw = readfile(TASLegacySettingsPath)
            if type(legacyRaw) == "string" and legacyRaw ~= "" then
                if not isfolder(TASSettingsRootFolder) then
                    makefolder(TASSettingsRootFolder)
                end
                writefile(TasSettingsPath, legacyRaw)
            end
        end)
        sourcePath = TasSettingsPath
    end
    if not isfile(sourcePath) then return {} end
    local ok, raw = pcall(readfile, sourcePath)
    if not ok or type(raw) ~= "string" or raw == "" then return {} end
    local ok2, data = pcall(function() return TASServices.HttpService:JSONDecode(raw) end)
    if ok2 and type(data) == "table" then
        return data
    end
    return {}
end

function SaveTasSettings()
    local cfg = TasSettings or {}
    cfg.Version = 1
    cfg.ThemePreset = cfg.ThemePreset or "Midnight Blue"
    cfg.AccentHex = string.format("#%02X%02X%02X", math.floor(Theme.accent.R*255+0.5), math.floor(Theme.accent.G*255+0.5), math.floor(Theme.accent.B*255+0.5))
    cfg.FPS = tonumber(TASConfig.FPS) or 120
    cfg.TASRecordingFPS = tonumber(TASConfig.TASRecordingFPS) or 60
    cfg.TAS = cfg.TAS or {}
    cfg.TAS.AllowClientObjectManipulation = TASConfig.AllowClientObjectManipulation ~= false
    cfg.TAS.CORecordingRadius = math.max(0, tonumber(TASConfig.CORecordingRadius) or 250)
    cfg.KeyboardTheme = currentTheme or "Default"
    cfg.Window = cfg.Window or {}
    cfg.Window.XScale = MainFrame and MainFrame.Position.X.Scale or 0.5
    cfg.Window.YScale = MainFrame and MainFrame.Position.Y.Scale or 0.5
    cfg.Window.XOffset = MainFrame and MainFrame.Position.X.Offset or 0
    cfg.Window.YOffset = MainFrame and MainFrame.Position.Y.Offset or 0
    cfg.Window.Width = MainFrame and MainFrame.Size.X.Offset or 700
    cfg.Window.Height = MainFrame and MainFrame.Size.Y.Offset or 500
    cfg.SidePanels = cfg.SidePanels or {}
    cfg.SidePanels.Players = PlayersPanelVisible ~= false
    cfg.SidePanels.Files = FilesPanelVisible ~= false
    cfg.Keybinds = cfg.Keybinds or {}
    local binds = {
        HideUI = Hideuikeybind, Record = Recordkeybind, Forward = Goforwardkeybind, Backward = Gobackwardskeybind,
        FrameForward = Frameadvanceforwardkeybind, FrameBackward = Frameadvancebackwardskeybind, Save = Savekeybind,
        Read = Readkeybind, Abort = Abortkeybind,
    }
    for name, shim in pairs(binds) do
        if shim then cfg.Keybinds[name] = _tasKeyName(shim.Value) end
    end
    cfg.Checkboxes = cfg.Checkboxes or {}
    if KeyboardOverlay then cfg.Checkboxes.KeyboardOverlay = KeyboardOverlay.Value end
    if DisableParticles then cfg.Checkboxes.DisableParticles = DisableParticles.Value end
    if DisableLighting then cfg.Checkboxes.DisableLighting = DisableLighting.Value end
    if MotionBlurToggle then cfg.Checkboxes.MotionBlur = MotionBlurToggle.Value end
    if movecameraonfroze then cfg.Checkboxes.MoveCameraFrozen = movecameraonfroze.Value end
    local ok, err = pcall(function()
        if not isfolder(TASSettingsRootFolder) then
            makefolder(TASSettingsRootFolder)
        end
        writefile(TasSettingsPath, TASServices.HttpService:JSONEncode(cfg))
    end)
    if ok then
        TasSettings = cfg
        _G.TasSettings = cfg
    else
        TASCharacter.ConsoleMessage("Settings save failed: " .. tostring(err))
    end
end

function QueueSaveTasSettings()
    task.defer(function() pcall(SaveTasSettings) end)
end

TasSettings = LoadTasSettings()
TasSettings = type(TasSettings) == "table" and TasSettings or {}
_G.TasSettings = TasSettings
if tonumber(TasSettings.FPS) then TASConfig.FPS = math.max(1, math.min(1000, tonumber(TasSettings.FPS))) end
if tonumber(TasSettings.TASRecordingFPS) then TASConfig.TASRecordingFPS = math.max(1, math.min(1000, tonumber(TasSettings.TASRecordingFPS))) end
if type(TasSettings.TAS) == "table" then
    if TasSettings.TAS.AllowClientObjectManipulation ~= nil then
        TASConfig.AllowClientObjectManipulation = TasSettings.TAS.AllowClientObjectManipulation == true
    end
    if tonumber(TasSettings.TAS.CORecordingRadius) then
        TASConfig.CORecordingRadius = math.max(0, tonumber(TasSettings.TAS.CORecordingRadius))
    end
end
_tasApplySavedThemeAccent(TasSettings)

-- Discord integration is hosted separately in dc.lua.
local TAS_DISCORD_MODULE_URL = "https://raw.githubusercontent.com/yeetinguser/tasability/refs/heads/main/dc.lua"
local TAS_DISCORD_INVITE_FALLBACK = "https://discord.gg/hJGAvDXmjj"
local TAS_DISCORD_MODULE

local function LoadDiscordModule()
    if TAS_DISCORD_MODULE ~= nil then return TAS_DISCORD_MODULE end
    local ok, result = pcall(function()
        local source = game:HttpGet(TAS_DISCORD_MODULE_URL)
        return assert(loadstring(source))()
    end)
    if ok then
        TAS_DISCORD_MODULE = result
        return result
    end
    return nil, "Discord module load failed: " .. tostring(result)
end

_G.__TasabilityOpenDiscordInviteInBrowser = function(invite)
    local module, err = LoadDiscordModule()
    if not module then return false, err end

    local fn = module
    if type(module) == "table" then
        fn = module.OpenInvite or module.Join or module.Open or module.Invite
    end

    if type(fn) ~= "function" then
        return false, "dc.lua must return a function or table with OpenInvite/Join/Open/Invite"
    end

    local ok, a, b = pcall(function()
        return fn(invite or TAS_DISCORD_INVITE_FALLBACK)
    end)

    if not ok then
        return false, "Discord module threw: " .. tostring(a)
    end
    if a == false then
        return false, tostring(b or "Discord module returned false")
    end

    return true, tostring(b or "Discord invite requested")
end

_G.__TasabilityMaybeOpenDiscordOnFirstLaunch = function()
    TasSettings = TasSettings or {}
    if TasSettings.DiscordFirstLaunchOpened == true then return end

    task.defer(function()
        local opened, reason = _G.__TasabilityOpenDiscordInviteInBrowser(TAS_DISCORD_INVITE_FALLBACK)

        if opened then
            TasSettings.DiscordFirstLaunchOpened = true
            _G.TasSettings = TasSettings
            pcall(SaveTasSettings)
            TASCharacter.ConsoleMessage("Discord invite opened")
        else
            TASCharacter.ConsoleMessage(
                "Could not open Discord automatically: " ..
                tostring(reason or "unknown error") ..
                " | Use: invite"
            )
        end
    end)
end

-- ── Instance helpers ─────────────────────────────────────────────────────────

-- Layered border: BorderSizePixel=2, BorderColor3=border, UIStroke=outline
function addLayeredBorder(parent)
    parent.BorderSizePixel = 2
    parent.BorderColor3 = Theme.border
    applyTheme(parent, "BorderColor3", "border")
    local s = mk("UIStroke", {
        Parent = parent,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        LineJoinMode = Enum.LineJoinMode.Miter,
        Color = Theme.outline,
        Thickness = 1,
    })
    applyTheme(s, "Color", "outline")
    return s
end

-- Simple outline stroke (no inner border)
function addStroke(parent, themeKey, thickness, transparency)
    local s = mk("UIStroke", {
        Parent = parent,
        Color = Theme[themeKey or "outline"],
        Thickness = thickness or 1,
        Transparency = transparency or 0,
        LineJoinMode = Enum.LineJoinMode.Miter,
    })
    applyTheme(s, "Color", themeKey or "outline")
    return s
end

-- Text shadow stroke
function addTextShadow(parent)
    return mk("UIStroke", {
        Parent = parent,
        LineJoinMode = Enum.LineJoinMode.Miter,
        Color = Theme.txt_shadow,
        Thickness = 1,
    })
end

-- Accent gradient line
function addAccentLine(parent, pos, size)
    local line = mk("Frame", {
        Parent = parent,
        Position = pos or UDim2.new(0, 0, 0, 0),
        Size = size or UDim2.new(1, 0, 0, 2),
        BackgroundColor3 = Theme.accent,
        BorderSizePixel = 0,
        ZIndex = 3,
    })
    applyTheme(line, "BackgroundColor3", "accent")
    mk("UIGradient", {
        Parent = line,
        Rotation = 90,
        Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(65, 65, 65)),
        },
    })
    return line
end

-- Vertical gradient overlay for buttons / elements
function addVertGradient(parent)
    return mk("UIGradient", {
        Parent = parent,
        Rotation = 90,
        Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 100, 100)),
        },
    })
end

-- ══════════════════════════════════════════════════════════════════════════════
--  ROOT GUI
-- ══════════════════════════════════════════════════════════════════════════════

RootGui = mk("ScreenGui", {
    Name = "TasabilityGUI",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 9990,
    IgnoreGuiInset = true,
    Parent = game:GetService("CoreGui"),
})

-- Dedicated topmost layer for dropdown lists. It sits above popups/windows/overlays.
DropdownGui = mk("ScreenGui", {
    Name = "TasabilityDropdowns",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 10000000,
    IgnoreGuiInset = true,
    Parent = game:GetService("CoreGui"),
})

-- ══════════════════════════════════════════════════════════════════════════════
--  MAIN WINDOW
-- ══════════════════════════════════════════════════════════════════════════════

MainFrame = mk("Frame", {
    Name = "MainFrame",
    Size = UDim2.fromOffset(700, 500),
    Position = UDim2.fromScale(0.5, 0.5),
    AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundColor3 = Theme.bg_window,
    BorderSizePixel = 0,
    Parent = RootGui,
})
applyTheme(MainFrame, "BackgroundColor3", "bg_window")

-- Accent outer stroke 
accentBorder = mk("UIStroke", {
    Parent = MainFrame,
    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    LineJoinMode = Enum.LineJoinMode.Miter,
    Color = Theme.accent,
    Thickness = 1,
})
applyTheme(accentBorder, "Color", "accent")

-- Top accent gradient line
addAccentLine(MainFrame, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 2))

-- ── Title bar ────────────────────────────────────────────────────────────────
TitleBar = mk("Frame", {
    Size = UDim2.new(1, 0, 0, 28),
    Position = UDim2.fromOffset(0, 2),
    BackgroundColor3 = Theme.bg_deep,
    BorderSizePixel = 0,
    Parent = MainFrame,
})
applyTheme(TitleBar, "BackgroundColor3", "bg_deep")

-- Title bar bottom separator
mk("Frame", {
    Size = UDim2.new(1, 0, 0, 1),
    Position = UDim2.new(0, 0, 1, -1),
    BackgroundColor3 = Theme.outline,
    BorderSizePixel = 0,
    Parent = TitleBar,
})

-- Drag
do
    local dragging = false
    local dragStart = nil
    local frameStart = nil

    TitleBar.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = inp.Position
            frameStart = MainFrame.Position
        end
    end)

    TitleBar.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    TASServices.UserInputService.InputChanged:Connect(function(inp)
        if not dragging or inp.UserInputType ~= Enum.UserInputType.MouseMovement then
            return
        end

        local delta = inp.Position - dragStart

        -- Preserve the original Scale components. The main window starts at
        -- UDim2.fromScale(0.5, 0.5); replacing the whole position with
        -- UDim2.fromOffset(...) makes the 0.5 scale turn into a huge offset
        -- jump (the window appears to fly to the screen edge).
        MainFrame.Position = UDim2.new(
            frameStart.X.Scale,
            frameStart.X.Offset + delta.X,
            frameStart.Y.Scale,
            frameStart.Y.Offset + delta.Y
        )
    end)
end

-- Title label
TitleLabel = mk("TextLabel", {
    Size = UDim2.fromOffset(78, 28),
    Position = UDim2.fromOffset(8, 0),
    BackgroundTransparency = 1,
    Text = "TASABILITY",
    TextColor3 = Theme.accent,
    FontFace = UIFontBold,
    TextSize = 13,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = TitleBar,
})
applyTheme(TitleLabel, "TextColor3", "accent")
addTextShadow(TitleLabel)

-- Version label: styled chip/badge matching the reference screenshot.
VersionLabel = mk("TextButton", {
    Size = UDim2.fromOffset(52, 16),
    Position = UDim2.new(0, 100, 0.5, -8),
    BackgroundColor3 = Theme.bg_panel,
    BorderSizePixel = 2,
    BorderColor3 = Theme.border,
    Text = tostring(TASConfig.Version):gsub("%-TAS5$", ""),
    TextColor3 = Theme.txt_muted,
    FontFace = UIFont,
    TextSize = 9,
    AutoButtonColor = false,
    Parent = TitleBar,
})
applyTheme(VersionLabel, "BackgroundColor3", "bg_panel")
applyTheme(VersionLabel, "BorderColor3", "border")
addStroke(VersionLabel, "outline", 1)

-- Minimize button
HideBtn = mk("TextButton", {
    Size = UDim2.fromOffset(22, 16),
    Position = UDim2.new(1, -28, 0.5, -8),
    BackgroundColor3 = Theme.bg_element,
    BorderSizePixel = 2,
    BorderColor3 = Theme.border,
    Text = "—",
    TextColor3 = Theme.txt_muted,
    FontFace = UIFontBold,
    TextSize = 11,
    AutoButtonColor = false,
    Parent = TitleBar,
})
applyTheme(HideBtn, "BackgroundColor3", "bg_element")
applyTheme(HideBtn, "BorderColor3", "border")
addStroke(HideBtn, "outline", 1)
HideBtn.MouseButton1Click:Connect(function() MainFrame.Visible = not MainFrame.Visible end)
HideBtn.MouseEnter:Connect(function() tw(HideBtn, {TextColor3 = Theme.accent}) end)
HideBtn.MouseLeave:Connect(function() tw(HideBtn, {TextColor3 = Theme.txt_muted}) end)

-- ── Side window toggles (reference-style layout) ───────────────────────────
PlayersPanelVisible = true
FilesPanelVisible = true

function addTitleToggle(parent, text, x)
    local b = mk("TextButton", {
        Size = UDim2.fromOffset(62, 18),
        Position = UDim2.fromOffset(x, 5),
        BackgroundColor3 = Theme.bg_element,
        BorderSizePixel = 2,
        BorderColor3 = Theme.border,
        Text = text,
        TextColor3 = Theme.txt_muted,
        FontFace = UIFontBold,
        TextSize = 9,
        AutoButtonColor = false,
        Parent = parent,
    })
    applyTheme(b, "BackgroundColor3", "bg_element")
    applyTheme(b, "BorderColor3", "border")
    addStroke(b, "outline", 1)
    b.MouseEnter:Connect(function() tw(b, {TextColor3 = Theme.accent}) end)
    b.MouseLeave:Connect(function() tw(b, {TextColor3 = Theme.txt_muted}) end)
    return b
end

PlayersToggle = addTitleToggle(TitleBar, "PLAYERS", 170)
FilesToggle = addTitleToggle(TitleBar, "FILES", 234)

-- Reference-style search/status controls in the title bar.
SearchBox = mk("TextBox", {
    Size = UDim2.fromOffset(190, 18),
    Position = UDim2.new(1, -332, 0, 5),
    BackgroundColor3 = Theme.bg_element,
    BorderSizePixel = 2,
    BorderColor3 = Theme.border,
    Text = "",
    PlaceholderText = "search...",
    PlaceholderColor3 = Theme.txt_dim,
    TextColor3 = Theme.txt,
    FontFace = UIFont,
    TextSize = 9,
    TextXAlignment = Enum.TextXAlignment.Left,
    ClearTextOnFocus = false,
    Parent = TitleBar,
})
applyTheme(SearchBox, "BackgroundColor3", "bg_element")
applyTheme(SearchBox, "BorderColor3", "border")
addStroke(SearchBox, "outline", 1)
mk("UIPadding", {PaddingLeft = UDim.new(0, 6), Parent = SearchBox})

StatusPill = mk("TextLabel", {
    Size = UDim2.fromOffset(102, 18),
    Position = UDim2.new(1, -136, 0, 5),
    BackgroundColor3 = Theme.bg_element,
    BorderSizePixel = 2,
    BorderColor3 = Theme.border,
    Text = "■ Idle",
    TextColor3 = Theme.txt_muted,
    FontFace = UIFont,
    TextSize = 9,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = TitleBar,
})
applyTheme(StatusPill, "BackgroundColor3", "bg_element")
applyTheme(StatusPill, "BorderColor3", "border")
addStroke(StatusPill, "outline", 1)
mk("UIPadding", {PaddingLeft = UDim.new(0, 6), Parent = StatusPill})

-- Side panel factory: compact, dark, blue-accented windows matching the reference.
function makeSidePanel(name, title, side, size)
    local panel = mk("Frame", {
        Name = name,
        Size = UDim2.fromOffset(size.X, size.Y),
        Position = side == "left"
            and UDim2.new(0, -size.X - 8, 0, 0)
            or UDim2.new(1, 8, 0, 0),
        BackgroundColor3 = Theme.bg_window,
        BorderSizePixel = 0,
        Parent = MainFrame,
    })
    applyTheme(panel, "BackgroundColor3", "bg_window")
    addStroke(panel, "outline", 1)
    local panelAccentBorder = mk("UIStroke", {
        Parent = panel,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        LineJoinMode = Enum.LineJoinMode.Miter,
        Color = Theme.accent,
        Thickness = 1,
        Transparency = 0,
    })
    applyTheme(panelAccentBorder, "Color", "accent")
    local panelGlow = mk("UIStroke", {
        Parent = panel,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        LineJoinMode = Enum.LineJoinMode.Miter,
        Color = Theme.accent_glow,
        Thickness = 3,
        Transparency = 0.65,
    })
    applyTheme(panelGlow, "Color", "accent_glow")
    addAccentLine(panel, UDim2.fromOffset(0,0), UDim2.new(1,0,0,2))

    local hdr = mk("Frame", {
        Size = UDim2.new(1,0,0,34),
        Position = UDim2.fromOffset(0,2),
        BackgroundColor3 = Theme.bg_deep,
        BorderSizePixel = 0,
        Parent = panel,
    })
    applyTheme(hdr, "BackgroundColor3", "bg_deep")
    local hdrTitle = mk("TextLabel", {
        Size = UDim2.new(1,-36,1,0), Position = UDim2.fromOffset(10,0),
        BackgroundTransparency = 1, Text = title:upper(),
        TextColor3 = Theme.accent, FontFace = UIFontBold, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = hdr,
    })
    applyTheme(hdrTitle, "TextColor3", "accent")
    addTextShadow(hdrTitle)
    mk("Frame", {
        Size = UDim2.new(1,0,0,1), Position = UDim2.new(0,0,1,-1),
        BackgroundColor3 = Theme.outline, BorderSizePixel = 0, Parent = hdr,
    })

    local closeBtn = mk("TextButton", {
        Size = UDim2.fromOffset(20, 18),
        Position = UDim2.new(1, -26, 0.5, -9),
        BackgroundColor3 = Theme.bg_element,
        BorderSizePixel = 2,
        BorderColor3 = Theme.border,
        Text = "x",
        TextColor3 = Theme.txt_muted,
        FontFace = UIFontBold,
        TextSize = 11,
        AutoButtonColor = false,
        Parent = hdr,
    })
    applyTheme(closeBtn, "BackgroundColor3", "bg_element")
    applyTheme(closeBtn, "BorderColor3", "border")
    addStroke(closeBtn, "outline", 1)

    local body = mk("ScrollingFrame", {
        Position = UDim2.fromOffset(6,38), Size = UDim2.new(1,-12,1,-44),
        BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.accent_dim,
        CanvasSize = UDim2.fromScale(0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ClipsDescendants = true,
        Parent = panel,
    })
    applyTheme(body, "ScrollBarImageColor3", "accent_dim")

    closeBtn.MouseEnter:Connect(function()
        tw(closeBtn, {TextColor3 = Theme.accent})
    end)
    closeBtn.MouseLeave:Connect(function()
        tw(closeBtn, {TextColor3 = Theme.txt_muted})
    end)
    closeBtn.MouseButton1Click:Connect(function()
        panel.Visible = false
        if side == "left" then
            FilesPanelVisible = false
        else
            PlayersPanelVisible = false
        end
        QueueSaveTasSettings()
    end)

    return panel, body
end

FilesPanel, _G_TAS_FilesBody = makeSidePanel("FilesPanel", "File Manager", "left", Vector2.new(364, 400))
PlayersPanel, _G_TAS_PlayersBody = makeSidePanel("PlayersPanel", "Player Viewer", "right", Vector2.new(488, 441))

function clearChildrenExceptLayouts(parent)
    for _, child in ipairs(parent:GetChildren()) do
        if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
            child:Destroy()
        end
    end
end

function buildFilesPanel()
    clearChildrenExceptLayouts(_G_TAS_FilesBody)
    local body = _G_TAS_FilesBody

    -- UIListLayout-based layout so elements stack without hardcoded Y offsets.
    mk("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8),
        Parent = body,
    })
    mk("UIPadding", {
        PaddingTop = UDim.new(0, 8),
        PaddingBottom = UDim.new(0, 10),
        PaddingLeft = UDim.new(0, 0),
        PaddingRight = UDim.new(0, 0),
        Parent = body,
    })

    -- Helper: section label matching main-window accent style
    local function makeSmallLabel(text)
        local lbl = mk("TextLabel", {
            Size = UDim2.new(1, 0, 0, 16),
            BackgroundTransparency = 1,
            Text = text,
            TextColor3 = Theme.accent,
            FontFace = UIFontBold,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = body,
        })
        applyTheme(lbl, "TextColor3", "accent")
        addTextShadow(lbl)
        return lbl
    end

    -- Helper: action button matching addButton() style from main window
    local function makeBtn(parent, label, w, callback)
        local btn = mk("TextButton", {
            Size = w or UDim2.new(1, 0, 0, 22),
            BackgroundColor3 = Theme.bg_element,
            BorderSizePixel = 2,
            BorderColor3 = Theme.border,
            Text = "",
            AutoButtonColor = false,
            Parent = parent,
        })
        applyTheme(btn, "BackgroundColor3", "bg_element")
        applyTheme(btn, "BorderColor3", "border")
        addStroke(btn, "outline", 1)
        addVertGradient(btn)
        local lbl = mk("TextLabel", {
            Size = UDim2.fromScale(1, 1),
            Position = UDim2.fromOffset(0, -1),
            BackgroundTransparency = 1,
            Text = label,
            TextColor3 = Theme.txt,
            FontFace = UIFont,
            TextSize = 11,
            Parent = btn,
        })
        applyTheme(lbl, "TextColor3", "txt")
        addTextShadow(lbl)
        btn.MouseButton1Click:Connect(callback or function() end)
        btn.MouseEnter:Connect(function()
            tw(btn, {BackgroundColor3 = Theme.bg_hover})
            tw(lbl, {TextColor3 = Theme.accent})
        end)
        btn.MouseLeave:Connect(function()
            tw(btn, {BackgroundColor3 = Theme.bg_element})
            tw(lbl, {TextColor3 = Theme.txt})
        end)
        return btn
    end

    -- ── Current file bar ─────────────────────────────────────────────────────
    local current = mk("TextLabel", {
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundColor3 = Theme.bg_deep,
        BorderSizePixel = 2,
        BorderColor3 = Theme.border,
        Text = "Current: " .. tostring(TASPaths.ReplayPath),
        TextColor3 = Theme.accent,
        FontFace = UIFont,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextWrapped = false,
        ClipsDescendants = true,
        Parent = body,
    })
    applyTheme(current, "BackgroundColor3", "bg_deep")
    applyTheme(current, "BorderColor3", "border")
    addStroke(current, "outline", 1)
    mk("UIPadding", {PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 6), Parent = current})

    -- ── Replay file list ─────────────────────────────────────────────────────
    makeSmallLabel("REPLAY FILES")

    local list = mk("ScrollingFrame", {
        Size = UDim2.new(1, 0, 0, 155),
        BackgroundColor3 = Theme.bg_deep,
        BorderSizePixel = 2,
        BorderColor3 = Theme.border,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.accent_dim,
        CanvasSize = UDim2.fromScale(0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Parent = body,
    })
    applyTheme(list, "BackgroundColor3", "bg_deep")
    applyTheme(list, "BorderColor3", "border")
    addStroke(list, "outline", 1)
    mk("UIPadding", {
        PaddingTop = UDim.new(0, 3), PaddingBottom = UDim.new(0, 3),
        PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4),
        Parent = list,
    })
    mk("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 2),
        Parent = list,
    })

    local ok, files = pcall(function() return listfiles(TASPaths.FolderPath) end)
    files = ok and files or {}
    table.sort(files, function(a, b)
        return tostring(a):lower() < tostring(b):lower()
    end)

    local replayFileCount = 0
    for _, path in ipairs(files) do
        local fileName = tostring(path):gsub('^.*[\\/]', '')
        local lowerName = fileName:lower()
        if lowerName ~= "settings.json" and (lowerName:sub(-5) == ".json" or lowerName:sub(-4) == ".tas") then
            replayFileCount += 1
            local btn = mk("TextButton", {
                Size = UDim2.new(1, 0, 0, 22),
                BackgroundColor3 = Theme.bg_inline,
                BorderSizePixel = 1,
                BorderColor3 = Theme.outline,
                Text = "",
                AutoButtonColor = false,
                Parent = list,
            })
            applyTheme(btn, "BackgroundColor3", "bg_inline")
            applyTheme(btn, "BorderColor3", "outline")
            local btnLbl = mk("TextLabel", {
                Size = UDim2.fromScale(1, 1),
                Position = UDim2.fromOffset(0, -1),
                BackgroundTransparency = 1,
                Text = fileName,
                TextColor3 = Theme.txt,
                FontFace = UIFont,
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = btn,
            })
            applyTheme(btnLbl, "TextColor3", "txt")
            addTextShadow(btnLbl)
            mk("UIPadding", {PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 5), Parent = btn})
            btn.MouseEnter:Connect(function()
                tw(btn, {BackgroundColor3 = Theme.bg_hover})
                tw(btnLbl, {TextColor3 = Theme.accent})
            end)
            btn.MouseLeave:Connect(function()
                tw(btn, {BackgroundColor3 = Theme.bg_inline})
                tw(btnLbl, {TextColor3 = Theme.txt})
            end)
            btn.MouseButton1Click:Connect(function()
                TASPaths.ReplayPath = path
                TASPaths.ReplayNeedsReload = true
                CurrentFile.Text = "Current File: " .. fileName
                current.Text = "Current: " .. tostring(path)
            end)
        end
    end

    if replayFileCount == 0 then
        local empty = mk("TextLabel", {
            Size = UDim2.new(1, -6, 0, 22),
            BackgroundTransparency = 1,
            Text = "No replay files",
            TextColor3 = Theme.txt_dim,
            FontFace = UIFont,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = list,
        })
        mk("UIPadding", {PaddingLeft = UDim.new(0, 8), Parent = empty})
    end

    -- ── Actions ──────────────────────────────────────────────────────────────
    makeSmallLabel("ACTIONS")

    local actions = mk("Frame", {
        Size = UDim2.new(1, 0, 0, 22),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Parent = body,
    })
    mk("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 4),
        Parent = actions,
    })

    local cols = {
        {"Load", function()
            if TASPaths.ReplayPath and isfile(TASPaths.ReplayPath) then
                local ok2, raw = pcall(readfile, TASPaths.ReplayPath)
                if ok2 and raw then
                    local decoded, replayFPS = ReplayDecode(raw)
                    if decoded then
                        TASRuntime.ReplayTable = decoded
                        TASRuntime.ReplaySaveState.Version = TASRuntime.ReplaySaveState.Version + 1
                        TASRuntime.ReplaySaveState.Encoded = raw
                        TASRuntime.ReplaySaveState.EncodedVersion = TASRuntime.ReplaySaveState.Version
                        TASRuntime.ReplaySourceFPS = math.max(1, tonumber(replayFPS or TASConfig.TASRecordingFPS) or 1)
                        TASRuntime.ActiveReplayFPS = TASRuntime.ReplaySourceFPS
                        TASPaths.ReplayNeedsReload = false
                        TASPaths.LastLoadedPath = TASPaths.ReplayPath
                        TASCharacter.ConsoleMessage("Loaded: " .. tostring(TASPaths.ReplayPath))
                    end
                end
            end
        end},
        {"Save",    function() SaveToFile() end},
        {"Delete",  function()
            if TASPaths.ReplayPath and isfile(TASPaths.ReplayPath) then
                pcall(delfile, TASPaths.ReplayPath)
                TASPaths.ReplayNeedsReload = true
            end
            buildFilesPanel()
        end},
        {"Refresh", function() buildFilesPanel() end},
    }
    for _, item in ipairs(cols) do
        makeBtn(actions, item[1], UDim2.new(0.25, -3, 0, 22), item[2])
    end

    -- ── Create new ───────────────────────────────────────────────────────────
    makeSmallLabel("CREATE NEW")

    local createRow = mk("Frame", {
        Size = UDim2.new(1, 0, 0, 22),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Parent = body,
    })
    mk("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4), Parent = createRow})

    local createBox = mk("TextBox", {
        Size = UDim2.new(0.78, -2, 0, 22),
        BackgroundColor3 = Theme.bg_element,
        BorderSizePixel = 2,
        BorderColor3 = Theme.border,
        Text = "",
        PlaceholderText = "filename (no extension)...",
        PlaceholderColor3 = Theme.txt_dim,
        TextColor3 = Theme.txt,
        FontFace = UIFont,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        Parent = createRow,
    })
    applyTheme(createBox, "BackgroundColor3", "bg_element")
    applyTheme(createBox, "BorderColor3", "border")
    local cbStroke = addStroke(createBox, "outline", 1)
    mk("UIPadding", {PaddingLeft = UDim.new(0, 7), PaddingRight = UDim.new(0, 5), Parent = createBox})
    createBox.Focused:Connect(function() tw(cbStroke, {Color = Theme.accent, Transparency = 0.3}); tw(createBox, {TextColor3 = Theme.accent}) end)
    createBox.FocusLost:Connect(function() tw(cbStroke, {Color = Theme.outline, Transparency = 0}); tw(createBox, {TextColor3 = Theme.txt}) end)

    local createBtn = makeBtn(createRow, "Create", UDim2.new(0.22, -2, 0, 22))

    local function createReplayFile()
        local name = tostring(createBox.Text or "")
        name = name:gsub("^%s+", ""):gsub("%s+$", "")
        if name == "" then TASCharacter.ConsoleMessage("Enter a file name"); return end
        name = name:gsub('[\\/:*?"<>|]', "_")
        if not name:lower():match("%.json$") then name = name .. ".json" end
        if not isfolder(TASPaths.FolderPath) then pcall(makefolder, TASPaths.FolderPath) end
        local path = TASPaths.FolderPath .. "\\" .. name
        if isfile(path) then TASCharacter.ConsoleMessage("File already exists: " .. name); return end
        local emptyReplay = '{"Format":"TASABILITY_JSON3","Version":3,"FPS":' .. tostring(math.max(1, tonumber(TASConfig.TASRecordingFPS) or 1)) .. ',"Compression":"TAS4","Binary":"base64","RawBytes":0,"PackedBytes":0,"Frames":0,"Data":""}'
        local okWrite, err = pcall(writefile, path, emptyReplay)
        if okWrite then
            TASPaths.ReplayPath = path
            TASPaths.ReplayNeedsReload = true
            TASPaths.LastLoadedPath = nil
            CurrentFile.Text = "Current File: " .. name
            current.Text = "Current: " .. path
            createBox.Text = ""
            buildFilesPanel()
            TASCharacter.ConsoleMessage("Created: " .. path)
        else
            TASCharacter.ConsoleMessage("Create failed: " .. tostring(err))
        end
    end
    createBtn.MouseButton1Click:Connect(createReplayFile)
    createBox.FocusLost:Connect(function(enterPressed) if enterPressed then createReplayFile() end end)

    -- ── Extra ─────────────────────────────────────────────────────────────────
    makeSmallLabel("EXTRA")

    local extra = mk("Frame", {
        Size = UDim2.new(1, 0, 0, 22),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Parent = body,
    })
    mk("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4), Parent = extra})

    makeBtn(extra, "Copy Path",     UDim2.new(0.5, -2, 0, 22), function() if setclipboard then setclipboard(tostring(TASPaths.ReplayPath)) end end)
    makeBtn(extra, "Erase Current", UDim2.new(0.5, -2, 0, 22), function() TASFunctions.ResetCurrentRecording(); buildFilesPanel() end)
end

TASPlayerViewerRuntime = TASPlayerViewerRuntime or {
    Selected = nil,
    PreviewModel = nil,
    PreviewTrack = nil,
    PreviewAnimationId = "",
    PreviewSourceCharacter = nil,
    PreviewSourceRoot = nil,
    PreviewPartPairs = {},
    UpdateToken = 0,
}

function TASPlayerViewerColorHex(c)
    c = c or Theme.txt
    return string.format("#%02X%02X%02X", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
end

function TASPlayerViewerDestroyPreview()
    local rt = TASPlayerViewerRuntime
    rt.PreviewAnimationId = ""
    rt.PreviewSourceCharacter = nil
    rt.PreviewSourceRoot = nil
    rt.PreviewPartPairs = {}
    if rt.PreviewTrack then
        pcall(function()
            rt.PreviewTrack:Stop(0)
            rt.PreviewTrack:Destroy()
        end)
        rt.PreviewTrack = nil
    end
    if rt.PreviewModel then
        pcall(function() rt.PreviewModel:Destroy() end)
        rt.PreviewModel = nil
    end
end

function TASPlayerViewerPruneThemeBindings(root)
    local alive = {}
    for _, binding in ipairs(ThemeBindings) do
        local inst = binding[1]
        local belongsToRoot = false
        if inst and inst.Parent and inst ~= root then
            local cursor = inst
            while cursor and cursor ~= root do
                cursor = cursor.Parent
            end
            belongsToRoot = cursor == root
        end
        if not belongsToRoot then
            alive[#alive + 1] = binding
        end
    end
    ThemeBindings = alive
end

function TASPlayerViewerGetBestTrack(humanoid)
    if not humanoid then return nil end
    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then return nil end

    local best = nil
    local bestPriority = -math.huge
    local bestWeight = -math.huge
    for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
        local weight = tonumber(track.WeightCurrent) or 0
        -- A TAS-freezed local character intentionally has its animation speed
        -- set to 0.  Such a track can still be the authoritative animation
        -- state even though Roblox may report it as not actively advancing.
        -- Prefer it when it is still loaded and has a valid Animation object.
        local hasAnimation = track.Animation ~= nil
        local isUsable = (track.IsPlaying and weight > 0.001) or (hasAnimation and track.IsPlaying == true)
        if isUsable then
            local priority = (track.Priority and tonumber(track.Priority.Value)) or 0
            if priority > bestPriority or (priority == bestPriority and weight > bestWeight) then
                best = track
                bestPriority = priority
                bestWeight = weight
            end
        end
    end

    -- During TAS freeze the selected local track is explicitly held at speed 0.
    -- Prefer the TAS track over a stale/default Roblox track in that case.
    if humanoid == TASCharacter.Humanoid and TASFreeze.Frozen and TASAnimation.currentAnimTrack then
        local t = TASAnimation.currentAnimTrack
        if t.Parent and t.Animation then
            best = t
        end
    end
    return best
end

function TASPlayerViewerGetRelativePath(inst, root)
    local parts = {}
    local cursor = inst
    while cursor and cursor ~= root do
        table.insert(parts, 1, cursor.Name)
        cursor = cursor.Parent
    end
    return table.concat(parts, "/")
end

function TASPlayerViewerFindRelative(root, path)
    local current = root
    for partName in string.gmatch(path, "[^/]+") do
        current = current and current:FindFirstChild(partName)
        if not current then return nil end
    end
    return current
end

function TASPlayerViewerBuildPreview(plr, viewport, camera)
    TASPlayerViewerDestroyPreview()
    if not plr then return end

    local char = plr.Character
    if not char or not char.Parent then
        viewport.CurrentCamera = camera
        return
    end

    local sourceRoot = char:FindFirstChild("HumanoidRootPart")
    if not sourceRoot then
        viewport.CurrentCamera = camera
        return
    end

    local oldArchivable = char.Archivable
    char.Archivable = true
    local ok, clone = pcall(function() return char:Clone() end)
    char.Archivable = oldArchivable
    if not ok or not clone then
        return
    end

    -- The preview is a lightweight pose mirror, not a second live Roblox rig.
    -- Removing joints lets us copy the source part CFrames at a low cadence
    -- without running a second animation/physics simulation.
    for _, obj in ipairs(clone:GetDescendants()) do
        if obj:IsA("Script") or obj:IsA("LocalScript") or obj:IsA("ModuleScript") then
            obj:Destroy()
        elseif obj:IsA("Motor6D") or obj:IsA("Weld") or obj:IsA("WeldConstraint") or obj:IsA("ManualWeld") then
            obj:Destroy()
        elseif obj:IsA("BasePart") then
            obj.Anchored = true
            obj.CanCollide = false
            obj.CanTouch = false
            obj.CanQuery = false
            obj.Massless = true
        end
    end

    local humanoid = clone:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.AutoRotate = false
        humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
        if not humanoid:FindFirstChildOfClass("Animator") then
            Instance.new("Animator", humanoid)
        end
    end

    local worldModel = viewport:FindFirstChildOfClass("WorldModel")
    if not worldModel then
        worldModel = Instance.new("WorldModel")
        worldModel.Name = "PreviewWorld"
        worldModel.Parent = viewport
    else
        worldModel:ClearAllChildren()
    end
    clone.Parent = worldModel

    local cloneRoot = clone:FindFirstChild("HumanoidRootPart")
    if not cloneRoot then
        clone:Destroy()
        return
    end

    -- Keep the rig centred in the mini-camera.
    local boundsCFrame, boundsSize = clone:GetBoundingBox()
    local target = Vector3.new(0, math.max(boundsSize.Y * 0.47, 0.5), 0)
    local move = target - boundsCFrame.Position
    clone:PivotTo(CFrame.new(move) * clone:GetPivot())
    cloneRoot = clone:FindFirstChild("HumanoidRootPart") or cloneRoot

    local maxSize = math.max(boundsSize.X, boundsSize.Y, boundsSize.Z, 1)
    local distance = maxSize * 1.85
    local cameraOffset = Vector3.new(distance * 0.72, maxSize * 0.12, distance)
    camera.FieldOfView = 35
    camera.CFrame = CFrame.lookAt(target + cameraOffset, target)
    viewport.CurrentCamera = camera

    -- Build a stable source->preview part map once.
    local pairs = {}
    for _, src in ipairs(char:GetDescendants()) do
        if src:IsA("BasePart") then
            local relative = TASPlayerViewerGetRelativePath(src, char)
            local dst = TASPlayerViewerFindRelative(clone, relative)
            if dst and dst:IsA("BasePart") then
                pairs[#pairs + 1] = {src, dst}
            end
        end
    end

    TASPlayerViewerRuntime.PreviewModel = clone
    TASPlayerViewerRuntime.PreviewSourceCharacter = char
    TASPlayerViewerRuntime.PreviewSourceRoot = sourceRoot
    TASPlayerViewerRuntime.PreviewPartPairs = pairs
    TASPlayerViewerRuntime.PreviewTargetRootCFrame = cloneRoot.CFrame
end

function TASPlayerViewerSyncPreviewPose()
    local rt = TASPlayerViewerRuntime
    local sourceChar = rt.PreviewSourceCharacter
    local sourceRoot = rt.PreviewSourceRoot
    local clone = rt.PreviewModel
    if not sourceChar or not sourceChar.Parent or not sourceRoot or not sourceRoot.Parent or not clone or not clone.Parent then
        return false
    end

    local cloneRoot = clone:FindFirstChild("HumanoidRootPart")
    if not cloneRoot then return false end

    local targetRootCFrame = rt.PreviewTargetRootCFrame or cloneRoot.CFrame
    cloneRoot.CFrame = targetRootCFrame

    for _, pair in ipairs(rt.PreviewPartPairs or {}) do
        local src, dst = pair[1], pair[2]
        if src and src.Parent and dst and dst.Parent then
            local ok, relative = pcall(function()
                return sourceRoot.CFrame:ToObjectSpace(src.CFrame)
            end)
            if ok and relative then
                dst.CFrame = targetRootCFrame * relative
                dst.Transparency = src.Transparency
            end
        end
    end
    return true
end

function buildPlayersPanel()
    clearChildrenExceptLayouts(_G_TAS_PlayersBody)
    local body = _G_TAS_PlayersBody
    local rt = TASPlayerViewerRuntime
    rt.UpdateToken = (rt.UpdateToken or 0) + 1
    local updateToken = rt.UpdateToken

    -- The reference viewer is a fixed-size 488x441 side window. Keep the
    -- body static so the preview and state panes line up exactly instead of
    -- becoming a vertically scrolling form.
    body.AutomaticCanvasSize = Enum.AutomaticSize.None
    body.CanvasSize = UDim2.fromOffset(0, 0)
    body.ScrollBarThickness = 0

    TASPlayerViewerPruneThemeBindings(body)

    local search = mk("TextBox", {
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.fromOffset(150, 24),
        BackgroundColor3 = Theme.bg_deep,
        BorderSizePixel = 2,
        BorderColor3 = Theme.border,
        Text = "",
        PlaceholderText = "search players...",
        PlaceholderColor3 = Theme.txt_dim,
        TextColor3 = Theme.txt,
        FontFace = UIFont,
        TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        Parent = body,
    })
    applyTheme(search, "BackgroundColor3", "bg_deep")
    applyTheme(search, "BorderColor3", "border")
    addStroke(search, "outline", 1)
    mk("UIPadding", {PaddingLeft = UDim.new(0, 7), Parent = search})

    local list = mk("ScrollingFrame", {
        Position = UDim2.fromOffset(0, 30),
        Size = UDim2.new(0, 150, 1, -30),
        BackgroundColor3 = Theme.bg_deep,
        BorderSizePixel = 2,
        BorderColor3 = Theme.border,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Theme.accent_dim,
        CanvasSize = UDim2.fromScale(0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ClipsDescendants = true,
        Parent = body,
    })
    applyTheme(list, "BackgroundColor3", "bg_deep")
    applyTheme(list, "BorderColor3", "border")
    applyTheme(list, "ScrollBarImageColor3", "accent_dim")
    addStroke(list, "outline", 1)
    mk("UIPadding", {
        PaddingTop = UDim.new(0, 3),
        PaddingBottom = UDim.new(0, 3),
        PaddingLeft = UDim.new(0, 4),
        PaddingRight = UDim.new(0, 4),
        Parent = list,
    })
    mk("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 1),
        Parent = list,
    })

    local previewTitle = mk("TextLabel", {
        Position = UDim2.fromOffset(158, 0),
        Size = UDim2.new(1, -158, 0, 18),
        BackgroundTransparency = 1,
        Text = "PREVIEW",
        TextColor3 = Theme.accent,
        FontFace = UIFontBold,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = body,
    })
    applyTheme(previewTitle, "TextColor3", "accent")
    addTextShadow(previewTitle)

    local viewport = mk("ViewportFrame", {
        Position = UDim2.fromOffset(158, 22),
        Size = UDim2.new(1, -158, 0, 160),
        BackgroundColor3 = Theme.bg_deep,
        BorderSizePixel = 2,
        BorderColor3 = Theme.border,
        Ambient = Color3.fromRGB(180, 180, 180),
        LightColor = Color3.fromRGB(255, 255, 255),
        LightDirection = Vector3.new(-1, -1, -1),
        Parent = body,
    })
    applyTheme(viewport, "BackgroundColor3", "bg_deep")
    applyTheme(viewport, "BorderColor3", "border")
    addStroke(viewport, "outline", 1)

    local camera = Instance.new("Camera")
    camera.Name = "PreviewCamera"
    camera.Parent = viewport
    viewport.CurrentCamera = camera

    local worldModel = Instance.new("WorldModel")
    worldModel.Name = "PreviewWorld"
    worldModel.Parent = viewport

    local stateTitle = mk("TextLabel", {
        Position = UDim2.fromOffset(158, 190),
        Size = UDim2.new(1, -158, 0, 18),
        BackgroundTransparency = 1,
        Text = "STATE",
        TextColor3 = Theme.accent,
        FontFace = UIFontBold,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = body,
    })
    applyTheme(stateTitle, "TextColor3", "accent")
    addTextShadow(stateTitle)

    local info = mk("TextLabel", {
        Position = UDim2.fromOffset(158, 212),
        Size = UDim2.new(1, -158, 1, -212),
        BackgroundColor3 = Theme.bg_deep,
        BorderSizePixel = 2,
        BorderColor3 = Theme.border,
        Text = "Select a player",
        TextColor3 = Theme.txt,
        FontFace = UIFont,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
        RichText = true,
        Parent = body,
    })
    applyTheme(info, "BackgroundColor3", "bg_deep")
    applyTheme(info, "BorderColor3", "border")
    applyTheme(info, "TextColor3", "txt")
    addStroke(info, "outline", 1)
    mk("UIPadding", {
        PaddingTop = UDim.new(0, 10),
        PaddingBottom = UDim.new(0, 8),
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 8),
        Parent = info,
    })

    local buttons = {}
    local selectedButton = nil

    local function setButtonVisual(item, selected)
        if not item or not item.btn or not item.btn.Parent then return end
        item.selected = selected == true
        if item.selected then
            item.btn.BackgroundTransparency = 0
            item.btn.BackgroundColor3 = Theme.bg_panel
            item.btn.TextColor3 = Theme.accent
        else
            item.btn.BackgroundTransparency = 1
            item.btn.TextColor3 = Theme.txt_muted
        end
    end

    local function selectPlayer(plr)
        if not plr or not plr.Parent then return end
        rt.Selected = plr
        if selectedButton and selectedButton ~= plr then
            local old = nil
            for _, item in ipairs(buttons) do
                if item.plr == selectedButton then old = item break end
            end
            setButtonVisual(old, false)
        end
        selectedButton = plr
        for _, item in ipairs(buttons) do
            if item.plr == plr then
                setButtonVisual(item, true)
                break
            end
        end
        TASPlayerViewerBuildPreview(plr, viewport, camera)
    end

    local function buildPlayerState(plr)
        if not plr or not plr.Parent then
            return "Select a player"
        end

        local char = plr.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local pos = root and root.Position
        local vel = root and root.AssemblyLinearVelocity
        local stateStr = hum and hum:GetState().Name or "N/A"
        local floor = hum and tostring(hum.FloorMaterial):gsub("Enum.Material.", "") or "N/A"
        local animTrack = TASPlayerViewerGetBestTrack(hum)
        local animName = animTrack and ((animTrack.Name ~= "" and animTrack.Name ~= "Animation") and animTrack.Name or ((animTrack.Animation and animTrack.Animation.Name ~= "") and animTrack.Animation.Name or "Playing")) or ((plr == TASServices.Player and TASAnimation.currentAnimName ~= "" and TASAnimation.currentAnimName) or "idle")
        local animId = animTrack and animTrack.Animation and tostring(animTrack.Animation.AnimationId or "") or ""
        if animId == "" and plr == TASServices.Player and TASAnimation.currentAnimTrack and TASAnimation.currentAnimTrack.Animation then
            animId = tostring(TASAnimation.currentAnimTrack.Animation.AnimationId or "")
        end
        local team = plr.Team and plr.Team.Name or "None"
        local teamColor = plr.TeamColor and plr.TeamColor.Color or Theme.accent
        local velocity = vel or Vector3.zero
        local position = pos or Vector3.zero
        local animSpeed = animTrack and tonumber(animTrack.Speed) or ((plr == TASServices.Player and tonumber(TASAnimation.currentAnimSpeed)) or 1)
        local animText = animId ~= "" and (animName .. " (" .. animId .. ")") or animName

        return string.format(
            "Name: %s\nDisplay: %s\nUserId: %d\n\nState: <font color='%s'>%s</font>\nHealth: <font color='%s'>%.1f / %.1f</font>\nWalkSpeed: <font color='%s'>%.1f</font>\nJumpPower: <font color='%s'>%.1f</font>\nPosition: %.1f, %.1f, %.1f\nVelocity: %.1f  (%.1f, %.1f, %.1f)\nAnimation: <font color='%s'>%s</font>\nAnim Speed: <font color='%s'>%.2f</font>\nFloor: <font color='%s'>%s</font>\nTeam: <font color='%s'>%s</font>",
            plr.Name,
            plr.DisplayName,
            plr.UserId,
            TASPlayerViewerColorHex((stateStr == "Dead" and Theme.red) or Theme.yellow), stateStr,
            TASPlayerViewerColorHex(Theme.green), hum and hum.Health or 0, hum and hum.MaxHealth or 0,
            TASPlayerViewerColorHex(Theme.green), hum and hum.WalkSpeed or 0,
            TASPlayerViewerColorHex(Theme.green), hum and hum.JumpPower or 0,
            position.X, position.Y, position.Z,
            velocity.Magnitude, velocity.X, velocity.Y, velocity.Z,
            TASPlayerViewerColorHex(Theme.accent), animText,
            TASPlayerViewerColorHex(Theme.accent), animSpeed,
            TASPlayerViewerColorHex(Theme.txt_muted), floor,
            TASPlayerViewerColorHex(teamColor), team
        )
    end

    local function syncPreviewAnimation(plr)
        local char = plr and plr.Character
        if not char or not char.Parent then
            TASPlayerViewerDestroyPreview()
            return
        end
        if rt.PreviewModel and rt.PreviewSourceCharacter ~= char then
            TASPlayerViewerBuildPreview(plr, viewport, camera)
        end
        -- The mini-camera intentionally updates its pose at a low cadence
        -- (see the 0.125s accumulator below) to keep the main game cheap.
        TASPlayerViewerSyncPreviewPose()
    end

    local function addPlayerButton(plr)
        local btn = mk("TextButton", {
            Size = UDim2.new(1, 0, 0, 22),
            BackgroundColor3 = Theme.bg_inline,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Text = "  " .. plr.Name,
            TextColor3 = Theme.txt_muted,
            FontFace = UIFont,
            TextSize = 9,
            TextXAlignment = Enum.TextXAlignment.Left,
            AutoButtonColor = false,
            Parent = list,
        })
        applyTheme(btn, "BackgroundColor3", "bg_inline")
        applyTheme(btn, "TextColor3", "txt_muted")
        local stroke = addStroke(btn, "outline", 0.5, 0.75)
        local item = {plr = plr, btn = btn, stroke = stroke, selected = false}
        buttons[#buttons + 1] = item

        btn.MouseEnter:Connect(function()
            if not item.selected then
                btn.BackgroundTransparency = 0
                btn.BackgroundColor3 = Theme.bg_hover
            end
            tw(btn, {TextColor3 = Theme.accent})
        end)
        btn.MouseLeave:Connect(function()
            if item.selected then
                btn.BackgroundTransparency = 0
                btn.BackgroundColor3 = Theme.bg_panel
                btn.TextColor3 = Theme.accent
            else
                btn.BackgroundTransparency = 1
                btn.TextColor3 = Theme.txt_muted
            end
        end)
        btn.MouseButton1Click:Connect(function()
            selectPlayer(plr)
        end)
        return item
    end

    local players = game:GetService("Players"):GetPlayers()
    table.sort(players, function(a, b)
        return tostring(a.Name):lower() < tostring(b.Name):lower()
    end)
    for _, plr in ipairs(players) do
        addPlayerButton(plr)
    end

    local function refreshPlayerFilter()
        local q = string.lower(search.Text or "")
        for _, item in ipairs(buttons) do
            local name = string.lower(item.plr.Name or "")
            local display = string.lower(item.plr.DisplayName or "")
            item.btn.Visible = (q == "" or string.find(name, q, 1, true) ~= nil or string.find(display, q, 1, true) ~= nil)
        end
    end
    search:GetPropertyChangedSignal("Text"):Connect(refreshPlayerFilter)

    if rt.Selected and rt.Selected.Parent then
        local exists = false
        for _, item in ipairs(buttons) do
            if item.plr == rt.Selected then exists = true break end
        end
        if exists then
            selectedButton = rt.Selected
            for _, item in ipairs(buttons) do
                if item.plr == rt.Selected then setButtonVisual(item, true) end
            end
            TASPlayerViewerBuildPreview(rt.Selected, viewport, camera)
        else
            rt.Selected = nil
        end
    end

    if not rt.Selected and players[1] then
        selectPlayer(players[1])
    end

    task.spawn(function()
        local previewAccumulator = 0
        local stateAccumulator = 0
        local lastStateText = nil
        while TASPlayerViewerRuntime.UpdateToken == updateToken do
            task.wait(0.05)
            if TASPlayerViewerRuntime.UpdateToken ~= updateToken then break end
            local selected = TASPlayerViewerRuntime.Selected
            previewAccumulator += 0.05
            stateAccumulator += 0.05

            if selected and selected.Parent and PlayersPanel.Visible then
                if previewAccumulator >= 0.125 then
                    previewAccumulator = previewAccumulator - 0.125
                    syncPreviewAnimation(selected) -- 8 FPS live mini-camera
                end

                if stateAccumulator >= 0.10 then
                    stateAccumulator = 0
                    local stateText = buildPlayerState(selected)
                    if stateText ~= lastStateText then
                        info.Text = stateText
                        lastStateText = stateText
                    end
                end
            elseif selected and not selected.Parent then
                rt.Selected = nil
                TASPlayerViewerDestroyPreview()
                info.Text = "Select a player"
                lastStateText = info.Text
            end
        end
    end)
end

buildFilesPanel()
buildPlayersPanel()

game:GetService("Players").PlayerAdded:Connect(function()
    if PlayersPanelVisible then task.defer(buildPlayersPanel) end
end)
game:GetService("Players").PlayerRemoving:Connect(function()
    if PlayersPanelVisible then task.defer(buildPlayersPanel) end
end)

PlayersToggle.MouseButton1Click:Connect(function()
    PlayersPanelVisible = not PlayersPanelVisible
    PlayersPanel.Visible = PlayersPanelVisible
    QueueSaveTasSettings()
end)
FilesToggle.MouseButton1Click:Connect(function()
    FilesPanelVisible = not FilesPanelVisible
    FilesPanel.Visible = FilesPanelVisible
    QueueSaveTasSettings()
end)

pcall(function()
    local w = TasSettings.Window
    if type(w) == "table" and MainFrame then
        MainFrame.Position = UDim2.new(tonumber(w.XScale) or 0.5, tonumber(w.XOffset) or 0, tonumber(w.YScale) or 0.5, tonumber(w.YOffset) or 0)
        local savedWidth = tonumber(w.Width)
        local savedHeight = tonumber(w.Height)
        -- Standard window size is 700x500. Migrate old defaults so an older
        -- saved config cannot silently restore the previous main-window size.
        local oldDefault = (savedWidth == 1180 and savedHeight == 760)
            or (savedWidth == 650 and savedHeight == 468)
        if savedWidth and savedHeight and not oldDefault and savedWidth >= 400 and savedHeight >= 300 then
            MainFrame.Size = UDim2.fromOffset(savedWidth, savedHeight)
        else
            MainFrame.Size = UDim2.fromOffset(700, 500)
            TasSettings.Window = TasSettings.Window or {}
            TasSettings.Window.Width = 700
            TasSettings.Window.Height = 500
        end
    end
    if type(TasSettings.SidePanels) == "table" then
        PlayersPanelVisible = TasSettings.SidePanels.Players ~= false
        FilesPanelVisible = TasSettings.SidePanels.Files ~= false
        PlayersPanel.Visible = PlayersPanelVisible
        FilesPanel.Visible = FilesPanelVisible
    end
end)

-- ── Inline frame ( style: window > inline > content) ─────────────────
InlineFrame = mk("Frame", {
    Position = UDim2.fromOffset(7, 32),
    Size = UDim2.new(1, -14, 1, -39),
    BackgroundColor3 = Theme.bg_inline,
    BorderSizePixel = 0,
    Parent = MainFrame,
})
applyTheme(InlineFrame, "BackgroundColor3", "bg_inline")
addLayeredBorder(InlineFrame)

-- ── Tab bar (inside inline) ──────────────────────────────────────────────────
TabBar = mk("Frame", {
    Position = UDim2.fromOffset(7, 7),
    Size = UDim2.new(1, -14, 0, 22),
    BackgroundTransparency = 1,
    ClipsDescendants = true,
    Parent = InlineFrame,
})
mk("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    SortOrder = Enum.SortOrder.LayoutOrder,
    VerticalAlignment = Enum.VerticalAlignment.Center,
    Padding = UDim.new(0, 5),
    Parent = TabBar,
})

-- ── Content frame (inside inline, below tabs) ────────────────────────────────
ContentFrame = mk("Frame", {
    Position = UDim2.fromOffset(7, 32),
    Size = UDim2.new(1, -14, 1, -39),
    BackgroundColor3 = Theme.bg_deep,
    BorderSizePixel = 0,
    Parent = InlineFrame,
})
applyTheme(ContentFrame, "BackgroundColor3", "bg_deep")
addLayeredBorder(ContentFrame)

-- ══════════════════════════════════════════════════════════════════════════════
--  TAB SYSTEM
-- ══════════════════════════════════════════════════════════════════════════════

tabPages = {}
tabButtons = {}  -- stores the button Instances
tabData = {}     -- stores {textLbl, hideBar} per tab name (separate from Instance)
activeTab = nil

function switchTab(name)
    for n, pg in pairs(tabPages) do pg.Visible = (n == name) end
    for n, btn in pairs(tabButtons) do
        local data = tabData[n]
        if not data then continue end
        if n == name then
            data.textLbl.TextColor3 = Theme.accent
            data.textLbl.TextTransparency = 0
            data.hideBar.Visible = true
            btn.BackgroundColor3 = Theme.bg_inline
        else
            data.textLbl.TextColor3 = Theme.txt
            data.textLbl.TextTransparency = 0.48
            data.hideBar.Visible = false
            btn.BackgroundColor3 = Theme.bg_panel
        end
    end
    activeTab = name
end

function addTab(label)
    local btn = mk("TextButton", {
        Size = UDim2.new(0, 90, 1, 0),
        BackgroundColor3 = Theme.bg_panel,
        BorderSizePixel = 2,
        BorderColor3 = Theme.border,
        Text = "",
        AutoButtonColor = false,
        Parent = TabBar,
    })
    applyTheme(btn, "BackgroundColor3", "bg_panel")
    applyTheme(btn, "BorderColor3", "border")
    addStroke(btn, "outline", 1)
    addVertGradient(btn)

    local textLbl = mk("TextLabel", {
        Size = UDim2.fromScale(1, 1),
        Position = UDim2.fromOffset(0, -1),
        BackgroundTransparency = 1,
        Text = label:upper(),
        TextColor3 = Theme.txt,
        TextTransparency = 0.48,
        FontFace = UIFont,
        TextSize = 11,
        Parent = btn,
    })
    addTextShadow(textLbl)

    -- Accent underline shown at the bottom of the active tab (matches the reference screenshot).
    local hideBar = mk("Frame", {
        Size = UDim2.new(1, 0, 0, 2),
        Position = UDim2.new(0, 0, 1, -2),
        AnchorPoint = Vector2.new(0, 1),
        BackgroundColor3 = Theme.accent,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 4,
        Parent = btn,
    })
    applyTheme(hideBar, "BackgroundColor3", "accent")

    -- Store data in a plain Lua table, NOT on the Instance
    tabData[label] = {textLbl = textLbl, hideBar = hideBar}

    btn.MouseEnter:Connect(function()
        if activeTab ~= label then
            tw(textLbl, {TextColor3 = Theme.accent_glow})
            tw(btn, {BackgroundColor3 = Theme.bg_hover})
        end
    end)
    btn.MouseLeave:Connect(function()
        if activeTab ~= label then
            tw(textLbl, {TextColor3 = Theme.txt})
            tw(btn, {BackgroundColor3 = Theme.bg_panel})
        end
    end)

    -- Page
    local page = mk("ScrollingFrame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Theme.accent_dim,
        CanvasSize = UDim2.fromScale(0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false,
        Parent = ContentFrame,
    })
    mk("UIPadding", {PaddingTop=UDim.new(0,8), PaddingBottom=UDim.new(0,8),
        PaddingLeft=UDim.new(0,8), PaddingRight=UDim.new(0,8), Parent=page})
    mk("UIListLayout", {FillDirection=Enum.FillDirection.Vertical, SortOrder=Enum.SortOrder.LayoutOrder,
        Padding=UDim.new(0,7), Parent=page})

    tabPages[label] = page
    tabButtons[label] = btn
    btn.MouseButton1Click:Connect(function() switchTab(label) end)
    return page
end

-- ══════════════════════════════════════════════════════════════════════════════
--  SECTION BUILDER 
-- ══════════════════════════════════════════════════════════════════════════════

function addSection(page, title)
    local wrap = mk("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Theme.bg_inline,
        BorderSizePixel = 0,
        Parent = page,
    })
    applyTheme(wrap, "BackgroundColor3", "bg_inline")
    addLayeredBorder(wrap)

    -- Accent line at top
    addAccentLine(wrap, UDim2.fromOffset(0, 0), UDim2.new(1, 0, 0, 2))

    -- Section title
    local titleLbl = mk("TextLabel", {
        Size = UDim2.new(1, -10, 0, 16),
        Position = UDim2.fromOffset(6, 4),
        BackgroundTransparency = 1,
        Text = title:upper(),
        TextColor3 = Theme.accent_glow,
        FontFace = UIFontBold,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = wrap,
    })
    applyTheme(titleLbl, "TextColor3", "accent_glow")
    addTextShadow(titleLbl)

    -- Body container
    local body = mk("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Position = UDim2.fromOffset(0, 22),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Parent = wrap,
    })
    mk("UIPadding", {PaddingTop=UDim.new(0,4), PaddingBottom=UDim.new(0,6),
        PaddingLeft=UDim.new(0,8), PaddingRight=UDim.new(0,8), Parent=body})
    mk("UIListLayout", {FillDirection=Enum.FillDirection.Vertical, SortOrder=Enum.SortOrder.LayoutOrder,
        Padding=UDim.new(0,5), Parent=body})

    return body
end

-- ══════════════════════════════════════════════════════════════════════════════
--  ELEMENT BUILDERS
-- ══════════════════════════════════════════════════════════════════════════════

-- addLabel ─────────────────────────────────────────────
function addLabel(parent, defaultText)
    local lbl = mk("TextLabel", {
        Size = UDim2.new(1, 0, 0, 14),
        BackgroundTransparency = 1,
        Text = defaultText or "",
        TextColor3 = Theme.txt_muted,
        FontFace = UIFont, TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        RichText = true,
        Parent = parent,
    })
    addTextShadow(lbl)
    local shim = {}
    setmetatable(shim, {
        __index = function(_, k)
            if k == "Text" then return lbl.Text end
            if k == "TextColor3" then return lbl.TextColor3 end
        end,
        __newindex = function(_, k, v)
            if k == "Text" then lbl.Text = v
            elseif k == "TextColor3" then lbl.TextColor3 = v end
        end,
    })
    return shim
end

-- addButton ────────────────────────────────────────────
function addButton(parent, label, callback)
    local btn = mk("TextButton", {
        Size = UDim2.new(1, 0, 0, 22),
        BackgroundColor3 = Theme.bg_element,
        BorderSizePixel = 2,
        BorderColor3 = Theme.border,
        Text = "",
        AutoButtonColor = false,
        Parent = parent,
    })
    applyTheme(btn, "BackgroundColor3", "bg_element")
    applyTheme(btn, "BorderColor3", "border")
    addStroke(btn, "outline", 1)
    addVertGradient(btn)

    local textLbl = mk("TextLabel", {
        Size = UDim2.fromScale(1, 1),
        Position = UDim2.fromOffset(0, -1),
        BackgroundTransparency = 1,
        Text = label,
        TextColor3 = Theme.txt,
        FontFace = UIFont, TextSize = 11,
        Parent = btn,
    })
    applyTheme(textLbl, "TextColor3", "txt")
    addTextShadow(textLbl)

    btn.MouseButton1Click:Connect(callback or function() end)
    btn.MouseEnter:Connect(function()
        tw(btn, {BackgroundColor3 = Theme.bg_hover})
        tw(textLbl, {TextColor3 = Theme.accent})
    end)
    btn.MouseLeave:Connect(function()
        tw(btn, {BackgroundColor3 = Theme.bg_element})
        tw(textLbl, {TextColor3 = Theme.txt})
    end)

    local shim = {}
    setmetatable(shim, {
        __index = function(_, k) if k == "Text" then return textLbl.Text end end,
        __newindex = function(_, k, v) if k == "Text" then textLbl.Text = v end end,
    })
    return shim
end

-- addRow ───────────────────────────────────────────────
function addRow(parent)
    local row = mk("Frame", {
        Size = UDim2.new(1, 0, 0, 22),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Parent = parent,
    })
    mk("UIListLayout", {FillDirection=Enum.FillDirection.Horizontal, SortOrder=Enum.SortOrder.LayoutOrder,
        Padding=UDim.new(0,4), Parent=row})

    local rowShim = {}
    function rowShim:Button(cfg)
        local b = mk("TextButton", {
            Size = UDim2.new(0.55, 0, 1, 0),
            BackgroundColor3 = Theme.bg_element,
            BorderSizePixel = 2, BorderColor3 = Theme.border,
            Text = "", AutoButtonColor = false, Parent = row,
        })
        applyTheme(b, "BackgroundColor3", "bg_element")
        applyTheme(b, "BorderColor3", "border")
        addStroke(b, "outline", 1)
        addVertGradient(b)

        local t = mk("TextLabel", {
            Size=UDim2.fromScale(1,1), Position=UDim2.fromOffset(0,-1),
            BackgroundTransparency=1, Text=cfg.Text or "button",
            TextColor3=Theme.txt, FontFace=UIFont, TextSize=11, Parent=b,
        })
        addTextShadow(t)

        b.MouseButton1Click:Connect(cfg.Callback or function() end)
        b.MouseEnter:Connect(function()
            tw(b, {BackgroundColor3 = Theme.bg_hover})
            tw(t, {TextColor3 = Theme.accent})
        end)
        b.MouseLeave:Connect(function()
            tw(b, {BackgroundColor3 = Theme.bg_element})
            tw(t, {TextColor3 = Theme.txt})
        end)
        return b
    end
    function rowShim:Keybind(cfg)
        return addKeybind(row, cfg, UDim2.new(0.45, -4, 1, 0))
    end
    return rowShim
end

-- addKeybind ──────────────────────────────────────────
function addKeybind(parent, cfg, size)
    local currentKey = cfg.Value or Enum.KeyCode.Unknown
    local binding = false

    local btn = mk("TextButton", {
        Size = size or UDim2.new(1, 0, 0, 22),
        BackgroundColor3 = Theme.bg_element,
        BorderSizePixel = 2, BorderColor3 = Theme.border,
        Text = "", AutoButtonColor = false, Parent = parent,
    })
    applyTheme(btn, "BackgroundColor3", "bg_element")
    applyTheme(btn, "BorderColor3", "border")
    addStroke(btn, "outline", 1)

    local inner = mk("Frame", {Size=UDim2.fromScale(1,1), BackgroundTransparency=1, Parent=btn})
    mk("UIPadding", {PaddingLeft=UDim.new(0,6), PaddingRight=UDim.new(0,4), Parent=inner})

    mk("TextLabel", {
        Size=UDim2.new(0.55,0,1,0), BackgroundTransparency=1,
        Text=cfg.Label or "keybind", TextColor3=Theme.txt_muted,
        FontFace=UIFont, TextSize=10, TextXAlignment=Enum.TextXAlignment.Left,
        Parent=inner,
    })

    local keyBg = mk("Frame", {
        Size=UDim2.new(0.42,0,0.7,0), Position=UDim2.new(0.58,0,0.15,0),
        BackgroundColor3=Theme.bg_deep, BorderSizePixel=2, BorderColor3=Theme.border,
        Parent=inner,
    })
    applyTheme(keyBg, "BackgroundColor3", "bg_deep")
    applyTheme(keyBg, "BorderColor3", "border")
    addStroke(keyBg, "accent_dim", 1, 0.4)

    local keyLbl = mk("TextLabel", {
        Size=UDim2.fromScale(1,1), BackgroundTransparency=1,
        Text=tostring(currentKey):gsub("Enum.KeyCode.", ""),
        TextColor3=Theme.accent, FontFace=UIFont, TextSize=10,
        TextXAlignment=Enum.TextXAlignment.Center, Parent=keyBg,
    })
    applyTheme(keyLbl, "TextColor3", "accent")
    addTextShadow(keyLbl)

    local shim = {Value = currentKey}
    btn.MouseButton1Click:Connect(function()
        if binding then return end
        binding = true
        keyLbl.Text = "..."
        keyLbl.TextColor3 = Theme.yellow
        local conn
        conn = TASServices.UserInputService.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.Keyboard then
                shim.Value = inp.KeyCode
                currentKey = inp.KeyCode
                keyLbl.Text = tostring(inp.KeyCode):gsub("Enum.KeyCode.", "")
                keyLbl.TextColor3 = Theme.accent
                binding = false
                conn:Disconnect()
            end
        end)
    end)
    return shim
end

-- addCheckbox ─────────────────────────────────────────
function addCheckbox(parent, cfg)
    local enabled = cfg.Default or false

    local row = mk("TextButton", {
        Size=UDim2.new(1,0,0,18), BackgroundTransparency=1, BorderSizePixel=0,
        Text="", AutoButtonColor=false, Parent=parent,
    })

    local box = mk("Frame", {
        Size=UDim2.fromOffset(12,12), Position=UDim2.fromOffset(0,3),
        BackgroundColor3=Theme.bg_deep, BorderSizePixel=2, BorderColor3=Theme.border,
        Parent=row,
    })
    applyTheme(box, "BackgroundColor3", "bg_deep")
    applyTheme(box, "BorderColor3", "border")
    addStroke(box, "outline", 1)
    addVertGradient(box)

    local tick = mk("TextLabel", {
        Size=UDim2.fromScale(1,1), BackgroundTransparency=1,
        Text="✓", TextColor3=Theme.accent, FontFace=UIFontBold, TextSize=9,
        TextXAlignment=Enum.TextXAlignment.Center, Visible=enabled, Parent=box,
    })
    applyTheme(tick, "TextColor3", "accent")

    local lbl = mk("TextLabel", {
        Size=UDim2.new(1,-20,1,0), Position=UDim2.fromOffset(20,0),
        BackgroundTransparency=1, Text=cfg.Label or "",
        TextColor3=Theme.txt, FontFace=UIFont, TextSize=11,
        TextXAlignment=Enum.TextXAlignment.Left, Parent=row,
    })
    addTextShadow(lbl)

    local shim = {Value = enabled}
    local function setState(v)
        shim.Value = v
        tick.Visible = v
        if v then
            tw(box, {BackgroundColor3 = Theme.accent_dim})
        else
            tw(box, {BackgroundColor3 = Theme.bg_deep})
        end
        if cfg.Callback then cfg.Callback(shim) end
    end
    row.MouseButton1Click:Connect(function() setState(not shim.Value) end)
    setState(enabled)
    return shim
end

-- addTextbox ──────────────────────────────────────────
function addTextbox(parent, cfg)
    local wrap = mk("Frame", {
        Size=UDim2.new(1,0,0,22), BackgroundTransparency=1, BorderSizePixel=0, Parent=parent,
    })
    mk("TextLabel", {
        Size=UDim2.new(0.38,0,1,0), BackgroundTransparency=1,
        Text=cfg.Label or "", TextColor3=Theme.txt_muted,
        FontFace=UIFont, TextSize=10, TextXAlignment=Enum.TextXAlignment.Left,
        Parent=wrap,
    })
    local box = mk("TextBox", {
        Size=UDim2.new(0.62,0,1,0), Position=UDim2.fromScale(0.38,0),
        BackgroundColor3=Theme.bg_element, BorderSizePixel=2, BorderColor3=Theme.border,
        Text=tostring(cfg.Value or ""), PlaceholderText=cfg.Placeholder or "",
        PlaceholderColor3=Theme.txt_dim, TextColor3=Theme.txt,
        FontFace=UIFont, TextSize=11, TextXAlignment=Enum.TextXAlignment.Left,
        ClearTextOnFocus=false, Parent=wrap,
    })
    applyTheme(box, "BackgroundColor3", "bg_element")
    applyTheme(box, "BorderColor3", "border")
    mk("UIPadding", {PaddingLeft=UDim.new(0,5), PaddingRight=UDim.new(0,4), Parent=box})
    local bxStroke = addStroke(box, "outline", 1)

    box.Focused:Connect(function()
        tw(bxStroke, {Color = Theme.accent, Transparency = 0.3})
        tw(box, {TextColor3 = Theme.accent})
    end)
    box.FocusLost:Connect(function()
        tw(bxStroke, {Color = Theme.outline, Transparency = 0})
        tw(box, {TextColor3 = Theme.txt})
        if cfg.Callback then cfg.Callback(box, box.Text) end
    end)

    local shim = {_Frame = wrap}
    setmetatable(shim, {
        __index = function(_, k)
            if k == "Value" then return box.Text end
            return nil
        end,
        __newindex = function(_, k, v)
            if k == "Value" then
                box.Text = tostring(v)
                return
            end
            rawset(shim, k, v)
        end,
    })
    function shim:SetValue(v) box.Text = tostring(v) end
    function shim:SetVisible(v) wrap.Visible = v == true end
    return shim
end

-- addCombo (dropdown) ─────────────────────────────────
function addCombo(parent, cfg)
    local selected = ""
    local open = false

    local wrap = mk("Frame", {
        Size=UDim2.new(1,0,0,22), BackgroundTransparency=1, BorderSizePixel=0, Parent=parent,
    })
    mk("TextLabel", {
        Size=UDim2.new(0.38,0,1,0), BackgroundTransparency=1,
        Text=cfg.Text or "", TextColor3=Theme.txt_muted,
        FontFace=UIFont, TextSize=10, TextXAlignment=Enum.TextXAlignment.Left,
        Parent=wrap,
    })

    local dropBtn = mk("TextButton", {
        Size=UDim2.new(0.62,0,1,0), Position=UDim2.fromScale(0.38,0),
        BackgroundColor3=Theme.bg_element, BorderSizePixel=2, BorderColor3=Theme.border,
        Text="  "..(cfg.Placeholder or "select..."), TextColor3=Theme.txt_muted,
        FontFace=UIFont, TextSize=10, TextXAlignment=Enum.TextXAlignment.Left,
        AutoButtonColor=false, Parent=wrap,
    })
    applyTheme(dropBtn, "BackgroundColor3", "bg_element")
    applyTheme(dropBtn, "BorderColor3", "border")
    addStroke(dropBtn, "outline", 1)

    mk("TextLabel", {
        Size=UDim2.fromOffset(16,22), Position=UDim2.new(1,-18,0,0),
        BackgroundTransparency=1, Text="▾", TextColor3=Theme.txt_dim,
        FontFace=UIFontBold, TextSize=11, Parent=dropBtn,
    })

    -- Floating list
    local listFrame = mk("Frame", {
        BackgroundColor3=Theme.bg_deep, BorderSizePixel=2, BorderColor3=Theme.border,
        Visible=false, ZIndex=10, Size=UDim2.fromOffset(0,0), Parent=DropdownGui,
    })
    applyTheme(listFrame, "BackgroundColor3", "bg_deep")
    applyTheme(listFrame, "BorderColor3", "border")
    addStroke(listFrame, "outline", 1)
    mk("UIListLayout", {FillDirection=Enum.FillDirection.Vertical, SortOrder=Enum.SortOrder.LayoutOrder,
        Padding=UDim.new(0,0), Parent=listFrame})

    local shim = {Value = ""}

    local function buildList()
        for _, ch in ipairs(listFrame:GetChildren()) do
            if ch:IsA("TextButton") then ch:Destroy() end
        end
        local items = (cfg.GetItems and cfg.GetItems()) or cfg.Items or {}
        listFrame.Size = UDim2.fromOffset(dropBtn.AbsoluteSize.X, math.min(#items, 8) * 20)
        for _, item in ipairs(items) do
            local opt = mk("TextButton", {
                Size=UDim2.new(1,0,0,20), BackgroundTransparency=1, BorderSizePixel=0,
                Text="  "..tostring(item), TextColor3=Theme.txt_muted,
                FontFace=UIFont, TextSize=10, TextXAlignment=Enum.TextXAlignment.Left,
                AutoButtonColor=false, ZIndex=11, Parent=listFrame,
            })
            opt.MouseEnter:Connect(function()
                opt.BackgroundTransparency = 0.85
                tw(opt, {TextColor3 = Theme.accent})
            end)
            opt.MouseLeave:Connect(function()
                opt.BackgroundTransparency = 1
                tw(opt, {TextColor3 = Theme.txt_muted})
            end)
            opt.MouseButton1Click:Connect(function()
                selected = tostring(item); shim.Value = selected
                dropBtn.Text = "  "..selected; dropBtn.TextColor3 = Theme.txt
                listFrame.Visible = false; open = false
                if cfg.Callback then cfg.Callback(shim, item) end
            end)
        end
    end

    dropBtn.MouseButton1Click:Connect(function()
        open = not open
        if open then
            buildList()
            local abs = dropBtn.AbsolutePosition
            listFrame.Position = UDim2.fromOffset(abs.X, abs.Y + 23)
            listFrame.Visible = true
        else listFrame.Visible = false end
    end)
    TASServices.UserInputService.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 and open then
            task.wait()
            local mx, my = inp.Position.X, inp.Position.Y
            local ap, as = listFrame.AbsolutePosition, listFrame.AbsoluteSize
            if not (mx >= ap.X and mx <= ap.X+as.X and my >= ap.Y and my <= ap.Y+as.Y) then
                listFrame.Visible = false; open = false
            end
        end
    end)
    return shim
end

-- makeConsole ─────────────────────────────────────────
function makeConsole(parent)
    local frame = mk("Frame", {
        Size=UDim2.fromScale(1,1), BackgroundColor3=Theme.bg_deep, BorderSizePixel=0, Parent=parent,
    })
    applyTheme(frame, "BackgroundColor3", "bg_deep")

    local sf = mk("ScrollingFrame", {
        Size=UDim2.new(1,0,1,-26), BackgroundTransparency=1, BorderSizePixel=0,
        ScrollBarThickness=2, ScrollBarImageColor3=Theme.accent_dim,
        CanvasSize=UDim2.fromScale(0,0), AutomaticCanvasSize=Enum.AutomaticSize.Y,
        Parent=frame,
    })

    mk("UIPadding", {
        PaddingTop=UDim.new(0,4), PaddingBottom=UDim.new(0,4),
        PaddingLeft=UDim.new(0,6), PaddingRight=UDim.new(0,6), Parent=sf
    })
    mk("UIListLayout", {
        FillDirection=Enum.FillDirection.Vertical, SortOrder=Enum.SortOrder.LayoutOrder,
        Padding=UDim.new(0,2), Parent=sf
    })

    local promptBar = mk("Frame", {
        Size=UDim2.new(1,0,0,26), Position=UDim2.new(0,0,1,-26),
        BackgroundColor3=Theme.bg_inline, BorderSizePixel=0, Parent=frame,
    })
    applyTheme(promptBar, "BackgroundColor3", "bg_inline")

    mk("Frame", {
        Size=UDim2.new(1,0,0,1), BackgroundColor3=Theme.outline,
        BorderSizePixel=0, Parent=promptBar
    })
    mk("Frame", {
        Size=UDim2.new(0,2,1,0), BackgroundColor3=Theme.accent,
        BorderSizePixel=0, Parent=promptBar
    })
    mk("TextLabel", {
        Size=UDim2.fromOffset(14,26), Position=UDim2.fromOffset(6,0),
        BackgroundTransparency=1, Text=">", TextColor3=Theme.accent_glow,
        FontFace=UIFont, TextSize=13, TextXAlignment=Enum.TextXAlignment.Center,
        Parent=promptBar,
    })

    local inputBox = mk("TextBox", {
        Size=UDim2.new(1,-22,1,0), Position=UDim2.fromOffset(20,0),
        BackgroundTransparency=1, BorderSizePixel=0,
        Text="", PlaceholderText="enter command...", PlaceholderColor3=Theme.txt_dim,
        TextColor3=Theme.accent, FontFace=UIFont, TextSize=11,
        TextXAlignment=Enum.TextXAlignment.Left, ClearTextOnFocus=false,
        Parent=promptBar,
    })
    mk("UIPadding", {
        PaddingLeft=UDim.new(0,4), PaddingRight=UDim.new(0,4), Parent=inputBox
    })

    local consoleShim = {Callback = nil}

    local function colorForMessage(msg)
        local lo = msg:lower()
        if lo:find("error", 1, true) or lo:find("fail", 1, true) or lo:find("warn", 1, true) then
            return Theme.yellow
        elseif lo:find("loaded", 1, true) or lo:find("saved", 1, true)
            or lo:find("done", 1, true) or lo:find("ok", 1, true) then
            return Theme.green
        elseif lo:find("reading", 1, true) or lo:find("decod", 1, true)
            or lo:find("encod", 1, true) then
            return Theme.cyan
        end
        return Theme.txt_muted
    end

    function consoleShim:ClearLogs()
        for _, child in ipairs(sf:GetChildren()) do
            if child:IsA("TextBox") then
                child:Destroy()
            end
        end
        sf.CanvasPosition = Vector2.zero
    end

    function consoleShim:AppendText(...)
        local parts = {}
        for _, v in ipairs({...}) do
            parts[#parts+1] = tostring(v)
        end
        local msg = table.concat(parts, " ")

        local line = mk("TextBox", {
            Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
            BackgroundTransparency=1, BorderSizePixel=0,
            Text=msg, TextColor3=colorForMessage(msg),
            FontFace=UIFont, TextSize=11,
            TextXAlignment=Enum.TextXAlignment.Left,
            TextYAlignment=Enum.TextYAlignment.Top,
            TextWrapped=true,
            MultiLine=true,
            TextEditable=false,
            ClearTextOnFocus=false,
            Selectable=true,
            RichText=false,
            Parent=sf,
        })

        task.defer(function()
            sf.CanvasPosition = Vector2.new(0, math.max(0, sf.AbsoluteCanvasSize.Y - sf.AbsoluteSize.Y))
        end)
    end

    inputBox.FocusLost:Connect(function(enter)
        if enter and #inputBox.Text > 0 then
            local txt = inputBox.Text
            inputBox.Text = ""
            if consoleShim.Callback then
                local shimSelf = {Clear = function() inputBox.Text = "" end}
                consoleShim.Callback(shimSelf, txt)
            end
        end
    end)

    local inputShim = {}
    setmetatable(inputShim, {
        __newindex = function(_, k, v)
            if k == "Callback" then consoleShim.Callback = v end
        end,
        __index = function(_, k)
            if k == "Callback" then return consoleShim.Callback end
        end
    })

    return consoleShim, inputShim
end

-- makePopup ───────────────────────────────────────────
function makePopup(title)
    local overlay = mk("Frame", {
        Size=UDim2.fromScale(1,1), BackgroundColor3=Color3.new(0,0,0),
        BackgroundTransparency=0.5, BorderSizePixel=0, ZIndex=9000, Parent=RootGui,
    })
    local box = mk("Frame", {
        Size=UDim2.fromOffset(320,0), AutomaticSize=Enum.AutomaticSize.Y,
        Position=UDim2.fromScale(0.5,0.5), AnchorPoint=Vector2.new(0.5,0.5),
        BackgroundColor3=Theme.bg_window, BorderSizePixel=2, BorderColor3=Theme.border,
        ZIndex=9001, Parent=overlay,
    })
    applyTheme(box, "BackgroundColor3", "bg_window")
    applyTheme(box, "BorderColor3", "border")
    addStroke(box, "outline", 1)

    -- Popup header
    addAccentLine(box, UDim2.fromOffset(0,0), UDim2.new(1,0,0,2))
    local popHdr = mk("Frame", {
        Size=UDim2.new(1,0,0,26), BackgroundColor3=Theme.bg_deep,
        BorderSizePixel=0, ZIndex=9002, Parent=box,
    })
    applyTheme(popHdr, "BackgroundColor3", "bg_deep")

    mk("TextLabel", {
        Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
        Text=title:upper(), TextColor3=Theme.accent,
        FontFace=UIFontBold, TextSize=11, ZIndex=9002, Parent=popHdr,
    })

    mk("Frame", {
        Size=UDim2.new(1,0,0,1), Position=UDim2.new(0,0,1,-1),
        BackgroundColor3=Theme.outline, BorderSizePixel=0, ZIndex=9002, Parent=popHdr,
    })

    local body = mk("Frame", {
        Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
        Position=UDim2.fromOffset(0,26), BackgroundTransparency=1,
        BorderSizePixel=0, ZIndex=9002, Parent=box,
    })
    mk("UIPadding", {PaddingTop=UDim.new(0,8), PaddingBottom=UDim.new(0,10),
        PaddingLeft=UDim.new(0,10), PaddingRight=UDim.new(0,10), Parent=body})
    mk("UIListLayout", {FillDirection=Enum.FillDirection.Vertical, SortOrder=Enum.SortOrder.LayoutOrder,
        Padding=UDim.new(0,6), Parent=body})

    local popup = {}
    function popup:Textbox(c) return addTextbox(body, {Label=c.Text or "", Placeholder=c.Placeholder or "", Callback=c.Callback}) end
    function popup:Combo(c) return addCombo(body, c) end
    function popup:Button(c) addButton(body, c.Text or "ok", function() if c.Callback then c.Callback() end end) end
    function popup:ClosePopup() overlay:Destroy() end
    return popup
end

-- ══════════════════════════════════════════════════════════════════════════════
--  BUILD THE UI
-- ══════════════════════════════════════════════════════════════════════════════

controlsPage = addTab("controls")
physicsPage  = addTab("physics")
visualsPage  = addTab("visuals")
consolePage  = addTab("console")
settingsPage = addTab("settings")

-- Controls/secondary tab UI is built in a helper function so its temporary
-- locals do not consume registers from the giant GUI setup chunk.
local function __BuildRemainingGui()
-- This keeps the main window close to the reference layout while preserving
-- the existing element builders and callbacks.
do
    local cleanup = controlsPage:GetChildren()
    for _, child in ipairs(cleanup) do
        if child:IsA("UIListLayout") or child:IsA("UIPadding") then
            child:Destroy()
        end
    end

    controlsPage.CanvasSize = UDim2.new(0, 0, 0, 0)
    controlsPage.AutomaticCanvasSize = Enum.AutomaticSize.None
    controlsPage.ScrollBarThickness = 0

    local dashboard = mk("Frame", {
        Size = UDim2.new(1, -4, 1, -4),
        Position = UDim2.fromOffset(2, 2),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Parent = controlsPage,
    })

    local leftColumn = mk("Frame", {
        Size = UDim2.new(0.5, -5, 1, 0),
        Position = UDim2.fromOffset(0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Parent = dashboard,
    })
    mk("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 7),
        Parent = leftColumn,
    })

    local rightColumn = mk("Frame", {
        Size = UDim2.new(0.5, -5, 1, 0),
        Position = UDim2.new(0.5, 5, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Parent = dashboard,
    })
    mk("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 7),
        Parent = rightColumn,
    })

    -- ── INFO ───────────────────────────────────────────────────────────────────
    infoSec = addSection(leftColumn, "info")
    RecordedFramesLabel     = addLabel(infoSec, "Frames: 0")
    PressedKeysLabel        = addLabel(infoSec, "Pressed keys: |")
    WritingPressedKeysLabel = addLabel(infoSec, "Writing Pressed keys: |")

    do
        ColorCodeFrame = mk("TextLabel", {
            Size=UDim2.new(1,0,0,14), BackgroundTransparency=1,
            Text="Status: Idle", TextColor3=Theme.txt,
            FontFace=UIFontBold, TextSize=11, TextXAlignment=Enum.TextXAlignment.Left,
            Parent=infoSec,
        })
        addTextShadow(ColorCodeFrame)
    end

    ConnectedLabel = addLabel(infoSec, "AHK folder not found")

    do
        CurrentPlaceIdButton = addButton(infoSec, "Place id: "..tostring(TASPaths.PlaceId), function()
            if setclipboard then setclipboard(tostring(TASPaths.PlaceId)) end
        end)
    end

    CurrentFile = addLabel(infoSec, "Current File: ")

    -- ── CONTROLS ───────────────────────────────────────────────────────────────
    ctrlSec = addSection(leftColumn, "controls")

    FrozenRow = addRow(ctrlSec)
    FrozenRow:Button({Text = "Frozen → Idle", Callback = function() IdleButton_MouseButton1Click() end})
    Frozenkeybind = FrozenRow:Keybind({Label = "keybind", Value = Enum.KeyCode.M})

    Pausekeybind = addKeybind(ctrlSec, {Label = "Pause / Resume", Value = Enum.KeyCode.R})

    IgnoreGameProcessedButton = addCheckbox(ctrlSec, {
        Label = "Ignore Game Processed", Default = false,
        Callback = function(self) TASRuntime.IgnoreGameProcessed = self.Value end,
    })

    KeyboardOverlayThemes = {
        ["Default"] = {
            create = function(container)
                local function createKey(name, position, size, displayText)
                    local key = Instance.new("TextLabel")
                    key.Name=name; key.Size=size; key.Position=position
                    key.BackgroundColor3=Color3.fromRGB(35,35,42); key.BorderSizePixel=0
                    key.Text=displayText or name; key.TextColor3=Color3.fromRGB(220,220,230)
                    key.TextSize=(size.X.Offset>70) and 14 or 18; key.Font=Enum.Font.GothamBold
                    key.Parent=container
                    Instance.new("UICorner",key).CornerRadius=UDim.new(0,6)
                    local stroke=Instance.new("UIStroke",key)
                    stroke.Color=Color3.fromRGB(60,60,70); stroke.Thickness=2; stroke.Transparency=0.5
                    return key
                end
                local ks = UDim2.fromOffset(45,45)
                local W=createKey("W",UDim2.fromOffset(120,10),ks)
                local A=createKey("A",UDim2.fromOffset(65,65),ks)
                local S=createKey("S",UDim2.fromOffset(120,65),ks)
                local D=createKey("D",UDim2.fromOffset(175,65),ks)
                local CL=createKey("CapsLock",UDim2.fromOffset(5,65),UDim2.fromOffset(50,45),"CAPS"); CL.TextSize=12
                local SH=createKey("LeftShift",UDim2.fromOffset(5,120),UDim2.fromOffset(50,45),"SHIFT"); SH.TextSize=12
                local SL=createKey("Slash",UDim2.fromOffset(175,10),UDim2.fromOffset(45,45),"/")
                local SP=createKey("Space",UDim2.fromOffset(65,120),UDim2.fromOffset(210,45),""); SP.TextSize=14
                return {W=W,A=A,S=S,D=D,LeftShift=SH,RightShift=SH,Space=SP,CapsLock=CL,Slash=SL}
            end,
            size = UDim2.fromOffset(320,200),
            updateColors = function(keyFrame, state)
                if state == "writing" then
                    keyFrame.BackgroundColor3 = Color3.fromRGB(200,180,80)
                elseif state == "pressed" then
                    keyFrame.BackgroundColor3 = Color3.fromRGB(80,200,120)
                else
                    keyFrame.BackgroundColor3 = Color3.fromRGB(35,35,42)
                end
            end
        },
    }
    currentTheme = (TasSettings and TasSettings.KeyboardTheme) or "Default"

    KeyboardOverlay = addCheckbox(ctrlSec, {
        Label = "Keyboard Overlay", Default = false,
        Callback = function(self)
            local enabled = self.Value
            if enabled then
                getgenv().KeyboardOverlayEnabled = true
                if not getgenv().KeyboardOverlayGui then
                    local overlayGui = Instance.new("ScreenGui")
                    overlayGui.Name="KeyboardOverlay"; overlayGui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
                    overlayGui.ResetOnSpawn=false; overlayGui.DisplayOrder=9999; overlayGui.Parent=TASServices.Player.PlayerGui
                    local container = Instance.new("Frame")
                    container.Name="Container"; container.Size=KeyboardOverlayThemes[currentTheme].size
                    container.Position=UDim2.new(0,20,1,-container.Size.Y.Offset-20)
                    container.BackgroundTransparency=1; container.BorderSizePixel=0; container.Parent=overlayGui
                    local keys = KeyboardOverlayThemes[currentTheme].create(container)
                    getgenv().KeyboardOverlayGui = overlayGui
                    getgenv().KeyboardOverlayContainer = container
                    getgenv().KeyboardOverlayKeys = keys
                else
                    getgenv().KeyboardOverlayGui.Enabled = true
                end
            else
                getgenv().KeyboardOverlayEnabled = false
                if getgenv().KeyboardOverlayGui then getgenv().KeyboardOverlayGui.Enabled = false end
            end
        end,
    })

    KeyboardThemeCombo = addCombo(ctrlSec, {
        Text = "Overlay Theme", Placeholder = "Default",
        GetItems = function() return {"Default"} end,
        Callback = function(_, sel)
            if sel and KeyboardOverlayThemes[sel] then
                currentTheme = sel
                TasSettings.KeyboardTheme = sel
                QueueSaveTasSettings()
                TASCharacter.ConsoleMessage("Keyboard theme changed to: "..sel)
            end
        end,
    })

    movecameraonfroze = addCheckbox(ctrlSec, {Label = "Move camera while frozen", Default = false})

    ReadRow = addRow(ctrlSec)
    ReadRow:Button({Text = "Read", Callback = function() ReadButton_MouseButton1Click() end})
    Readkeybind = ReadRow:Keybind({Label = "keybind", Value = Enum.KeyCode.Z})

    AbortRow = addRow(ctrlSec)
    AbortRow:Button({Text = "Abort", Callback = function() TASFunctions.StopReading(true) end})
    Abortkeybind = AbortRow:Keybind({Label = "keybind", Value = Enum.KeyCode.L})

    -- ── KEYBINDS ───────────────────────────────────────────────────────────────
    keybindSec = addSection(rightColumn, "keybinds")
    Hideuikeybind               = addKeybind(keybindSec, {Label = "Hide UI",                  Value = Enum.KeyCode.U})
    Recordkeybind               = addKeybind(keybindSec, {Label = "Record / Freeze",          Value = Enum.KeyCode.E})
    Goforwardkeybind            = addKeybind(keybindSec, {Label = "Go forward",               Value = Enum.KeyCode.T})
    Gobackwardskeybind          = addKeybind(keybindSec, {Label = "Go backwards",             Value = Enum.KeyCode.Q})
    Frameadvanceforwardkeybind  = addKeybind(keybindSec, {Label = "Frame advance forward",     Value = Enum.KeyCode.G})
    Frameadvancebackwardskeybind= addKeybind(keybindSec, {Label = "Frame advance backward",    Value = Enum.KeyCode.F})
    Savekeybind                 = addKeybind(keybindSec, {Label = "Save to file",              Value = Enum.KeyCode.P})

    -- ── UTILITY ────────────────────────────────────────────────────────────────
    utilitySec = addSection(rightColumn, "utility")

    addButton(utilitySec, "Erase Recording", function()
        TASFunctions.ResetCurrentRecording()
    end)

    addButton(utilitySec, "Rejoin", function()
        TASCharacter.ConsoleMessage("Rejoining...")
        SaveToFile()
        while TASRuntime.Saving do TASServices.RunService.Heartbeat:Wait() end
        SaveTasSettings()
        task.wait(0.5)
        if #game.Players:GetPlayers() <= 1 then
            game.Players.LocalPlayer:Kick("\nRejoining...")
            task.wait()
            game:GetService("TeleportService"):Teleport(game.PlaceId, game.Players.LocalPlayer)
        else
            game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, game.Players.LocalPlayer)
        end
    end)

    FPSTextbox = addTextbox(utilitySec, {
        Label = "FPS Cap", Value = tostring(TASConfig.FPS), Placeholder = "Enter FPS...",
        Callback = function(_, value)
            local newFPS = tonumber(value)
            if newFPS and newFPS > 0 and newFPS <= 1000 then
                TASConfig.FPS = newFPS
                if setfpscap then pcall(setfpscap, TASConfig.FPS) end
                TasSettings.FPS = TASConfig.FPS
                QueueSaveTasSettings()
                TASCharacter.ConsoleMessage("FPS set to "..tostring(TASConfig.FPS))
            else
                TASCharacter.ConsoleMessage("Invalid FPS value")
            end
        end,
    })

    TASRecordingFPSTextbox = addTextbox(utilitySec, {
        Label = "TAS FPS", Value = tostring(TASConfig.TASRecordingFPS), Placeholder = "Enter TAS FPS...",
        Callback = function(_, value)
            local newFPS = tonumber(value)
            if newFPS and newFPS > 0 and newFPS <= 1000 then
                TASConfig.TASRecordingFPS = newFPS
                TasSettings.TASRecordingFPS = TASConfig.TASRecordingFPS
                QueueSaveTasSettings()
                TASCharacter.ConsoleMessage("TAS FPS set to "..tostring(TASConfig.TASRecordingFPS))
            else
                TASCharacter.ConsoleMessage("Invalid TAS FPS value")
            end
        end,
    })

    TeleportTextbox = addTextbox(utilitySec, {Label = "Teleport PlaceId", Placeholder = "Enter PlaceId..."})
    addButton(utilitySec, "Teleport", function()
        local placeId = tonumber(TeleportTextbox.Value)
        if placeId and placeId > 0 then
            TASCharacter.ConsoleMessage("Teleporting to: "..tostring(placeId))
            SaveToFile()
            while TASRuntime.Saving do TASServices.RunService.Heartbeat:Wait() end
            SaveTasSettings()
            task.wait(0.5)
            pcall(function()
                game:GetService("TeleportService"):Teleport(placeId, game.Players.LocalPlayer)
            end)
        else
            TASCharacter.ConsoleMessage("Invalid PlaceId")
        end
    end)
end

-- Physics tab
physSec = addSection(physicsPage, "physics modifiers")

function getPhysicsValues()
    return {
        WalkSpeed = tonumber(WalkSpeedTextbox and WalkSpeedTextbox.Value),
        JumpPower = tonumber(JumpPowerTextbox and JumpPowerTextbox.Value),
        Gravity = tonumber(GravityTextbox and GravityTextbox.Value),
        Friction = tonumber(FrictionTextbox and FrictionTextbox.Value),
        Density = tonumber(DensityTextbox and DensityTextbox.Value),
    }
end

function ApplyConfiguredPhysics(ignorePlaybackLock)
    local values = getPhysicsValues()
    if TASCharacter.Character then
        local hum = TASCharacter.Character:FindFirstChild("Humanoid")
        local hrp = TASCharacter.Character:FindFirstChild("HumanoidRootPart")
        if hum then
            if values.WalkSpeed and (ignorePlaybackLock or not AllowChangingPhysics) then
                hum.WalkSpeed = values.WalkSpeed
                TASCharacter.DefaultWalkSpeed = values.WalkSpeed
            end
            if values.JumpPower and (ignorePlaybackLock or not AllowChangingPhysics) then
                hum.JumpPower = values.JumpPower
                TASCharacter.DefaultJumpPower = values.JumpPower
            end
        end
        if values.Gravity then
            TASCharacter.DefaultGravity = values.Gravity
            if ignorePlaybackLock or not AllowChangingPhysics then
                workspace.Gravity = values.Gravity
            end
        end
        if hrp and values.Friction and values.Density then
            hrp.CustomPhysicalProperties = PhysicalProperties.new(values.Density, values.Friction, 0.5, 1, 1)
        end
    end
end

function EnforcePlaybackPhysics()
    if not TASRuntime.Reading or AllowChangingPhysics then return end
    ApplyConfiguredPhysics(false)
end

WalkSpeedTextbox = addTextbox(physSec, {Label = "WalkSpeed", Value = "16", Placeholder = "16",
    Callback = function(_, v)
        local n = tonumber(v)
        if n then
            TASCharacter.DefaultWalkSpeed = n
            if TASCharacter.Character and TASCharacter.Character:FindFirstChild("Humanoid") and (not TASRuntime.Reading or not AllowChangingPhysics) then
                TASCharacter.Character.Humanoid.WalkSpeed = n
            end
        end
    end})
JumpPowerTextbox = addTextbox(physSec, {Label = "JumpPower", Value = "50", Placeholder = "50",
    Callback = function(_, v)
        local n = tonumber(v)
        if n then
            TASCharacter.DefaultJumpPower = n
            if TASCharacter.Character and TASCharacter.Character:FindFirstChild("Humanoid") and (not TASRuntime.Reading or not AllowChangingPhysics) then
                TASCharacter.Character.Humanoid.JumpPower = n
            end
        end
    end})
GravityTextbox = addTextbox(physSec, {Label = "Gravity", Value = "196.2", Placeholder = "196.2",
    Callback = function(_, v)
        local n = tonumber(v)
        if n then
            TASCharacter.DefaultGravity = n
            if not TASRuntime.Reading or not AllowChangingPhysics then
                workspace.Gravity = n
            end
        end
    end})
FrictionTextbox = addTextbox(physSec, {Label = "Friction", Value = "0.3", Placeholder = "0.3",
    Callback = function(_, v)
        local n = tonumber(v)
        if n and TASCharacter.Character and TASCharacter.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = TASCharacter.Character.HumanoidRootPart
            local cur = hrp.CustomPhysicalProperties
            hrp.CustomPhysicalProperties = PhysicalProperties.new(cur and cur.Density or 0.7, n, cur and cur.Elasticity or 0.5, 1, 1)
        end
    end})
DensityTextbox = addTextbox(physSec, {Label = "Density", Value = "0.7", Placeholder = "0.7",
    Callback = function(_, v)
        local n = tonumber(v)
        if n and TASCharacter.Character and TASCharacter.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = TASCharacter.Character.HumanoidRootPart
            local cur = hrp.CustomPhysicalProperties
            hrp.CustomPhysicalProperties = PhysicalProperties.new(n, cur and cur.Friction or 0.3, cur and cur.Elasticity or 0.5, 1, 1)
        end
    end})

addCheckbox(physSec, {Label = "Allow changing physics", Default = true, Callback = function(self)
    AllowChangingPhysics = self.Value
    if not AllowChangingPhysics then
        ApplyConfiguredPhysics(false)
    end
end})

addButton(physSec, "Apply Physics", function()
    ApplyConfiguredPhysics(true)
    TASCharacter.ConsoleMessage("Physics applied")
end)

addButton(physSec, "Reset Physics", function()
    WalkSpeedTextbox.Value = "16"
    JumpPowerTextbox.Value = "50"
    GravityTextbox.Value = "196.2"
    FrictionTextbox.Value = "0.3"
    DensityTextbox.Value = "0.7"
    TASCharacter.DefaultWalkSpeed = 16
    TASCharacter.DefaultJumpPower = 50
    TASCharacter.DefaultGravity = 196.2
    ApplyConfiguredPhysics(true)
    TASCharacter.ConsoleMessage("Physics reset")
end)

-- Visuals tab
visSec = addSection(visualsPage, "visuals")
addCheckbox(visSec, {Label = "Stats HUD", Default = false, Callback = function(self)
    StatsHudEnabled = self.Value
    if StatsHudEnabled then createStatsHud() else destroyStatsHud() end
end})
addCheckbox(visSec, {Label = "Trajectory Tracer", Default = false, Callback = function(self)
    TASTracer.TracerEnabled = self.Value
    if not TASTracer.TracerEnabled then clearTracerObjects() end
end})
addTextbox(visSec, {Label = "Tracer Lookahead (s)", Value = tostring(TASTracer.TRACER_LOOKAHEAD),
    Callback = function(_, v)
        local n = tonumber(v)
        if n and n > 0 and n <= 5 then TASTracer.TRACER_LOOKAHEAD = n end
    end})
addTextbox(visSec, {Label = "Tracer Steps", Value = tostring(TASTracer.TRACER_STEPS),
    Callback = function(_, v)
        local n = tonumber(v)
        if n and n > 0 and n <= 100 then TASTracer.TRACER_STEPS = math.floor(n); clearTracerObjects() end
    end})

-- Optional visual toggles moved out of Controls so the main dashboard stays compact.
addCheckbox(visSec, {Label = "Disable Particle Emitters", Default = false, Callback = function(self)
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("ParticleEmitter") then obj.Enabled = not self.Value end
    end
end})
addCheckbox(visSec, {Label = "Disable Lighting Effects", Default = false, Callback = function(self)
    local Lighting = game:GetService("Lighting")
    if self.Value then
        if not getgenv().OriginalLightingSettings then
            getgenv().OriginalLightingSettings = {
                Ambient=Lighting.Ambient, Brightness=Lighting.Brightness,
                GlobalShadows=Lighting.GlobalShadows, ClockTime=Lighting.ClockTime,
            }
        end
        Lighting.Ambient=Color3.fromRGB(255,255,255); Lighting.Brightness=2
        Lighting.GlobalShadows=false; Lighting.ClockTime=14
        for _, obj in pairs(Lighting:GetChildren()) do
            if obj:IsA("BloomEffect") or obj:IsA("BlurEffect") or obj:IsA("ColorCorrectionEffect")
                or obj:IsA("SunRaysEffect") or obj:IsA("DepthOfFieldEffect") then
                obj.Enabled = false
            end
        end
    else
        if getgenv().OriginalLightingSettings then
            for k, v in pairs(getgenv().OriginalLightingSettings) do Lighting[k] = v end
        end
        for _, obj in pairs(Lighting:GetChildren()) do
            if obj:IsA("BloomEffect") or obj:IsA("BlurEffect") or obj:IsA("ColorCorrectionEffect")
                or obj:IsA("SunRaysEffect") or obj:IsA("DepthOfFieldEffect") then
                obj.Enabled = true
            end
        end
    end
end})
addCheckbox(visSec, {Label = "Motion Blur", Default = false, Callback = function(self)
    local Lighting = game:GetService("Lighting")
    if self.Value then
        if not Lighting:FindFirstChild("TasabilityMotionBlur") then
            local blur = Instance.new("BlurEffect"); blur.Name="TasabilityMotionBlur"; blur.Size=3; blur.Parent=Lighting
        end
    else
        local blur = Lighting:FindFirstChild("TasabilityMotionBlur")
        if blur then blur:Destroy() end
    end
end})

-- ── CONSOLE TAB ──────────────────────────────────────────────────────────────
consoleTabFrame = mk("Frame", {
    Size=UDim2.fromScale(1,1), BackgroundColor3=Theme.bg_deep,
    BorderSizePixel=0, Visible=false, Parent=ContentFrame,
})
applyTheme(consoleTabFrame, "BackgroundColor3", "bg_deep")
tabPages["console"] = consoleTabFrame

console, ConsoleInput = makeConsole(consoleTabFrame)

-- ── SETTINGS TAB ─────────────────────────────────────────────────────────────
-- File actions intentionally do NOT live here; they are handled by the Files panel.

local tasSettingsSec = addSection(settingsPage, "TAS Settings")
local CORecordingRadiusTextbox
local allowClientObjectManipulation = addCheckbox(tasSettingsSec, {
    Label = "Allow Client Object Manipulation",
    Default = TASConfig.AllowClientObjectManipulation ~= false,
    Callback = function(self)
        TASConfig.AllowClientObjectManipulation = self.Value == true
        if not TASConfig.AllowClientObjectManipulation then
            pcall(function()
                if CO and CO.ReleaseHeldState then CO.ReleaseHeldState() end
                if CO and CO.Stop then CO.Stop() end
                if CO then
                    CO._initialized = false
                    CO._recordingRequested = false
                    CO._forceFullFrame = false
                    CO._lerpTargets = {}
                    CO._FullStateCache = nil
                end
            end)
        elseif not TASRuntime.Reading and CO and CO.QueueInitialization then
            pcall(CO.QueueInitialization)
        end
        if CORecordingRadiusTextbox then
            CORecordingRadiusTextbox:SetVisible(TASConfig.AllowClientObjectManipulation)
        end
        QueueSaveTasSettings()
    end,
})

CORecordingRadiusTextbox = addTextbox(tasSettingsSec, {
    Label = "Set radius recording client objects (in studs)",
    Value = tostring(TASConfig.CORecordingRadius),
    Placeholder = "250",
    Callback = function(_, v)
        local n = tonumber(v)
        if n and n >= 0 and n <= 10000 then
            TASConfig.CORecordingRadius = n
            QueueSaveTasSettings()
        end
    end,
})
CORecordingRadiusTextbox:SetVisible(TASConfig.AllowClientObjectManipulation ~= false)

themeSec = addSection(settingsPage, "theme")

addCombo(themeSec, {
    Text = "Theme Preset", Placeholder = "Midnight Blue",
    GetItems = function()
        local names = {}
        for k in pairs(ThemePresets) do table.insert(names, k) end
        table.sort(names)
        return names
    end,
    Callback = function(_, presetName)
        if presetName then
            setThemePreset(presetName)
            TasSettings.ThemePreset = presetName
            QueueSaveTasSettings()
            TASCharacter.ConsoleMessage("Theme set to: "..presetName)
        end
    end,
})

addLabel(themeSec, "Customize accent color below:")

addTextbox(themeSec, {
    Label = "Accent Hex", Value = "#64AFFF", Placeholder = "#64AFFF",
    Callback = function(_, v)
        local ok, col = pcall(function() return Color3.fromHex(v) end)
        if ok and col then
            Theme.accent = col
            Theme.accent_dim = Color3.fromRGB(
                math.floor(col.R*255*0.30), math.floor(col.G*255*0.30), math.floor(col.B*255*0.30))
            Theme.accent_glow = Color3.fromRGB(
                math.floor(col.R*255*0.80), math.floor(col.G*255*0.80), math.floor(col.B*255*0.80))
            refreshAllTheme()
            TasSettings.AccentHex = v
            QueueSaveTasSettings()
            TASCharacter.ConsoleMessage("Accent set to: "..v)
        end
    end,
})

addButton(themeSec, "Save Settings", function()
    SaveTasSettings()
    TASCharacter.ConsoleMessage("Settings saved")
end)

_G.__TasabilityWindowSec = addSection(settingsPage, "window")
addTextbox(_G.__TasabilityWindowSec, {
    Label = "Window Width", Value = tostring(MainFrame.Size.X.Offset), Placeholder = "700",
    Callback = function(_, v)
        local n = tonumber(v)
        if n and n >= 700 and n <= 1400 then
            MainFrame.Size = UDim2.fromOffset(n, MainFrame.Size.Y.Offset)
            QueueSaveTasSettings()
        end
    end,
})
addTextbox(_G.__TasabilityWindowSec, {
    Label = "Window Height", Value = tostring(MainFrame.Size.Y.Offset), Placeholder = "500",
    Callback = function(_, v)
        local n = tonumber(v)
        if n and n >= 500 and n <= 950 then
            MainFrame.Size = UDim2.fromOffset(MainFrame.Size.X.Offset, n)
            QueueSaveTasSettings()
        end
    end,
})


    switchTab("controls")
end
__BuildRemainingGui()

end -- GUI scope
__BuildGUI()
if type(_G.__TasabilityMaybeOpenDiscordOnFirstLaunch) == "function" then
    _G.__TasabilityMaybeOpenDiscordOnFirstLaunch()
end

-- ── Window shim ──────────────────────────────────────────────────────────────
Window = {}
function Window:ToggleVisibility()
    MainFrame.Visible = not MainFrame.Visible
end

-- ── Current file auto-update ─────────────────────────────────────────────────
task.spawn(function()
    local function getFileName(path)
        if type(path) ~= "string" or path == "" then
            return "No file selected"
        end
        local parts = string.split(path, "\\")
        return parts[#parts] or path
    end

    local old = false
    while task.wait(0.25) do
        local path = TASPaths.ReplayPath
        if path ~= old then
            CurrentFile.Text = "Current File: "..getFileName(path)
            old = path
        end
    end
end)

-- ══════════════════════════════════════════════════════════════════════════════
--  GUI FUNCTIONS
-- ══════════════════════════════════════════════════════════════════════════════

local SetColorCodeFrame
local GetColorCodeFrame
do
    TASCharacter.ConsoleMessage = function(...)
        setthreadidentity(8)
        console:AppendText(...)
    end

    TASCharacter.ConsoleMessage("Tasability loading...")

    SetColorCodeFrame = function(Name)
        -- Status UI must never be able to break recording/playback cleanup.
        -- Some executor callback threads may temporarily lack Instance capability
        -- after a previous playback, so treat HUD/status updates as best-effort.
        pcall(function()
            if ColorCodeFrame then
                ColorCodeFrame.TextColor3 = TASConfig.ColorCodes[Name] or TASConfig.ColorCodes.None
                ColorCodeFrame.Text = "Status: "..(TASConfig.ColorCodes[Name] and Name or "None")
            end
            if StatusPill then
                StatusPill.Text = "■ "..(TASConfig.ColorCodes[Name] and Name or "None")
                StatusPill.TextColor3 = TASConfig.ColorCodes[Name] or Theme.txt_muted
            end
        end)
    end

    GetColorCodeFrame = function()
        return string.sub(ColorCodeFrame.Text, 9, #ColorCodeFrame.Text)
    end
end

do -- Anticheat bypasses
	do -- standard anti kick
		--// Variables
		
		local Players = game:GetService("Players")
		local OldNameCall = nil

		--// Anti Kick Hook
		local plr = game.Players.LocalPlayer
		OldNameCall = hookmetamethod(game, "__namecall", function(Self, ...)
			local NameCallMethod = getnamecallmethod()

			if not checkcaller() and Self == plr and NameCallMethod == "Kick" then
				if getgenv().SendNotifications == true then
					game:GetService("StarterGui"):SetCore("SendNotification", {
						Title = "Almost Kicked",
						Text = tostring(({...})[1]),
						Icon = "rbxassetid://6238540373",
						Duration = 3,
					})
				end
				
				return nil
			end
			
			return OldNameCall(Self, ...)
		end)
	end
	pcall(function() -- Practice anticheat bypass
		game.ReplicatedStorage.Remotes.Send:Destroy()
	end)
	pcall(function() -- Slad anticheat bypass
		local sendremote = game.ReplicatedStorage.DefaultChatSystemChatEvents.ChannelNameColorUpdated
		local oldspawn
		oldspawn = hookfunction(getrenv().spawn, function(...)
			if not checkcaller() and (tostring(getcallingscript()) == "Animate" or tostring(getcallingscript()) == "RbxAnimateScript") then
				return oldspawn(function()
					
				end)
			end
			return oldspawn(...)
		end)
		sendremote:Destroy()
	end)

	-- ADONIS BYPASS
	; (function()
		local d = false
		local h = {}
		local state = {x = nil, y = nil, o = nil}
		setthreadidentity(2)
		for _, v in getgc(true) do
			if typeof(v) == "table" then
				local detected = rawget(v, "Detected")
				local kill = rawget(v, "Kill")
				if typeof(detected) == "function" and not state.x then
					state.x = detected
					hookfunction(state.x, function(c, f, n)
						if c ~= "_" and d then
							warn(`Adonis AntiCheat flagged\nMethod: {c}\nInfo: {f}`)
						end
						return true
					end)
					table.insert(h, state.x)
				end
				if rawget(v, "Variables") and rawget(v, "Process") and typeof(kill) == "function" and not state.y then
					state.y = kill
					hookfunction(state.y, function(f)
						if d then warn(`Adonis AntiCheat tried to kill (fallback): {f}`) end
						return nil
					end)
					table.insert(h, state.y)
				end
			end
		end
		local debugInfo = getrenv().debug.info
		state.o = hookfunction(debugInfo, newcclosure(function(a, ...)
			if state.x and a == state.x then
				if d then warn(`zins adonis bypassed`) end
				return coroutine.yield(coroutine.running())
			end
			return state.o(a, ...)
		end))
		setthreadidentity(7)
	end)()
end -- Anticheat bypasses

-- Animation Functions (assigned inside do-block below)
local StopAllAnimations, Reanimate, GetAnimationFunctionFromId
local onDied, onRunning, onJumping, onClimbing, onGettingUp
local onFreeFall, onFallingDown, onSeated, onPlatformStanding, onSwimming
local PlayAnimation, setAnimationSpeed

do
	StopAllAnimations = function()
		for _,v in pairs(TASCharacter.Humanoid:GetPlayingAnimationTracks()) do 
			v:Stop()
		end
	end
	
	GetAnimationFunctionFromId = function(Id)
		return ({
			[1] = OnDied;
			[2] = onRunning;
			[3] = onJumping;
			[4] = onClimbing;
			[5] = onGettingUp;
			[6] = onFreeFall;
			[7] = onFallingDown;
			[8] = onSeated;
			[9] = onPlatformStanding;
			[10] = onSwimming;
		})[Id]
	end

	Reanimate = function(Character)
		local animateFound = false
		
	
		if not Character:FindFirstChild("Humanoid") then
			Character:WaitForChild("Humanoid", 5)
		end
		
	
		if Character:WaitForChild("Animate", 3) then
			for _, Animate in ipairs(Character:GetDescendants()) do
				if Animate:IsA("LocalScript") and Animate.Name == "Animate" then
					animateFound = true
					for _,Connection in pairs(getconnections(Animate.Changed)) do
						Connection:Disconnect()
					end
					if TASConfig.BypassAntiExploit then
						Animate.Disabled = true
						if setparentinternal then
							setparentinternal(Animate, game.Lighting)
						else
							TASCharacter.ConsoleMessage("Your exploit does not support setparentinternal, expect animation glitches")
						end
					else
						Animate:Destroy()
					end
					TASCharacter.ConsoleMessage("Animate script found and disabled")
					break
				end
			end
		end
		
	
		if not animateFound then
			TASCharacter.ConsoleMessage("[WARNING] Animate script not found - animations will be handled manually")
		end
		
		StopAllAnimations()
		
		do -- Animate script replacement
			local Figure = Character
			local Torso = Figure:WaitForChild("Torso")
			local RightShoulder = Torso:WaitForChild("Right Shoulder")
			local LeftShoulder = Torso:WaitForChild("Left Shoulder")
			local RightHip = Torso:WaitForChild("Right Hip")
			local LeftHip = Torso:WaitForChild("Left Hip")
			local Neck = Torso:WaitForChild("Neck")
			TASCharacter.Humanoid = Figure:WaitForChild("Humanoid")

			local currentAnim = ""
			local currentAnimInstance = nil
			local currentAnimTrack = nil
			local currentAnimKeyframeHandler = nil
			local animTable = {}
			local animNames = { 
				idle = 	{	
							{ id = "http://www.roblox.com/asset/?id=180435571", weight = 8 },
							{ id = "http://www.roblox.com/asset/?id=180435792", weight = 1 }
						},
				walk = 	{ 	
							{ id = "http://www.roblox.com/asset/?id=180426354", weight = 10 } 
						}, 
				run = 	{
							{ id = "run.xml", weight = 10 } 
						}, 
				jump = 	{
							{ id = "http://www.roblox.com/asset/?id=125750702", weight = 12 } 
						}, 
				fall = 	{
							{ id = "http://www.roblox.com/asset/?id=180436148", weight = 9 } 
						}, 
				climb = {
							{ id = "http://www.roblox.com/asset/?id=180436334", weight = 10 } 
						}, 
				sit = 	{
							{ id = "http://www.roblox.com/asset/?id=178130996", weight = 10 } 
						},	
				toolnone = {
							{ id = "http://www.roblox.com/asset/?id=182393478", weight = 10 } 
						},
				toolslash = {
							{ id = "http://www.roblox.com/asset/?id=129967390", weight = 10 } 
						},
				toollunge = {
							{ id = "http://www.roblox.com/asset/?id=129967478", weight = 10 } 
						},
				wave = {
							{ id = "http://www.roblox.com/asset/?id=128777973", weight = 10 } 
						},
				point = {
							{ id = "http://www.roblox.com/asset/?id=128853357", weight = 10 } 
						},
				dance1 = {
							{ id = "http://www.roblox.com/asset/?id=182435998", weight = 10 }, 
							{ id = "http://www.roblox.com/asset/?id=182491037", weight = 10 }, 
							{ id = "http://www.roblox.com/asset/?id=182491065", weight = 10 } 
						},
				dance2 = {
							{ id = "http://www.roblox.com/asset/?id=182436842", weight = 10 }, 
							{ id = "http://www.roblox.com/asset/?id=182491248", weight = 10 }, 
							{ id = "http://www.roblox.com/asset/?id=182491277", weight = 10 } 
						},
				dance3 = {
							{ id = "http://www.roblox.com/asset/?id=182436935", weight = 10 }, 
							{ id = "http://www.roblox.com/asset/?id=182491368", weight = 10 }, 
							{ id = "http://www.roblox.com/asset/?id=182491423", weight = 10 } 
						},
				laugh = {
							{ id = "http://www.roblox.com/asset/?id=129423131", weight = 10 } 
						},
				cheer = {
							{ id = "http://www.roblox.com/asset/?id=129423030", weight = 10 } 
						},
			}
			local dances = {"dance1", "dance2", "dance3"}

			local emoteNames = { wave = false, point = false, dance1 = true, dance2 = true, dance3 = true, laugh = false, cheer = false}

			function configureAnimationSet(name, fileList)
				if (animTable[name] ~= nil) then
					for _, connection in pairs(animTable[name].connections) do
						connection:disconnect()
					end
				end
				animTable[name] = {}
				animTable[name].count = 0
				animTable[name].totalWeight = 0	
				animTable[name].connections = {}

				if (animTable[name].count <= 0) then
					for idx, anim in pairs(fileList) do
						animTable[name][idx] = {}
						animTable[name][idx].anim = Instance.new("Animation")
						animTable[name][idx].anim.Name = name
						animTable[name][idx].anim.AnimationId = anim.id
						animTable[name][idx].weight = anim.weight
						animTable[name].count = animTable[name].count + 1
						animTable[name].totalWeight = animTable[name].totalWeight + anim.weight
					end
				end
			end

			local animator = TASCharacter.Humanoid and TASCharacter.Humanoid:FindFirstChildOfClass("Animator") or nil
			if animator then
				local animTracks = animator:GetPlayingAnimationTracks()
				for i,track in ipairs(animTracks) do
					track:Stop(0)
					track:Destroy()
				end
			end

			for name, fileList in pairs(animNames) do 
				configureAnimationSet(name, fileList)
			end	

			local toolAnim = "None"
			local toolAnimTime = 0
			local jumpAnimTime = 0
			local jumpAnimDuration = 0.3
			local toolTransitionTime = 0.1
			local fallTransitionTime = 0.3
			local jumpMaxLimbVelocity = 0.75

			function stopAllAnimations()
				local oldAnim = currentAnim
				if (emoteNames[oldAnim] ~= nil and emoteNames[oldAnim] == false) then
					oldAnim = "idle"
				end
				currentAnim = ""
				TASAnimation.currentAnimName = ""
				currentAnimInstance = nil
				if (currentAnimKeyframeHandler ~= nil) then
					currentAnimKeyframeHandler:disconnect()
				end
				if (currentAnimTrack ~= nil) then
					currentAnimTrack:Stop()
					currentAnimTrack:Destroy()
					currentAnimTrack = nil
				end
				TASAnimation.currentAnimTrack = nil
				return oldAnim
			end

			setAnimationSpeed = function(speed)
				-- Humanoid Running/Climbing callbacks may fire while anchored. Do not let
				-- them alter the animation speed we are deliberately holding at freeze.
				if TASFreeze.Frozen then return end
				speed = tonumber(speed) or 0
				TASAnimation.currentAnimSpeed = speed
				if currentAnimTrack then
					pcall(function() currentAnimTrack:AdjustSpeed(speed) end)
				end
			end

			function keyFrameReachedFunc(frameName)
				if (frameName == "End") then
					local repeatAnim = currentAnim
					if (emoteNames[repeatAnim] ~= nil and emoteNames[repeatAnim] == false) then
						repeatAnim = "idle"
					end
					local animSpeed = TASAnimation.currentAnimSpeed
					playAnimation(repeatAnim, 0.0, TASCharacter.Humanoid)
					setAnimationSpeed(animSpeed)
				end
			end

			playAnimation = function(animName, transitionTime, humanoid, bypassAnimateDisabled, forceRestart) 
				pcall(function()
					-- Keep the live recording animation intact while frozen. Explicit frozen-frame
					-- reconstruction uses bypassAnimateDisabled=true.
					if TASFreeze.Frozen and not bypassAnimateDisabled then
						return
					end
					if TASRuntime.AnimateDisabled and not bypassAnimateDisabled then
						return
					end
					
					local lastAnimation = TASRuntime.AnimationQueue[#TASRuntime.AnimationQueue]
					if not lastAnimation or lastAnimation[1] ~= animName or lastAnimation[2] ~= transitionTime then
						table.insert(TASRuntime.AnimationQueue,{animName,transitionTime})
					end
					
					local roll = math.random(1, animTable[animName].totalWeight) 
					local origRoll = roll
					local idx = 1
					while (roll > animTable[animName][idx].weight) do
						roll = roll - animTable[animName][idx].weight
						idx = idx + 1
					end
					local anim = animTable[animName][idx].anim

					if (anim ~= currentAnimInstance) or forceRestart then
						if (currentAnimTrack ~= nil) then
							currentAnimTrack:Stop(transitionTime)
							currentAnimTrack:Destroy()
						end
						TASAnimation.currentAnimSpeed = 1.0
						currentAnimTrack = humanoid:LoadAnimation(anim)
						TASAnimation.currentAnimTrack = currentAnimTrack
						currentAnimTrack.Priority = Enum.AnimationPriority.Core
						currentAnimTrack:Play(transitionTime)
						currentAnim = animName
						TASAnimation.currentAnimName = animName
						currentAnimInstance = anim
						if (currentAnimKeyframeHandler ~= nil) then
							currentAnimKeyframeHandler:disconnect()
						end
						currentAnimKeyframeHandler = currentAnimTrack.KeyframeReached:connect(keyFrameReachedFunc)
					end
				end)
			end

			local toolAnimName = ""
			local toolAnimTrack = nil
			local toolAnimInstance = nil
			local currentToolAnimKeyframeHandler = nil

			function toolKeyFrameReachedFunc(frameName)
				if (frameName == "End") then
					playToolAnimation(toolAnimName, 0.0, TASCharacter.Humanoid)
				end
			end

			function playToolAnimation(animName, transitionTime, humanoid, priority)	 
				local roll = math.random(1, animTable[animName].totalWeight) 
				local origRoll = roll
				local idx = 1
				while (roll > animTable[animName][idx].weight) do
					roll = roll - animTable[animName][idx].weight
					idx = idx + 1
				end
				local anim = animTable[animName][idx].anim
				if (toolAnimInstance ~= anim) then
					if (toolAnimTrack ~= nil) then
						toolAnimTrack:Stop()
						toolAnimTrack:Destroy()
						transitionTime = 0
					end
					toolAnimTrack = humanoid:LoadAnimation(anim)
					if priority then
						toolAnimTrack.Priority = priority
					end
					toolAnimTrack:Play(transitionTime)
					toolAnimName = animName
					toolAnimInstance = anim
					currentToolAnimKeyframeHandler = toolAnimTrack.KeyframeReached:connect(toolKeyFrameReachedFunc)
				end
			end

			function stopToolAnimations()
				local oldAnim = toolAnimName
				if (currentToolAnimKeyframeHandler ~= nil) then
					currentToolAnimKeyframeHandler:disconnect()
				end
				toolAnimName = ""
				toolAnimInstance = nil
				if (toolAnimTrack ~= nil) then
					toolAnimTrack:Stop()
					toolAnimTrack:Destroy()
					toolAnimTrack = nil
				end
				return oldAnim
			end

			onRunning = function(speed)
				if speed > 0.01 then
					playAnimation("walk", 0.1, TASCharacter.Humanoid)
					if currentAnimInstance and currentAnimInstance.AnimationId == "http://www.roblox.com/asset/?id=180426354" then
						setAnimationSpeed(speed / 14.5)
					end
					TASAnimation.pose = "Running"
				else
					if emoteNames[currentAnim] == nil then
						playAnimation("idle", 0.1, TASCharacter.Humanoid)
						TASAnimation.pose = "Standing"
					end
				end
			end

			onDied = function()
				TASAnimation.pose = "Dead"
			end

			onJumping = function()
				playAnimation("jump", 0.1, TASCharacter.Humanoid)
				jumpAnimTime = jumpAnimDuration
				TASAnimation.pose = "Jumping"
			end

			onClimbing = function(speed)
				playAnimation("climb", 0.1, TASCharacter.Humanoid)
				setAnimationSpeed(speed / 12.0)
				TASAnimation.pose = "Climbing"
			end

			onGettingUp = function()
				TASAnimation.pose = "GettingUp"
			end

			onFreeFall = function()
				if (jumpAnimTime <= 0) then
					playAnimation("fall", fallTransitionTime, TASCharacter.Humanoid)
				end
				TASAnimation.pose = "FreeFall"
			end

			onFallingDown = function()
				TASAnimation.pose = "FallingDown"
			end

			onSeated = function()
				TASAnimation.pose = "Seated"
			end

			onPlatformStanding = function()
				TASAnimation.pose = "PlatformStanding"
			end

			onSwimming = function(speed)
				if speed > 0 then
					TASAnimation.pose = "Running"
				else
					TASAnimation.pose = "Standing"
				end
			end

			function getTool()	
				for _, kid in ipairs(Figure:GetChildren()) do
					if kid.className == "Tool" then return kid end
				end
				return nil
			end

			function getToolAnim(tool)
				for _, c in ipairs(tool:GetChildren()) do
					if c.Name == "toolanim" and c.className == "StringValue" then
						return c
					end
				end
				return nil
			end

			function animateTool()
				if (toolAnim == "None") then
					playToolAnimation("toolnone", toolTransitionTime, TASCharacter.Humanoid, Enum.AnimationPriority.Idle)
					return
				end
				if (toolAnim == "Slash") then
					playToolAnimation("toolslash", 0, TASCharacter.Humanoid, Enum.AnimationPriority.Action)
					return
				end
				if (toolAnim == "Lunge") then
					playToolAnimation("toollunge", 0, TASCharacter.Humanoid, Enum.AnimationPriority.Action)
					return
				end
			end

			function moveSit()
				RightShoulder.MaxVelocity = 0.15
				LeftShoulder.MaxVelocity = 0.15
				RightShoulder:SetDesiredAngle(3.14 /2)
				LeftShoulder:SetDesiredAngle(-3.14 /2)
				RightHip:SetDesiredAngle(3.14 /2)
				LeftHip:SetDesiredAngle(-3.14 /2)
			end

			local lastTick = 0

			function move(time)
				if TASRuntime.AnimateDisabled then
					return
				end
				
				local amplitude = 1
				local frequency = 1
				local deltaTime = time - lastTick
				lastTick = time
				local climbFudge = 0
				local setAngles = false

				if (jumpAnimTime > 0) then
					jumpAnimTime = jumpAnimTime - deltaTime
				end

				if (TASAnimation.pose == "FreeFall" and jumpAnimTime <= 0) then
					playAnimation("fall", fallTransitionTime, TASCharacter.Humanoid)
				elseif (TASAnimation.pose == "Seated") then
					playAnimation("sit", 0.5, TASCharacter.Humanoid)
					return
				elseif (TASAnimation.pose == "Running") then
					playAnimation("walk", 0.1, TASCharacter.Humanoid)
				elseif (TASAnimation.pose == "Dead" or TASAnimation.pose == "GettingUp" or TASAnimation.pose == "FallingDown" or TASAnimation.pose == "Seated" or TASAnimation.pose == "PlatformStanding") then
					stopAllAnimations()
					amplitude = 0.1
					frequency = 1
					setAngles = true
				end

				if (setAngles) then
					local desiredAngle = amplitude * math.sin(time * frequency)
					RightShoulder:SetDesiredAngle(desiredAngle + climbFudge)
					LeftShoulder:SetDesiredAngle(desiredAngle - climbFudge)
					RightHip:SetDesiredAngle(-desiredAngle)
					LeftHip:SetDesiredAngle(-desiredAngle)
				end

				local tool = getTool()
				if tool and tool:FindFirstChild("Handle") then
					local animStringValueObject = getToolAnim(tool)
					if animStringValueObject then
						toolAnim = animStringValueObject.Value
						animStringValueObject.Parent = nil
						toolAnimTime = time + .3
					end
					if time > toolAnimTime then
						toolAnimTime = 0
						toolAnim = "None"
					end
					animateTool()		
				else
					stopToolAnimations()
					toolAnim = "None"
					toolAnimInstance = nil
					toolAnimTime = 0
				end
			end

			local function guarded(fn)
				return function(...) if not TASRuntime.AnimateDisabled then fn(...) end end
			end
			TASCharacter.Humanoid.Died:connect(guarded(onDied))
			TASCharacter.Humanoid.Running:connect(guarded(onRunning))
			TASCharacter.Humanoid.Jumping:connect(onJumping)
			TASCharacter.Humanoid.Climbing:connect(guarded(onClimbing))
			TASCharacter.Humanoid.GettingUp:connect(guarded(onGettingUp))
			TASCharacter.Humanoid.FreeFalling:connect(guarded(onFreeFall))
			TASCharacter.Humanoid.FallingDown:connect(guarded(onFallingDown))
			TASCharacter.Humanoid.Seated:connect(guarded(onSeated))
			TASCharacter.Humanoid.PlatformStanding:connect(guarded(onPlatformStanding))
			TASCharacter.Humanoid.Swimming:connect(guarded(onSwimming))

			game:GetService("Players").LocalPlayer.Chatted:connect(function(msg)
				local emote = ""
				if msg == "/e dance" then
					emote = dances[math.random(1, #dances)]
				elseif (string.sub(msg, 1, 3) == "/e ") then
					emote = string.sub(msg, 4)
				elseif (string.sub(msg, 1, 7) == "/emote ") then
					emote = string.sub(msg, 8)
				end
				
				if (TASAnimation.pose == "Standing" and emoteNames[emote] ~= nil) then
					playAnimation(emote, 0.1, TASCharacter.Humanoid)
				end
			end)

			playAnimation("idle", 0.1, TASCharacter.Humanoid)
			TASAnimation.pose = "Standing"

			spawn(function()
				while Figure.Parent ~= nil do
					local _, time = wait(0.1)
					move(time)
				end
			end)
		end 
	end 
end 

; (function()
	-- Load mouse lock action
	TASServices.VirtualInputManager:SendKeyEvent(true, 304, false, workspace)
	wait()
	TASServices.VirtualInputManager:SendKeyEvent(true, 304, false, workspace)
	wait()
	
	local ZoomControllers = {}
	
	do -- Get ZoomControllers from getgc
		for _,Table in pairs(getgc(true)) do
			if type(Table) == "table" then
				pcall(function()
					if type(Table.SetCameraToSubjectDistance) == "function"
					and type(Table.GetCameraToSubjectDistance) == "function"
					and Table.FIRST_PERSON_DISTANCE_THRESHOLD
					and Table.lastCameraTransform then
						table.insert(ZoomControllers,Table)
					end
				end)
			end
		end
		TASCharacter.ConsoleMessage(tostring(#ZoomControllers).." ZoomController"..(#ZoomControllers == 1 and "" or "s"))
	end
	TASFunctions.GetZoom = function()
		for _,ZoomController in pairs(ZoomControllers) do
			local Zoom = ZoomController:GetCameraToSubjectDistance()
			if Zoom and Zoom ~= 12.5 then
				return Zoom
			end
		end
		return 12.5
	end
	TASFunctions.SetZoom = function(Zoom)
		for _, ZoomController in pairs(ZoomControllers) do
			pcall(function()
				ZoomController:SetCameraToSubjectDistance(Zoom)
			end)
		end
	end

	
	TASFunctions.GetShiftLockEnabled = function()
		return TASServices.ShiftLockEnabled
	end

	local cachedMouseLockController = nil
	local function getMouseLockController()
		if cachedMouseLockController and cachedMouseLockController.DoMouseLockSwitch then
			return cachedMouseLockController
		end
		
		for _, obj in getgc(true) do 
			if type(obj) == "table" and rawget(obj, "activeMouseLockController") then 
				cachedMouseLockController = obj.activeMouseLockController
				return cachedMouseLockController
			end
		end
		return nil
	end

	function shiftLock(active)
		local mouseLockController = getMouseLockController()
		if not mouseLockController then return end
		
		local isLocked = mouseLockController:GetIsMouseLocked()
		if (active and not isLocked) or (not active and isLocked) then
			mouseLockController:DoMouseLockSwitch("MouseLockSwitchAction", Enum.UserInputState.Begin, game)
		end
	end

	TASFunctions.SetShiftLockEnabled = function(Enabled)
		if TASServices.ShiftLockEnabled ~= Enabled then
			TASServices.ShiftLockEnabled = Enabled
			if Enabled then
				TASFunctions.SetCursor("MouseLockedCursor")
			else
				TASFunctions.SetCursor("ArrowFarCursor")
			end
			shiftLock(Enabled)
		end
	end
		
	TASFunctions.SetCameraCFrame = function(NewCFrame)
		TASRuntime.CameraCFrame = NewCFrame
		workspace.CurrentCamera.CFrame = NewCFrame
	end
	
	do
		local BlockGui = Instance.new("ScreenGui")
		local BlockFrame = Instance.new("TextButton")
		BlockFrame.Text = ""
		BlockFrame.BackgroundTransparency = 1
		BlockFrame.Size = UDim2.fromScale(1,1)
		BlockFrame.Selectable = false
		BlockFrame.Selected = false
		BlockFrame.Parent = BlockGui
		BlockGui.Enabled = false
		BlockGui.Parent = GUIParent
		TASFunctions.BlockInputs = function()
			BlockGui.Enabled = true
		end
		TASFunctions.UnblockInputs = function()
			BlockGui.Enabled = false
		end
	end
	
	CursorHolder = Instance.new("ScreenGui")
    CursorHolder.Name = "TasabilityCursor"
    CursorHolder.ZIndexBehavior = Enum.ZIndexBehavior.Global  
    CursorHolder.IgnoreGuiInset = true
    CursorHolder.ResetOnSpawn = false
    CursorHolder.DisplayOrder = 999999  
    CursorHolder.Parent = game:GetService("CoreGui")  
	
	TASRuntime.Cursor.Name = "Cursor"
	TASRuntime.Cursor.BackgroundTransparency = 1
	TASRuntime.Cursor.ZIndex = 10000
	TASRuntime.Cursor.Parent = CursorHolder
	
	TASCharacter.Resolution = workspace.CurrentCamera.ViewportSize
	
	TASFunctions.SetCursor = function(CursorName)
		local CursorData = TASConfig.Cursors[CursorName]
		if CursorData then
			TASRuntime.CursorIcon = CursorData.Icon
			TASRuntime.CursorSize = CursorData.Size
			TASRuntime.CursorOffset = CursorData.Offset
		end
	end
	
	-- Initialize cursor
	TASFunctions.SetCursor("ArrowFarCursor")
end)()



-- AHK Functions
IsInstalled = nil -- IsInstalled() -> bool
SendSignal = nil -- SendSignal(Signal) -> nil
do
	IsInstalled = function()
		return isfolder(TASConfig.AHKConnectionFolderPath)
	end
	SendSignal = function(Signal)
		if IsInstalled() then
			writefile(TASConfig.AHKConnectionRequestPath,Signal)
		else
			TASCharacter.ConsoleMessage("AHK folder not found")
		end
	end
end


local CO = {}
-- CO_REGISTER_SCOPE_V3: isolate CO compiler registers from the main chunk.
(function(CO)
    local CO_EPSILON        = 0.001
    local CO_ATTRIBUTE_NAME = "TAS_ObjectId"
    local CO_SCAN_CHUNK     = 350 -- Yield often enough to keep Record/startup responsive.

    local objectRegistry = {}
    local idByObject     = {}
    local lastCFrames    = {}
    local nextId         = 1
    local scanComplete   = false
    local watchConn      = nil
    local withinRecordRadius = {} -- Tracks radius transitions so re-entering objects get a full sample.
    local ropePartSet    = {}
    local originalAnchored = {}

    -- Anchored BaseParts are not added to the main registry immediately,
    -- because maps can contain thousands of static parts. We still watch them
    -- so a client object that becomes physical after the player approaches it
    -- can be registered at that moment.
    local anchoredCandidates = {}
    local anchoredCandidateConnections = {}

    local function isWithinRecordRadius(part)
        local radius = tonumber(TASConfig.CORecordingRadius) or 0
        if radius <= 0 then return true end
        local root = TASCharacter.RootPart
        if not root or not root.Parent then return true end
        local d = part.Position - root.Position
        return d.X * d.X + d.Y * d.Y + d.Z * d.Z <= radius * radius
    end
    local forceCaptureIds = {}

    local function isBlacklisted(part)
        if TASCharacter.Character and part:IsDescendantOf(TASCharacter.Character) then return true end
        for _, plr in ipairs(game.Players:GetPlayers()) do
            if plr.Character and part:IsDescendantOf(plr.Character) then return true end
        end
        return false
    end

    local function rebuildRopePartSet()
        ropePartSet = {}
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("RopeConstraint") then
                local a0, a1 = obj.Attachment0, obj.Attachment1
                if a0 and a0.Parent and a0.Parent:IsA("BasePart") then ropePartSet[a0.Parent] = true end
                if a1 and a1.Parent and a1.Parent:IsA("BasePart") then ropePartSet[a1.Parent] = true end
            end
        end
    end

    local function clearAnchoredCandidate(part)
        anchoredCandidates[part] = nil
        local conn = anchoredCandidateConnections[part]
        if conn then
            conn:Disconnect()
            anchoredCandidateConnections[part] = nil
        end
    end

    local function registerPart(part, forceCapture)
        if idByObject[part] then
            local id = idByObject[part]
            if forceCapture then
                forceCaptureIds[id] = true
            end
            clearAnchoredCandidate(part)
            return
        end
        if not part:IsA("BasePart") then return end
        if isBlacklisted(part) then return end

        -- Existing TAS_ObjectId is authoritative. If a part already has an ID,
        -- allow it to be restored even while it is still anchored.
        local existingId = part:GetAttribute(CO_ATTRIBUTE_NAME)
        local eligible = (not part.Anchored) or ropePartSet[part] or existingId ~= nil
        if not eligible then return end

        local id
        if existingId and not objectRegistry[existingId] then
            id = existingId
        else
            id = nextId
            nextId = nextId + 1
        end

        part:SetAttribute(CO_ATTRIBUTE_NAME, id)
        objectRegistry[id] = part
        idByObject[part]   = id
        lastCFrames[id]    = part.CFrame
        forceCaptureIds[id] = forceCapture == true
        clearAnchoredCandidate(part)
    end

    local function watchAnchoredPart(part)
        if not part or not part:IsA("BasePart") then return end
        if idByObject[part] or isBlacklisted(part) then return end
        if not part.Anchored or ropePartSet[part] then
            registerPart(part, true)
            return
        end
        if anchoredCandidateConnections[part] then return end

        anchoredCandidates[part] = part.CFrame
        local conn = part:GetPropertyChangedSignal("Anchored"):Connect(function()
            if not part.Parent or isBlacklisted(part) then
                clearAnchoredCandidate(part)
                return
            end
            if not part.Anchored or ropePartSet[part] then
                registerPart(part, true)
            end
        end)
        anchoredCandidateConnections[part] = conn
    end

    local function scanWorkspace()
        rebuildRopePartSet()
        local descendants = workspace:GetDescendants()
        local processed = 0
        for i = 1, #descendants do
            local desc = descendants[i]
            if desc:IsA("BasePart") and not isBlacklisted(desc) then
                if not desc.Anchored or ropePartSet[desc] or desc:GetAttribute(CO_ATTRIBUTE_NAME) ~= nil then
                    registerPart(desc, false)
                else
                    watchAnchoredPart(desc)
                end
            end
            processed = processed + 1
            if processed >= CO_SCAN_CHUNK then
                processed = 0
                TASServices.RunService.Heartbeat:Wait()
            end
        end
        scanComplete = true
        TASCharacter.ConsoleMessage("[CO] Scanned " .. tostring(nextId - 1) .. " registered parts; watching anchored candidates")
    end

    local function startWatching()
        if watchConn then watchConn:Disconnect() end
        watchConn = workspace.DescendantAdded:Connect(function(desc)
            if desc:IsA("RopeConstraint") then
                task.defer(function() rebuildRopePartSet() end)
            elseif desc:IsA("BasePart") and not isBlacklisted(desc) then
                if not desc.Anchored or ropePartSet[desc] or desc:GetAttribute(CO_ATTRIBUTE_NAME) ~= nil then
                    registerPart(desc, true)
                else
                    watchAnchoredPart(desc)
                end
            end
        end)
    end

    function CO.Init()
        CO._initializing = true
        objectRegistry = {}
        idByObject     = {}
        lastCFrames    = {}
        originalAnchored = {}
        anchoredCandidates = {}
        for part, conn in pairs(anchoredCandidateConnections) do
            if conn then conn:Disconnect() end
            anchoredCandidateConnections[part] = nil
        end
        forceCaptureIds = {}
        withinRecordRadius = {}
        nextId         = 1
        scanComplete   = false
        scanWorkspace()
        startWatching()
        TASServices.RunService.Heartbeat:Wait()
        TASCharacter.ConsoleMessage("[CO] Init done, recording world objects")
        CO._initialized = true
        CO._initializing = false
        if CO._recordingRequested then
            -- The registry was rebuilt while recording was already running.
            -- Capture a complete CO state on the next sample so newly discovered
            -- objects are not missing from the replay prefix.
            CO._forceFullFrame = true
            lastCFrames = {}
        end
    end

    CO._initializing = false
    local function QueueCOInitialization()
        if CO._initialized or CO._initializing or TASFreeze.COInitializationQueued then
            return
        end
        TASFreeze.COInitializationQueued = true
        task.spawn(function()
            local ok, err = pcall(function() CO.Init() end)
            TASFreeze.COInitializationQueued = false
            if not ok then
                CO._initializing = false
                TASCharacter.ConsoleMessage("[CO] Init failed: "..tostring(err))
            end
        end)
    end
    CO.QueueInitialization = QueueCOInitialization

    function CO.RecordFrame()
        if not TASConfig.AllowClientObjectManipulation then return {} end
        if not scanComplete then return {} end
        if CO._preparedFirstFrameReady and CO._preparedFirstFrame then
            local first = CO._preparedFirstFrame
            CO._preparedFirstFrame = nil
            CO._preparedFirstFrameReady = false
            return first
        end
        local delta = {}
        local forceAll = CO._forceFullFrame == true
        for id, part in pairs(objectRegistry) do
            if part and part.Parent then
                local inRadius = isWithinRecordRadius(part)
                local wasInRadius = withinRecordRadius[id] == true
                withinRecordRadius[id] = inRadius

                -- Objects outside the radius are not sampled. When they re-enter,
                -- force one complete sample even if they stopped moving.
                if inRadius then
                    local cf   = part.CFrame
                    local prev = lastCFrames[id]
                    local moved = forceAll or forceCaptureIds[id] == true or not wasInRadius
                    if not moved and prev then
                        local rel = prev:ToObjectSpace(cf)
                        local pos = rel.Position
                        if  math.abs(pos.X)                > CO_EPSILON
                         or math.abs(pos.Y)                > CO_EPSILON
                         or math.abs(pos.Z)                > CO_EPSILON
                         or math.abs(rel.XVector.X - 1)   > CO_EPSILON
                        then
                            moved = true
                        end
                    elseif not moved then
                        moved = true
                    end
                    if moved then
                        delta[tostring(id)] = RoundTable({cf:GetComponents()}, TASConfig.RoundDigits)
                        lastCFrames[id]     = cf
                        forceCaptureIds[id] = nil
                    end
                end
            else
                forceCaptureIds[id] = nil
                withinRecordRadius[id] = nil
            end
        end
        CO._forceFullFrame = false
        return delta
    end

    
    CO._coRate = 15
    CO._lerpTargets = {}
    CO._lastCoTime = nil
    CO._coDataWarned = false
    CO._preparedFirstFrame = nil
    CO._preparedFirstFrameReady = false
    function CO.ApplyFrame(delta, forcedAlpha)
        if delta == nil then
            if not CO._coDataWarned then
                CO._coDataWarned = true
                TASCharacter.ConsoleMessage("[CO] WARNING: No CO data in replay. Re-record to enable spinner sync.")
            end
            return
        end
        CO._coDataWarned = false

        for idStr, components in pairs(delta) do
            CO._lerpTargets[idStr] = components
        end

        local alpha = forcedAlpha
        if alpha == nil then
            local now = tick()
            local dt = CO._lastCoTime and math.min(now - CO._lastCoTime, 0.1) or (1/60)
            CO._lastCoTime = now
            alpha = 1 - math.exp(-CO._coRate * dt)
        end

        for idStr, target in pairs(CO._lerpTargets) do
            local id = tonumber(idStr)
            local part = objectRegistry[id]
            if part and part.Parent then
                local targetCFrame = FastTableToCFrame(target)
                if alpha <= 0 then
                    part.CFrame = targetCFrame
                elseif alpha >= 1 then
                    part.CFrame = targetCFrame
                else
                    part.CFrame = part.CFrame:Lerp(targetCFrame, alpha)
                end
            end
        end
    end

    function CO.ApplyInterpolatedFrame(currentDelta, nextDelta, alpha)
        if currentDelta == nil then
            CO.WarnNoCOData()
            return
        end
        CO._coDataWarned = false

        -- Frame[13] is delta data: only objects that changed in the current
        -- sample are present. Keep the last known target for every object.
        for idStr, components in pairs(currentDelta) do
            CO._lerpTargets[idStr] = components
        end

        alpha = math.clamp(tonumber(alpha) or 0, 0, 1)
        for idStr, currentTarget in pairs(CO._lerpTargets) do
            local id = tonumber(idStr)
            local part = objectRegistry[id]
            if part and part.Parent then
                local nextTarget = nil
                if nextDelta then
                    nextTarget = nextDelta[idStr]
                    if nextTarget == nil and id ~= nil then
                        nextTarget = nextDelta[tostring(id)]
                    end
                end

                local fromCF = FastTableToCFrame(currentTarget)
                local toCF = nextTarget and FastTableToCFrame(nextTarget) or fromCF
                if alpha <= 0 or fromCF == toCF then
                    part.CFrame = fromCF
                elseif alpha >= 1 then
                    part.CFrame = toCF
                else
                    part.CFrame = fromCF:Lerp(toCF, alpha)
                end
                part.AssemblyLinearVelocity = Vector3.zero
                part.AssemblyAngularVelocity = Vector3.zero
            end
        end
    end

    function CO.AnchorAll()
        for id, part in pairs(objectRegistry) do
            if part and part.Parent then
                if originalAnchored[id] == nil then
                    originalAnchored[id] = part.Anchored
                end
                part.Anchored = true
                part.AssemblyLinearVelocity = Vector3.zero
                part.AssemblyAngularVelocity = Vector3.zero
            end
        end
        TASCharacter.ConsoleMessage("[CO] All tracked parts anchored")
    end

    function CO.RestoreAnchors()
        for id, part in pairs(objectRegistry) do
            if part and part.Parent then
                local wasAnchored = originalAnchored[id] == true
                part.AssemblyLinearVelocity = Vector3.zero
                part.AssemblyAngularVelocity = Vector3.zero
                part.Anchored = wasAnchored
            end
        end
        originalAnchored = {}
        TASCharacter.ConsoleMessage("[CO] Restored tracked object physics")
    end
    function CO.RebuildFromAttributes()
        objectRegistry = {}
        idByObject     = {}
        lastCFrames    = {}
        originalAnchored = {}
        anchoredCandidates = {}
        for part, conn in pairs(anchoredCandidateConnections) do
            if conn then conn:Disconnect() end
            anchoredCandidateConnections[part] = nil
        end
        forceCaptureIds = {}
        withinRecordRadius = {}
        rebuildRopePartSet()
        local highest  = 0
        for _, desc in ipairs(workspace:GetDescendants()) do
            if desc:IsA("BasePart") and not isBlacklisted(desc) then
                local id = desc:GetAttribute(CO_ATTRIBUTE_NAME)
                if id then
                    objectRegistry[id] = desc
                    idByObject[desc]   = id
                    lastCFrames[id]    = desc.CFrame
                    forceCaptureIds[id] = true
                    if id >= highest then highest = id + 1 end
                elseif not desc.Anchored or ropePartSet[desc] then
                    registerPart(desc, true)
                    local newId = idByObject[desc]
                    if newId and newId >= highest then highest = newId + 1 end
                else
                    watchAnchoredPart(desc)
                end
            end
        end
        nextId = highest
        scanComplete = true
        startWatching()
        TASCharacter.ConsoleMessage("[CO] Rebuilt registry: " .. tostring(highest - 1) .. " parts")
    end

	function CO.GetFullStateAtFrame(frameIndex, replayTable)
        frameIndex = math.max(0, math.floor(tonumber(frameIndex) or 0))
        if frameIndex <= 0 or type(replayTable) ~= "table" then return {} end

        local cache = CO._FullStateCache
        if type(cache) ~= "table" then
            cache = {frame = 0, state = {}, checkpoints = {}}
            CO._FullStateCache = cache
        end
        cache.checkpoints = cache.checkpoints or {}

        if cache.frame == frameIndex then
            return cache.state
        end

        local checkpointStep = 300
        local startFrame = 1
        local state = {}

        if frameIndex >= cache.frame and cache.frame > 0 then
            startFrame = cache.frame + 1
            state = cache.state
        else
            local bestFrame = 0
            for cpFrame, cpState in pairs(cache.checkpoints) do
                if cpFrame <= frameIndex and cpFrame > bestFrame then
                    bestFrame = cpFrame
                    state = {}
                    for id, components in pairs(cpState) do state[id] = components end
                end
            end
            if bestFrame > 0 then
                startFrame = bestFrame + 1
            end
        end

        for i = startFrame, frameIndex do
            local frame = replayTable[i]
            if type(frame) == "table" and frame[13] then
                for idStr, components in pairs(frame[13]) do
                    state[idStr] = components
                end
            end
            if i % checkpointStep == 0 then
                local cp = {}
                for id, components in pairs(state) do cp[id] = components end
                cache.checkpoints[i] = cp
            end
        end

        cache.frame = frameIndex
        cache.state = state
        return state
    end

    function CO.ApplyFullState(state)
        for idStr, components in pairs(state) do
            local id   = tonumber(idStr)
            local part = objectRegistry[id]
            if part and part.Parent then
                part.CFrame = FastTableToCFrame(components)
                part.AssemblyLinearVelocity = Vector3.zero
                part.AssemblyAngularVelocity = Vector3.zero
            end
        end
    end

    function CO.HoldCurrentState()
        for id, part in pairs(objectRegistry) do
            if part and part.Parent then
                if originalAnchored[id] == nil then originalAnchored[id] = part.Anchored end
                part.AssemblyLinearVelocity = Vector3.zero
                part.AssemblyAngularVelocity = Vector3.zero
                part.Anchored = true
            end
        end
        TASFreeze.FrozenHeldCO = true
    end

    function CO.ReleaseHeldState()
        if not TASFreeze.FrozenHeldCO then return end
        for id, part in pairs(objectRegistry) do
            if part and part.Parent and originalAnchored[id] ~= nil then
                part.AssemblyLinearVelocity = Vector3.zero
                part.AssemblyAngularVelocity = Vector3.zero
                part.Anchored = originalAnchored[id] == true
            end
        end
        originalAnchored = {}
        TASFreeze.FrozenHeldCO = false
    end

    function CO.Stop()
        CO._recordingRequested = false
        if watchConn then
            watchConn:Disconnect()
            watchConn = nil
        end
        CO._lerpTargets  = {}
        CO._FullStateCache = nil
        lastCoTime   = nil
        originalAnchored = {}
        objectRegistry = {}
        idByObject = {}
        lastCFrames = {}
        forceCaptureIds = {}
        withinRecordRadius = {}
        for part, conn in pairs(anchoredCandidateConnections) do
            if conn then conn:Disconnect() end
            anchoredCandidateConnections[part] = nil
        end
        anchoredCandidates = {}
        forceCaptureIds = {}
        scanComplete = false
        nextId = 1
        CO._preparedFirstFrame = nil
        CO._preparedFirstFrameReady = false
    end

    -- TAS5 compatibility/state helpers. The actual CO recording/playback model
    -- above intentionally matches message.txt; these helpers only satisfy the
    -- newer TAS5 call sites without changing the CO state semantics.
    CO._initialized = false
    CO._recordingRequested = false
    CO._forceFullFrame = false
    CO._coDataWarned = false
    CO._replayHasNoCO = false
    CO._currentTargets = {}
    CO._activeIds = {}
    CO._activeIdSet = {}
    CO._activeCurrent = {}
    CO._activeNext = {}
    CO._FullStateCache = nil

    CO._OriginalInit = CO.Init
    CO.Init = function(...)
        CO._OriginalInit(...)
        CO._initialized = true
        CO._forceFullFrame = CO._recordingRequested == true
        if CO._recordingRequested then
            lastCFrames = {}
        end
        CO._coDataWarned = false
        CO._replayHasNoCO = false
        CO._currentTargets = {}
        CO._activeIds = {}
        CO._activeIdSet = {}
        CO._activeCurrent = {}
        CO._activeNext = {}
        CO._FullStateCache = nil
    end

    CO._OriginalRebuildFromAttributes = CO.RebuildFromAttributes
    CO.RebuildFromAttributes = function(...)
        CO._OriginalRebuildFromAttributes(...)
        CO._initialized = true
        CO._forceFullFrame = false
        CO._coDataWarned = false
        CO._replayHasNoCO = false
        CO._currentTargets = {}
        CO._activeIds = {}
        CO._activeIdSet = {}
        CO._activeCurrent = {}
        CO._activeNext = {}
        CO._FullStateCache = nil
    end

    function CO.ReuseRegistryForPlayback()
        -- Reuse the already-built registry when playback follows a recording in the same session.
        -- This avoids rescanning the entire workspace on every Read.
        scanComplete = true
        for id, part in pairs(objectRegistry) do
            if part and part.Parent then
                lastCFrames[id] = part.CFrame
            else
                objectRegistry[id] = nil
            end
        end
        startWatching()
    end

    function CO.PrepareFirstRecordingFrame()
        if not scanComplete then return false end
        local prepared = {}
        local processed = 0
        for id, part in pairs(objectRegistry) do
            if part and part.Parent and isWithinRecordRadius(part) then
                local cf = part.CFrame
                prepared[tostring(id)] = RoundTable({cf:GetComponents()}, TASConfig.RoundDigits)
                lastCFrames[id] = cf
                withinRecordRadius[id] = true
                forceCaptureIds[id] = nil
            else
                withinRecordRadius[id] = false
            end
            processed = processed + 1
            if processed % 150 == 0 then
                TASServices.RunService.Heartbeat:Wait()
            end
        end
        CO._preparedFirstFrame = prepared
        CO._preparedFirstFrameReady = true
        CO._forceFullFrame = false
        return true
    end

    function CO.BeginRecording()
        CO._recordingRequested = true
        CO._forceFullFrame = false
        forceCaptureIds = {}
    end

    function CO.ResetTargets()
        CO._lastCoTime = nil
        CO._currentTargets = {}
        CO._activeIds = {}
        CO._activeIdSet = {}
        CO._activeCurrent = {}
        CO._activeNext = {}
    end

    function CO.BeginPlaybackCleanup()
        CO._FullStateCache = nil
        CO._lastCoTime = nil
    end
    function CO.EndPlaybackCleanup() end

    function CO.InvalidateStateCache()
        CO._FullStateCache = nil
    end

    function CO.WarnNoCOData()
        if not CO._coDataWarned then
            CO._coDataWarned = true
            CO._replayHasNoCO = true
            TASCharacter.ConsoleMessage('[CO] WARNING: No CO data in replay. Re-record to enable spinner sync.')
        end
    end

    function CO.GetPartCount()
        return nextId - 1
    end

    CO._OriginalStop = CO.Stop
    CO.Stop = function(...)
        CO._OriginalStop(...)
        CO._initialized = false
        CO._forceFullFrame = false
        CO._currentTargets = {}
        CO._activeIds = {}
        CO._activeIdSet = {}
        CO._activeCurrent = {}
        CO._activeNext = {}
        CO._FullStateCache = nil
    end

end)(CO) -- CO_REGISTER_SCOPE_V3

local Freeze

-- Replay Functions (assigned below)
do
	GetReplayFile = function()
        local path = TASPaths.ReplayPath
        if type(path) ~= "string" or path == "" or not isfile(path) then
            return nil
        end
        local ok, content = pcall(readfile, path)
        if ok and type(content) == "string" then
            return content
        end
        return nil
    end

    -- Shared cooperative codec yielding. Kept outside TAS4Codec because
    -- JSON3/Base64 helpers also need to yield while they process large files.
    local ReplayCodecTick = tick()
    local function ReplayCodecYield(force)
        local budget = math.max(0.0005, tonumber(TASConfig.ReplayCodecTimeBudget) or 0.003)
        local now = tick()
        if force or (now - ReplayCodecTick) >= budget then
            TASServices.RunService.Heartbeat:Wait()
            ReplayCodecTick = tick()
        end
    end

	local TAS4Codec = (function()
	local TAS4_MAGIC = "TAS4"
	local TAS4_VERSION = 1
	local TAS4_FLOAT = "<d"

	local function tas4PackU(n)
		n = math.max(0, math.floor(tonumber(n) or 0))
		local out = {}
		repeat
			local b = n % 128
			n = math.floor(n / 128)
			if n > 0 then b = b + 128 end
			out[#out + 1] = string.char(b)
		until n == 0
		return table.concat(out)
	end

	local function tas4ReadU(data, pos)
		local n, shift = 0, 0
		while pos <= #data do
			local b = string.byte(data, pos)
			pos = pos + 1
			n = n + (b % 128) * (2 ^ shift)
			if b < 128 then return n, pos end
			shift = shift + 7
			if shift > 49 then error("TAS4 varint too large") end
		end
		error("TAS4 truncated varint")
	end

	local function tas4PackString(str)
		str = tostring(str or "")
		return tas4PackU(#str) .. str
	end

	local function tas4ReadString(data, pos)
		local len
		len, pos = tas4ReadU(data, pos)
		local last = pos + len - 1
		if last > #data then error("TAS4 truncated string") end
		return data:sub(pos, last), last + 1
	end

	local function tas4PackDouble(n)
		return string.pack(TAS4_FLOAT, tonumber(n) or 0)
	end

	local function tas4ReadDouble(data, pos)
		local value, nextPos = string.unpack(TAS4_FLOAT, data, pos)
		return value, nextPos
	end

	-- Exact IEEE-754 delta: stores XOR of the 64-bit representation.
	local function tas4PackDoubleDelta(value, previous)
		local raw = string.pack(TAS4_FLOAT, tonumber(value) or 0)
		local lo, hi = string.unpack("<I4I4", raw)
		local plo, phi = 0, 0
		if previous ~= nil then
			local praw = string.pack(TAS4_FLOAT, tonumber(previous) or 0)
			plo, phi = string.unpack("<I4I4", praw)
		end
		return tas4PackU(bit32.bxor(lo, plo)) .. tas4PackU(bit32.bxor(hi, phi))
	end

	local function tas4ReadDoubleDelta(data, pos, previous)
		local dlo, dhi
		dlo, pos = tas4ReadU(data, pos)
		dhi, pos = tas4ReadU(data, pos)
		local plo, phi = 0, 0
		if previous ~= nil then
			local praw = string.pack(TAS4_FLOAT, tonumber(previous) or 0)
			plo, phi = string.unpack("<I4I4", praw)
		end
		local raw = string.pack("<I4I4", bit32.bxor(dlo, plo), bit32.bxor(dhi, phi))
		local value = string.unpack(TAS4_FLOAT, raw)
		return value, pos
	end

	local function tas4CollectString(dict, list, value)
		value = tostring(value or "")
		local id = dict[value]
		if not id then
			id = #list + 1
			dict[value] = id
			list[id] = value
		end
		return id
	end

	local function tas4PackSparse(values, previous, count)
		local mask = 0
		for i = 1, count do
			local cur = values[i]
			if not previous or cur ~= previous[i] then
				mask = mask + 2 ^ (i - 1)
			end
		end
		local out = {tas4PackU(mask)}
		for i = 1, count do
			if math.floor(mask / (2 ^ (i - 1))) % 2 == 1 then
				out[#out + 1] = tas4PackDoubleDelta(values[i], previous and previous[i] or nil)
			end
		end
		return table.concat(out), values
	end

	local function tas4ReadSparse(data, pos, previous, count)
		local mask
		mask, pos = tas4ReadU(data, pos)
		local values = {}
		for i = 1, count do
			local bit = math.floor(mask / (2 ^ (i - 1))) % 2
			if bit == 1 then
				values[i], pos = tas4ReadDoubleDelta(data, pos, previous and previous[i] or nil)
			elseif previous then
				values[i] = previous[i]
			else
				error("TAS4 sparse field missing initial component")
			end
		end
		return values, pos
	end

	-- Build animation, pose and input dictionaries in one pass instead of two.
	local function tas4BuildDictionaries(tableOfFrames)
		local animDict, animList = {}, {}
		local poseDict, poseList = {}, {}
		local inputDict, inputList = {}, {}
		for i = 1, #tableOfFrames do
			local frame = tableOfFrames[i]
			if type(frame) == "table" then
				local anims = frame[2]
				if type(anims) == "table" then
					for j = 1, #anims do
						local a = anims[j]
						if type(a) == "table" then tas4CollectString(animDict, animList, a[1]) end
					end
				end
				if frame[9] ~= nil then tas4CollectString(poseDict, poseList, frame[9]) end
				local events = frame[12]
				if type(events) == "table" then
					for pass = 1, 2 do
						local src = events[pass]
						if type(src) == "table" then
							for j = 1, #src do tas4CollectString(inputDict, inputList, src[j]) end
						end
					end
				end
			end
		end
		return animDict, animList, poseDict, poseList, inputDict, inputList
	end

	local function tas4SameFlat(a, b, count)
		if a == b then return true end
		if type(a) ~= "table" or type(b) ~= "table" then return false end
		for i = 1, count do if a[i] ~= b[i] then return false end end
		return true
	end

	local function tas4SameEvents(a, b)
		if a == b then return true end
		if type(a) ~= "table" or type(b) ~= "table" or #a ~= #b then return false end
		for i = 1, #a do if a[i] ~= b[i] then return false end end
		return true
	end

	local function tas4SameAnimations(a, b)
		if a == b then return true end
		if type(a) ~= "table" or type(b) ~= "table" or #a ~= #b then return false end
		for i = 1, #a do
			local aa, bb = a[i], b[i]
			if aa ~= bb then
				if type(aa) ~= "table" or type(bb) ~= "table" or aa[1] ~= bb[1] or aa[2] ~= bb[2] then return false end
			end
		end
		return true
	end

	local function tas4SameObjects(a, b)
		if a == b then return true end
		if type(a) ~= "table" or type(b) ~= "table" then return false end
		local countA, countB = 0, 0
		for id, components in pairs(a) do
			countA += 1
			local other = b[id] or b[tonumber(id)]
			if type(other) ~= "table" or not tas4SameFlat(components, other, 12) then return false end
		end
		for _ in pairs(b) do countB += 1 end
		return countA == countB
	end

	local function tas4FramesSame(a, b)
		if a == b then return true end
		if type(a) ~= "table" or type(b) ~= "table" then return false end
		return tas4SameFlat(a[1], b[1], 12)
			and tas4SameAnimations(a[2], b[2])
			and a[3] == b[3] and a[4] == b[4]
			and tas4SameFlat(a[5], b[5], 3) and tas4SameFlat(a[6], b[6], 3)
			and tas4SameFlat(a[7], b[7], 12)
			and a[8] == b[8] and a[9] == b[9] and a[10] == b[10]
			and tas4SameFlat(a[11], b[11], 2)
			and type(a[12]) == "table" and type(b[12]) == "table"
			and tas4SameEvents(a[12][1], b[12][1]) and tas4SameEvents(a[12][2], b[12][2])
			and tas4SameObjects(a[13], b[13])
	end

	local encode = function(Table)
		local frameCount = #Table
		TASCharacter.ConsoleMessage("TAS4 encoding "..tostring(frameCount).." frames")
		local StartTick = tick()

		-- One dictionary pass instead of separate input + animation/pose passes.
		local animDict, animList, poseDict, poseList, inputDict, inputList = tas4BuildDictionaries(Table)

		local out = {TAS4_MAGIC, string.char(TAS4_VERSION)}
		local replayFPS = tonumber(TASRuntime.RecordingReplayFPS or TASRuntime.ActiveReplayFPS or TASConfig.TASRecordingFPS) or TASConfig.TASRecordingFPS
		out[#out + 1] = tas4PackU(replayFPS)
		out[#out + 1] = tas4PackU(frameCount)

		local headerOut = {}
		headerOut[#headerOut + 1] = tas4PackU(#animList)
		for i = 1, #animList do headerOut[#headerOut + 1] = tas4PackString(animList[i]) end
		headerOut[#headerOut + 1] = tas4PackU(#poseList)
		for i = 1, #poseList do headerOut[#headerOut + 1] = tas4PackString(poseList[i]) end
		headerOut[#headerOut + 1] = tas4PackU(#inputList)
		for i = 1, #inputList do headerOut[#headerOut + 1] = tas4PackString(inputList[i]) end
		out[#out + 1] = table.concat(headerOut)

		local prevCFrame1, prevCFrame7, prevV3_5, prevV3_6, prevV2_11
		local prevN3, prevN8
		local prevObjects = {}
		local previousObjectIds = {}
		local previousObjectIdSet = {}

		local function getObjectIds(objects)
			if next(objects) == nil then
				previousObjectIds = {}
				previousObjectIdSet = {}
				return previousObjectIds
			end
			local sameSet, count = #previousObjectIds > 0, 0
			if sameSet then
				for idValue in pairs(objects) do
					count += 1
					if not previousObjectIdSet[tonumber(idValue) or 0] then sameSet = false; break end
				end
				if sameSet and count ~= #previousObjectIds then sameSet = false end
			end
			if sameSet then return previousObjectIds end
			local ids = {}
			for idValue in pairs(objects) do ids[#ids + 1] = tonumber(idValue) or 0 end
			table.sort(ids)
			local set = {}
			for i = 1, #ids do set[ids[i]] = true end
			previousObjectIds, previousObjectIdSet = ids, set
			return ids
		end

		local function packEvents(events)
			if type(events) ~= "table" then return tas4PackU(0) end
			local parts = {tas4PackU(#events)}
			for i = 1, #events do
				local event = events[i]
				local id = inputDict[type(event) == "string" and event or tostring(event)]
				parts[#parts + 1] = tas4PackU(id or 0)
			end
			return table.concat(parts)
		end

		-- Batch each frame into one string: fewer entries in the outer table means
		-- less allocator/GC pressure while still producing the exact same TAS4 bytes.
		local frameOut = {}

		for i = 1, frameCount do
            ReplayCodecYield(false)
			local frame = Table[i]
			local previousFrame = Table[i - 1]
			table.clear(frameOut)

			if i > 1 and type(frame) == "table" and type(previousFrame) == "table" and tas4FramesSame(frame, previousFrame) then
				frameOut[1] = string.char(3)
			elseif frame == 0 then
				frameOut[1] = string.char(0)
			elseif frame == 1 then
				frameOut[1] = string.char(1)
			elseif type(frame) == "table" then
				frameOut[1] = string.char(2)
				local packed
				packed, prevCFrame1 = tas4PackSparse(frame[1], prevCFrame1, 12); frameOut[#frameOut + 1] = packed
				local anims = frame[2] or {}
				frameOut[#frameOut + 1] = tas4PackU(#anims)
				for j = 1, #anims do
					local a = anims[j]
					frameOut[#frameOut + 1] = tas4PackU(animDict[type(a[1]) == "string" and a[1] or tostring(a[1])] or 0)
					frameOut[#frameOut + 1] = tas4PackDouble(a[2] or 0)
				end
				local n3 = frame[3] or 0
				frameOut[#frameOut + 1] = string.char(n3 == prevN3 and 0 or 1)
				if n3 ~= prevN3 then frameOut[#frameOut + 1] = tas4PackDoubleDelta(n3, prevN3); prevN3 = n3 end
				frameOut[#frameOut + 1] = tas4PackU(frame[4] or 0)
				packed, prevV3_5 = tas4PackSparse(frame[5], prevV3_5, 3); frameOut[#frameOut + 1] = packed
				packed, prevV3_6 = tas4PackSparse(frame[6], prevV3_6, 3); frameOut[#frameOut + 1] = packed
				packed, prevCFrame7 = tas4PackSparse(frame[7], prevCFrame7, 12); frameOut[#frameOut + 1] = packed
				local n8 = frame[8] or 0
				frameOut[#frameOut + 1] = string.char(n8 == prevN8 and 0 or 1)
				if n8 ~= prevN8 then frameOut[#frameOut + 1] = tas4PackDoubleDelta(n8, prevN8); prevN8 = n8 end
				frameOut[#frameOut + 1] = tas4PackU(poseDict[type(frame[9]) == "string" and frame[9] or tostring(frame[9] or "")] or 0)
				frameOut[#frameOut + 1] = string.char((frame[10] == 1) and 1 or 0)
				packed, prevV2_11 = tas4PackSparse(frame[11], prevV2_11, 2); frameOut[#frameOut + 1] = packed
				local events = frame[12] or {}
				frameOut[#frameOut + 1] = packEvents(events[1])
				frameOut[#frameOut + 1] = packEvents(events[2])
				local objects = frame[13] or {}
				local objectIds = getObjectIds(objects)
				frameOut[#frameOut + 1] = tas4PackU(#objectIds)
				local lastId = 0
				for j = 1, #objectIds do
                    ReplayCodecYield(false)
					local id = objectIds[j]
					frameOut[#frameOut + 1] = tas4PackU(math.max(0, id - lastId)); lastId = id
					local key = tostring(id)
					local components = objects[key] or objects[id]
					local previous = prevObjects[key]
					local same = previous and #previous == 12
					if same then for k = 1, 12 do if components[k] ~= previous[k] then same = false; break end end end
					if same then
						frameOut[#frameOut + 1] = string.char(0)
					else
						frameOut[#frameOut + 1] = string.char(1)
						local objectPacked
						objectPacked, prevObjects[key] = tas4PackSparse(components, previous, 12)
						frameOut[#frameOut + 1] = objectPacked
					end
				end
			else
				error("TAS4 cannot encode invalid frame at index "..tostring(i))
			end
			out[#out + 1] = table.concat(frameOut)
		end

		local Encoded = table.concat(out)
		TASCharacter.ConsoleMessage("TAS4 encoded "..tostring(#Encoded).." bytes in "..TASUtilityFunctions.RoundNumber(tick()-StartTick,2).." seconds")
		return Encoded
	end

	local function tas4Decode(data)
		local pos = 6
		local version = string.byte(data, 5)
		if version ~= TAS4_VERSION then error("unsupported TAS4 version "..tostring(version)) end
		local replayFPS, frameCount
		replayFPS, pos = tas4ReadU(data, pos)
		frameCount, pos = tas4ReadU(data, pos)

		local function readDict()
			local count; count, pos = tas4ReadU(data, pos)
			local list = {}
			for i = 1, count do list[i], pos = tas4ReadString(data, pos) end
			return list
		end
		local animList = readDict()
		local poseList = readDict()
		local inputList = readDict()

		local Replay = {}
		local prevCFrame1, prevCFrame7, prevV3_5, prevV3_6, prevV2_11
		local prevN3, prevN8
		local prevObjects = {}

		local function readEvents()
			local count; count, pos = tas4ReadU(data, pos)
			local events = {}
			for i = 1, count do
				local id; id, pos = tas4ReadU(data, pos)
				events[i] = inputList[id] or ""
			end
			return events
		end

		for i = 1, frameCount do
            ReplayCodecYield(false)
			local tag = string.byte(data, pos); pos = pos + 1
			if tag == 0 then
				Replay[i] = 0
			elseif tag == 1 then
				Replay[i] = 1
			elseif tag == 3 then
				local previous = Replay[i - 1]
				if type(previous) ~= "table" then error("TAS4 repeat frame without previous table at "..tostring(i)) end
				local function clone(v)
					if type(v) ~= "table" then return v end
					local c = {}
					for j = 1, #v do c[j] = clone(v[j]) end
					return c
				end
				Replay[i] = clone(previous)
			elseif tag == 2 then
				local Frame = {}
				Frame[1], pos = tas4ReadSparse(data, pos, prevCFrame1, 12); prevCFrame1 = Frame[1]
				local animCount; animCount, pos = tas4ReadU(data, pos)
				Frame[2] = {}
				for j = 1, animCount do
					local id; id, pos = tas4ReadU(data, pos)
					local transition; transition, pos = tas4ReadDouble(data, pos)
					Frame[2][j] = {animList[id] or "", transition}
				end
				local changed = string.byte(data, pos); pos = pos + 1
				if changed == 1 then Frame[3], pos = tas4ReadDoubleDelta(data, pos, prevN3); prevN3 = Frame[3] else Frame[3] = prevN3 end
				if Frame[3] == nil then Frame[3] = 0; prevN3 = 0 end
				Frame[4], pos = tas4ReadU(data, pos)
				Frame[5], pos = tas4ReadSparse(data, pos, prevV3_5, 3); prevV3_5 = Frame[5]
				Frame[6], pos = tas4ReadSparse(data, pos, prevV3_6, 3); prevV3_6 = Frame[6]
				Frame[7], pos = tas4ReadSparse(data, pos, prevCFrame7, 12); prevCFrame7 = Frame[7]
				changed = string.byte(data, pos); pos = pos + 1
				if changed == 1 then Frame[8], pos = tas4ReadDoubleDelta(data, pos, prevN8); prevN8 = Frame[8] else Frame[8] = prevN8 end
				if Frame[8] == nil then Frame[8] = 0; prevN8 = 0 end
				local poseId; poseId, pos = tas4ReadU(data, pos); Frame[9] = poseList[poseId] or ""
				local flags = string.byte(data, pos); pos = pos + 1; Frame[10] = (flags % 2 == 1) and 1 or 0
				Frame[11], pos = tas4ReadSparse(data, pos, prevV2_11, 2); prevV2_11 = Frame[11]
				Frame[12] = {readEvents(), readEvents()}

				local objectCount; objectCount, pos = tas4ReadU(data, pos)
				Frame[13] = {}
				local lastId = 0
				for j = 1, objectCount do
                    ReplayCodecYield(false)
					local deltaId; deltaId, pos = tas4ReadU(data, pos)
					local id = lastId + deltaId; lastId = id
					local key = tostring(id)
					local mode = string.byte(data, pos); pos = pos + 1
					if mode == 0 then
						local previous = prevObjects[key]
						if not previous then error("TAS4 object repeat without previous state for "..key) end
						Frame[13][key] = previous
					else
						local components
						components, pos = tas4ReadSparse(data, pos, prevObjects[key], 12)
						prevObjects[key] = components
						Frame[13][key] = components
					end
				end
				Replay[i] = Frame
			else
				error("TAS4 unknown frame tag "..tostring(tag))
			end
		end
		return Replay, replayFPS
	end

	local function tas5Compress(raw)
		-- TAS5 = TAS4 payload + optional native Zstd wrapper.
		-- This is intentionally save/load-only; recording and playback still use Frames.
		local ok, service, compressed
		ok, service = pcall(function() return game:GetService("EncodingService") end)
		if ok and service and type(buffer) == "table" and Enum and Enum.CompressionAlgorithm and Enum.CompressionAlgorithm.Zstd then
			local compressedOk
			compressedOk, compressed = pcall(function()
				local input = buffer.fromstring(raw)
				local out = service:CompressBuffer(input, Enum.CompressionAlgorithm.Zstd, math.max(1, math.min(22, math.floor(tonumber(TASConfig.TASCompressionLevel) or 3))))
				return buffer.tostring(out)
			end)
			if compressedOk and type(compressed) == "string" and #compressed < #raw then
				return "TAS5" .. string.char(TAS4_VERSION, 1) .. tas4PackU(#raw) .. compressed, true
			end
		end
		-- Fallback: keep the exact TAS4 stream without compression.
		return "TAS5" .. string.char(TAS4_VERSION, 0) .. tas4PackU(#raw) .. raw, false
	end

	local function tas5Decompress(data)
		if data:sub(1, 4) ~= "TAS5" then error("TAS5 invalid magic") end
		local version = string.byte(data, 5)
		local flags = string.byte(data, 6)
		if version ~= TAS4_VERSION then error("unsupported TAS5 version "..tostring(version)) end
		local rawSize, pos = tas4ReadU(data, 7)
		local payload = data:sub(pos)
		if flags == 0 then
			if #payload ~= rawSize then error("TAS5 raw payload size mismatch") end
			return payload
		end
		if flags ~= 1 then error("unsupported TAS5 compression flags "..tostring(flags)) end
		local ok, service, raw
		ok, service = pcall(function() return game:GetService("EncodingService") end)
		if not ok or not service or type(buffer) ~= "table" or not Enum or not Enum.CompressionAlgorithm or not Enum.CompressionAlgorithm.Zstd then
			error("TAS5 Zstd decoder unavailable")
		end
		ok, raw = pcall(function()
			local input = buffer.fromstring(payload)
			local out = service:DecompressBuffer(input, Enum.CompressionAlgorithm.Zstd)
			return buffer.tostring(out)
		end)
		if not ok or type(raw) ~= "string" then error("TAS5 Zstd decode failed: "..tostring(raw)) end
		if #raw ~= rawSize then error("TAS5 decompressed size mismatch") end
		return raw
	end

	local decode = function(String)
		if type(String) ~= "string" then
			TASCharacter.ConsoleMessage("Replay decode failed: expected string, got "..type(String)); return nil
		end
		if String:sub(1, 4) == "TAS5" then
			TASCharacter.ConsoleMessage("Decoding TAS5 "..tostring(#String).." bytes")
			local StartTick = tick()
			local ok, raw = pcall(tas5Decompress, String)
			if not ok then
				TASCharacter.ConsoleMessage("TAS5 decompress failed: "..tostring(raw)); return nil
			end
			local ok2, Replay, replayFPS = pcall(tas4Decode, raw)
			if not ok2 then
				TASCharacter.ConsoleMessage("TAS5 decode failed: "..tostring(Replay)); return nil
			end
			TASCharacter.ConsoleMessage("TAS5 decoded "..tostring(#Replay).." frames in "..TASUtilityFunctions.RoundNumber(tick()-StartTick,2).." seconds")
			return Replay, replayFPS
		end
		if String:sub(1, 4) == TAS4_MAGIC then
			TASCharacter.ConsoleMessage("Decoding TAS4 "..tostring(#String).." bytes")
			local StartTick = tick()
			local ok, Replay, replayFPS = pcall(tas4Decode, String)
			if not ok then
				TASCharacter.ConsoleMessage("TAS4 decode failed: "..tostring(Replay)); return nil
			end
			TASCharacter.ConsoleMessage("TAS4 decoded "..tostring(#Replay).." frames in "..TASUtilityFunctions.RoundNumber(tick()-StartTick,2).." seconds")
			return Replay, replayFPS
		end
		String = String:gsub("^\239\187\191", ""):gsub("^%s+", ""):gsub("%s+$", "")
		if String == "" then TASCharacter.ConsoleMessage("Nothing to read"); return nil end
		if String:sub(1, 1) ~= "{" then
			TASCharacter.ConsoleMessage("Invalid replay file: unknown format"); return nil
		end
		local StartTick = tick()
		local ok, Decoded = pcall(json.decode, String)
		if not ok or type(Decoded) ~= "table" or type(Decoded.Replay) ~= "table" then
			TASCharacter.ConsoleMessage("Replay decode failed: invalid legacy JSON/replay data"); return nil
		end
		local replayFPS = tonumber(Decoded.TASConfig.FPS)
		TASCharacter.ConsoleMessage("Legacy JSON decoded in "..TASUtilityFunctions.RoundNumber(tick()-StartTick,2).." seconds")
		return Decoded.Replay, replayFPS
	end
	return {encode = encode, decode = decode, compress = tas5Compress}
	end)()


    local JSONReplayCodec = (function()
	-- Compact JSON replay codec.
    -- JSON3 keeps the file a real JSON document, but stores the replay payload
    -- in the already-tested TAS4/TAS5 binary codec.  This avoids the huge
    -- textual overhead of writing thousands of CFrame components as JSON.
    -- Legacy JSON2 files are still decoded for compatibility.

    local Base64Alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    local Base64DecodeMap = {}
    for i = 1, #Base64Alphabet do
        Base64DecodeMap[Base64Alphabet:sub(i, i)] = i - 1
    end

    local function Base64Encode(data)
        if type(data) ~= "string" then error("Base64Encode expected string") end
        local out = {}
        local oi = 0
        local i = 1
        local len = #data
        while i <= len do
            ReplayCodecYield(false)
            local a = string.byte(data, i) or 0
            local b = (i + 1 <= len) and (string.byte(data, i + 1) or 0) or 0
            local c = (i + 2 <= len) and (string.byte(data, i + 2) or 0) or 0
            local triple = a * 65536 + b * 256 + c
            local s1 = math.floor(triple / 262144) % 64 + 1
            local s2 = math.floor(triple / 4096) % 64 + 1
            local s3 = math.floor(triple / 64) % 64 + 1
            local s4 = triple % 64 + 1
            oi = oi + 1; out[oi] = Base64Alphabet:sub(s1, s1)
            oi = oi + 1; out[oi] = Base64Alphabet:sub(s2, s2)
            if i + 1 <= len then
                oi = oi + 1; out[oi] = Base64Alphabet:sub(s3, s3)
            else
                oi = oi + 1; out[oi] = "="
            end
            if i + 2 <= len then
                oi = oi + 1; out[oi] = Base64Alphabet:sub(s4, s4)
            else
                oi = oi + 1; out[oi] = "="
            end
            i = i + 3
        end
        return table.concat(out)
    end

    local function Base64Decode(data)
        if type(data) ~= "string" then error("Base64Decode expected string") end
        data = data:gsub("%s+", "")
        if (#data % 4) ~= 0 then error("invalid base64 length") end
        local out = {}
        local oi = 0
        local i = 1
        while i <= #data do
            ReplayCodecYield(false)
            local aChar = data:sub(i, i)
            local bChar = data:sub(i + 1, i + 1)
            local cChar = data:sub(i + 2, i + 2)
            local dChar = data:sub(i + 3, i + 3)
            local a = Base64DecodeMap[aChar]
            local b = Base64DecodeMap[bChar]
            if a == nil or b == nil then error("invalid base64 character") end
            local c = (cChar == "=") and 0 or Base64DecodeMap[cChar]
            local d = (dChar == "=") and 0 or Base64DecodeMap[dChar]
            if c == nil or d == nil then error("invalid base64 character") end
            local triple = a * 262144 + b * 4096 + c * 64 + d
            oi = oi + 1; out[oi] = string.char(math.floor(triple / 65536) % 256)
            if cChar ~= "=" then
                oi = oi + 1; out[oi] = string.char(math.floor(triple / 256) % 256)
            end
            if dChar ~= "=" then
                oi = oi + 1; out[oi] = string.char(triple % 256)
            end
            i = i + 4
        end
        return table.concat(out)
    end

    local function JSON3CompressBinary(raw)
        -- JSON3 already provides the outer compact container. Keep the binary
        -- payload as plain TAS4 so a replay saved here can always be read back
        -- without depending on EncodingService/Zstd being available.
        return raw
    end

    local function JSON3DecompressBinary(payload)
        -- TAS4Codec.decode already understands TAS5 and TAS4, so use its
        -- compatibility path instead of duplicating the decompressor here.
        return payload
    end

    local function JSONReplayEncode(Table)
        if type(Table) ~= "table" then error("replay must be a table") end
        local StartTick = tick()
        local raw = TAS4Codec.encode(Table)
        local packed = JSON3CompressBinary(raw)
        local payload = {
            Format = "TASABILITY_JSON3",
            Version = 3,
            FPS = math.max(1, tonumber(TASRuntime.RecordingReplayFPS or TASRuntime.ActiveReplayFPS or TASRuntime.ReplaySourceFPS or TASConfig.TASRecordingFPS) or 1),
            Compression = "TAS4",
            Binary = "base64",
            RawBytes = #raw,
            PackedBytes = #packed,
            Frames = #Table,
            Data = Base64Encode(packed),
        }
        local encoded = json.encode(payload)
        TASCharacter.ConsoleMessage("JSON3 encoded "..tostring(#Table).." frames: "..tostring(#encoded).." bytes (binary "..tostring(#packed)..") in "..TASUtilityFunctions.RoundNumber(tick()-StartTick,2).." seconds")
        return encoded
    end

    local function JSON2ReplayDecode(decoded)
        if type(decoded) ~= "table" or decoded.Format ~= "TASABILITY_JSON2" or type(decoded.Replay) ~= "table" then
            error("invalid TASABILITY JSON2 replay")
        end
        local replay = {}
        local fps = tonumber(decoded.FPS) or TASConfig.TASRecordingFPS
        local function unpackCO(list)
            local result = {}
            if type(list) ~= "table" then return result end
            local index, lastId = 1, 0
            while index <= #list do
                local deltaId = tonumber(list[index]) or 0
                index += 1
                local id = lastId + deltaId
                lastId = id
                local components = {}
                for j = 1, 12 do
                    components[j] = list[index] or 0
                    index += 1
                end
                result[tostring(id)] = components
            end
            return result
        end
        local previousFrame = nil
        for _, item in ipairs(decoded.Replay) do
            if item == 0 or item == 1 then
                replay[#replay + 1] = item
                previousFrame = nil
            elseif type(item) == "table" and item[1] == 3 and #item == 2 then
                local count = math.max(0, math.floor(tonumber(item[2]) or 0))
                if not previousFrame then error("repeat frame without previous frame") end
                for _ = 1, count do
                    local repeatFrame = {}
                    repeatFrame[1] = previousFrame[1]
                    repeatFrame[2] = {}
                    repeatFrame[3] = previousFrame[3]
                    repeatFrame[4] = previousFrame[4]
                    repeatFrame[5] = previousFrame[5]
                    repeatFrame[6] = previousFrame[6]
                    repeatFrame[7] = previousFrame[7]
                    repeatFrame[8] = previousFrame[8]
                    repeatFrame[9] = previousFrame[9]
                    repeatFrame[10] = previousFrame[10]
                    repeatFrame[11] = previousFrame[11]
                    repeatFrame[12] = {{}, {}}
                    repeatFrame[13] = {}
                    replay[#replay + 1] = repeatFrame
                end
            elseif type(item) == "table" then
                local frame = {}
                for i = 1, 12 do frame[i] = item[i] end
                frame[13] = unpackCO(item[13])
                replay[#replay + 1] = frame
                previousFrame = frame
            else
                replay[#replay + 1] = 0
                previousFrame = nil
            end
        end
        return replay, fps
    end

    local function JSONReplayDecode(String)
        local decoded = json.decode(String)
        if type(decoded) ~= "table" then error("invalid JSON replay root") end
        if decoded.Format == "TASABILITY_JSON3" then
            local jsonVersion = tonumber(decoded.Version) or 1

            -- Some older TASABILITY builds labeled their normal replay object
            -- as JSON3 Version 1. Accept that representation directly when it
            -- contains a Replay table.
            if type(decoded.Replay) == "table" then
                return decoded.Replay, tonumber(decoded.FPS) or TASConfig.TASRecordingFPS
            end

            if jsonVersion < 1 or jsonVersion > 3 then
                error("unsupported TASABILITY JSON3 version "..tostring(decoded.Version))
            end
            if decoded.Binary ~= "base64" or type(decoded.Data) ~= "string" then
                error("invalid TASABILITY JSON3 binary payload")
            end
            local packed = Base64Decode(decoded.Data)
            local ok, replay, replayFPS = pcall(TAS4Codec.decode, packed)
            if ok and type(replay) == "table" then
                return replay, tonumber(decoded.FPS) or replayFPS or TASConfig.TASRecordingFPS
            end
            -- Compatibility fallback: some builds wrote a JSON3 container while
            -- storing an already-decoded replay table alongside the binary payload.
            if type(decoded.Replay) == "table" then
                return decoded.Replay, tonumber(decoded.FPS) or TASConfig.TASRecordingFPS
            end
            error("JSON3 binary decode failed: "..tostring(replay))
        end
        if decoded.Format == "TASABILITY_JSON2" then
            return JSON2ReplayDecode(decoded)
        end
        if type(decoded.Replay) == "table" then
            local replayFPS = tonumber(decoded.FPS)
            return decoded.Replay, replayFPS
        end
        error("invalid TASABILITY JSON replay format")
    end

        return {
            Encode = JSONReplayEncode,
            Decode = JSONReplayDecode,
        }
    end)()

    local JSONReplayEncode = JSONReplayCodec.Encode
    local JSONReplayDecode = JSONReplayCodec.Decode


    TASFunctions.ReplayEncode = function(Table)
        if Table == TASRuntime.ReplayTable and TASRuntime.ReplaySaveState.Encoded and TASRuntime.ReplaySaveState.EncodedVersion == TASRuntime.ReplaySaveState.Version then
            TASCharacter.ConsoleMessage("JSON3 replay reused cached encoding: "..tostring(#TASRuntime.ReplaySaveState.Encoded).." bytes")
            return TASRuntime.ReplaySaveState.Encoded
        end
        local encoded = JSONReplayEncode(Table)
        if Table == TASRuntime.ReplayTable then
            TASRuntime.ReplaySaveState.Encoded = encoded
            TASRuntime.ReplaySaveState.EncodedVersion = TASRuntime.ReplaySaveState.Version
        end
        return encoded
    end

    ReplayDecode = function(String)
        if type(String) ~= "string" then return nil end
        if String:sub(1,1) == "{" then
            local ok, replay, replayFPS = pcall(JSONReplayDecode, String)
            if ok and type(replay) == "table" then return replay, replayFPS end
            -- Last-resort compatibility path for replay containers produced by
            -- intermediate JSON3 builds. Decode the root directly and, when a
            -- Replay table is present, prefer it over a failing binary payload.
            local okRoot, root = pcall(json.decode, String)
            if okRoot and type(root) == "table" then
                if type(root.Replay) == "table" then
                    return root.Replay, tonumber(root.FPS) or TASConfig.TASRecordingFPS
                end
            end
            TASCharacter.ConsoleMessage("JSON replay decode failed: "..tostring(replay or "unknown error"))
            return nil
        end
        local ok, replay, replayFPS = pcall(TAS4Codec.decode, String)
        if ok and type(replay) == "table" then return replay, replayFPS end
        TASCharacter.ConsoleMessage("Binary replay decode failed: "..tostring(replay))
        return nil
    end

	TASFunctions.RecordReplay = function()
		TASCharacter.ConsoleMessage("Waiting for input")
		if TASRuntime.Writing then
			TASFunctions.StopRecording()
			TASFunctions.SaveRecording()
			-- Persist the completed recording immediately. SaveRecording() only
			-- moves frames into ReplayTable; it does not write Replay.json.
			local saved = SaveToFile()
			if saved then
				TASCharacter.ConsoleMessage("Recording stopped; saving in background...")
			else
				TASCharacter.ConsoleMessage("Recording stopped (nothing was saved)")
			end
			return
		end
		SetColorCodeFrame("WaitingForInput")
		TASUtilityFunctions.WaitForInput()
		TASFunctions.StartRecording()
		TASCharacter.ConsoleMessage("Recording started")
	end
	TASFunctions.StartRecording = function()
		if not TASRuntime.Reading then
			if CO.ReleaseHeldState then pcall(CO.ReleaseHeldState) end
			if TASConfig.AllowClientObjectManipulation then
				-- Prepare CO completely BEFORE enabling Writing.
				if not CO._initialized then
					if TASConfig.AllowClientObjectManipulation and CO.QueueInitialization then pcall(CO.QueueInitialization) end
					while CO._initializing do
						TASServices.RunService.Heartbeat:Wait()
					end
					if not CO._initialized and CO.RebuildFromAttributes then
						local ok, err = pcall(CO.RebuildFromAttributes)
						if not ok then
							TASCharacter.ConsoleMessage('[CO] Preparation failed: '..tostring(err))
							return
						end
						CO._initialized = true
					end
					if not CO._initialized then
						TASCharacter.ConsoleMessage('[CO] Preparation failed: initialization did not complete')
						return
					end
				end
				CO._recordingRequested = true
				if CO.PrepareFirstRecordingFrame then
					local ok, prepared = pcall(CO.PrepareFirstRecordingFrame)
					if not ok or not prepared then
						CO._recordingRequested = false
						TASCharacter.ConsoleMessage('[CO] First-frame preparation failed: '..tostring(prepared))
						return
					end
				end
				CO.BeginRecording()
				end
			-- Client FPS cap and TAS recording FPS are independent.
			-- Example: FPS=120, TASRecordingFPS=60 => client at 120 FPS,
			-- replay samples at exactly 60 FPS.
			TASRuntime.RecordingReplayFPS = math.max(1, tonumber(TASConfig.TASRecordingFPS) or 1)
			TASRuntime.RecordingAccumulator = 0
			TASRuntime.InputBeganQueue = {}
			TASRuntime.InputEndedQueue = {}
			TASRuntime.AnimationQueue = {}
			TASRuntime.ForceAnimationSync = true
			SetColorCodeFrame("Recording")
			TASRuntime.Writing = true
			TASRuntime.RecordingFPSCapActive = true

			-- Re-apply the client FPS cap at recording start. This does not
			-- change the TAS sampling rate: that remains TASRecordingFPS.
			if setfpscap then
				pcall(setfpscap, TASConfig.FPS)
			end
		end
	end
	TASFunctions.StopRecording = function()
		if not TASRuntime.Reading then
			TASRuntime.Writing = false
			TASRuntime.RecordingFPSCapActive = false
            TASPause.PendingRecordingFlush = true
		end
	end
	TASFunctions.ResetCurrentRecording = function()
		-- Reset clears the unsaved recording, in-memory replay frames, and the current replay file.
		ReleaseAllPlaybackKeys()
		if TASRuntime.Reading then
			pcall(function() TASFunctions.StopReading() end)
		end
		TASRuntime.Writing = false
		TASFreeze.Frozen = false
		TASRuntime.RecordingTable = {}
        ClearPlaybackWarmCache()
		TASRuntime.ReplayTable = {}
        TASRuntime.SaveGeneration = TASRuntime.SaveGeneration + 1
        TASRuntime.Saving = false
        TASRuntime.ReplaySaveState.Version = TASRuntime.ReplaySaveState.Version + 1
        TASRuntime.ReplaySaveState.Encoded = nil
        TASRuntime.ReplaySaveState.EncodedVersion = -1
		TASRuntime.ReplayTableIndex = 0
		TASFreeze.FreezeFrame = 1
		TASRuntime.RecordingReplayFPS = nil
		TASRuntime.ActiveReplayFPS = nil
		TASRuntime.RecordingFPSCapActive = false
		TASRuntime.RecordingAccumulator = 0
        TASPause.PendingRecordingFlush = false
		TASRuntime.PlaybackSourcePosition = 1
		TASPaths.ReplayNeedsReload = false
		TASRuntime.InputBeganQueue = {}
		TASRuntime.InputEndedQueue = {}
		TASRuntime.AnimationQueue = {}
		TASRuntime.ForceAnimationSync = false
		TASRuntime.HumanoidStateQueue = {}
		TASRuntime.PlaybackPressedKeys = {}
		TASRuntime.PlaybackAccumulator = 0
		-- Preserve the already-built CO registry across reset. CO.Stop() destroys the
		-- registry and forces the next recording to rescan the whole workspace.
		pcall(function()
			CO._recordingRequested = false
			CO._forceFullFrame = true
			CO._coDataWarned = false
			CO._replayHasNoCO = false
			if CO.ResetTargets then CO.ResetTargets() end
			if CO.InvalidateStateCache then CO.InvalidateStateCache() end
		end)
		-- Clear the currently selected replay file as well, so reset is persistent.
		pcall(function()
			if type(TASPaths.ReplayPath) == "string" and isfile(TASPaths.ReplayPath) then
				writefile(TASPaths.ReplayPath, TASFunctions.ReplayEncode({}))
			end
		end)
		pcall(function()
			if CO.InvalidateStateCache then CO.InvalidateStateCache() end
		end)
		SetColorCodeFrame("Idle")
		TASCharacter.ConsoleMessage("Recording and replay frames reset")
	end

	SaveToFile = function()
    -- Move freshly recorded frames into ReplayTable immediately; the expensive
    -- encode/compress/base64/file-write portion runs cooperatively in task.spawn.
    if TASRuntime.Saving then
        TASCharacter.ConsoleMessage("Save already in progress")
        return true
    end

    if #TASRuntime.RecordingTable > 0 then
        TASFunctions.SaveRecording()
    end

    if #TASRuntime.ReplayTable == 0 then
        TASCharacter.ConsoleMessage("Save skipped: replay has no frames (RecordingTable="..tostring(#TASRuntime.RecordingTable)..")")
        return false
    end

    local targetPath = TASPaths.ReplayPath
    if type(targetPath) ~= "string" or targetPath == "" then
        TASCharacter.ConsoleMessage("Save skipped: no replay file selected. Create/select a replay file in Files.")
        return false
    end
    if type(targetPath) == "string" and targetPath:lower():sub(-4) == ".tas" then
        targetPath = targetPath:sub(1, -5) .. ".json"
    end

    local snapshot = table.clone(TASRuntime.ReplayTable)
    local snapshotVersion = TASRuntime.ReplaySaveState.Version
    local snapshotCount = #snapshot
    local saveId = TASRuntime.SaveGeneration + 1
    TASRuntime.SaveGeneration = saveId
    TASRuntime.Saving = true
    TASCharacter.ConsoleMessage("Saving replay in background... ("..tostring(snapshotCount).." frames)")
    TASCharacter.ConsoleMessage("Encoding replay for: "..tostring(targetPath))

    task.spawn(function()
        local ok, err = pcall(function()
            local okEncode, ReplayEncoded = pcall(TASFunctions.ReplayEncode, snapshot)
            if not okEncode or type(ReplayEncoded) ~= "string" then
                error("encoding failed: "..tostring(ReplayEncoded))
            end

            if saveId ~= TASRuntime.SaveGeneration then
                TASCharacter.ConsoleMessage("Background save discarded: replay changed during encoding")
                return
            end

            local okWrite, writeErr = pcall(function()
                if not isfolder(TASPaths.FolderPath) then makefolder(TASPaths.FolderPath) end
                writefile(targetPath, ReplayEncoded)
            end)
            if not okWrite then
                error("writefile failed: "..tostring(writeErr))
            end

            -- Only publish the cache/file state if the replay was not changed
            -- while this background save was running.
            if saveId == TASRuntime.SaveGeneration and snapshotVersion == TASRuntime.ReplaySaveState.Version then
                TASPaths.ReplayPath = targetPath
                TASPaths.ReplayNeedsReload = true
                TASPaths.LastLoadedPath = nil
                TASRuntime.ReplaySaveState.Encoded = ReplayEncoded
                TASRuntime.ReplaySaveState.EncodedVersion = TASRuntime.ReplaySaveState.Version
            end

            TASCharacter.ConsoleMessage("Saved JSON replay: "..tostring(targetPath).." ("..tostring(#ReplayEncoded).." bytes, "..tostring(snapshotCount).." frames)")
        end)

        if not ok then
            TASCharacter.ConsoleMessage("Save failed: "..tostring(err))
        end
        if saveId == TASRuntime.SaveGeneration then
            TASRuntime.Saving = false
        end
    end)

    return true
end
	TASFunctions.SaveRecording = function()
    if TASPause.PendingRecordingFlush then
        local deadline = tick() + 0.25
        while TASPause.PendingRecordingFlush and tick() < deadline do
            TASServices.RunService.Heartbeat:Wait()
        end
    end

    local count = #TASRuntime.RecordingTable
    if count > 0 then
        local recordingFPS = TASRuntime.RecordingReplayFPS or TASConfig.TASRecordingFPS
        TASRuntime.ReplaySaveState.Version = TASRuntime.ReplaySaveState.Version + 1
        TASRuntime.ReplaySaveState.Encoded = nil
        TASRuntime.ReplaySaveState.EncodedVersion = -1
        TASRuntime.SaveGeneration = TASRuntime.SaveGeneration + 1
        TASRuntime.Saving = false

        local first = #TASRuntime.ReplayTable + 1
        if table.move then
            table.move(TASRuntime.RecordingTable, 1, count, first, TASRuntime.ReplayTable)
        else
            for i = 1, count do
                TASRuntime.ReplayTable[first + i - 1] = TASRuntime.RecordingTable[i]
            end
        end

        TASRuntime.ReplaySourceFPS = math.max(1, tonumber(recordingFPS) or 1)
        TASRuntime.ActiveReplayFPS = TASRuntime.ReplaySourceFPS
        if CO.InvalidateStateCache then
            CO.InvalidateStateCache()
        end
        TASRuntime.RecordingTable = {}
        TASPaths.ReplayNeedsReload = false
        TASCharacter.ConsoleMessage("Saved recording to memory at "..tostring(TASRuntime.ActiveReplayFPS).." FPS")
    end
end
		TASFunctions.DiscardRecording = function()
		if #TASRuntime.RecordingTable > 0 then
			TASRuntime.RecordingTable = {}
			TASCharacter.ConsoleMessage("Discarded")
		end
	end
	TASFunctions.StartReading = function()
    if TASRuntime.Reading then
        TASCharacter.ConsoleMessage("You are already reading")
        return
    end
    if TASFreeze.PendingReadingStart then
        TASCharacter.ConsoleMessage("Replay is already loading")
        return
    end

    TASFreeze.PendingReadingStart = true
    TASCharacter.ConsoleMessage("Loading replay in background...")
    task.spawn(function()
        local ok, err = pcall(function()
            if TASPaths.ReplayNeedsReload or TASPaths.ReplayPath ~= TASPaths.LastLoadedPath then
                local fileContent = GetReplayFile()
                if not fileContent then
                    TASRuntime.ReplayTable = {}
                    TASPaths.ReplayNeedsReload = false
                    TASPaths.LastLoadedPath = TASPaths.ReplayPath
                    SetColorCodeFrame("Idle")
                    TASCharacter.ConsoleMessage("No replay file selected or file does not exist")
                    return
                end
                TASCharacter.ConsoleMessage("Reading replay file: "..tostring(TASPaths.ReplayPath)
                    .." ("..tostring(#fileContent).." bytes)")
                local decoded, replayFPS = ReplayDecode(fileContent)
                if decoded then
                    TASRuntime.ReplayTable = decoded
                    TASRuntime.ReplaySaveState.Version = TASRuntime.ReplaySaveState.Version + 1
                    TASRuntime.ReplaySaveState.Encoded = (type(fileContent) == "string" and fileContent ~= "") and fileContent or nil
                    TASRuntime.ReplaySaveState.EncodedVersion = TASRuntime.ReplaySaveState.Encoded and TASRuntime.ReplaySaveState.Version or -1
                    TASRuntime.ReplaySourceFPS = math.max(1, tonumber(replayFPS or TASConfig.TASRecordingFPS) or 1)
                    TASRuntime.ActiveReplayFPS = TASRuntime.ReplaySourceFPS
                    TASRuntime.PlaybackInterval = 1 / TASRuntime.ActiveReplayFPS
                    TASRuntime.ReplayTableIndex = 1
                    TASPaths.ReplayNeedsReload = false
                    TASPaths.LastLoadedPath = TASPaths.ReplayPath
                    TASCharacter.ConsoleMessage("Decoded replay from file at "..tostring(TASRuntime.ActiveReplayFPS).." FPS")
                else
                    TASRuntime.ReplayTable = {}
                    SetColorCodeFrame("Idle")
                    error("Failed to decode replay")
                end
            else
                TASCharacter.ConsoleMessage("Using cached replay (no decode needed)")
            end

            if not (TASRuntime.ReplayTable and #TASRuntime.ReplayTable > 0) then
                SetColorCodeFrame("Idle")
                TASCharacter.ConsoleMessage("No replay data to read")
                return
            end

            if TASFreeze.Frozen then
                Freeze(false, true)
            end

            TASRuntime.Writing = false
            TASRuntime.RecordingFPSCapActive = false
            TASRuntime.Paused = false
            EndPlaybackPause()
            TASRuntime.AnimateDisabled = false
            if not AllowChangingPhysics then
                ApplyConfiguredPhysics(false)
            end
            TASRuntime.ReplayTableIndex = 1
            TASRuntime.PlaybackInterval = 1 / math.max(1, tonumber(TASRuntime.ActiveReplayFPS or TASRuntime.ReplaySourceFPS or TASConfig.TASRecordingFPS) or 1)
            TASRuntime.PlaybackAccumulator = 0

            if TASConfig.AllowClientObjectManipulation and CO.ReleaseHeldState then pcall(CO.ReleaseHeldState) end

            if TASConfig.AllowClientObjectManipulation then
                if TASConfig.AllowClientObjectManipulation and not CO._initialized and not CO._initializing and CO.QueueInitialization then
                    pcall(CO.QueueInitialization)
                end
                while CO._initializing do
                    TASServices.RunService.Heartbeat:Wait()
                end
                if CO._initialized and CO.ReuseRegistryForPlayback then
                    CO.ReuseRegistryForPlayback()
                elseif CO.RebuildFromAttributes then
                    CO.RebuildFromAttributes()
                end
            elseif CO._initialized and CO.Stop then
                pcall(CO.Stop)
            end
            CO.BeginPlaybackCleanup()
            CO.ResetTargets()
            CO._coDataWarned = false
            CO._replayHasNoCO = false
            CO.AnchorAll()

            if not TASPause.CachedAnimateScript or not TASPause.CachedAnimateScript.Parent then
                TASPause.CachedAnimateScript = findAnimateScript(TASCharacter.Character)
            end

            TASFreeze.ReplayCharacterCollisionStates = {}
            if TASCharacter.Character then
                for _, part in ipairs(TASCharacter.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        TASFreeze.ReplayCharacterCollisionStates[part] = part.CanCollide
                        part.CanCollide = false
                    end
                end
            end

            ClearPlaybackWarmCache()
            local warmCount = math.min(12, #TASRuntime.ReplayTable)
            for warmIndex = 1, warmCount do
                local warmFrame = TASRuntime.ReplayTable[warmIndex]
                if type(warmFrame) == "table" then
                    local warmInputs = warmFrame[12] or {{}, {}}
                    TASPause.PlaybackWarmCache[warmIndex] = {
                        hrpCFrame = FastTableToCFrame(warmFrame[1]),
                        camCFrame = FastTableToCFrame(warmFrame[7]),
                        hrpVel = FastTableToVector3(warmFrame[5]),
                        hrpRotVel = FastTableToVector3(warmFrame[6]),
                        mouseLocation = FastTableToVector2(warmFrame[11]),
                        animations = warmFrame[2] or {},
                        animSpeed = warmFrame[3] or 1,
                        humanoidState = warmFrame[4] or 0,
                        zoom = warmFrame[8] or 0,
                        animPose = warmFrame[9] or "Standing",
                        shiftLock = (warmFrame[10] == 1),
                        inputBegan = warmInputs[1] or {},
                        inputEnded = warmInputs[2] or {}
                    }
                end
                if warmIndex % 4 == 0 then
                    TASServices.RunService.Heartbeat:Wait()
                end
            end

            TASFunctions.BlockInputs()
            TASRuntime.Reading = true
            SetColorCodeFrame("Reading")
            TASCharacter.ConsoleMessage("Reading started")
            TASCharacter.ConsoleMessage("Length: "..TASUtilityFunctions.RoundNumber(#TASRuntime.ReplayTable/math.max(TASRuntime.ReplaySourceFPS, 1)).." seconds (playback "..tostring(TASRuntime.ActiveReplayFPS).." FPS)")
        end)

        TASFreeze.PendingReadingStart = false
        if not ok then
            TASRuntime.Reading = false
            EndPlaybackPause()
            SetColorCodeFrame("Idle")
            TASCharacter.ConsoleMessage("Replay load failed: "..tostring(err))
        end
    end)
end
	TASFunctions.StopReading = function(PreserveCurrentFrame)
        local savedCFrame, savedVelocity, savedRotVelocity
        if TASRuntime.Reading and PreserveCurrentFrame and TASCharacter.Character and TASCharacter.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = TASCharacter.Character.HumanoidRootPart
            savedCFrame = hrp.CFrame
            savedVelocity = hrp.Velocity
            savedRotVelocity = hrp.RotVelocity
        end
		TASRuntime.Paused = false
        EndPlaybackPause()
		ReleaseAllPlaybackKeys()
		TASRuntime.PlaybackAccumulator = 0
		if TASRuntime.Reading then
            TASRuntime.Reading = false
            if TASConfig.AllowClientObjectManipulation then
                if PreserveCurrentFrame and CO.HoldCurrentState then
                    pcall(CO.HoldCurrentState)
                else
                    pcall(CO.RestoreAnchors)
                end
                if CO.ResetTargets then CO.ResetTargets() end
                if not PreserveCurrentFrame and CO.Stop then
                    CO.Stop()
                end
            end

			TASFunctions.UnblockInputs() -- Enable scrolling and clicks
			if TASFreeze.ReplayCharacterCollisionStates and TASCharacter.Character then
				for part, canCollide in pairs(TASFreeze.ReplayCharacterCollisionStates) do
					if part and part.Parent then
						part.CanCollide = canCollide
					end
				end
			end
			TASFreeze.ReplayCharacterCollisionStates = nil
            if TASFreeze.ReplayAnimateScript and TASFreeze.ReplayAnimateScript.Parent then
                TASFreeze.ReplayAnimateScript.Disabled = (TASFreeze.ReplayAnimateScriptDisabled == true)
            end
            TASFreeze.ReplayAnimateScript = nil
            TASFreeze.ReplayAnimateScriptDisabled = nil
			TASRuntime.AnimateDisabled = false -- Enable fake animate script
			if not AllowChangingPhysics then
				ApplyConfiguredPhysics(false)
			end
            if PreserveCurrentFrame and savedCFrame and TASCharacter.Character:FindFirstChild("HumanoidRootPart") then
                local hrp = TASCharacter.Character.HumanoidRootPart
                hrp.CFrame = savedCFrame
                hrp.Velocity = savedVelocity
                hrp.RotVelocity = savedRotVelocity
            end
            TASRuntime.PlaybackSourcePosition = math.max(1, TASRuntime.PlaybackSourcePosition or TASRuntime.ReplayTableIndex or 1)
			SetColorCodeFrame("Idle")
			TASCharacter.ConsoleMessage("Reading stopped")
            ClearPlaybackWarmCache()
		else
			TASCharacter.ConsoleMessage("You are not reading")
		end
	end
end

-- Tasability functions
--local Freeze -- Freeze(NewFrozen) -> nil
do
	Freeze = function(NewFrozen, DoNotRecord)
        if TASFreeze.Frozen == NewFrozen or TASRuntime.Reading then
            return
        end
        TASFreeze.SeekDirection = 0
        if NewFrozen then
            TASFreeze.Frozen = true
            TASFunctions.StopRecording()
            TASFunctions.SaveRecording()
            TASFreeze.FreezeFrame = math.clamp(#TASRuntime.ReplayTable, 1, math.max(#TASRuntime.ReplayTable, 1))
            TASFreeze.ResumeCFrame = nil
            TASFreeze.ResumeVelocity = nil
            TASFreeze.ResumeRotVelocity = nil
            TASFreeze.ResumeHumanoidState = nil
            TASFreeze.ResumeAnimPose = nil
            TASFreeze.ResumeAnimSpeed = nil
            TASFreeze.FrozenAnimTrack = nil
            TASFreeze.FrozenAnimName = TASAnimation.currentAnimName
            TASFreeze.FrozenAnimTime = nil
            TASFreeze.FrozenAnimSpeed = nil
            TASFreeze.ResumeShiftLockEnabled = TASServices.ShiftLockEnabled
            TASFreeze.PhysicsOverrideActive = false

            -- Snapshot the exact live animation at the instant freeze is pressed.
            -- The last recorded TAS frame is not authoritative for the visual state
            -- during a recording freeze.
            pcall(function()
                local track = TASAnimation.currentAnimTrack
                if track and track.Parent then
                    TASFreeze.FrozenAnimTrack = track
                    TASFreeze.FrozenAnimName = TASAnimation.currentAnimName
                    TASFreeze.FrozenAnimTime = tonumber(track.TimePosition) or 0
                    TASFreeze.FrozenAnimSpeed = tonumber(track.Speed) or tonumber(TASAnimation.currentAnimSpeed) or 1
                    TASFreeze.ResumeAnimPose = TASAnimation.pose
                    TASFreeze.ResumeAnimSpeed = TASFreeze.FrozenAnimSpeed
                    track:AdjustSpeed(0)
                end
            end)
            TASPause.PlaybackWarmCache._FreezeInitial = true

            -- Preserve the actual live physics state at the exact moment freeze is
            -- requested. The recording is sampled at TAS FPS, so its last frame can
            -- be slightly older than the real jump/fall state.
            pcall(function()
                local character = TASCharacter.Character
                local hrp = character and character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    TASFreeze.ResumeCFrame = hrp.CFrame
                    TASFreeze.ResumeVelocity = hrp.AssemblyLinearVelocity
                    TASFreeze.ResumeRotVelocity = hrp.AssemblyAngularVelocity
                end
                if TASCharacter.Humanoid then
                    TASFreeze.ResumeHumanoidState = TASCharacter.Humanoid:GetState().Value
                end
            end)

            do
                local freezeFrameData = TASRuntime.ReplayTable[math.clamp(TASUtilityFunctions.RoundNumber(TASFreeze.FreezeFrame, 0), 1, math.max(#TASRuntime.ReplayTable, 1))]
                if type(freezeFrameData) == "table" then
                    -- The replay frame is still used for animation metadata.
                    -- Physical resume data was captured from the live character above
                    -- so a jump/fall is not flattened by frame quantization.
                    if not TASFreeze.ResumeCFrame and freezeFrameData[1] then
                        TASFreeze.ResumeCFrame = FastTableToCFrame(freezeFrameData[1])
                    end
                    if not TASFreeze.ResumeVelocity and freezeFrameData[5] then
                        TASFreeze.ResumeVelocity = FastTableToVector3(freezeFrameData[5])
                    end
                    if not TASFreeze.ResumeRotVelocity and freezeFrameData[6] then
                        TASFreeze.ResumeRotVelocity = FastTableToVector3(freezeFrameData[6])
                    end
                    if TASFreeze.ResumeHumanoidState == nil then TASFreeze.ResumeHumanoidState = freezeFrameData[4] end
                    if not TASFreeze.FrozenAnimTrack then
                        TASFreeze.ResumeAnimPose = freezeFrameData[9]
                        TASFreeze.ResumeAnimSpeed = freezeFrameData[3]
                    end
                end
            end
            ReleaseAllPlaybackKeys()
            if TASConfig.AllowClientObjectManipulation then
                if CO.ResetTargets then CO.ResetTargets() end
                if CO.AnchorAll then CO.AnchorAll() end
            end


            -- Freeze the mouse position independently of the camera-freeze option.
            pcall(function()
                TASFreeze.FrozenMouseBehavior = TASServices.UserInputService.MouseBehavior
                TASServices.UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
            end)

            if workspace.CurrentCamera and not (movecameraonfroze and movecameraonfroze.Value) then
                TASFreeze.FrozenCameraType = workspace.CurrentCamera.CameraType
                workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
                local f = TASRuntime.ReplayTable[math.clamp(TASUtilityFunctions.RoundNumber(TASFreeze.FreezeFrame, 0), 1, math.max(#TASRuntime.ReplayTable, 1))]
                if type(f) == "table" and f[7] then
                    TASFreeze.FrozenCameraCFrame = FastTableToCFrame(f[7])
                    workspace.CurrentCamera.CFrame = TASFreeze.FrozenCameraCFrame
                else
                    TASFreeze.FrozenCameraCFrame = workspace.CurrentCamera.CFrame
                end
                pcall(function()
                    TASServices.RunService:UnbindFromRenderStep(TASFreeze.FrozenCameraBindName)
                    TASServices.RunService:BindToRenderStep(TASFreeze.FrozenCameraBindName, Enum.RenderPriority.Camera.Value + 10, function()
                        if not TASFreeze.Frozen then return end
                        local cam = workspace.CurrentCamera
                        if cam then
                            cam.CameraType = Enum.CameraType.Scriptable
                            if TASFreeze.FrozenCameraCFrame then
                                cam.CFrame = TASFreeze.FrozenCameraCFrame
                            end
                        end
                    end)
                end)
            end
            SetColorCodeFrame("Frozen")
        else
            pcall(function() TASServices.RunService:UnbindFromRenderStep(TASFreeze.FrozenCharacterBindName) end)
            pcall(function() TASServices.RunService:UnbindFromRenderStep(TASFreeze.FrozenCameraBindName) end)
            if TASConfig.AllowClientObjectManipulation then
                if CO.RestoreAnchors then CO.RestoreAnchors() end
                if CO.ResetTargets then CO.ResetTargets() end
            end
            if TASFreeze.FrozenCameraType and workspace.CurrentCamera then
                local cam = workspace.CurrentCamera
                local restoreType = TASFreeze.FrozenCameraType
                -- Never restore Scriptable from a previous freeze cycle.
                -- That would leave the camera permanently locked after M.
                if restoreType == Enum.CameraType.Scriptable then
                    restoreType = Enum.CameraType.Custom
                end
                cam.CameraType = restoreType
                if restoreType == Enum.CameraType.Custom and TASCharacter.Humanoid then
                    pcall(function() cam.CameraSubject = TASCharacter.Humanoid end)
                end
                TASFreeze.FrozenCameraType = nil
            end
            pcall(function()
                if TASFreeze.FrozenMouseBehavior ~= nil then
                    TASServices.UserInputService.MouseBehavior = TASFreeze.FrozenMouseBehavior
                end
            end)
            TASFreeze.FrozenMouseBehavior = nil
            TASFreeze.FrozenCameraCFrame = nil
            TASFreeze.FrozenCameraType = nil
            TASFreeze.PhysicsOverrideActive = false
            TASFreeze.Frozen = false
            pcall(function()
                -- Always release the real character. Normal freeze anchors it too;
                -- the important distinction is that the resume state comes from the
                -- live character captured at the instant freeze was pressed.
                local character = TASCharacter.Character
                local hrp = character and character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.Anchored = false
                end
                if TASCharacter.Humanoid then
                    TASCharacter.Humanoid.PlatformStand = false
                end
                if not AllowChangingPhysics then
                    ApplyConfiguredPhysics(false)
                end

                if TASCharacter.Humanoid and TASFreeze.ResumeHumanoidState ~= nil then
                    pcall(function() TASCharacter.Humanoid:ChangeState(TASFreeze.ResumeHumanoidState) end)
                end
                -- Restore the exact animation track/time after ChangeState, because
                -- unfreezing can fire a state callback that otherwise swaps it.
                pcall(function()
                    local track = TASFreeze.FrozenAnimTrack
                    if track and track.Parent then
                        if TASFreeze.FrozenAnimTime ~= nil then
                            track.TimePosition = TASFreeze.FrozenAnimTime
                        end
                        local speed = tonumber(TASFreeze.FrozenAnimSpeed or TASFreeze.ResumeAnimSpeed) or 1
                        track:AdjustSpeed(speed)
                        TASAnimation.currentAnimTrack = track
                        TASAnimation.currentAnimName = TASFreeze.FrozenAnimName or TASAnimation.currentAnimName
                        TASAnimation.currentAnimSpeed = speed
                    end
                end)
                if hrp then
                    if TASFreeze.ResumeCFrame then hrp.CFrame = TASFreeze.ResumeCFrame end
                    if TASFreeze.ResumeRotVelocity then
                        hrp.AssemblyAngularVelocity = TASFreeze.ResumeRotVelocity
                        hrp.RotVelocity = TASFreeze.ResumeRotVelocity
                    end
                    if TASFreeze.ResumeVelocity then
                        hrp.AssemblyLinearVelocity = TASFreeze.ResumeVelocity
                        hrp.Velocity = TASFreeze.ResumeVelocity
                    end
                end

                -- Roblox may recalculate the humanoid assembly on the first physics
                -- step after unanchoring. Reapply the captured velocity once after
                -- Heartbeat so a jump/fall continues with its original Y velocity.
                local resumeVelocity = TASFreeze.ResumeVelocity
                local resumeRotVelocity = TASFreeze.ResumeRotVelocity
                if resumeVelocity or resumeRotVelocity then
                    task.spawn(function()
                        TASServices.RunService.Heartbeat:Wait()
                        pcall(function()
                            local currentCharacter = TASCharacter.Character
                            local currentHRP = currentCharacter and currentCharacter:FindFirstChild("HumanoidRootPart")
                            if currentHRP and not TASFreeze.Frozen then
                                if resumeRotVelocity then
                                    currentHRP.AssemblyAngularVelocity = resumeRotVelocity
                                    currentHRP.RotVelocity = resumeRotVelocity
                                end
                                if resumeVelocity then
                                    currentHRP.AssemblyLinearVelocity = resumeVelocity
                                    currentHRP.Velocity = resumeVelocity
                                end
                            end
                        end)
                    end)
                end
                if TASFreeze.ResumeAnimPose then TASAnimation.pose = TASFreeze.ResumeAnimPose end
                if TASFreeze.ResumeAnimSpeed then pcall(setAnimationSpeed, TASFreeze.ResumeAnimSpeed) end
            end)

            -- Freeze must be transparent to Shift Lock: restore exactly the state
            -- that existed before M/FREEZE was pressed.
            if TASFreeze.ResumeShiftLockEnabled ~= nil and TASServices.ShiftLockEnabled ~= TASFreeze.ResumeShiftLockEnabled then
                pcall(function() TASFunctions.SetShiftLockEnabled(TASFreeze.ResumeShiftLockEnabled) end)
            end
            TASFreeze.ResumeShiftLockEnabled = nil
            TASFreeze.FrozenAnimTrack = nil
            TASFreeze.FrozenAnimName = nil
            TASFreeze.FrozenAnimTime = nil
            TASFreeze.FrozenAnimSpeed = nil
            if DoNotRecord then
                SetColorCodeFrame("Idle")
            else
                for Index = #TASRuntime.ReplayTable, TASFreeze.FreezeFrame, -1 do
                    TASRuntime.ReplayTable[Index] = nil
                end
                TASFunctions.StartRecording()
                SetColorCodeFrame("Recording")
            end
        end
    end
end

-- Commands
Commands = {}
do
	Commands["help"] = function(Args)
		if Args == "help" then
			TASCharacter.ConsoleMessage("help <command>: Shows a list of all commands, or a specific command")
		else
			local Command = Args[1]
			if Command then
				Command = string.lower(Command)
				if Commands[Command] then
					Commands[Command]("help")
				else
					TASCharacter.ConsoleMessage("Command", Command, "was not found")
				end
			else
				for _,Command in pairs(Commands) do
					Command("help")
				end
			end
		end
	end
	Commands["clean"] = function(Args)
		if Args == "help" then
			TASCharacter.ConsoleMessage("clean: Clears all messages from the in-game console")
		else
			if console and console.ClearLogs then
				console:ClearLogs()
			end
		end
	end

	Commands["erase"] = function(Args)
    if Args == "help" then
        TASCharacter.ConsoleMessage("erase: Erases the selected replay file",TASPaths.PlaceId)
    else
        if type(TASPaths.ReplayPath) ~= "string" or not isfile(TASPaths.ReplayPath) then
            return "No replay file selected"
        end
        writefile(TASPaths.ReplayPath, TASFunctions.ReplayEncode({}))
        TASRuntime.ReplayTable = {}
        TASRuntime.ReplaySaveState.Version = TASRuntime.ReplaySaveState.Version + 1
        TASRuntime.ReplaySaveState.Encoded = nil
        TASRuntime.ReplaySaveState.EncodedVersion = -1
        TASPaths.ReplayNeedsReload = false
        TASPaths.LastLoadedPath = TASPaths.ReplayPath
        return TASPaths.ReplayPath.." has been erased (cache cleared)"
    end
end

	Commands["reset"] = function(Args)
		if Args == "help" then
			TASCharacter.ConsoleMessage("reset: Clears the current recording, all replay frames, and the current replay file")
		else
			TASFunctions.ResetCurrentRecording()
			return "Current recording and replay frames reset"
		end
	end
	Commands["setsdm"] = function(Args)
		if Args == "help" then
			TASCharacter.ConsoleMessage("setsdm <number SeekDirectionMultiplier>: Sets speed multiplier when using R and T while frozen")
		else
			local Number = tonumber(Args[1]) or 1
			if Number then
				local OldValue = TASFreeze.SeekDirectionMultiplier
				TASFreeze.SeekDirectionMultiplier = Number
				return "SeekDirectionMultiplier has been set from "..tostring(OldValue).." to "..tostring(Number)
			end
		end
	end
	Commands["rejoin"] = function(Args)
		if Args == "help" then
			TASCharacter.ConsoleMessage("rejoin <bool SaveReplay>: Sets one of the configs at the top of the script (PlaybackInputs, etc)")
		else
			local SaveReplay = Args[1] and string.lower(Args[1])
			TASCharacter.ConsoleMessage("Saving...")
			if SaveReplay == "true" or SaveReplay == "yes" or SaveReplay == "1" or SaveReplay == "save" then
				SaveToFile()
			end
			TASCharacter.ConsoleMessage("Rejoining...")
			if #game.Players:GetPlayers() <= 1 then
				game.Players.LocalPlayer:Kick("\nRejoining...")
				wait()
				game:GetService("TeleportService"):Teleport(game.PlaceId, game.Players.LocalPlayer)
			else
				game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, game.Players.LocalPlayer)
			end
			return "Sent request to rejoin"
		end
	end
	Commands["invite"] = function(Args)
		if Args == "help" then
			TASCharacter.ConsoleMessage("invite: Invites you to Tasability Discord")
			return
		end
		local opened, reason = false, "unavailable"
		if type(_G.__TasabilityOpenDiscordInviteInBrowser) == "function" then
			opened, reason = _G.__TasabilityOpenDiscordInviteInBrowser(TAS_DISCORD_INVITE_FALLBACK)
		end
		if opened then
			return "Sent invite: " .. TAS_DISCORD_INVITE_FALLBACK
		end
		return "Invite failed: " .. tostring(reason)
	end
end

-- Connection Functions (assigned below)
local StateChanged, CharacterAdded, InputBegan, InputChanged, InputEnded
local RenderStepped, Stepped, CurrentCamera_Changed
do
	StateChanged = function(_,State)
		table.insert(TASRuntime.HumanoidStateQueue,State.Value)
	end
	CharacterAdded = function(NewCharacter)
		TASCharacter.Humanoid = NewCharacter:WaitForChild("Humanoid")
		TASCharacter.Humanoid.StateChanged:Connect(StateChanged)
		TASCharacter.RootPart = NewCharacter:WaitForChild("HumanoidRootPart")
		TASCharacter.DefaultJumpPower = TASCharacter.Humanoid.JumpPower
		TASCharacter.DefaultWalkSpeed = TASCharacter.Humanoid.WalkSpeed
		Reanimate(NewCharacter)
		TASCharacter.Character = NewCharacter
		TASCharacter.Humanoid.Died:Connect(function()
			TASRuntime.Dead = true
		end)
		TASRuntime.Dead = false
	end
	InputBegan = function(Input,GameProcessed)
	if Input.UserInputType == Enum.UserInputType.Keyboard and TASServices.UserInputService:GetFocusedTextBox() then
		return
	end

	if TASRuntime.IgnoreGameProcessed then
		GameProcessed = false
	end
	
	if Input.UserInputType == Enum.UserInputType.MouseButton1 then
		table.insert(TASRuntime.InputBeganQueue,"b1")
	elseif Input.UserInputType == Enum.UserInputType.MouseButton2 then
		table.insert(TASRuntime.InputBeganQueue,"b2")
	elseif Input.UserInputType == Enum.UserInputType.Keyboard then
		local InputName = string.split(tostring(Input.KeyCode),".")[3]
		if not TASConfig.InputBlacklist[InputName] then
			table.insert(TASRuntime.InputBeganQueue,InputName)
		end
	end
	
	if Input.KeyCode == Enum.KeyCode.LeftShift and not TASRuntime.Reading and not TASFreeze.Frozen and not GameProcessed then
		TASFunctions.SetShiftLockEnabled(not TASServices.ShiftLockEnabled)
	end
	
	if Input.KeyCode == Recordkeybind.Value and not GameProcessed then
		-- Freeze/Unfreeze
		Freeze(not TASFreeze.Frozen)
	elseif Input.KeyCode == Gobackwardskeybind.Value and not GameProcessed then
		if not TASRuntime.Reading then
			TASFreeze.SeekAccumulator = 0
			Freeze(true)
			if TASFreeze.SeekDirection == 0 then
				TASFreeze.SeekDirection = -1*TASFreeze.SeekDirectionMultiplier -- Backwards
			end
		end
	elseif Input.KeyCode == Goforwardkeybind.Value and not GameProcessed then
		-- Seek fowards
		if not TASRuntime.Reading then
			TASFreeze.SeekAccumulator = 0
			Freeze(true)
			if TASFreeze.SeekDirection == 0 then
				TASFreeze.SeekDirection = 1*TASFreeze.SeekDirectionMultiplier -- Fowards
			end
		end
	elseif Input.KeyCode == Frameadvancebackwardskeybind.Value and not GameProcessed then
		-- Go 1 frame backwards
		TASFreeze.SeekAccumulator = 0
		Freeze(true)
		if TASFreeze.Frozen and TASFreeze.SeekDirection == 0 then
			local NewFreezeFrame = TASFreeze.FreezeFrame - 1
			if NewFreezeFrame > 0 and NewFreezeFrame <= #TASRuntime.ReplayTable then
				TASFreeze.FreezeFrame = NewFreezeFrame
			end
		end
	elseif Input.KeyCode == Frameadvanceforwardkeybind.Value and not GameProcessed then
		-- Go 1 frame fowards
		TASFreeze.SeekAccumulator = 0
		Freeze(true)
		if TASFreeze.Frozen and TASFreeze.SeekDirection == 0 then
			local NewFreezeFrame = TASFreeze.FreezeFrame + 1
			if NewFreezeFrame > 0 and NewFreezeFrame <= #TASRuntime.ReplayTable then
				TASFreeze.FreezeFrame = NewFreezeFrame
			end
		end
	elseif Input.KeyCode == Hideuikeybind.Value and not GameProcessed then
		-- Toggle UI
		Window:ToggleVisibility()
	elseif Input.KeyCode == Abortkeybind.Value and not GameProcessed then
		-- Stop reading
		TASFunctions.StopReading(true)
	elseif Input.KeyCode == Savekeybind.Value and not GameProcessed then
		-- Save to file
		SaveToFile()
	elseif Input.KeyCode == Frozenkeybind.Value and not GameProcessed then
		-- Frozen to idle
		IdleButton_MouseButton1Click()
	elseif Input.KeyCode == Readkeybind.Value and not GameProcessed then
		ReadButton_MouseButton1Click()
	elseif Input.KeyCode == Pausekeybind.Value and not GameProcessed then
		-- Pause/Resume reading
		if TASRuntime.Reading then
            if not TASRuntime.Paused then
                TASRuntime.Paused = true
                BeginPlaybackPause()
                TASCharacter.ConsoleMessage("Paused")
                SetColorCodeFrame("Frozen")
            else
                EndPlaybackPause()
                TASRuntime.Paused = false
                TASRuntime.PlaybackAccumulator = 0
                TASCharacter.ConsoleMessage("Resumed")
                SetColorCodeFrame("Reading")
            end
		end
	end
end
	InputChanged = function(Input,GameProcessed)
		if Input.UserInputType == Enum.UserInputType.MouseWheel then
			if Input.Position.Z > 0 then
				table.insert(TASRuntime.InputBeganQueue,"u")
			else
				table.insert(TASRuntime.InputBeganQueue,"d")
			end
		end
	end
	InputEnded = function(Input,GameProcessed)
		if Input.UserInputType == Enum.UserInputType.Keyboard and TASServices.UserInputService:GetFocusedTextBox() then
			return
		end
		if Input.UserInputType == Enum.UserInputType.MouseButton1 then
			table.insert(TASRuntime.InputEndedQueue,"b1")
		elseif Input.UserInputType == Enum.UserInputType.MouseButton2 then
			table.insert(TASRuntime.InputEndedQueue,"b2")
		elseif Input.UserInputType == Enum.UserInputType.MouseWheel then
			if Input.Position.Z > 0 then
				table.insert(TASRuntime.InputEndedQueue,"u")
			else
				table.insert(TASRuntime.InputEndedQueue,"d")
			end
		elseif Input.UserInputType == Enum.UserInputType.Keyboard then
			local InputName = string.split(tostring(Input.KeyCode),".")[3]
			if not TASConfig.InputBlacklist[InputName] then
				table.insert(TASRuntime.InputEndedQueue,InputName)
			end
		end
		
		if Input.KeyCode == Gobackwardskeybind.Value then
			-- Stop seeking backwards
			if TASFreeze.SeekDirection == -1*TASFreeze.SeekDirectionMultiplier then
				TASFreeze.SeekDirection = 0
			end
		elseif Input.KeyCode == Goforwardkeybind.Value then
			-- Stop seeking fowards
			if TASFreeze.SeekDirection == 1*TASFreeze.SeekDirectionMultiplier then
				TASFreeze.SeekDirection = 0
			end
		end
	end
	RenderStepped = function(deltaTime, ...)
		for _,Function in pairs(TASRuntime.RenderSteppedConnections) do
			Function(deltaTime, ...)
		end
	end
	Stepped = function(...)
		for _,Function in pairs(TASRuntime.SteppedConnections) do
			Function(...)
		end
	end
	ReadButton_MouseButton1Click = function()
		if TASConfig.ReplayStartTime >= 1 then
			for i = TASConfig.ReplayStartTime,1,-1 do
				TASCharacter.ConsoleMessage("Reading in "..tostring(i).." seconds")
				wait(1)
			end
		end
		TASFunctions.StartReading()
	end
	IdleButton_MouseButton1Click = function()
		if GetColorCodeFrame() == "Frozen" then
			Freeze(false,true)
		end
	end
    CurrentCamera_Changed = function()
        if TASRuntime.Reading then
            workspace.CurrentCamera.CFrame = TASRuntime.CameraCFrame
        elseif TASFreeze.Frozen and not (movecameraonfroze and movecameraonfroze.Value) then
            local idx = math.clamp(TASUtilityFunctions.RoundNumber(TASFreeze.FreezeFrame, 0), 1, #TASRuntime.ReplayTable)
            local f = TASRuntime.ReplayTable[idx]
            if type(f) == "table" and f[7] then
                workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
                workspace.CurrentCamera.CFrame = TASUtilityFunctions.TableToCFrame(f[7])
            end
        end
    end
	ConsoleInput.Callback = function(self, value)
		local Input = value
		local InputSplit = string.split(Input," ")
		local Command = Commands[string.lower(InputSplit[1])]
		if Command then
			table.remove(InputSplit,1)
			local ReturnMessage = Command(InputSplit)
			if ReturnMessage then
				TASCharacter.ConsoleMessage(ReturnMessage)
			end
		else
			TASCharacter.ConsoleMessage("Command",InputSplit[1],"was not found")
		end
		self:Clear()
	end
end

-- RenderStepped/Stepped connections
do
	-- INFO frame label is refreshed by the low-frequency UI sampler below.
	TASRuntime.RenderSteppedConnections.DrawPathVisuals = function()
    if TASPaths.pathVisualsEnabled then
        drawPathVisuals()
    end
end
	TASRuntime.RenderSteppedConnections.SeekDirectionHandler = function(deltaTime)
		if not TASFreeze.Frozen or TASFreeze.SeekDirection == 0 then
			TASFreeze.SeekAccumulator = 0
			return
		end

		local seekFPS = math.max(1, tonumber(TASConfig.TASRecordingFPS) or 1)
		local interval = 1 / seekFPS
		TASFreeze.SeekAccumulator = TASFreeze.SeekAccumulator + math.max(0, tonumber(deltaTime) or 0)

		local steps = math.floor((TASFreeze.SeekAccumulator + 1e-9) / interval)
		if steps <= 0 then return end
		TASFreeze.SeekAccumulator = TASFreeze.SeekAccumulator - steps * interval
		if TASFreeze.SeekAccumulator < 0 then TASFreeze.SeekAccumulator = 0 end

		local direction = TASFreeze.SeekDirection > 0 and 1 or -1
		local maxFrame = #TASRuntime.ReplayTable
		if maxFrame <= 0 then return end

		TASFreeze.FreezeFrame = math.clamp(TASFreeze.FreezeFrame + direction * steps, 1, maxFrame)
	end


    local PressedWriting = {}

    local function TASBuildPressedKeysText(keys)
        local names = {}
        for keyName, isDown in pairs(keys or {}) do
            if isDown then names[#names + 1] = tostring(keyName) end
        end
        table.sort(names)
        if #names == 0 then return "|" end
        return "|" .. table.concat(names, "|") .. "|"
    end

    -- Low-frequency UI sampler: the game state is updated at normal TAS cadence,
    -- while these labels are refreshed only 10 times/sec. This keeps the INFO
    -- panel live without writing TextLabel properties on every render frame.
    task.spawn(function()
        local lastFramesText, lastPressedText, lastWritingText
        while MainFrame and MainFrame.Parent do
            task.wait(0.1)
            local frameText
            if TASRuntime.Writing then
                frameText = "Frames: " .. tostring(#TASRuntime.RecordingTable)
            elseif TASRuntime.Reading then
                frameText = string.format("Frames: %d / %d", TASRuntime.ReplayTableIndex or 0, #TASRuntime.ReplayTable)
            elseif TASFreeze.Frozen then
                frameText = string.format("Frames: %d / %d", TASUtilityFunctions.RoundNumber(TASFreeze.FreezeFrame, 0), #TASRuntime.ReplayTable)
            else
                frameText = "Frames: " .. tostring(#TASRuntime.ReplayTable)
            end

            local pressedText = "Pressed keys: " .. TASBuildPressedKeysText(TASRuntime.Pressed)
            local writingText = "Writing Pressed keys: " .. TASBuildPressedKeysText(PressedWriting)

            if frameText ~= lastFramesText then
                RecordedFramesLabel.Text = frameText
                lastFramesText = frameText
            end
            if pressedText ~= lastPressedText then
                PressedKeysLabel.Text = pressedText
                lastPressedText = pressedText
            end
            if writingText ~= lastWritingText then
                WritingPressedKeysLabel.Text = writingText
                lastWritingText = writingText
            end
        end
    end)

TASRuntime.SteppedConnections.UpdateKeyboardOverlay = function()
    if getgenv().KeyboardOverlayEnabled and getgenv().KeyboardOverlayKeys then
        local keys = getgenv().KeyboardOverlayKeys
        local theme = KeyboardOverlayThemes[currentTheme]
        
        -- Determine which key table to use
        local keysToCheck = TASRuntime.Writing and PressedWriting or TASRuntime.Pressed
        
        for keyName, keyFrame in pairs(keys) do
            local state = "normal"
            
            if keysToCheck[keyName] then
                state = TASRuntime.Writing and "writing" or "pressed"
            end
            
            theme.updateColors(keyFrame, state)
        end
    end
end

TASRuntime.SteppedConnections.UpdateInputPreview = function()
	for _,Input in pairs(TASRuntime.InputBeganQueue) do
		if Input == "u" or Input == "d" then
			return
		end
		TASRuntime.Pressed[Input] = true
	end
	for _,Input in pairs(TASRuntime.InputEndedQueue) do
		TASRuntime.Pressed[Input] = nil
	end
	-- Pressed-key labels are rendered by the low-frequency INFO sampler.

	if TASRuntime.Writing then
		for _,Input in pairs(TASRuntime.InputBeganQueue) do
			if Input == "u" or Input == "d" then
			else
				PressedWriting[Input] = true
			end
		end
		for _,Input in pairs(TASRuntime.InputEndedQueue) do
			PressedWriting[Input] = nil
		end
		-- Writing pressed-key labels are rendered by the low-frequency INFO sampler.
		end
	end
end

-- Apply saved keybinds/checkbox state after controls are created.
-- Kept in its own function so these temporary locals do not consume registers
-- from the large top-level GUI chunk.
local function ApplySavedControlState()
    local k = type(TasSettings.Keybinds) == "table" and TasSettings.Keybinds or {}
    local map = {HideUI=Hideuikeybind, Record=Recordkeybind, Forward=Goforwardkeybind, Backward=Gobackwardskeybind, FrameForward=Frameadvanceforwardkeybind, FrameBackward=Frameadvancebackwardskeybind, Save=Savekeybind, Read=Readkeybind, Abort=Abortkeybind}
    for name, shim in pairs(map) do
        local enumName = k[name]
        if shim and type(enumName) == "string" then
            local ok = pcall(function() shim.Value = Enum.KeyCode[enumName] end)
            if not ok then
                -- Ignore unknown/obsolete keybind names from old settings.
            end
        end
    end
    local c = type(TasSettings.Checkboxes) == "table" and TasSettings.Checkboxes or {}
    if KeyboardOverlay and c.KeyboardOverlay ~= nil then KeyboardOverlay.Value = c.KeyboardOverlay end
    if DisableParticles and c.DisableParticles ~= nil then DisableParticles.Value = c.DisableParticles end
    if DisableLighting and c.DisableLighting ~= nil then DisableLighting.Value = c.DisableLighting end
    if MotionBlurToggle and c.MotionBlur ~= nil then MotionBlurToggle.Value = c.MotionBlur end
    if movecameraonfroze and c.MoveCameraFrozen ~= nil then movecameraonfroze.Value = c.MoveCameraFrozen end
end
ApplySavedControlState()
pcall(SaveTasSettings)

-- Lightweight settings watcher. It only writes when the serialized signature changes.
task.spawn(function()
    local lastSig = ""
    while true do
        task.wait(2)
        local parts = {
            tostring(TASConfig.FPS), tostring(TASConfig.TASRecordingFPS), tostring(currentTheme),
            tostring(PlayersPanelVisible), tostring(FilesPanelVisible),
            MainFrame and tostring(MainFrame.Position.X.Scale) or "", MainFrame and tostring(MainFrame.Position.X.Offset) or "",
            MainFrame and tostring(MainFrame.Position.Y.Scale) or "", MainFrame and tostring(MainFrame.Position.Y.Offset) or "",
            MainFrame and tostring(MainFrame.Size.X.Offset) or "", MainFrame and tostring(MainFrame.Size.Y.Offset) or "",
            Hideuikeybind and _tasKeyName(Hideuikeybind.Value) or "",
            Recordkeybind and _tasKeyName(Recordkeybind.Value) or "",
            Goforwardkeybind and _tasKeyName(Goforwardkeybind.Value) or "",
            Gobackwardskeybind and _tasKeyName(Gobackwardskeybind.Value) or "",
            Frameadvanceforwardkeybind and _tasKeyName(Frameadvanceforwardkeybind.Value) or "",
            Frameadvancebackwardskeybind and _tasKeyName(Frameadvancebackwardskeybind.Value) or "",
            Savekeybind and _tasKeyName(Savekeybind.Value) or "",
            Readkeybind and _tasKeyName(Readkeybind.Value) or "",
            Abortkeybind and _tasKeyName(Abortkeybind.Value) or "",
            tostring(KeyboardOverlay and KeyboardOverlay.Value), tostring(DisableParticles and DisableParticles.Value),
            tostring(DisableLighting and DisableLighting.Value), tostring(MotionBlurToggle and MotionBlurToggle.Value),
            tostring(movecameraonfroze and movecameraonfroze.Value),
        }
        local sig = table.concat(parts, "|")
        if sig ~= lastSig then
            lastSig = sig
            pcall(SaveTasSettings)
        end
    end
end)


do -- Connections
	TASServices.UserInputService.InputBegan:Connect(InputBegan)
	TASServices.UserInputService.InputChanged:Connect(InputChanged)
	TASServices.UserInputService.InputEnded:Connect(InputEnded)
	TASServices.RunService.RenderStepped:Connect(RenderStepped)
	TASServices.RunService.Stepped:Connect(Stepped)
	TASServices.Player.CharacterAdded:Connect(CharacterAdded)
end

do -- Setup
	-- Replay files are created only explicitly from the Files panel.
	TASFunctions.SetCursor("ArrowFarCursor") -- Add fake cursor - MUST BE BEFORE HIDING REAL CURSOR
	TASServices.UserInputService.MouseIconEnabled = false -- Remove real cursor; fake cursor is rendered by TASRuntime.Cursor
	TASCharacter.DefaultGravity = workspace.Gravity -- Set DefaultGravity
	TASServices.ShiftLockBoundKeys.Value = "" -- Remove shift lock keybinds
	CharacterAdded(TASServices.Player.Character) -- Set character
	SetColorCodeFrame("Idle") -- Set color code
    if setfpscap then setfpscap(TASConfig.FPS) end

    -- Prepare CO only when client-object recording is enabled.
    if TASConfig.AllowClientObjectManipulation then
        pcall(function() CO.QueueInitialization() end)
    end
end

function findAnimateScript(character)
    if not character then return nil end
          
    local names = {
        "Animate",
        "AnimationScript",
        "CharacterAnimate",
        "PlayerAnimate"
    }

    for _, name in ipairs(names) do
        local s = character:FindFirstChild(name, true)
        if s and s:IsA("LocalScript") then
            return s
        end
    end

    for _, obj in ipairs(character:GetDescendants()) do
        if obj:IsA("LocalScript") then
            for _, sub in ipairs(obj:GetChildren()) do
                local n = sub.Name:lower()
                if n == "idle" or n == "walk" or n == "run" or n == "jump" or n == "fall" then
                    return obj
                end
            end
        end
    end

    return nil
end



 

spawn(function() -- Reading Loop

    local frameCache = TASPause.PlaybackWarmCache
    local lastVelocity = Vector3.new()
    local idleFrameCount = 0
    local idle_threshold = 3
    local playbackAccumulator = 0
    local finalFrameHold = 0
    local playbackSignal = {}

    while true do
        local deltaTime = TASServices.RunService.Heartbeat:Wait()

        if TASRuntime.Reading then
            if TASRuntime.Paused then
                playbackAccumulator = 0
                HoldPlaybackPausedState()
                continue
            end

            -- The TAS timeline is fixed to the saved recording FPS, not the
            -- client's rendering/heartbeat FPS. At 120 client FPS and 60 TAS
            -- FPS we must keep each TAS frame for two heartbeats.
            local playbackInterval = TASRuntime.PlaybackInterval
            if playbackInterval <= 0 then
                playbackInterval = 1 / math.max(1, tonumber(TASRuntime.ActiveReplayFPS or TASRuntime.ReplaySourceFPS or TASConfig.TASRecordingFPS) or 1)
                TASRuntime.PlaybackInterval = playbackInterval
            end
            playbackAccumulator = playbackAccumulator + math.max(0, tonumber(deltaTime) or 0)

            local advanceFrame = false
            if playbackAccumulator + 1e-9 >= playbackInterval then
                local steps = math.floor((playbackAccumulator + 1e-9) / playbackInterval)
                steps = math.min(steps, 4)
                playbackAccumulator = playbackAccumulator - steps * playbackInterval
                if playbackAccumulator < 0 then playbackAccumulator = 0 end

                local oldIndex = TASRuntime.ReplayTableIndex
                TASRuntime.ReplayTableIndex = math.min(TASRuntime.ReplayTableIndex + steps, #TASRuntime.ReplayTable)
                advanceFrame = TASRuntime.ReplayTableIndex ~= oldIndex
            end

            local Frame = TASRuntime.ReplayTable[TASRuntime.ReplayTableIndex]

            if Frame == 0 then
                TASCharacter.Humanoid:ChangeState(15)
                for _, Descendant in pairs(TASCharacter.Character:GetDescendants()) do
                    if Descendant:IsA("BasePart") then
                        Descendant:Destroy()
                    end
                end
                repeat task.wait() until not TASRuntime.Dead
                TASServices.RunService.Heartbeat:Wait()
                TASRuntime.ReplayTableIndex = TASRuntime.ReplayTableIndex + 1
                idleFrameCount = 0
                continue
            elseif Frame == 1 then
                TASCharacter.Humanoid:ChangeState(15)
                if not AllowChangingPhysics then
                    ApplyConfiguredPhysics(false)
                end
                repeat task.wait() until not TASRuntime.Dead
                TASServices.RunService.Heartbeat:Wait()
                TASRuntime.ReplayTableIndex = TASRuntime.ReplayTableIndex + 1
                idleFrameCount = 0
                continue
            end

            if not Frame or typeof(Frame) == "string" then
                TASFunctions.StopReading(true)
                continue
            end

            -- Animate Script is cached at playback start. Only fall back to a
            -- search if the instance was removed/replaced.
            local animateScript = TASPause.CachedAnimateScript
            if not animateScript or not animateScript.Parent then
                animateScript = findAnimateScript(TASCharacter.Character)
                TASPause.CachedAnimateScript = animateScript
            end
            if animateScript then
                animateScript.Disabled = true
                if not TASFreeze.ReplayAnimateScript then
                    TASFreeze.ReplayAnimateScript = animateScript
                    TASFreeze.ReplayAnimateScriptDisabled = false
                end
            end

            TASRuntime.AnimateDisabled = true
            EnforcePlaybackPhysics()

            if not TASCharacter.Character:FindFirstChild("HumanoidRootPart") then
                TASServices.RunService.Heartbeat:Wait()
                continue
            end

            local HRP = TASCharacter.Character.HumanoidRootPart
            TASCharacter.Humanoid.PlatformStand = true

            local inputs = Frame[12] or {{}, {}}
            local cache = frameCache[TASRuntime.ReplayTableIndex]
            if not cache then
                cache = {
                    hrpCFrame = FastTableToCFrame(Frame[1]),
                    camCFrame = FastTableToCFrame(Frame[7]),
                    hrpVel = FastTableToVector3(Frame[5]),
                    hrpRotVel = FastTableToVector3(Frame[6]),
                    mouseLocation = FastTableToVector2(Frame[11]),
                    animations = Frame[2] or {},
                    animSpeed = Frame[3] or 1,
                    humanoidState = Frame[4] or 0,
                    zoom = Frame[8] or 0,
                    animPose = Frame[9] or "Standing",
                    shiftLock = (Frame[10] == 1),
                    inputBegan = inputs[1] or {},
                    inputEnded = inputs[2] or {}
                }
                frameCache[TASRuntime.ReplayTableIndex] = cache
            end

            local currentVelocity = cache.hrpVel
            local velocityMagnitude = currentVelocity.Magnitude
            local isOnGround = cache.humanoidState == 8 or cache.humanoidState == 0 or cache.humanoidState == 2
            local isClimbing = cache.humanoidState == 12
            local isSeated = cache.humanoidState == 13
            local isStationary = velocityMagnitude < 0.1

            if isStationary and isOnGround and not isClimbing and not isSeated then
                idleFrameCount = idleFrameCount + 1
            else
                idleFrameCount = 0
            end

            local shouldForceIdle = idleFrameCount >= idle_threshold and isOnGround and not isClimbing and not isSeated

            -- Inputs, animations, camera, and state-change callbacks belong to
            -- the TAS timeline, so they are processed only when we advance to a
            -- new TAS frame. The physical pose itself is still enforced every
            -- heartbeat below, keeping the character visually locked to the
            -- current recorded frame.
            if advanceFrame then
                TASAnimation.pose = cache.animPose
                TASCharacter.Humanoid:ChangeState(cache.humanoidState)

                if shouldForceIdle then
                    local hasWalkOrRun = false
                    for _, Arguments in pairs(cache.animations) do
                        local animName = Arguments[1]
                        if animName == "walk" or animName == "run" then
                            hasWalkOrRun = true
                            break
                        end
                    end

                    if hasWalkOrRun then
                        playAnimation("idle", 0.1, TASCharacter.Humanoid, true)
                        pcall(setAnimationSpeed, 1.0)
                    else
                        for _, Arguments in pairs(cache.animations) do
                            playAnimation(Arguments[1], Arguments[2], TASCharacter.Humanoid, true)
                        end
                        pcall(setAnimationSpeed, cache.animSpeed)
                    end
                else
                    for _, Arguments in pairs(cache.animations) do
                        playAnimation(Arguments[1], Arguments[2], TASCharacter.Humanoid, true)
                    end
                    pcall(setAnimationSpeed, cache.animSpeed)
                end

                TASFunctions.SetCameraCFrame(cache.camCFrame)
                TASFunctions.SetZoom(cache.zoom)

                if cache.shiftLock ~= TASFunctions.GetShiftLockEnabled() then
                    TASFunctions.SetShiftLockEnabled(cache.shiftLock)
                end

                if TASConfig.PlaybackMouseLocation and not cache.shiftLock and cache.zoom > 0.52 then
                    mousemoveabs(cache.mouseLocation.X, cache.mouseLocation.Y)
                else
                    local CurrentResolution = workspace.CurrentCamera.ViewportSize
                    local CurrentGuiInset = TASServices.GuiService:GetGuiInset()
                    mousemoveabs(
                        (CurrentResolution.X / 2) - CurrentGuiInset.X,
                        (CurrentResolution.Y / 2) - CurrentGuiInset.Y
                    )
                end

            if TASConfig.PlaybackInputs then
                table.clear(playbackSignal)
                local Signal = playbackSignal
                for _, Input in pairs(cache.inputBegan) do
                    if not TASConfig.InputBlacklist[Input] then
                        local Code = InputCodes[Input]
                        if Code then
                            keypress(Code)
                            TASRuntime.PlaybackPressedKeys[Input] = Code
                        elseif Input == "b1" then
                            mouse1press()
                            TASRuntime.PlaybackPressedKeys["b1"] = "b1"
                        elseif Input == "b2" then
                            mouse2press()
                            TASRuntime.PlaybackPressedKeys["b2"] = "b2"
                        elseif Input == "u" or Input == "d" then
                            table.insert(Signal, Input)
                        end
                    end
                end
                for _, Input in pairs(cache.inputEnded) do
                    if not TASConfig.InputBlacklist[Input] then
                        local Code = InputCodes[Input]
                        if Code then
                            keyrelease(Code)
                            TASRuntime.PlaybackPressedKeys[Input] = nil
                        elseif Input == "b1" then
                            mouse1release()
                            TASRuntime.PlaybackPressedKeys["b1"] = nil
                        elseif Input == "b2" then
                            mouse2release()
                            TASRuntime.PlaybackPressedKeys["b2"] = nil
                        end
                    end
                end
                if #Signal > 0 then
                    SendSignal(table.concat(Signal, ","))
                end
            end
            end

            -- Exact recorded character state, no interpolation.
            HRP.CFrame = cache.hrpCFrame
            HRP.Velocity = cache.hrpVel
            HRP.RotVelocity = cache.hrpRotVel

            -- Client objects are interpolated between the current TAS sample
            -- and the next sample. This keeps spinners and other moving KOs
            -- visually smooth without changing the recorded TAS timeline.
            if TASConfig.AllowClientObjectManipulation then
                local coData = Frame[13] or {}
                local nextFrame = (TASRuntime.ReplayTableIndex < #TASRuntime.ReplayTable) and TASRuntime.ReplayTable[TASRuntime.ReplayTableIndex + 1] or nil
                local nextCO = type(nextFrame) == "table" and nextFrame[13] or nil
                local coAlpha = math.clamp(playbackAccumulator / playbackInterval, 0, 1)
                CO.ApplyInterpolatedFrame(coData, nextCO, coAlpha)
            end

            lastVelocity = currentVelocity

            if TASRuntime.ReplayTableIndex >= #TASRuntime.ReplayTable then
                -- We already reached the final frame above. Keep displaying it
                -- for one complete TAS interval, then finish automatically.
                if advanceFrame then
                    finalFrameHold = 0
                else
                    finalFrameHold = finalFrameHold + math.max(0, tonumber(deltaTime) or 0)
                end

                if finalFrameHold + 1e-9 >= playbackInterval then
                    finalFrameHold = 0
                    playbackAccumulator = 0
                    TASFunctions.StopReading(true)
                    continue
                end
            else
                finalFrameHold = 0
            end

            if TASRuntime.ReplayTableIndex > 100 then
                frameCache[TASRuntime.ReplayTableIndex - 100] = nil
            end
        else
            playbackAccumulator = 0
            if not AllowChangingPhysics then
                ApplyConfiguredPhysics(false)
            end
            pcall(function()
                if TASCharacter.Character and TASCharacter.Character:FindFirstChild("Humanoid") then
                    TASCharacter.Character.Humanoid.PlatformStand = false
                end
            end)
            frameCache = {}
            lastVelocity = Vector3.new()
            idleFrameCount = 0
            TASRuntime.PlaybackPressedKeys = {}
            CO.ResetTargets()
        end

    end
end)

-- Clear input queues
TASServices.RunService.Heartbeat:Connect(function()
	if not TASRuntime.Writing then
		TASRuntime.InputBeganQueue = {}
		TASRuntime.InputEndedQueue = {}
	end
end)

spawn(function() -- Check if connected
    while true do
        task.wait(2)
        if not TASRuntime.Reading then
			local Installed = IsInstalled()
			if Installed then
				ConnectedLabel.Text = "AHK folder found"
				ConnectedLabel.TextColor3 = Color3.new(0,0.8,0)
			else
				ConnectedLabel.Text = "AHK folder not found"
				ConnectedLabel.TextColor3 = Color3.new(0.8,0,0)
			end
		end
	end
end)

spawn(function() -- Writing
    local function buildRepeatFrame(source)
        if type(source) ~= "table" then return nil end
        local hasCO = source[13] ~= nil
        local repeatFrame = table.move(source, 1, hasCO and 13 or 12, 1, {})
        repeatFrame[2] = {}
        repeatFrame[12] = {{}, {}}
        if not hasCO then repeatFrame[13] = nil end
        return repeatFrame
    end

    local function captureFrame()
        if (not TASCharacter.Character or not TASCharacter.Character.Parent) or (not TASCharacter.Character:FindFirstChild("HumanoidRootPart")) then
            if type(TASRuntime.RecordingTable[#TASRuntime.RecordingTable]) == "table" then
                table.insert(TASRuntime.RecordingTable, 0)
            end
            return nil
        elseif not TASCharacter.Humanoid or TASCharacter.Humanoid.Health == 0 then
            if type(TASRuntime.RecordingTable[#TASRuntime.RecordingTable]) == "table" then
                table.insert(TASRuntime.RecordingTable, 1)
            end
            return nil
        end

        local HRP = TASCharacter.Character.HumanoidRootPart
        local Frame = table.create(13)
        Frame[1] = RoundTable(TASUtilityFunctions.CFrameToTable(HRP.CFrame), TASConfig.RoundDigits)

        local animationEvents = TASRuntime.AnimationQueue
        if TASRuntime.ForceAnimationSync then
            TASRuntime.ForceAnimationSync = false
            animationEvents = {}
            local currentAnimName = TASAnimation.currentAnimName
            if type(currentAnimName) == "string" and currentAnimName ~= "" then
                animationEvents[1] = {currentAnimName, 0}
            end
        end
        Frame[2] = animationEvents
        Frame[3] = TASUtilityFunctions.RoundNumber(TASAnimation.currentAnimSpeed, TASConfig.RoundDigits)
        Frame[4] = TASCharacter.Humanoid:GetState().Value
        Frame[5] = RoundTable(TASUtilityFunctions.Vector3ToTable(HRP.Velocity), TASConfig.RoundDigits)
        Frame[6] = RoundTable(TASUtilityFunctions.Vector3ToTable(HRP.RotVelocity), TASConfig.RoundDigits)
        Frame[7] = RoundTable(TASUtilityFunctions.CFrameToTable(workspace.CurrentCamera.CFrame), TASConfig.RoundDigits)
        Frame[8] = TASUtilityFunctions.RoundNumber(TASFunctions.GetZoom(), TASConfig.RoundDigits)
        Frame[9] = TASAnimation.pose
        Frame[10] = (TASFunctions.GetShiftLockEnabled() and 1) or 0
        Frame[11] = RoundTable(Vector2ToTable(TASServices.UserInputService:GetMouseLocation()), TASConfig.RoundDigits)
        Frame[12] = {TASRuntime.InputBeganQueue, TASRuntime.InputEndedQueue}
        if TASConfig.AllowClientObjectManipulation then
            Frame[13] = CO.RecordFrame()
        end
        return Frame
    end

    while true do
        local deltaTime = TASServices.RunService.RenderStepped:Wait()

        if TASRuntime.Writing then
            -- Cadence follows the TAS recording FPS, not the client FPS cap.
            -- If actual rendering drops below the cap, repeated state frames
            -- preserve the timeline without replaying inputs/animations.
            local sampleInterval = TASRuntime.RecordingInterval
            if sampleInterval <= 0 then
                sampleInterval = 1 / math.max(1, tonumber(TASRuntime.RecordingReplayFPS) or tonumber(TASConfig.TASRecordingFPS) or 1)
                TASRuntime.RecordingInterval = sampleInterval
            end
            TASRuntime.RecordingAccumulator = TASRuntime.RecordingAccumulator + math.max(0, tonumber(deltaTime) or 0)

            local sampleCount = math.floor((TASRuntime.RecordingAccumulator + 1e-9) / sampleInterval)
            if sampleCount > 0 then
                TASRuntime.RecordingAccumulator = TASRuntime.RecordingAccumulator - sampleCount * sampleInterval
                if TASRuntime.RecordingAccumulator < 0 then TASRuntime.RecordingAccumulator = 0 end

                local Frame = captureFrame()
                if Frame then
                    TASRuntime.RecordingTable[#TASRuntime.RecordingTable + 1] = Frame

                    if sampleCount > 1 then
                        local repeatFrame = buildRepeatFrame(Frame)
                        for _ = 2, sampleCount do
                            TASRuntime.RecordingTable[#TASRuntime.RecordingTable + 1] = repeatFrame
                        end
                    end

                    TASRuntime.InputBeganQueue = {}
                    TASRuntime.InputEndedQueue = {}
                    TASRuntime.AnimationQueue = {}
                end
            end
        else
            TASRuntime.RecordingAccumulator = 0
            if TASPause.PendingRecordingFlush then
                local finalFrame = captureFrame()
                if finalFrame then
                    TASRuntime.RecordingTable[#TASRuntime.RecordingTable + 1] = finalFrame
                end
                TASPause.PendingRecordingFlush = false
            end
            TASRuntime.InputBeganQueue = {}
            TASRuntime.InputEndedQueue = {}
            TASRuntime.AnimationQueue = {}
        end

        TASRuntime.RunSpeed = 0
        TASRuntime.ClimbSpeed = 0
        TASRuntime.HumanoidStateQueue = {}
    end
end)


spawn(function() -- Update cursor
	local maxWait = 0
	repeat
		task.wait(0.1)
		maxWait = maxWait + 0.1
		if maxWait > 5 then break end
	until CursorHolder and TASRuntime.Cursor and TASRuntime.CursorIcon

	TASFunctions.SetCursor("ArrowFarCursor")
	TASRuntime.Cursor.Image = TASRuntime.CursorIcon
	TASRuntime.Cursor.Size = TASRuntime.CursorSize
	TASRuntime.Cursor.Visible = true
	TASRuntime.Cursor.BackgroundTransparency = 1
	TASRuntime.Cursor.ZIndex = 10000

	local lastIcon, lastSize
	while task.wait() do
		pcall(function()
			-- Only update image/size when they actually change
			if TASRuntime.CursorIcon ~= lastIcon then
				TASRuntime.Cursor.Image = TASRuntime.CursorIcon
				lastIcon = TASRuntime.CursorIcon
			end
			if TASRuntime.CursorSize ~= lastSize then
				TASRuntime.Cursor.Size = TASRuntime.CursorSize
				lastSize = TASRuntime.CursorSize
			end

			local ViewportSize = workspace.CurrentCamera.ViewportSize
			local hw = TASRuntime.CursorSize.X.Offset * 0.5
			local hh = TASRuntime.CursorSize.Y.Offset * 0.5
			if TASServices.ShiftLockEnabled then
				TASRuntime.Cursor.Position = UDim2.fromOffset(ViewportSize.X * 0.5 - hw, ViewportSize.Y * 0.5 - hh)
			else
				local ml = TASServices.UserInputService:GetMouseLocation()
				TASRuntime.Cursor.Position = UDim2.fromOffset(ml.X - hw, ml.Y - hh)
			end
		end)
	end
end)

TASPause.PlaybackWarmCache.ProcessFreezeFrame = function(RoundedFreezeFrame)
    local Frame = TASRuntime.ReplayTable[RoundedFreezeFrame]
    if type(Frame) ~= "table" then return end

    local AnimatePose, Animation
    local PreviousFreezeFrame = TASPause.PlaybackWarmCache._FreezeLastProcessed
    local FrameChanged = PreviousFreezeFrame ~= nil and PreviousFreezeFrame ~= RoundedFreezeFrame

    -- Resolve the animation event that is active at this exact replay frame.
    -- Frame[2] is an event queue, not a persistent state field, so empty frames
    -- must inherit the last animation event from an earlier frame.
    for Index = RoundedFreezeFrame, 1, -1 do
        local F = TASRuntime.ReplayTable[Index]
        if type(F) == "table" then
            if AnimatePose == nil and F[9] ~= nil then
                AnimatePose = F[9]
            end
            local events = F[2]
            if type(events) == "table" and #events > 0 and not Animation then
                for eventIndex = #events, 1, -1 do
                    local ev = events[eventIndex]
                    if type(ev) == "table" and type(ev[1]) == "string" and ev[1] ~= "" then
                        Animation = ev
                        break
                    end
                end
            end
            if AnimatePose ~= nil and Animation then
                break
            end
        end
    end

    local CurrentPressedKeys = TASPause.PlaybackWarmCache._FreezePressedKeys or {}
    if PreviousFreezeFrame ~= RoundedFreezeFrame then
        CurrentPressedKeys = {}
        local backtrackStart = math.max(1, RoundedFreezeFrame - math.max(TASConfig.FrameBacktrackCount, 0))
        for Index = backtrackStart, RoundedFreezeFrame do
            local F = TASRuntime.ReplayTable[Index]
            if type(F) == "table" then
                local inputs = F[12] or {{}, {}}
                local BeganInputs = inputs[1] or {}
                local EndedInputs = inputs[2] or {}
                for _, Key in pairs(BeganInputs) do
                    if Key ~= "u" and Key ~= "d" then
                        CurrentPressedKeys[Key] = true
                    end
                end
                for _, Key in pairs(EndedInputs) do
                    CurrentPressedKeys[Key] = nil
                end
            end
        end
        TASPause.PlaybackWarmCache._FreezePressedKeys = CurrentPressedKeys
    end

    WritingPressedKeysLabel.Text = "Writing Pressed keys: |"
    for Input, _ in pairs(CurrentPressedKeys) do
        WritingPressedKeysLabel.Text = WritingPressedKeysLabel.Text .. Input .. "|"
    end

    -- Snapshot the exact replay state used by unfreeze and by the Player Viewer.
    -- On the first freeze, keep the live physics snapshot taken at the instant
    -- freeze was pressed. Once the user seeks to another frame, switch the resume
    -- state to that selected replay frame.
    local CurrentFrame = TASRuntime.ReplayTable[RoundedFreezeFrame]
    if type(CurrentFrame) == "table" then
        if FrameChanged then
            if CurrentFrame[1] then TASFreeze.ResumeCFrame = FastTableToCFrame(CurrentFrame[1]) end
            if CurrentFrame[5] then TASFreeze.ResumeVelocity = FastTableToVector3(CurrentFrame[5]) end
            if CurrentFrame[6] then TASFreeze.ResumeRotVelocity = FastTableToVector3(CurrentFrame[6]) end
            TASFreeze.ResumeHumanoidState = CurrentFrame[4]
        elseif TASFreeze.ResumeCFrame == nil then
            -- Defensive fallback for an empty/missing live snapshot.
            if CurrentFrame[1] then TASFreeze.ResumeCFrame = FastTableToCFrame(CurrentFrame[1]) end
            if CurrentFrame[5] then TASFreeze.ResumeVelocity = FastTableToVector3(CurrentFrame[5]) end
            if CurrentFrame[6] then TASFreeze.ResumeRotVelocity = FastTableToVector3(CurrentFrame[6]) end
            TASFreeze.ResumeHumanoidState = CurrentFrame[4]
        end
        TASFreeze.ResumeAnimPose = CurrentFrame[9] or AnimatePose
        TASFreeze.ResumeAnimSpeed = tonumber(CurrentFrame[3]) or 1
    end

    -- On the first freeze, the live TAS track is the most accurate source of
    -- animation name/asset/time because playback has already chosen the actual
    -- animation variant. Keep that exact track identity for subsequent seeks.
    if not FrameChanged then
        local liveTrack = TASAnimation.currentAnimTrack
        if liveTrack and liveTrack.Parent and liveTrack.Animation then
            TASPause.PlaybackWarmCache._FreezeAnimationName = TASAnimation.currentAnimName
            TASPause.PlaybackWarmCache._FreezeAnimationId = tostring(liveTrack.Animation.AnimationId or "")
            TASPause.PlaybackWarmCache._FreezeAnimationTime = tonumber(liveTrack.TimePosition) or 0
            TASPause.PlaybackWarmCache._FreezeAnimationSpeed = tonumber(TASFreeze.ResumeAnimSpeed or TASAnimation.currentAnimSpeed) or 1
        end
    end

    local DesiredAnimName = Animation and Animation[1] or nil
    local CachedAnimName = TASPause.PlaybackWarmCache._FreezeAnimationName
    local CachedAnimId = TASPause.PlaybackWarmCache._FreezeAnimationId
    local CachedAnimTime = tonumber(TASPause.PlaybackWarmCache._FreezeAnimationTime) or 0
    local CachedAnimSpeed = tonumber(TASPause.PlaybackWarmCache._FreezeAnimationSpeed) or tonumber(TASFreeze.ResumeAnimSpeed) or 1

    local HumanoidRootPartCFrame = FastTableToCFrame(Frame[1])
    local AnimationSpeed = tonumber(Frame[3]) or 1
    local HumanoidState = Frame[4]
    local HumanoidRootPartVelocity = FastTableToVector3(Frame[5])
    local HumanoidRootPartRotVelocity = FastTableToVector3(Frame[6])
    local FrameCameraCFrame = FastTableToCFrame(Frame[7])
    local Zoom = Frame[8] or 0

    if DesiredAnimName and DesiredAnimName ~= "" then
        local CurrentTrack = TASAnimation.currentAnimTrack
        local CurrentTrackId = CurrentTrack and CurrentTrack.Animation and tostring(CurrentTrack.Animation.AnimationId or "") or ""
        local SameAnimation = CachedAnimName == DesiredAnimName
            and (CachedAnimId == "" or CurrentTrackId == "" or CachedAnimId == CurrentTrackId)

        if not SameAnimation or not CurrentTrack or not CurrentTrack.Parent then
            -- Crossing into a different animation requires a real restart.
            -- Existing replay files do not store the chosen animation asset id,
            -- so playAnimation remains backwards-compatible and chooses from the
            -- same animation set used during normal playback.
            local animTransition = tonumber(Animation[2]) or 0
            playAnimation(DesiredAnimName, animTransition, TASCharacter.Humanoid, true, true)

            CurrentTrack = TASAnimation.currentAnimTrack
            if CurrentTrack and CurrentTrack.Animation then
                CachedAnimId = tostring(CurrentTrack.Animation.AnimationId or "")
            end
            CachedAnimName = DesiredAnimName

            -- We landed on an already-running animation in the middle of its
            -- recorded span. Start the newly-created track at the phase implied
            -- by the latest event for this animation, rather than at frame 0.
            local startFrame = RoundedFreezeFrame
            for scan = RoundedFreezeFrame, 1, -1 do
                local sf = TASRuntime.ReplayTable[scan]
                local events = type(sf) == "table" and sf[2] or nil
                local found = false
                if type(events) == "table" then
                    for evIndex = #events, 1, -1 do
                        local ev = events[evIndex]
                        if type(ev) == "table" and ev[1] == DesiredAnimName then
                            found = true
                            break
                        end
                    end
                end
                if found then
                    startFrame = scan
                    break
                end
            end
            local replayFPS = math.max(1, tonumber(TASRuntime.ReplaySourceFPS or TASConfig.TASRecordingFPS) or 1)
            local elapsed = math.max(0, (RoundedFreezeFrame - startFrame) / replayFPS)
            CachedAnimSpeed = AnimationSpeed
            CachedAnimTime = elapsed * CachedAnimSpeed
        elseif FrameChanged then
            -- Keep the exact animation variant and move its phase by the number
            -- of TAS frames crossed. Using the mean of the previous and target
            -- speeds avoids visible phase jumps when animation speed changes.
            local replayFPS = math.max(1, tonumber(TASRuntime.ReplaySourceFPS or TASConfig.TASRecordingFPS) or 1)
            local frameDelta = RoundedFreezeFrame - (PreviousFreezeFrame or RoundedFreezeFrame)
            local previousSpeed = CachedAnimSpeed
            local targetSpeed = AnimationSpeed
            local effectiveSpeed = (previousSpeed + targetSpeed) * 0.5
            CachedAnimTime = CachedAnimTime + (frameDelta / replayFPS) * effectiveSpeed
            CachedAnimSpeed = targetSpeed
        end

        if CurrentTrack and CurrentTrack.Parent then
            pcall(function()
                local length = tonumber(CurrentTrack.Length) or 0
                if length > 0 then
                    local target = CachedAnimTime
                    if CurrentTrack.Looped then
                        target = target % length
                    else
                        target = math.clamp(target, 0, math.max(0, length - 0.001))
                    end
                    CurrentTrack.TimePosition = target
                else
                    CurrentTrack.TimePosition = math.max(0, CachedAnimTime)
                end
                CurrentTrack:AdjustSpeed(0)
            end)
            TASAnimation.currentAnimTrack = CurrentTrack
            TASAnimation.currentAnimName = DesiredAnimName
            TASPause.PlaybackWarmCache._FreezeAnimationName = DesiredAnimName
            TASPause.PlaybackWarmCache._FreezeAnimationId = CachedAnimId
            TASPause.PlaybackWarmCache._FreezeAnimationTime = CachedAnimTime
            TASPause.PlaybackWarmCache._FreezeAnimationSpeed = CachedAnimSpeed
        end
    elseif TASAnimation.currentAnimTrack and TASAnimation.currentAnimTrack.Parent then
        -- There is no event on this frame. Keep the live track, but preserve its
        -- exact name/asset/time instead of blanking the animation state.
        pcall(function() TASAnimation.currentAnimTrack:AdjustSpeed(0) end)
        TASPause.PlaybackWarmCache._FreezeAnimationName = TASAnimation.currentAnimName
        TASPause.PlaybackWarmCache._FreezeAnimationId = TASAnimation.currentAnimTrack.Animation and tostring(TASAnimation.currentAnimTrack.Animation.AnimationId or "") or CachedAnimId
        TASPause.PlaybackWarmCache._FreezeAnimationTime = tonumber(TASAnimation.currentAnimTrack.TimePosition) or CachedAnimTime
        TASPause.PlaybackWarmCache._FreezeAnimationSpeed = CachedAnimSpeed
    end

    if TASFreeze.ResumeAnimPose then TASAnimation.pose = TASFreeze.ResumeAnimPose end
    if AnimatePose ~= nil then
        TASAnimation.pose = AnimatePose
    end
    if (not TASAnimation.currentAnimName or TASAnimation.currentAnimName == "") and CachedAnimName then
        TASAnimation.currentAnimName = CachedAnimName
    end

    -- A frozen frame must freeze the animation track too.
    pcall(function()
        if TASAnimation.currentAnimTrack and TASAnimation.currentAnimTrack.Parent then
            TASAnimation.currentAnimTrack:AdjustSpeed(0)
        end
    end)

    -- Do not touch live character physics during a plain freeze. This matches the
    -- old implementation: freezing the TAS timeline must not cancel an in-progress
    -- jump. Physical replay-frame seeking is enabled only after the user actually
    -- moves to another frozen frame.
    if TASFreeze.PhysicsOverrideActive then
        TASCharacter.Humanoid:ChangeState(HumanoidState)
        TASCharacter.Character.HumanoidRootPart.CFrame = HumanoidRootPartCFrame
        TASCharacter.Character.HumanoidRootPart.AssemblyAngularVelocity = HumanoidRootPartRotVelocity
        TASCharacter.Character.HumanoidRootPart.RotVelocity = HumanoidRootPartRotVelocity
        TASCharacter.Character.HumanoidRootPart.AssemblyLinearVelocity = HumanoidRootPartVelocity
        TASCharacter.Character.HumanoidRootPart.Velocity = HumanoidRootPartVelocity
    end

    if not (movecameraonfroze and movecameraonfroze.Value) then
        TASFreeze.FrozenCameraCFrame = FrameCameraCFrame
        local cam = workspace.CurrentCamera
        if cam then
            cam.CameraType = Enum.CameraType.Scriptable
            cam.CFrame = TASFreeze.FrozenCameraCFrame
        end
        pcall(function()
            TASServices.UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
        end)
        TASFunctions.SetZoom(Zoom)
        -- Do not feed mouse/shift-lock input while frozen. The recorded camera
        -- CFrame is authoritative here.
    end

    if TASConfig.AllowClientObjectManipulation and CO then
        if #TASRuntime.ReplayTable > 0 and CO.GetFullStateAtFrame and CO.ApplyFullState then
            local coState = CO.GetFullStateAtFrame(RoundedFreezeFrame, TASRuntime.ReplayTable)
            CO.ApplyFullState(coState)
        end
        if CO.AnchorAll then CO.AnchorAll() end
    end

    -- Mark the frame only after every part of the frame has been applied.
    -- The old code marked it before animation reconstruction, so the first seek
    -- was treated as an unchanged frame and never force-resynced the track.
    TASPause.PlaybackWarmCache._FreezeLastProcessed = RoundedFreezeFrame
end

spawn(function() -- Handling freezing
    while true do
        if TASFreeze.Frozen then
            local character = TASCharacter.Character
            local hrp = character and character:FindFirstChild("HumanoidRootPart")

            -- Normal freeze: physically freeze the player in place, but do NOT
            -- rebuild the character from the replay frame. The live velocity/state
            -- captured in Freeze() is the authoritative resume state.
            if hrp then
                hrp.Anchored = true
            end
            -- Anchoring the root is enough to hold the recorded character still.
            -- Do NOT force PlatformStand here: the custom Animate loop treats the
            -- resulting PlatformStanding pose as a reason to stop/destroy the
            -- current animation track. The live animation is intentionally held
            -- separately above.

            if TASFreeze.FreezeFrame > 0 and TASFreeze.FreezeFrame <= #TASRuntime.ReplayTable then
                local RoundedFreezeFrame = TASUtilityFunctions.RoundNumber(TASFreeze.FreezeFrame, 0)
                local previousProcessed = TASPause.PlaybackWarmCache._FreezeLastProcessed

                if previousProcessed == nil then
                    -- Initial freeze: keep the live character exactly where it was.
                    TASPause.PlaybackWarmCache._FreezeLastProcessed = RoundedFreezeFrame
                    TASPause.PlaybackWarmCache._FreezeInitial = false
                elseif previousProcessed ~= RoundedFreezeFrame then
                    -- Actual frame seek: now it is intentional to reconstruct the
                    -- character from the selected replay frame.
                    TASFreeze.PhysicsOverrideActive = true
                    TASPause.PlaybackWarmCache.ProcessFreezeFrame(RoundedFreezeFrame)
                end

                CO.AnchorAll()

                if not (movecameraonfroze and movecameraonfroze.Value) and TASFreeze.FrozenCameraCFrame and workspace.CurrentCamera then
                    workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
                    workspace.CurrentCamera.CFrame = TASFreeze.FrozenCameraCFrame
                end
            end
        else
            TASFreeze.PhysicsOverrideActive = false
            TASPause.PlaybackWarmCache._FreezeLastProcessed = nil
            TASPause.PlaybackWarmCache._FreezePressedKeys = {}
            TASPause.PlaybackWarmCache._FreezeInitial = nil
        end
        TASServices.RunService.RenderStepped:Wait()
    end
end)

TASPause.PlaybackWarmCache.InitializeInitialReplay = function()
    TASCharacter.ConsoleMessage("Loading from file...")
    local fileContent = GetReplayFile()
    if not fileContent then
        TASRuntime.ReplayTable = {}
        TASRuntime.ReplaySourceFPS = math.max(1, tonumber(TASConfig.TASRecordingFPS) or 1)
        TASRuntime.ActiveReplayFPS = TASRuntime.ReplaySourceFPS
        TASRuntime.ReplaySaveState.Encoded = nil
        TASRuntime.ReplaySaveState.EncodedVersion = -1
        TASCharacter.ConsoleMessage("No replay file selected; starting with empty replay cache")
        return
    end

    local decodedReplay, decodedFPS = ReplayDecode(fileContent)
    TASRuntime.ReplayTable = decodedReplay or {}
    TASRuntime.ReplaySaveState.Version = TASRuntime.ReplaySaveState.Version + 1
    TASRuntime.ReplaySaveState.Encoded = fileContent ~= "" and fileContent or nil
    TASRuntime.ReplaySaveState.EncodedVersion = TASRuntime.ReplaySaveState.Encoded and TASRuntime.ReplaySaveState.Version or -1
    TASRuntime.ReplaySourceFPS = math.max(1, tonumber(decodedFPS or TASConfig.TASRecordingFPS) or 1)
    TASRuntime.ActiveReplayFPS = math.max(1, tonumber(TASRuntime.ReplaySourceFPS or TASConfig.TASRecordingFPS) or 1)

    if not decodedReplay then
        TASCharacter.ConsoleMessage("Failed to load replay file")
    else
        TASPaths.ReplayNeedsReload = false
        TASPaths.LastLoadedPath = TASPaths.ReplayPath
        TASCharacter.ConsoleMessage("Initial replay loaded and cached")
    end
end

TASPause.PlaybackWarmCache.InitializeInitialReplay()

TASCharacter.ConsoleMessage("Tasability",TASConfig.Version,"loaded in",TASUtilityFunctions.RoundNumber(tick()-TASPaths.ExecutionTick,2),"seconds")
TASCharacter.ConsoleMessage("Type help to see all commands")
