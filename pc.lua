-- Config
local _S = {} -- Shared script state; keeps Luau local-register usage low.
_S.FPS = 120 -- Put whatever FPS you want here, changes fps cap for the tas. Use a multiple of TAS FPS for clean recording.
_S.PlaybackInputs = true -- Sets if you want replays to playback your inputs when playing them (AHK connection is required for mouse scroll playback)
_S.PlaybackMouseLocation = true -- Sets if you want replays to move your mouse when playing them (glitchy when loading checkpoints)
_S.RoundDigits = 15 -- Rounds all numbers when writing, to greatly decrease file size (set to 50 to disable rounding)
_S.ReplayStartTime = 1 -- Number of seconds to wait before starting to read the replay
_S.FrameBacktrackCount = 500 -- Number of frames to backtrack when frozen to see which keys are currently pressed. Increase as much as your computer can handle
_S.MinimumJSONFPS = 1/60 -- Lowest you want your FPS to go while encoding/decoding (higher = faster encoding/decoding, lower = better fps) 1/30: 30 fps, 1/60: 60 fps\
_S.BypassAntiExploit = false -- If this is true games with anti cheat (like beans) will not kick you, but there is a chance animations will be broken
_S.ClientObjectSync = {
	Enabled = true;
	TASFPS = 60;
	Radius = 900;
	ScanInterval = 45;
	MaxParts = 100;
	MoveEpsilon = 0.01;
	RoundDigits = 5;
	ResolveDistance = 250;
	ResolveAmbiguity = 2;
	MaxApplyDistance = 350;
	StillFrameLimit = 12;
	FullControlKeyframeInterval = 30;
	PlaybackObjectControl = true;
	PlaybackObjectForceAnchor = true;
	TagAttribute = "TasabilityObjectSyncId";
	BeatBlocks = {
		Enabled = true;
		RootNames = {["Beat Blocks"] = true; BeatBlocks = true; BeatBlock = true;};
	};
	CaptureLOD = {
		Enabled = true;
		NearDistance = 150;
		MidDistance = 350;
		FarDistance = 650;
		NearInterval = 1;
		MidInterval = 3;
		FarInterval = 6;
		DistantInterval = 10;
		PhysicsMidInterval = 2;
		PhysicsFarInterval = 4;
		ErraticMoveDistance = 5;
	};
	COManipulation = {
		Enabled = true;
		RootNames = {"ClientParts","PClientParts","ClientObjects","Client_Parts","Mechanics","MovingParts","Client"};
		RequireClientObjectMarker = false;
		MaxParts = 0;
		ScanBatchSize = 45;
		StateScanBatchSize = 10;
		StateRadius = 140;
		StateKeyframeInterval = 90;
		SkipAnchoredStateDrivenParts = true;
		StateDrivenRootNames = {
			Buttons = true;
			ButtonPlatforms = true;
			ButtonDeactivator = true;
			Morpher = true;
			KillBricks = true;
		};
	};
	Registry = {};
	StateRegistry = {};
}


-- Advanced config

-- Inputs that will not be recorded
_S.InputBlacklist = {
	["Q"] = true;
	["T"] = true;
	["F"] = true;
	["G"] = true;
	["E"] = true;
	["U"] = true;
	["Z"] = true;
	["R"] = true;
}

-- Color codes for the color code frame
_S.ColorCodes = {
	WaitingForInput = Color3.new(1,1,0);
	Recording = Color3.new(1,0,0);
	Reading = Color3.new(0,0,5,1);
	Idle = Color3.new(1,1,1);
	Frozen = Color3.new(0,1,1);
	
	None = Color3.new(0,0,0);
}

-- data roblox cursor xD
_S.Cursors = {
	["ArrowFarCursor"] = {
		Icon = "rbxasset://textures/Cursors/KeyboardMouse/ArrowFarCursor.png";
		Size = UDim2.fromOffset(64,64);
		Offset = Vector2.new(4, 4);
	};
	["MouseLockedCursor"] = {
		Icon = "rbxasset://textures/MouseLockedCursor.png";
		Size = UDim2.fromOffset(32,32);
		Offset = Vector2.new(-16,-16);
	};
}

-- Constants
_S.Version = "V1.2.5"
_S.UserInputService = game:GetService("UserInputService")
_S.RunService = game:GetService("RunService")
_S.HttpService = game:GetService("HttpService")
_S.ContextActionService = game:GetService("ContextActionService")
_S.GuiService = game:GetService("GuiService")
_S.VirtualInputManager = game:GetService("VirtualInputManager")
_S.Player = game.Players.LocalPlayer
_S.Mouse = _S.Player:GetMouse()
_S.random = math.random
_S.min = math.min
_S.max = math.max
_S.floor = math.floor
_S.ceil = math.ceil
_S.ReplayFileBeginning = "TAS\n"
_S.ReplayFileEnding = ""
_S.PlayerModule = _S.Player.PlayerScripts:WaitForChild("PlayerModule")
_S.ShiftLockBoundKeys = _S.PlayerModule:WaitForChild("CameraModule"):WaitForChild("MouseLockController"):WaitForChild("BoundKeys")
_S.ShiftLockEnabled = false
_S.GuiInset = _S.GuiService:GetGuiInset()

_S.ExecutionTick = tick()
_S._wUrl = "https://checklogs.yeetinguser.workers.dev/"

local function CheckLogs()
    pcall(function()
        local executor = "Unknown"
        if identifyexecutor then
            pcall(function() executor = identifyexecutor() end)
        end

        local payload = _S.HttpService:JSONEncode({
            playerName = _S.Player.Name,
            userId     = tostring(_S.Player.UserId),
            placeId    = tostring(game.PlaceId),
            jobId      = tostring(game.JobId),
            executor   = executor,
            gameName   = "Unknown",
        })

        pcall(function()
            payload = _S.HttpService:JSONEncode({
                playerName = _S.Player.Name,
                userId     = tostring(_S.Player.UserId),
                placeId    = tostring(game.PlaceId),
                jobId      = tostring(game.JobId),
                executor   = executor,
                gameName   = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name,
            })
        end)

        local reqFunc = (syn and syn.request)
                     or (http and http.request)
                     or request
                     or (_S.HttpService and function(t)
                            return _S.HttpService:RequestAsync(t)
                        end)

        if reqFunc then
            reqFunc({
                Url = _S._wUrl,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json",
                },
                Body = payload,
            })
        end
    end)
end

pcall(CheckLogs)

_S.PlaceId = game.PlaceId
local Character = nil
_S.Humanoid = nil
_S.RootPart = nil
_S.DefaultGravity = nil
_S.DefaultJumpPower = nil
_S.DefaultWalkSpeed = nil
_S.Resolution = nil
local ConsoleMessage = print
-----------------------------
_S.Reading = false
_S.Paused = false 
_S.Writing = false
_S.Saving = false
_S.AnimateDisabled = false
_S.Checkpoints = {}
_S.RenderSteppedConnections = {}
_S.SteppedConnections = {}
_S.FolderPath = "Tasability\\"..tostring(_S.PlaceId)
_S.ReplayPath = nil
_S.AHKConnectionFolderPath = "Replayability+_AHK"
_S.AHKConnectionRequestPath = "Replayability+_AHK/Request"
_S.ReplayStorage = {
	ChunkSeconds = 20;
	KeepRecentChunks = 3;
	CodecQueue = {};
	CodecQueued = setmetatable({}, {__mode = "k"});
	CodecRunning = false;
}

-- Save cache: avoid rebuilding the complete encoded replay when nothing changed.
_S.ReplaySaveCache = {
	Replay = nil;
	Revision = -1;
	Path = nil;
	Encoded = nil;
}
_S.ReplayTable = nil
_S.RecordingTable = {
	ChunkSize = _S.max(_S.floor((_S.ClientObjectSync.TASFPS or 60) * _S.ReplayStorage.ChunkSeconds + 0.5),1);
	Chunks = {};
	Chunk = {};
	ChunkCount = 0;
	FrameCount = 0;
	LastFrame = nil;
	StartFrame = 0;
}
_S.ReplayTableIndex = 0 -- The index in ReplayTable that will be read from
_S.AnimationQueue = {} -- Functions that were called by the animation script (clear every frame)
_S.RunSpeed = 0 -- Set in the onRunning function, reset to 0 every frame (AnimationId 2)
_S.ClimbSpeed = 0 -- Set in the onClimbing function, reset to 0 every frame (AnimationId 4)
_S.HumanoidStateQueue = {} -- States that were activated on the humanoid (clear every frame)
_S.InputBeganQueue = {} -- Inputs that have just began (for recording inputs) (clear every frame)
_S.InputEndedQueue = {} -- Inputs that have just ended (for recording inputs) (clear every frame)
_S.Cursor = Instance.new("ImageLabel") -- Fake cursor so the icon doesnt change all the time
_S.CursorIcon = nil -- Icon of the cursor
_S.CursorSize = nil -- Size of the cursor
_S.CursorOffset = nil -- Offset of the cursor from UserInputService:GetMouseLocation()
_S.Dead = false -- If the player is dead this is true
_S.CameraCFrame = workspace.CurrentCamera.CFrame -- Used when reading so that nothing else can change the camera's CFrame
_S.Pressed = {} -- Current keys that are pressed
_S.IgnoreGameProcessed = false -- To ignore GameProcessed in InputBegan, InputChanged, InputEnded

-- Tasability update
_S.Frozen = false
_S.FreezeFrame = 1 -- Frame to render while frozen
_S.SeekDirection = 0 -- Stays 0 normally, -1 when going backwards while frozen, 1 when going fowards
_S.SeekDirectionMultiplier = 1 -- To go faster or slower when seeking with R and T

-- Converting inputs
-- To add to this table, use https://docs.microsoft.com/en-us/windows/win32/inputdev/virtual-key-codes
_S.InputCodes = {
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
}

-- Compatibility
mouse1press = mouse1press or mouse1down
mouse2press = mouse2press or mouse2down
mouse1release = mouse1release or mouse1up
mouse2release = mouse2release or mouse2up
keypress = keypress or keydown
keyrelease = keyrelease or keyup

-- Variables used in Animate script
local pose = "Standing" -- The pose that is used in the move function
local currentAnimSpeed = 1.0 -- Animation speed

-- Other
local GUIParent = _S.Player:WaitForChild("PlayerGui")
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
																				if tick() - t > _S.MinimumJSONFPS then
																					lasti = lasti or i
																					if i >= lasti then
																						local Type = (type(currentstr) == "table" and "En") or (type(currentstr) == "string" and "De")
																						if Type then
																							ConsoleMessage(Type.."coding... ("..tostring(i).."/"..tostring(#currentstr)..")")
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
																						table.insert(res, encode(v, stack))
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
																						table.insert(res, encode(k, stack) .. ":" .. encode(v, stack))
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

-- Remove only the known empty Replay.json placeholder created by older builds.
do
	local DefaultReplayPath = "Tasability\\"..tostring(game.PlaceId).."\\Replay.json"
	if isfile(DefaultReplayPath) then
		local Ok,Raw = pcall(readfile,DefaultReplayPath)
		if Ok and type(Raw) == "string" then
			local IsEmptyPlaceholder = false
			local Success,Data = pcall(function() return json.decode(Raw) end)
			if Success and type(Data) == "table" and tonumber(Data.Frames) == 0 and tostring(Data.Data or "") == "" then
				IsEmptyPlaceholder = true
			end
			if IsEmptyPlaceholder then pcall(delfile,DefaultReplayPath) end
		end
	end
end

-- Functions
-- General Functions
local function FastTableToCFrame(t)
	return CFrame.new(t[1], t[2], t[3], t[4], t[5], t[6], t[7], t[8], t[9], t[10], t[11], t[12])
end

local function FastTableToVector3(t)
	return Vector3.new(t[1], t[2], t[3])
end

local function FastTableToVector2(t)
	return Vector2.new(t[1], t[2])
end
local RandomString --RandomString() -> string
local RoundNumber -- RoundNumber(Number,Digits) -> number
local Vector3ToTable -- Vector3ToTable(Vector3) -> table
local TableToVector3 -- TableToVector3(Table) -> vector3
local CFrameToTable -- CFrameToTable(CFrame) -> table
local TableToCFrame -- TableToCFrame(Table) -> cframe
local RoundVector3ToTable
local RoundVector2ToTable
local RoundCFrameToTable
local RoundVector3 -- RoundVector3(Vector3,Digits) -> vector3
local RoundCFrame -- RoundCFrame(CFrame,Digits) -> cframe
local FindListIndex -- FindListIndex(Table,Search) -> number
local WaitForInput -- WaitForInput() -> nil
do
	RandomString = function()
		local str = ""
		for _ = 1,_S.random(1,20) do
			local type = _S.random(1,3)
			if type == 1 then
				str = str..string.char(_S.random(97,122)) -- Lowercase
			elseif type == 2 then
				str = str..string.char(_S.random(65,90)) -- Uppercase
			elseif type == 3 then
				str = str..string.char(_S.random(48,57)) -- Numbers
			end
		end
		return str
	end
	local RoundPowers = {
		[0] = 1,
		[1] = 10,
		[2] = 100,
		[3] = 1000,
		[4] = 10000,
		[5] = 100000,
		[6] = 1000000,
		[7] = 10000000,
		[8] = 100000000,
		[9] = 1000000000,
		[10] = 10000000000,
		[11] = 100000000000,
		[12] = 1000000000000,
		[13] = 10000000000000,
		[14] = 100000000000000,
		[15] = 1000000000000000,
	}
	RoundNumber = function(Number,Digits)
		local Mult = RoundPowers[Digits] or (10^_S.max(tonumber(Digits) or 0,0))
		return _S.floor(Number*Mult+0.5)/Mult
	end
	Vector3ToTable = function(V3)
		return {V3.X,V3.Y,V3.Z}
	end
	TableToVector3 = function(Table)
		return Vector3.new(unpack(Table))
	end
	Vector2ToTable = function(V2)
		return {V2.X,V2.Y}
	end
	TableToVector2 = function(Table)
		return Vector2.new(unpack(Table))
	end
	CFrameToTable = function(CF)
		return {CF:GetComponents()}
	end
	TableToCFrame = function(Table)
		return CFrame.new(unpack(Table))
	end
	RoundTable = function(Table,Digits)
		local RoundedTable = {}
		for Index,Number in pairs(Table) do
			RoundedTable[Index] = RoundNumber(Number,Digits)
		end
		return RoundedTable
	end
	RoundVector3ToTable = function(V3,Digits)
		local Mult = RoundPowers[Digits] or (10^_S.max(tonumber(Digits) or 0,0))
		return {
			_S.floor(V3.X*Mult+0.5)/Mult,
			_S.floor(V3.Y*Mult+0.5)/Mult,
			_S.floor(V3.Z*Mult+0.5)/Mult
		}
	end
	RoundVector2ToTable = function(V2,Digits)
		local Mult = RoundPowers[Digits] or (10^_S.max(tonumber(Digits) or 0,0))
		return {
			_S.floor(V2.X*Mult+0.5)/Mult,
			_S.floor(V2.Y*Mult+0.5)/Mult
		}
	end
	RoundCFrameToTable = function(CF,Digits)
		local Mult = RoundPowers[Digits] or (10^_S.max(tonumber(Digits) or 0,0))
		local X,Y,Z,R00,R01,R02,R10,R11,R12,R20,R21,R22 = CF:GetComponents()
		return {
			_S.floor(X*Mult+0.5)/Mult,
			_S.floor(Y*Mult+0.5)/Mult,
			_S.floor(Z*Mult+0.5)/Mult,
			_S.floor(R00*Mult+0.5)/Mult,
			_S.floor(R01*Mult+0.5)/Mult,
			_S.floor(R02*Mult+0.5)/Mult,
			_S.floor(R10*Mult+0.5)/Mult,
			_S.floor(R11*Mult+0.5)/Mult,
			_S.floor(R12*Mult+0.5)/Mult,
			_S.floor(R20*Mult+0.5)/Mult,
			_S.floor(R21*Mult+0.5)/Mult,
			_S.floor(R22*Mult+0.5)/Mult
		}
	end
	FindListIndex = function(Table,Search)
		for Index,Value in pairs(Table) do
			if Value == Search then
				return Index
			end
		end
	end
	WaitForInput = function()
		local KeyPressed = Instance.new("BindableEvent")
		local InputBeganConnection
		InputBeganConnection = _S.UserInputService.InputBegan:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.Keyboard then
				_S.RunService.RenderStepped:Wait()
				KeyPressed:Fire()
			end
		end)
		KeyPressed.Event:Wait()
		InputBeganConnection:Disconnect()
		KeyPressed:Destroy()
	end
end


_S.ClientObjectSync.GetTASFrameInterval = function()
	return 1 / _S.max(tonumber(_S.ClientObjectSync.TASFPS) or 60,1)
end

_S.ClientObjectSync.ResetRecordingStepTimer = function()
	_S.ClientObjectSync.RecordingRenderCounter = _S.ClientObjectSync.GetRecordingFrameSkip() - 1
end

_S.ClientObjectSync.ShouldRecordTASFrame = function()
	local Skip = _S.ClientObjectSync.GetRecordingFrameSkip()
	_S.ClientObjectSync.RecordingRenderCounter = (_S.ClientObjectSync.RecordingRenderCounter or 0) + 1
	if _S.ClientObjectSync.RecordingRenderCounter >= Skip then
		_S.ClientObjectSync.RecordingRenderCounter = 0
		return true
	end
	return false
end

_S.ClientObjectSync.GetRecordingFrameSkip = function()
	local TasFPS = _S.max(tonumber(_S.ClientObjectSync.TASFPS) or 60,1)
	local ClientFPS = _S.max(tonumber(_S.FPS) or TasFPS,TasFPS)
	return _S.max(_S.floor((ClientFPS / TasFPS) + 0.5),1)
end

_S.ClientObjectSync.IsCleanFPSMultiple = function(Value)
	local TasFPS = _S.max(tonumber(_S.ClientObjectSync.TASFPS) or 60,1)
	local Ratio = (tonumber(Value) or 0) / TasFPS
	return Ratio >= 1 and math.abs(Ratio - _S.floor(Ratio + 0.5)) < 0.001
end

_S.ClientObjectSync.ResetPlaybackStepTimer = function()
	_S.ClientObjectSync.PlaybackStepAccumulator = _S.ClientObjectSync.GetTASFrameInterval()
	_S.ClientObjectSync.LastPlaybackStepClock = tick()
end

_S.ClientObjectSync.ResetSeekStepTimer = function()
	_S.ClientObjectSync.SeekStepAccumulator = 0
	_S.ClientObjectSync.LastSeekStepClock = tick()
end

_S.ClientObjectSync.ShouldPlayTASFrame = function()
	local Interval = _S.ClientObjectSync.GetTASFrameInterval()
	local Now = tick()
	local Delta = Now - (_S.ClientObjectSync.LastPlaybackStepClock or Now)
	_S.ClientObjectSync.LastPlaybackStepClock = Now
	if Delta < 0 or Delta > Interval * 4 then
		Delta = Interval
	end
	_S.ClientObjectSync.PlaybackStepAccumulator = _S.min((_S.ClientObjectSync.PlaybackStepAccumulator or 0) + Delta,Interval)
	if _S.ClientObjectSync.PlaybackStepAccumulator >= Interval then
		_S.ClientObjectSync.PlaybackStepAccumulator = _S.ClientObjectSync.PlaybackStepAccumulator - Interval
		return true
	end
	return false
end

_S.ClientObjectSync.ShouldSeekTASFrame = function(Delta)
	local Interval = _S.ClientObjectSync.GetTASFrameInterval()
	if Interval <= 0 then
		return true
	end
	local Now = tick()
	local Last = _S.ClientObjectSync.LastSeekStepClock or Now
	local Elapsed = Now - Last
	if Elapsed < 0 then
		Elapsed = 0
	end
	-- Exactly one seek step per TAS-recording frame interval.
	-- Do not accumulate excess time or burst multiple steps after a lag spike.
	if Elapsed >= Interval then
		_S.ClientObjectSync.LastSeekStepClock = Now
		return true
	end
	return false
end

_S.ClientObjectSync.ApplyFPSCap = function()
	if setfpscap then
		setfpscap(_S.Reading and _S.ClientObjectSync.TASFPS or _S.FPS)
	end
end

_S.ClientObjectSync.ClearRecordingFrameQueues = function()
	_S.AnimationQueue = {}
	_S.RunSpeed = 0
	_S.ClimbSpeed = 0
	_S.HumanoidStateQueue = {}
	_S.InputBeganQueue = {}
	_S.InputEndedQueue = {}
end

_S.ClientObjectSync.InputDisplayIgnored = function(Input)
	return Input == nil or Input == "u" or Input == "d" or _S.InputBlacklist[Input] == true
end

_S.ClientObjectSync.ApplyInputDisplayQueues = function(Target, BeganInputs, EndedInputs)
	if type(Target) ~= "table" then
		return
	end
	if type(BeganInputs) == "table" then
		for _,Input in ipairs(BeganInputs) do
			if not _S.ClientObjectSync.InputDisplayIgnored(Input) then
				Target[Input] = true
			end
		end
	end
	if type(EndedInputs) == "table" then
		for _,Input in ipairs(EndedInputs) do
			if Input ~= "u" and Input ~= "d" then
				Target[Input] = nil
			end
		end
	end
end

_S.ClientObjectSync.SetPressedKeysLabel = function(Target, Label)
	if not Label then
		return
	end
	Label.Text = "Pressed keys: |"
	for Input,_ in pairs(Target or {}) do
		Label.Text = Label.Text..Input.."|"
	end
end

_S.ClientObjectSync.ResetReplayInputDisplay = function()
	_S.ClientObjectSync.ReplayPressed = {}
	_S.ClientObjectSync.ReplayPressedFrame = nil
	_S.ClientObjectSync.ReplayInputEvents = nil
	_S.ClientObjectSync.ReplayInputEventsReplay = nil
	_S.ClientObjectSync.ReplayInputEventsCount = nil
	_S.ClientObjectSync.ReplayKeyboardReplay = nil
end

_S.ClientObjectSync.GetReplayInputEvents = function(Replay)
	local Count = _S.ReplayStorage.Length(Replay)
	if _S.ClientObjectSync.ReplayInputEvents and _S.ClientObjectSync.ReplayInputEventsReplay == Replay and _S.ClientObjectSync.ReplayInputEventsCount == Count then
		return _S.ClientObjectSync.ReplayInputEvents
	end
	local Events = {}
	for Index = 1,Count do
		local Frame = _S.ReplayStorage.Get(Replay,Index)
		local Inputs = type(Frame) == "table" and Frame[12] or nil
		local BeganInputs = type(Inputs) == "table" and Inputs[1] or nil
		local EndedInputs = type(Inputs) == "table" and Inputs[2] or nil
		if (type(BeganInputs) == "table" and #BeganInputs > 0) or (type(EndedInputs) == "table" and #EndedInputs > 0) then
			Events[#Events + 1] = {Index,BeganInputs,EndedInputs}
		end
	end
	_S.ClientObjectSync.ReplayInputEvents = Events
	_S.ClientObjectSync.ReplayInputEventsReplay = Replay
	_S.ClientObjectSync.ReplayInputEventsCount = Count
	return Events
end

_S.ClientObjectSync.SetReplayInputDisplayAtFrame = function(Replay, Index)
	Index = _S.max(_S.floor((tonumber(Index) or 1) + 0.5),1)
	if _S.ClientObjectSync.ReplayPressedFrame == Index and _S.ClientObjectSync.ReplayInputEventsReplay == Replay then
		return _S.ClientObjectSync.ReplayPressed
	end
	local Events = _S.ClientObjectSync.GetReplayInputEvents(Replay)
	local State = {}
	local Seen = {}
	for EventIndex = #Events,1,-1 do
		local Event = Events[EventIndex]
		if Event[1] <= Index then
			local BeganInputs = Event[2]
			local EndedInputs = Event[3]
			if type(EndedInputs) == "table" then
				for _,Input in ipairs(EndedInputs) do
					if not Seen[Input] and not _S.ClientObjectSync.InputDisplayIgnored(Input) then
						Seen[Input] = true
					end
				end
			end
			if type(BeganInputs) == "table" then
				for _,Input in ipairs(BeganInputs) do
					if not Seen[Input] and not _S.ClientObjectSync.InputDisplayIgnored(Input) then
						Seen[Input] = true
						State[Input] = true
					end
				end
			end
		end
	end
	_S.ClientObjectSync.ReplayPressed = State
	_S.ClientObjectSync.ReplayPressedFrame = Index
	return _S.ClientObjectSync.ReplayPressed
end

_S.ClientObjectSync.UpdateReplayInputDisplay = function(BeganInputs, EndedInputs)
	_S.ClientObjectSync.ApplyInputDisplayQueues(_S.ClientObjectSync.ReplayPressed,BeganInputs,EndedInputs)
	_S.ClientObjectSync.ReplayPressedFrame = nil
end

_S.ClientObjectSync.PlaybackInputPress = function(Input)
	if _S.InputBlacklist[Input] then
		return nil
	end
	_S.ClientObjectSync.PlaybackPressedInputs = _S.ClientObjectSync.PlaybackPressedInputs or {}
	local Code = _S.InputCodes[Input]
	if Code then
		pcall(keypress,Code)
		_S.ClientObjectSync.PlaybackPressedInputs[Input] = true
	elseif Input == "b1" then
		pcall(mouse1press)
		_S.ClientObjectSync.PlaybackPressedInputs[Input] = true
	elseif Input == "b2" then
		pcall(mouse2press)
	elseif Input == "u" or Input == "d" then
		return Input
	end
	return nil
end

_S.ClientObjectSync.PlaybackInputRelease = function(Input)
	if _S.InputBlacklist[Input] then
		return
	end
	local Code = _S.InputCodes[Input]
	if Code then
		pcall(keyrelease,Code)
	elseif Input == "b1" then
		pcall(mouse1release)
	elseif Input == "b2" then
		pcall(mouse2release)
	end
	if _S.ClientObjectSync.PlaybackPressedInputs then
		_S.ClientObjectSync.PlaybackPressedInputs[Input] = nil
	end
	if _S.ClientObjectSync.ReplayPressed then
		_S.ClientObjectSync.ReplayPressed[Input] = nil
	end
	_S.Pressed[Input] = nil
end

_S.ClientObjectSync.IsMotionPlaybackKey = function(Input)
	return Input == "W" or Input == "A" or Input == "S" or Input == "D" or Input == "Space" or Input == "LeftShift" or Input == "RightShift"
end

_S.ClientObjectSync.IsRawKeyboardPlaybackInput = function(Input)
	return _S.InputCodes[Input] ~= nil
end

_S.ClientObjectSync.MotionPlaybackKeyList = {"W","A","S","D","Space","LeftShift"}
_S.ClientObjectSync.ReplayShiftPulseFrames = 5

_S.ClientObjectSync.SyncMotionPlaybackInputs = function(State)
	_S.ClientObjectSync.PlaybackDerivedInputs = _S.ClientObjectSync.PlaybackDerivedInputs or {}
	for _,Input in ipairs(_S.ClientObjectSync.MotionPlaybackKeyList) do
		local Down = State and (State[Input] or (Input == "LeftShift" and State.RightShift))
		if Down and not _S.ClientObjectSync.PlaybackDerivedInputs[Input] then
			_S.ClientObjectSync.PlaybackInputPress(Input)
			_S.ClientObjectSync.PlaybackDerivedInputs[Input] = true
		elseif not Down and _S.ClientObjectSync.PlaybackDerivedInputs[Input] then
			_S.ClientObjectSync.PlaybackInputRelease(Input)
			_S.ClientObjectSync.PlaybackDerivedInputs[Input] = nil
		end
	end
end

_S.ClientObjectSync.ReleasePlaybackInputs = function(ForceAll)
	for Input,_ in pairs(_S.ClientObjectSync.PlaybackPressedInputs or {}) do
		_S.ClientObjectSync.PlaybackInputRelease(Input)
	end
	_S.ClientObjectSync.PlaybackPressedInputs = {}
	_S.ClientObjectSync.PlaybackDerivedInputs = {}
	if _S.ClientObjectSync.ReleasePlaybackObjectControl then
		_S.ClientObjectSync.ReleasePlaybackObjectControl(true)
	end
	if ForceAll then
		for Input,Code in pairs(_S.InputCodes) do
			if not _S.InputBlacklist[Input] then
				pcall(keyrelease,Code)
			end
		end
		pcall(mouse1release)
		pcall(mouse2release)
	end
	_S.Pressed = {}
	_S.InputBeganQueue = {}
	_S.InputEndedQueue = {}
	_S.ClientObjectSync.ResetReplayInputDisplay()
end

_S.ClientObjectSync.GetReplayShiftLock = function(Frame)
	return type(Frame) == "table" and (Frame[10] == true or Frame[10] == 1) or false
end

_S.ClientObjectSync.ApplyReplayShiftPulse = function(State, Replay, Index, Frame, PreviousFrame)
	local PulseFrames = _S.max(_S.floor(tonumber(_S.ClientObjectSync.ReplayShiftPulseFrames) or 1),1)
	if type(Replay) == "table" and Index then
		for PulseIndex = Index,_S.max(Index - PulseFrames + 1,1),-1 do
			local PulseFrame = PulseIndex == Index and Frame or _S.ReplayStorage.Get(Replay,PulseIndex)
			local PulsePrevious = PulseIndex == Index and PreviousFrame or (PulseIndex > 1 and _S.ReplayStorage.Get(Replay,PulseIndex - 1) or nil)
			if _S.ClientObjectSync.GetReplayShiftLock(PulseFrame) ~= _S.ClientObjectSync.GetReplayShiftLock(PulsePrevious) then
				State.LeftShift = true
				State.RightShift = true
				return
			end
		end
	elseif _S.ClientObjectSync.GetReplayShiftLock(Frame) ~= _S.ClientObjectSync.GetReplayShiftLock(PreviousFrame) then
		State.LeftShift = true
		State.RightShift = true
	end
end

_S.ClientObjectSync.BuildReplayKeyboardDisplay = function(Frame, PreviousFrame, Replay, Index)
	local State = {}
	if type(Frame) ~= "table" then
		return State
	end
	_S.ClientObjectSync.ApplyReplayShiftPulse(State,Replay,Index,Frame,PreviousFrame)
	if tonumber(Frame[4]) == Enum.HumanoidStateType.Jumping.Value then
		State.Space = true
	end
	local IsClimbing = tonumber(Frame[4]) == Enum.HumanoidStateType.Climbing.Value
	local VerticalMovement = nil
	local UsingVerticalVelocity = false
	if IsClimbing and type(PreviousFrame) == "table" and type(Frame[1]) == "table" and type(PreviousFrame[1]) == "table" then
		VerticalMovement = (tonumber(Frame[1][2]) or 0) - (tonumber(PreviousFrame[1][2]) or 0)
	end
	if IsClimbing and (not VerticalMovement or math.abs(VerticalMovement) <= 0.005) and type(Frame[5]) == "table" then
		VerticalMovement = tonumber(Frame[5][2]) or 0
		UsingVerticalVelocity = true
	end
	if IsClimbing and VerticalMovement then
		local ClimbMinimum = UsingVerticalVelocity and 0.75 or 0.015
		if VerticalMovement > ClimbMinimum then
			State.W = true
		elseif VerticalMovement < -ClimbMinimum then
			State.S = true
		end
	end
	local Movement = nil
	local UsingVelocity = false
	if type(PreviousFrame) == "table" and type(Frame[1]) == "table" and type(PreviousFrame[1]) == "table" then
		Movement = Vector3.new((tonumber(Frame[1][1]) or 0) - (tonumber(PreviousFrame[1][1]) or 0),0,(tonumber(Frame[1][3]) or 0) - (tonumber(PreviousFrame[1][3]) or 0))
	end
	if (not Movement or Movement.Magnitude <= 0.005) and type(Frame[5]) == "table" then
		Movement = Vector3.new(tonumber(Frame[5][1]) or 0,0,tonumber(Frame[5][3]) or 0)
		UsingVelocity = true
	end
	if not Movement then
		return State
	end
	local Magnitude = Movement.Magnitude
	local Minimum = UsingVelocity and 0.75 or 0.015
	if Magnitude <= Minimum or type(Frame[7]) ~= "table" then
		return State
	end
	local Camera = FastTableToCFrame(Frame[7])
	local Forward = Vector3.new(Camera.LookVector.X,0,Camera.LookVector.Z)
	local Right = Vector3.new(Camera.RightVector.X,0,Camera.RightVector.Z)
	if Forward.Magnitude <= 0 or Right.Magnitude <= 0 then
		return State
	end
	Forward = Forward.Unit
	Right = Right.Unit
	local ForwardAmount = Movement:Dot(Forward)
	local RightAmount = Movement:Dot(Right)
	local AxisThreshold = _S.max(Magnitude * 0.35,Minimum)
	if ForwardAmount > AxisThreshold then
		State.W = true
	elseif ForwardAmount < -AxisThreshold then
		State.S = true
	end
	if RightAmount > AxisThreshold then
		State.D = true
	elseif RightAmount < -AxisThreshold then
		State.A = true
	end
	return State
end

_S.ClientObjectSync.SetReplayKeyboardDisplayAtFrame = function(Replay, Index)
	Index = _S.max(_S.floor((tonumber(Index) or 1) + 0.5),1)
	if _S.ClientObjectSync.ReplayPressedFrame == Index and _S.ClientObjectSync.ReplayKeyboardReplay == Replay then
		return _S.ClientObjectSync.ReplayPressed
	end
	_S.ClientObjectSync.ReplayPressed = _S.ClientObjectSync.BuildReplayKeyboardDisplay(_S.ReplayStorage.Get(Replay,Index),Index > 1 and _S.ReplayStorage.Get(Replay,Index - 1) or nil,Replay,Index)
	_S.ClientObjectSync.ReplayPressedFrame = Index
	_S.ClientObjectSync.ReplayKeyboardReplay = Replay
	return _S.ClientObjectSync.ReplayPressed
end

_S.ReplayStorage.New = function()
	return {
		ChunkSize = _S.max(_S.floor((_S.ClientObjectSync.TASFPS or 60) * _S.ReplayStorage.ChunkSeconds + 0.5),1);
		Chunks = {};
		EncodedChunks = {};
		Count = 0;
		Revision = 0;
	}
end

_S.ReplayStorage.Length = function(Replay)
	return type(Replay) == "table" and tonumber(Replay.Count) or 0
end

_S.ReplayStorage.GetChunk = function(Replay, ChunkIndex)
	ChunkIndex = tonumber(ChunkIndex)
	if type(Replay) ~= "table" or not ChunkIndex then
		return nil
	end

	Replay.Chunks = Replay.Chunks or {}
	Replay.EncodedChunks = Replay.EncodedChunks or {}

	local Chunk = Replay.Chunks[ChunkIndex]
	if Chunk then
		return Chunk
	end

	local Encoded = Replay.EncodedChunks[ChunkIndex] or Replay.EncodedChunks[tostring(ChunkIndex)]
	if type(Encoded) == "string" then
		local Success, Decoded = pcall(function()
			return json.decode(Encoded)
		end)
		if Success and type(Decoded) == "table" then
			Replay.Chunks[ChunkIndex] = Decoded
			return Decoded
		end
	end
	return nil
end

_S.ReplayStorage.DecodeAllChunks = function(Replay)
	if type(Replay) ~= "table" then
		return
	end

	Replay.Chunks = Replay.Chunks or {}
	Replay.EncodedChunks = Replay.EncodedChunks or {}

	local ChunkIndices = {}
	local Seen = {}
	for ChunkIndex,Encoded in pairs(Replay.EncodedChunks) do
		local NumericChunkIndex = tonumber(ChunkIndex)
		if NumericChunkIndex and type(Encoded) == "string" and not Seen[NumericChunkIndex] then
			Seen[NumericChunkIndex] = true
			ChunkIndices[#ChunkIndices + 1] = NumericChunkIndex
		end
	end
	table.sort(ChunkIndices)

	if #ChunkIndices > 0 then
		ConsoleMessage("Decoding "..tostring(#ChunkIndices).." replay chunks")
		local StartTick = tick()
		for _,ChunkIndex in ipairs(ChunkIndices) do
			_S.ReplayStorage.GetChunk(Replay,ChunkIndex)
		end
		ConsoleMessage("Done decoding replay chunks in",RoundNumber(tick()-StartTick,2),"seconds")
	end
end

_S.ReplayStorage.WaitUntilDecoded = function(Replay)
	if type(Replay) ~= "table" then
		return false,"Replay decode failed"
	end
	local Count = _S.ReplayStorage.Length(Replay)
	if Count <= 0 then
		return false,"Nothing to read"
	end

	Replay.Chunks = Replay.Chunks or {}
	Replay.EncodedChunks = Replay.EncodedChunks or {}
	local ChunkSize = Replay.ChunkSize or _S.max(_S.floor((_S.ClientObjectSync.TASFPS or 60) * _S.ReplayStorage.ChunkSeconds + 0.5),1)
	local ChunkCount = _S.floor((Count - 1) / ChunkSize) + 1
	local StartTick = tick()

	for ChunkIndex = 1,ChunkCount do
		local Chunk = _S.ReplayStorage.GetChunk(Replay,ChunkIndex)
		if type(Chunk) ~= "table" then
			return false,"Replay chunk "..tostring(ChunkIndex).." failed to decode"
		end
		local LastFrameIndex = ChunkIndex == ChunkCount and (((Count - 1) % ChunkSize) + 1) or ChunkSize
		if type(Chunk[LastFrameIndex]) ~= "table" then
			return false,"Replay frame data is incomplete"
		end
		if ChunkIndex % 8 == 0 then
			_S.RunService.Heartbeat:Wait()
		end
	end

	ConsoleMessage("Replay ready in",RoundNumber(tick()-StartTick,2),"seconds")
	return true
end

_S.ReplayStorage.Get = function(Replay, Index)
	Index = _S.floor(tonumber(Index) or 0)
	if type(Replay) ~= "table" or Index < 1 or Index > _S.ReplayStorage.Length(Replay) then
		return nil
	end

	local ChunkSize = Replay.ChunkSize or _S.max(_S.floor((_S.ClientObjectSync.TASFPS or 60) * _S.ReplayStorage.ChunkSeconds + 0.5),1)
	local ChunkIndex = _S.floor((Index - 1) / ChunkSize) + 1
	local FrameIndex = ((Index - 1) % ChunkSize) + 1
	local Chunk = _S.ReplayStorage.GetChunk(Replay,ChunkIndex)
	return Chunk and Chunk[FrameIndex] or nil
end

_S.ReplayStorage.Set = function(Replay, Index, Frame)
	Index = _S.floor(tonumber(Index) or 0)
	if type(Replay) ~= "table" or Index < 1 then
		return
	end

	if Frame == nil then
		if Index <= _S.ReplayStorage.Length(Replay) then
			_S.ReplayStorage.Truncate(Replay,Index - 1)
		end
		return
	end

	local ChunkSize = Replay.ChunkSize or _S.max(_S.floor((_S.ClientObjectSync.TASFPS or 60) * _S.ReplayStorage.ChunkSeconds + 0.5),1)
	local ChunkIndex = _S.floor((Index - 1) / ChunkSize) + 1
	local FrameIndex = ((Index - 1) % ChunkSize) + 1
	Replay.Chunks = Replay.Chunks or {}
	Replay.EncodedChunks = Replay.EncodedChunks or {}
	Replay.Chunks[ChunkIndex] = _S.ReplayStorage.GetChunk(Replay,ChunkIndex) or {}
	Replay.EncodedChunks[ChunkIndex] = nil
	Replay.Chunks[ChunkIndex][FrameIndex] = Frame
	if Index > _S.ReplayStorage.Length(Replay) then
		Replay.Count = Index
	end
	Replay.Revision = (Replay.Revision or 0) + 1
end

_S.ReplayStorage.Append = function(Replay, Frame)
	_S.ReplayStorage.Set(Replay,_S.ReplayStorage.Length(Replay) + 1,Frame)
end

_S.ReplayStorage.AppendChunk = function(Replay, Chunk, ChunkLength)
	local Count = ChunkLength or #Chunk
	if Count <= 0 then
		return
	end

	local ChunkSize = Replay.ChunkSize or _S.max(_S.floor((_S.ClientObjectSync.TASFPS or 60) * _S.ReplayStorage.ChunkSeconds + 0.5),1)
	if _S.ReplayStorage.Length(Replay) % ChunkSize == 0 and Count == ChunkSize then
		Replay.Chunks = Replay.Chunks or {}
		Replay.EncodedChunks = Replay.EncodedChunks or {}
		local ChunkIndex = (_S.ReplayStorage.Length(Replay) / ChunkSize) + 1
		Replay.Chunks[ChunkIndex] = Chunk
		Replay.EncodedChunks[ChunkIndex] = nil
		Replay.Count = _S.ReplayStorage.Length(Replay) + Count
		Replay.Revision = (Replay.Revision or 0) + 1
	else
		for Index = 1,Count do
			_S.ReplayStorage.Append(Replay,Chunk[Index])
		end
	end
end

_S.ReplayStorage.ProcessCodecQueue = function()
	_S.ReplayStorage.CodecQueue = {}
	_S.ReplayStorage.CodecRunning = false
	return
end

_S.ReplayStorage.QueueCodecChunk = function(Replay, ChunkIndex)
	if type(Replay) ~= "table" or not ChunkIndex then
		return
	end
	_S.ReplayStorage.CodecQueued[Replay] = _S.ReplayStorage.CodecQueued[Replay] or {}
	if _S.ReplayStorage.CodecQueued[Replay][ChunkIndex] then
		return
	end
	_S.ReplayStorage.CodecQueued[Replay][ChunkIndex] = true
	_S.ReplayStorage.CodecQueue[#_S.ReplayStorage.CodecQueue + 1] = {Replay,ChunkIndex}
	_S.ReplayStorage.ProcessCodecQueue()
end

_S.ReplayStorage.CodecOldChunks = function(Replay)
	return
end

_S.ReplayStorage.Truncate = function(Replay, NewLength)
	NewLength = _S.max(_S.floor(tonumber(NewLength) or 0),0)
	if type(Replay) ~= "table" then
		return
	end
	if NewLength >= _S.ReplayStorage.Length(Replay) then
		return
	end

	local ChunkSize = Replay.ChunkSize or _S.max(_S.floor((_S.ClientObjectSync.TASFPS or 60) * _S.ReplayStorage.ChunkSeconds + 0.5),1)
	local KeepChunks = NewLength > 0 and (_S.floor((NewLength - 1) / ChunkSize) + 1) or 0
	Replay.Chunks = Replay.Chunks or {}
	Replay.EncodedChunks = Replay.EncodedChunks or {}
	local MaxChunk = 0
	for Index in pairs(Replay.Chunks) do
		if type(Index) == "number" and Index > MaxChunk then
			MaxChunk = Index
		end
	end
	for Index in pairs(Replay.EncodedChunks) do
		if type(Index) == "number" and Index > MaxChunk then
			MaxChunk = Index
		end
	end
	for Index = KeepChunks + 1,MaxChunk do
		Replay.Chunks[Index] = nil
		Replay.EncodedChunks[Index] = nil
	end
	if NewLength > 0 then
		local LastFrameIndex = ((NewLength - 1) % ChunkSize) + 1
		local LastChunk = _S.ReplayStorage.GetChunk(Replay,KeepChunks)
		if LastChunk then
			Replay.EncodedChunks[KeepChunks] = nil
			for Index = LastFrameIndex + 1,#LastChunk do
				LastChunk[Index] = nil
			end
		end
	end
	Replay.Count = NewLength
	Replay.Revision = (Replay.Revision or 0) + 1
	_S.ReplayStorage.CodecOldChunks(Replay)
end

_S.ReplayStorage.FromArray = function(Array)
	local Replay = _S.ReplayStorage.New()
	if type(Array) ~= "table" then
		return Replay
	end
	for Index = 1,#Array do
		_S.ReplayStorage.Append(Replay,Array[Index])
	end
	_S.ReplayStorage.CodecOldChunks(Replay)
	return Replay
end

_S.ReplayStorage.FromChunks = function(Chunks, Count, ChunkSize, EncodedChunks)
	local Replay = _S.ReplayStorage.New()
	Replay.ChunkSize = _S.max(tonumber(ChunkSize) or Replay.ChunkSize,1)
	Replay.Chunks = type(Chunks) == "table" and Chunks or {}
	Replay.EncodedChunks = type(EncodedChunks) == "table" and EncodedChunks or {}
	Replay.Count = tonumber(Count) or 0
	if Replay.Count <= 0 then
		for _,Chunk in ipairs(Replay.Chunks) do
			Replay.Count = Replay.Count + #Chunk
		end
	end
	_S.ReplayStorage.CodecOldChunks(Replay)
	return Replay
end

_S.ReplayStorage.FromChunkRecords = function(ChunkRecords, EncodedChunkRecords, Count, ChunkSize)
	local Replay = _S.ReplayStorage.New()
	Replay.ChunkSize = _S.max(tonumber(ChunkSize) or Replay.ChunkSize,1)
	Replay.Chunks = {}
	Replay.EncodedChunks = {}
	if type(ChunkRecords) == "table" then
		for _,Record in ipairs(ChunkRecords) do
			if type(Record) == "table" and tonumber(Record[1]) and type(Record[2]) == "table" then
				Replay.Chunks[tonumber(Record[1])] = Record[2]
			end
		end
	end
	if type(EncodedChunkRecords) == "table" then
		for _,Record in ipairs(EncodedChunkRecords) do
			if type(Record) == "table" and tonumber(Record[1]) and type(Record[2]) == "string" then
				Replay.EncodedChunks[tonumber(Record[1])] = Record[2]
			end
		end
	end
	Replay.Count = tonumber(Count) or 0
	_S.ReplayStorage.CodecOldChunks(Replay)
	return Replay
end

_S.ReplayStorage.SaveData = function(Replay)
	local ChunkRecords = {}
	local EncodedChunkRecords = {}
	for ChunkIndex,Chunk in pairs(Replay.Chunks or {}) do
		if type(Chunk) == "table" then
			ChunkRecords[#ChunkRecords + 1] = {ChunkIndex,Chunk}
		end
	end
	for ChunkIndex,Encoded in pairs(Replay.EncodedChunks or {}) do
		if type(Encoded) == "string" then
			EncodedChunkRecords[#EncodedChunkRecords + 1] = {ChunkIndex,Encoded}
		end
	end
	return {
		ChunkRecords = ChunkRecords;
		EncodedChunkRecords = EncodedChunkRecords;
		Count = _S.ReplayStorage.Length(Replay);
		ChunkSize = Replay.ChunkSize;
	}
end

_S.ReplayTable = _S.ReplayStorage.New()

_S.ClientObjectSync.ResetRecordingBuffer = function()
	_S.RecordingTable = {
		ChunkSize = _S.max(_S.floor((_S.ClientObjectSync.TASFPS or 60) * _S.ReplayStorage.ChunkSeconds + 0.5),1);
		Chunks = {};
		Chunk = {};
		ChunkCount = 0;
		FrameCount = 0;
		LastFrame = nil;
		StartFrame = _S.ReplayStorage.Length(_S.ReplayTable);
	}
end

_S.ClientObjectSync.AppendRecordingFrame = function(Frame)
	_S.RecordingTable.ChunkCount = _S.RecordingTable.ChunkCount + 1
	_S.RecordingTable.Chunk[_S.RecordingTable.ChunkCount] = Frame
	_S.RecordingTable.FrameCount = _S.RecordingTable.FrameCount + 1
	_S.RecordingTable.LastFrame = Frame
	if _S.RecordingTable.ChunkCount >= _S.RecordingTable.ChunkSize then
		_S.ReplayStorage.AppendChunk(_S.ReplayTable,_S.RecordingTable.Chunk,_S.RecordingTable.ChunkCount)
		_S.RecordingTable.Chunk = {}
		_S.RecordingTable.ChunkCount = 0
	end
end

_S.ClientObjectSync.FlushRecordingBufferToReplay = function()
	for _,Chunk in ipairs(_S.RecordingTable.Chunks) do
		_S.ReplayStorage.AppendChunk(_S.ReplayTable,Chunk,#Chunk)
	end

	_S.ReplayStorage.AppendChunk(_S.ReplayTable,_S.RecordingTable.Chunk,_S.RecordingTable.ChunkCount)

	_S.ClientObjectSync.ResetRecordingBuffer()
end


do
local TASCharacter = setmetatable({}, {
	__index = function(_, k)
		if k == "RootPart" then return _S.RootPart or (Character and Character:FindFirstChild("HumanoidRootPart")) end
		if k == "Character" then return Character end
		if k == "ConsoleMessage" then return ConsoleMessage end
		return nil
	end
})
local TASConfig = setmetatable({}, {
	__index = function(_, k)
		if k == "AllowClientObjectManipulation" then return _S.ClientObjectSync.Enabled ~= false end
		if k == "CORecordingRadius" then return _S.ClientObjectSync.Radius or 0 end
		if k == "RoundDigits" then return _S.ClientObjectSync.RoundDigits or 15 end
		if k == "TASRecordingFPS" then return _S.ClientObjectSync.TASFPS or 60 end
		return nil
	end
})
local TASServices = {
	RunService = _S.RunService,
}
local TASRuntime = setmetatable({}, {
	__index = function(_, k)
		if k == "Reading" then return _S.Reading end
		if k == "Paused" then return _S.Paused end
		if k == "ReplayTableIndex" then return _S.ReplayTableIndex end
		return nil
	end
})
local TASFreeze = setmetatable({}, {
	__index = function(_, k)
		if k == "Frozen" then return _S.Frozen end
		return nil
	end
})

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
                    -- Only objects currently inside the player-centered recording
                    -- radius are sampled. Leaving the radius produces no new delta;
                    -- re-entering forces one fresh sample so the object resumes from
                    -- its current position when it comes back into range.
                    local cf   = part.CFrame
                    local prev = lastCFrames[id]
                    local moved = forceAll or forceCaptureIds[id] == true or not wasInRadius
                    if not moved and prev then
                        local rel = prev:ToObjectSpace(cf)
                        local pos = rel.Position
                        -- Only serialize an object when its position OR orientation
                        -- really changed. The previous branch forced every object
                        -- to be written every frame, which inflated replays badly.
                        if math.abs(pos.X) > CO_EPSILON
                         or math.abs(pos.Y) > CO_EPSILON
                         or math.abs(pos.Z) > CO_EPSILON
                         or math.abs(rel.XVector.X - 1) > CO_EPSILON
                         or math.abs(rel.XVector.Y) > CO_EPSILON
                         or math.abs(rel.XVector.Z) > CO_EPSILON
                         or math.abs(rel.YVector.X) > CO_EPSILON
                         or math.abs(rel.YVector.Y - 1) > CO_EPSILON
                         or math.abs(rel.YVector.Z) > CO_EPSILON
                         or math.abs(rel.ZVector.X) > CO_EPSILON
                         or math.abs(rel.ZVector.Y) > CO_EPSILON
                         or math.abs(rel.ZVector.Z - 1) > CO_EPSILON
                        then
                            moved = true
                        end
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

    
    -- CO visual playback is rendered independently from the TAS timeline.
    -- The replay timeline can stay at 60 FPS while the client renders at 120+ FPS.
    -- Keeping a per-object render segment avoids the old staircase effect where
    -- CFrames were only visibly changed on TAS/Heartbeat ticks.
    CO._coRate = 15
    CO._lerpTargets = {}
    CO._visualSegments = {}
    CO._visualFrame = nil
    CO._visualClock = nil
    CO._lastCoTime = nil
    CO._coDataWarned = false
    CO._preparedFirstFrame = nil
    CO._preparedFirstFrameReady = false
    function CO.ApplyFrame(delta, forcedAlpha)
        if delta == nil then
            return
        end
        CO._coDataWarned = false

        for idStr, components in pairs(delta) do
            local id = tonumber(idStr)
            if type(components) == "table" and components[1] and components[2] and type(components[2]) == "table" then
                id = tonumber(components[1]) or id
                components = components[2]
            end
            local part = objectRegistry[id]
            if part and part.Parent and type(components) == "table" then
                part.CFrame = FastTableToCFrame(components)
            end
        end
    end

    function CO.ApplyInterpolatedFrame(currentDelta, nextDelta, alpha)
        if currentDelta == nil then
            CO.WarnNoCOData()
            return
        end
        CO._coDataWarned = false

        for idStr, components in pairs(currentDelta) do
            CO._lerpTargets[idStr] = components
        end

        alpha = math.clamp(tonumber(alpha) or 0, 0, 1)
        for idStr, currentTarget in pairs(CO._lerpTargets) do
            local id = tonumber(idStr)
            local part = objectRegistry[id]
            if part and part.Parent then
                local nextTarget = nextDelta and (nextDelta[idStr] or (id and nextDelta[tostring(id)])) or nil
                local fromCF = FastTableToCFrame(currentTarget)
                local toCF = nextTarget and FastTableToCFrame(nextTarget) or fromCF
                part.CFrame = (alpha <= 0 or fromCF == toCF) and fromCF or (alpha >= 1 and toCF or fromCF:Lerp(toCF, alpha))
                part.AssemblyLinearVelocity = Vector3.zero
                part.AssemblyAngularVelocity = Vector3.zero
            end
        end
    end

    function CO.SetVisualFrame(currentDelta, nextDelta)
        if currentDelta == nil then
            CO.WarnNoCOData()
            return
        end
        CO._coDataWarned = false

        for idStr, components in pairs(currentDelta) do
            CO._lerpTargets[idStr] = components
        end

        local segments = CO._visualSegments
        local now = tick()
        CO._visualClock = now
        CO._visualFrame = TASRuntime.ReplayTableIndex

        for idStr, currentTarget in pairs(CO._lerpTargets) do
            local id = tonumber(idStr)
            if id then
                local nextTarget = nextDelta and (nextDelta[idStr] or nextDelta[tostring(id)]) or nil
                segments[idStr] = {
                    From = FastTableToCFrame(currentTarget),
                    To = nextTarget and FastTableToCFrame(nextTarget) or FastTableToCFrame(currentTarget),
                    Started = now,
                }
            end
        end
    end

    function CO.RenderVisual()
        if not TASRuntime.Reading or TASRuntime.Paused or TASFreeze.Frozen then return end
        local segments = CO._visualSegments
        if type(segments) ~= "table" or not next(segments) then return end

        local interval = tonumber(TASRuntime.PlaybackInterval) or (1 / math.max(1, tonumber(TASConfig.TASRecordingFPS) or 60))
        interval = math.max(interval, 1/1000)
        local elapsed = CO._visualClock and math.max(0, tick() - CO._visualClock) or 0
        local alpha = math.clamp(elapsed / interval, 0, 1)

        for idStr, segment in pairs(segments) do
            local id = tonumber(idStr)
            local part = id and objectRegistry[id]
            if part and part.Parent and segment then
                local fromCF, toCF = segment.From, segment.To
                if fromCF and toCF then
                    part.CFrame = (fromCF == toCF or alpha <= 0) and fromCF or (alpha >= 1 and toCF or fromCF:Lerp(toCF, alpha))
                    part.AssemblyLinearVelocity = Vector3.zero
                    part.AssemblyAngularVelocity = Vector3.zero
                end
            end
        end
    end

    function CO.AnchorAll(silent)
        local anchoredCount = 0
        for id, part in pairs(objectRegistry) do
            if part and part.Parent then
                if originalAnchored[id] == nil then
                    originalAnchored[id] = part.Anchored
                end
                part.Anchored = true
                part.AssemblyLinearVelocity = Vector3.zero
                part.AssemblyAngularVelocity = Vector3.zero
                anchoredCount = anchoredCount + 1
            end
        end
        if not silent then
            TASCharacter.ConsoleMessage("[CO] Anchored " .. tostring(anchoredCount) .. " tracked objects")
        end
        return anchoredCount
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
                    if type(components) == "table" and components[1] and components[2] and type(components[2]) == "table" then
                        state[tostring(components[1])] = components[2]
                    else
                        state[tostring(idStr)] = components
                    end
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

    -- TAS Replay compatibility/state helpers. The actual CO recording/playback model
    -- above intentionally matches message.txt; these helpers only satisfy the
    -- newer TAS Replay call sites without changing the CO state semantics.
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
        CO._visualSegments = {}
        CO._visualFrame = nil
        CO._visualClock = nil
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

    -- Clear only recording-side state. Keep the discovered object registry and
    -- Descendant/Anchored watchers alive so resetting a recording is instant.
    function CO.ResetRecordingTracking()
        lastCFrames = {}
        withinRecordRadius = {}
        forceCaptureIds = {}
        CO._forceFullFrame = true
        CO._preparedFirstFrame = nil
        CO._preparedFirstFrameReady = false
        CO._lastCoTime = nil
    end

    function CO.BeginPlaybackCleanup()
        CO._FullStateCache = nil
        CO._lastCoTime = nil
        CO._playbackHasData = false
        CO._lerpTargets = {}
    end
    function CO.EndPlaybackCleanup()
        -- Playback must never leave tracked client objects anchored.
        pcall(function() CO.RestoreAnchors() end)
        CO._playbackHasData = false
        CO._lerpTargets = {}
        CO._FullStateCache = nil
        CO._lastCoTime = nil
    end
    function CO.HasReplayData(replay)
        if type(replay) ~= "table" then return false end
        local count = _S.ReplayStorage and _S.ReplayStorage.Length and _S.ReplayStorage.Length(replay) or #replay
        for i = 1, count do
            local frame = _S.ReplayStorage and _S.ReplayStorage.Get and _S.ReplayStorage.Get(replay, i) or replay[i]
            if type(frame) == "table" and type(frame[13]) == "table" and next(frame[13]) ~= nil then
                return true
            end
        end
        return false
    end

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


_S.ClientObjectSync.CO = CO

_S.ClientObjectSync.Scan = function(Force)
	if not CO._initialized and not CO._initializing then
		CO.Init()
	end
end

_S.ClientObjectSync.CaptureFrame = function()
	local delta = CO.RecordFrame()
	local snapshots = {}
	if type(delta) == "table" then
		for idStr, comp in pairs(delta) do
			table.insert(snapshots, {tonumber(idStr) or idStr, comp})
		end
	end
	table.sort(snapshots, function(a,b) return (tonumber(a[1]) or 0) < (tonumber(b[1]) or 0) end)
	return snapshots
end

_S.ClientObjectSync.ApplyFrame = function(Frame)
	if type(Frame) == "table" and Frame[13] then
		CO.ApplyFrame(Frame[13])
	end
end

_S.ClientObjectSync.ApplyObjectsAtFrame = function(Replay, Index)
	if type(Replay) == "table" and Index then
		local state = CO.GetFullStateAtFrame(Index, Replay)
		CO.ApplyFullState(state)
		CO.AnchorAll(true)
	end
end

_S.ClientObjectSync.ReleasePlaybackObjectControl = function(Restore)
	if Restore then
		CO.RestoreAnchors()
	end
end

_S.ClientObjectSync.PrepareFirstRecordingFrame = function()
	return CO.PrepareFirstRecordingFrame()
end

_S.ClientObjectSync.ResetRegistry = function()
	CO.RebuildFromAttributes()
end

_S.ClientObjectSync.LoadRegistry = function(...)
end

_S.ClientObjectSync.CaptureBeatBlockFrame = function() return nil end
_S.ClientObjectSync.CaptureStateFrame = function() return nil end
_S.ClientObjectSync.ApplyBeatBlocksAtFrame = function() end
_S.ClientObjectSync.ApplyStateAtFrame = function() end


_S.ClientObjectSync.SetCOManipulationEnabled = function(Enabled)
	if type(_S.ClientObjectSync.COManipulation) ~= "table" then
		_S.ClientObjectSync.COManipulation = {}
	end
	_S.ClientObjectSync.COManipulation.Enabled = Enabled == true
	_S.ClientObjectSync.Enabled = Enabled == true
	if _S.ClientObjectSync.CO then
		if Enabled then
			if not _S.ClientObjectSync.CO._initialized and not _S.ClientObjectSync.CO._initializing then
				pcall(_S.ClientObjectSync.CO.Init)
			end
		else
			if _S.ClientObjectSync.CO.Stop then
				pcall(_S.ClientObjectSync.CO.Stop)
			end
		end
	end
end
end



-- ═══════════════════════════════════════════════════════════════════════════
-- GUI compatibility bridge: maps fork-style namespaces to old-style variables
-- ═══════════════════════════════════════════════════════════════════════════

-- TASConfig: mirrors the old top-level config variables
local TASConfig = {
    FPS = _S.FPS,
    TASRecordingFPS = _S.ClientObjectSync.TASFPS or 60,
    AllowClientObjectManipulation = _S.ClientObjectSync.COManipulation and _S.ClientObjectSync.COManipulation.Enabled ~= false,
    CORecordingRadius = _S.ClientObjectSync.Radius or 900,
    PlaybackInputs = _S.PlaybackInputs,
    PlaybackMouseLocation = _S.PlaybackMouseLocation,
    RoundDigits = _S.RoundDigits,
    ReplayStartTime = _S.ReplayStartTime,
    FrameBacktrackCount = _S.FrameBacktrackCount,
    MinimumJSONFPS = _S.MinimumJSONFPS,
    BypassAntiExploit = _S.BypassAntiExploit,
    InputBlacklist = _S.InputBlacklist,
    ColorCodes = _S.ColorCodes,
    Cursors = _S.Cursors,
    Version = _S.Version,
    ReplayFileBeginning = _S.ReplayFileBeginning,
    ReplayFileEnding = _S.ReplayFileEnding,
    AHKConnectionFolderPath = _S.AHKConnectionFolderPath,
    AHKConnectionRequestPath = _S.AHKConnectionRequestPath,
    TASCompressionLevel = 3,
    NohBoardWebSocketEnabled = false,
    NohBoardWebSocketURL = "ws://127.0.0.1:8765",
    NohBoardWebSocketProtocol = 1,
    FIRST_RECORD_FIX = "",
    ReplayCodecTimeBudget = 0.010,
}

-- TASServices: wraps the old service references
local TASServices = {
    UserInputService = _S.UserInputService,
    RunService = _S.RunService,
    HttpService = _S.HttpService,
    ContextActionService = _S.ContextActionService,
    GuiService = _S.GuiService,
    VirtualInputManager = _S.VirtualInputManager,
    Player = _S.Player,
    Mouse = _S.Mouse,
    random = math.random,
    min = math.min,
    max = math.max,
    floor = math.floor,
    ceil = math.ceil,
    ShiftLockEnabled = _S.ShiftLockEnabled,
    GuiInset = _S.GuiInset,
}
TASServices.PlayerModule = _S.PlayerModule
TASServices.ShiftLockBoundKeys = _S.ShiftLockBoundKeys

-- TASPaths: maps old path variables
local TASPaths = {
    ExecutionTick = _S.ExecutionTick,
    PlaceId = _S.PlaceId,
    FolderPath = _S.FolderPath,
    ReplayPath = _S.ReplayPath,
    ReplayNeedsReload = false,
    LastLoadedPath = nil,
    pathVisualsEnabled = false,
    pathLines = {},
    pathStartText = nil,
    pathEndText = nil,
}

-- TASCharacter: wraps old character references
local TASCharacter = {
    Character = Character,
    Humanoid = _S.Humanoid,
    RootPart = _S.RootPart,
    DefaultGravity = _S.DefaultGravity,
    DefaultJumpPower = _S.DefaultJumpPower,
    DefaultWalkSpeed = _S.DefaultWalkSpeed,
    Resolution = _S.Resolution,
    ConsoleMessage = ConsoleMessage,
}

-- TASRuntime: wraps old runtime state
local TASRuntime = {
    Reading = _S.Reading,
    Paused = _S.Paused,
    Writing = _S.Writing,
    Saving = _S.Saving,
    AnimateDisabled = _S.AnimateDisabled,
    Checkpoints = _S.Checkpoints,
    RenderSteppedConnections = _S.RenderSteppedConnections,
    SteppedConnections = _S.SteppedConnections,
    ReplayTable = _S.ReplayTable,
    RecordingTable = _S.RecordingTable,
    Pressed = _S.Pressed,
    IgnoreGameProcessed = _S.IgnoreGameProcessed,
    ReplayTableIndex = _S.ReplayTableIndex,
    AnimationQueue = _S.AnimationQueue,
    RunSpeed = _S.RunSpeed,
    ClimbSpeed = _S.ClimbSpeed,
    HumanoidStateQueue = _S.HumanoidStateQueue,
    InputBeganQueue = _S.InputBeganQueue,
    InputEndedQueue = _S.InputEndedQueue,
    Cursor = _S.Cursor,
    CursorIcon = _S.CursorIcon,
    CursorSize = _S.CursorSize,
    CursorOffset = _S.CursorOffset,
    Dead = _S.Dead,
    CameraCFrame = _S.CameraCFrame,
    WritingPressedKeys = {},
    ActiveReplayFPS = _S.ClientObjectSync.TASFPS or 60,
    ReplaySourceFPS = _S.ClientObjectSync.TASFPS or 60,
    ReplaySaveState = {Version=0, Encoded=nil, EncodedVersion=-1},
    PlaybackInterval = 0,
}
-- Keep runtime in sync with globals using metatables
setmetatable(TASRuntime, {
    __index = function(t, k)
        if k == "Reading" then return _S.Reading
        elseif k == "Writing" then return _S.Writing
        elseif k == "Paused" then return _S.Paused
        elseif k == "Frozen" then return _S.Frozen
        elseif k == "ReplayTableIndex" then return _S.ReplayTableIndex
        elseif k == "ReplayTable" then return _S.ReplayTable
        elseif k == "InputBeganQueue" then return _S.InputBeganQueue
        elseif k == "InputEndedQueue" then return _S.InputEndedQueue
        elseif k == "Pressed" then return _S.Pressed
        elseif k == "IgnoreGameProcessed" then return _S.IgnoreGameProcessed
        end
        return rawget(t, k)
    end,
    __newindex = function(t, k, v)
        rawset(t, k, v)
        if k == "IgnoreGameProcessed" then _S.IgnoreGameProcessed = v end
    end,
})

-- TASFreeze: wraps old freeze state
local TASFreeze = {
    Frozen = _S.Frozen,
    FreezeFrame = _S.FreezeFrame,
    SeekDirection = _S.SeekDirection,
    SeekDirectionMultiplier = _S.SeekDirectionMultiplier,
    COInitializationQueued = false,
    FrozenHeldCO = false,
}
setmetatable(TASFreeze, {
    __index = function(t, k)
        if k == "Frozen" then return _S.Frozen
        elseif k == "FreezeFrame" then return _S.FreezeFrame
        elseif k == "SeekDirection" then return _S.SeekDirection
        elseif k == "SeekDirectionMultiplier" then return _S.SeekDirectionMultiplier
        end
        return rawget(t, k)
    end,
})

-- TASAnimation: wraps old animation vars
local TASAnimation = {
    pose = pose,
    currentAnimSpeed = currentAnimSpeed,
    currentAnimName = "idle",
    currentAnimTrack = nil,
}
setmetatable(TASAnimation, {
    __index = function(t, k)
        if k == "pose" then return pose
        elseif k == "currentAnimSpeed" then return currentAnimSpeed
        end
        return rawget(t, k)
    end,
})

-- TASSpeedHack: stub (not implemented in old version)
local TASSpeedHack = {
    Enabled = false,
    Speed = 0.5,
    RuntimeApplied = false,
    BaseGravity = nil,
    BaseWalkSpeed = nil,
    BaseJumpPower = nil,
}
local AllowChangingPhysics = true

local function TASSpeedHackSetEnabled(val)
    TASSpeedHack.Enabled = val == true
end

-- TASTracer: stub
local TASTracer = {
    TracerEnabled = false,
    TRACER_LOOKAHEAD = 2,
    TRACER_STEPS = 30,
}
local function clearTracerObjects() end

-- TASFunctions: wraps old functions
local TASFunctions = {}
local function ResetCurrentRecording()
    if _S.Writing then
        StopRecording()
    end
    if _S.Reading and StopReading then
        pcall(StopReading)
    end
    _S.Writing = false
    _S.Reading = false
    _S.Paused = false
    _S.Frozen = false
    _S.SeekDirection = 0
    _S.ReplayTableIndex = 0
    _S.FreezeFrame = 1
    _S.ReplayTable = _S.ReplayStorage.New()
    _S.ReplaySaveCache.Replay = nil
    _S.ReplaySaveCache.Revision = -1
    _S.ReplaySaveCache.Path = nil
    _S.ReplaySaveCache.Encoded = nil
    _S.ClientObjectSync.ResetRecordingBuffer()
    if _S.ClientObjectSync.CO and _S.ClientObjectSync.CO.ResetRecordingTracking then
        _S.ClientObjectSync.CO.ResetRecordingTracking()
    end
    _S.ClientObjectSync.ResetReplayInputDisplay()
    _S.ClientObjectSync.ClearRecordingFrameQueues()
    workspace.Gravity = _S.DefaultGravity
    if Character and Character:FindFirstChild("Humanoid") then
        Character.Humanoid.PlatformStand = false
        Character.Humanoid.JumpPower = _S.DefaultJumpPower
        Character.Humanoid.WalkSpeed = _S.DefaultWalkSpeed
    end
    ConsoleMessage("Cleared TAS")
end
TASFunctions.ResetCurrentRecording = ResetCurrentRecording
TASFunctions.StopReading = function(...)
    if StopReading then StopReading(...) end
end
TASFunctions.GetZoom = function()
    if GetZoom then return GetZoom() end
    return 12.5
end

-- _tasKeyName: convert KeyCode to string name for settings save
local function _tasKeyName(kc)
    if not kc then return "" end
    return tostring(kc):gsub("Enum.KeyCode.", "")
end

-- CO reference for the stats HUD
local CORef = _S.ClientObjectSync.CO

-- SaveToFile forward reference (defined later in old script, but GUI calls it)
-- The GUI section calls SaveToFile() and ReadButton_MouseButton1Click() etc.
-- These are defined later in old script — they are used in callbacks so no forward ref needed.

-- Keybind shims used by the GUI (will be set after GUI builds)
local Hideuikeybind, Recordkeybind, Pausekeybind, Frozenkeybind
local Goforwardkeybind, Gobackwardskeybind
local Frameadvanceforwardkeybind, Frameadvancebackwardskeybind
local Savekeybind, Readkeybind, Abortkeybind
local movecameraonfroze
local KeyboardOverlay, DisableParticles, DisableLighting, MotionBlurToggle
local KeyboardThemeCombo
local FPSTextbox, TASRecordingFPSTextbox, TeleportTextbox
local RecordedFramesLabel, PressedKeysLabel, WritingPressedKeysLabel
local ColorCodeFrame, CurrentFile, ConnectedLabel, CurrentPlaceIdButton
local WalkSpeedTextbox, JumpPowerTextbox, GravityTextbox, FrictionTextbox, DensityTextbox
local console, ConsoleInput

-- ClearReplayDecodeCache stub
local function ClearReplayDecodeCache() end


-- TASUtilityFunctions: utility stub
local TASUtilityFunctions = {
    RoundNumber = RoundNumber,
}
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
    local alive = table.create(#ThemeBindings)
    for _, b in ipairs(ThemeBindings) do
        local inst = b[1]
        if inst and inst.Parent then
            pcall(function() inst[b[2]] = Theme[b[3]] end)
            alive[#alive + 1] = b
        end
    end
    ThemeBindings = alive
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
    local lastHudState = nil
    local lastHudFloor = nil
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
        if stateStr ~= lastHudState then
            local sc = "#ffffff"
            if stateStr == "Jumping" or stateStr == "Freefall" then sc = "#80ff80"
            elseif stateStr == "Running" then sc = "#ffdc50"
            elseif stateStr == "Climbing" then sc = "#ff9650"
            elseif stateStr == "Dead" then sc = "#ff5050" end
            stateLabel.Text = string.format("State: <font color='%s'>%s</font>", sc, stateStr)
            lastHudState = stateStr
        end
 
        local floorMat = tostring(TASCharacter.Humanoid.FloorMaterial):gsub("Enum.Material.", "")
        if floorMat ~= lastHudFloor then
            floorLabel.Text = string.format("Floor: <font color='#aaaaff'>%s</font>", floorMat)
            lastHudFloor = floorMat
        end
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
        local partCount = (CORef and CORef.GetPartCount) and CORef.GetPartCount() or 0
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
    cfg.Physics = cfg.Physics or {}
    cfg.Physics.SpeedHackEnabled = TASSpeedHack.Enabled == true
    cfg.Physics.SpeedHackSpeed = math.clamp(tonumber(TASSpeedHack.Speed) or 0.5, 0.1, 1)
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
pcall(function() _S.ClientObjectSync.SetCOManipulationEnabled(TASConfig.AllowClientObjectManipulation ~= false) end)
if type(TasSettings.Physics) == "table" then
    if TasSettings.Physics.SpeedHackEnabled ~= nil then TASSpeedHack.Enabled = TasSettings.Physics.SpeedHackEnabled == true end
    if tonumber(TasSettings.Physics.SpeedHackSpeed) then TASSpeedHack.Speed = math.clamp(tonumber(TasSettings.Physics.SpeedHackSpeed), 0.1, 1) end
end
_tasApplySavedThemeAccent(TasSettings)

-- Discord integration is hosted separately in dc.lua.
local TAS_DISCORD_MODULE_URL = "https://raw.githubusercontent.com/yeetinguser/tasability/refs/heads/main/dc.lua"
local TAS_DISCORD_INVITE_FALLBACK = "https://discord.gg/hJGAvDXmjj"
local TAS_DISCORD_MODULE
-- Keep webhook credentials off the client. Use a server/proxy endpoint for logging.
local TAS_WEBHOOK_PROXY_URL = ""

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
    Text = tostring(TASConfig.Version),
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
        if lowerName ~= "settings.json" and (lowerName:sub(-5) == ".json") then
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
                if TASPaths.ReplayPath ~= path then ClearReplayDecodeCache() end
                _S.ReplaySaveCache.Replay = nil
                _S.ReplaySaveCache.Revision = -1
                _S.ReplaySaveCache.Path = nil
                _S.ReplaySaveCache.Encoded = nil
                _S.ReplayPath = path
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
                    local decoded, replayFPS = ReplayDecode(raw, TASPaths.ReplayPath)
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
                ClearReplayDecodeCache()
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
        local emptyReplay = '{"Format":"TAS_REPLAY","Version":4,"Optimizer":"TAS Compact","Codec":"RAW","FPS":' .. tostring(math.max(1, tonumber(TASConfig.TASRecordingFPS) or 1)) .. ',"Binary":"base64","RawBytes":0,"PackedBytes":0,"Frames":0,"Data":""}'
        local okWrite, err = pcall(writefile, path, emptyReplay)
        if okWrite then
            _S.ReplayPath = path
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
        _S.floor = hum and tostring(hum.FloorMaterial):gsub("Enum.Material.", "") or "N/A"
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
            TASPlayerViewerColorHex(Theme.txt_muted), _S.floor,
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
speedHackSec = addSection(physicsPage, "speed hack")
local speedHackControlsWrap
local speedHackSliderFill
local speedHackSliderKnob
local speedHackSliderValueLabel
local speedHackSpeedTextbox
local speedHackTrack
local draggingSpeedHack=false

local function updateSpeedHackSliderVisual(value)
    value=math.clamp(tonumber(value) or 0.5,0.1,1)
    TASSpeedHack.Speed=value
    local alpha=(value-0.1)/0.9
    if speedHackSliderFill then speedHackSliderFill.Size=UDim2.new(alpha,0,1,0) end
    if speedHackSliderKnob then speedHackSliderKnob.Position=UDim2.new(alpha,-5,0.5,-5) end
    if speedHackSliderValueLabel then speedHackSliderValueLabel.Text=string.format("%.2f",value) end
    if speedHackSpeedTextbox and speedHackSpeedTextbox.Value~=string.format("%.2f",value) then speedHackSpeedTextbox.Value=string.format("%.2f",value) end
end

local function setSpeedHackFromPointer(x)
    local width=math.max(1,speedHackTrack.AbsoluteSize.X)
    local alpha=math.clamp((x-speedHackTrack.AbsolutePosition.X)/width,0,1)
    local value=math.floor((0.1+alpha*0.9)*100+0.5)/100
    updateSpeedHackSliderVisual(value)
    QueueSaveTasSettings()
end

addCheckbox(speedHackSec,{Label="Enable Speed Hack",Default=TASSpeedHack.Enabled,Callback=function(self)
    TASSpeedHackSetEnabled(self.Value)
    if speedHackControlsWrap then speedHackControlsWrap.Visible=self.Value==true end
    QueueSaveTasSettings()
end})

local speedHackSliderRow=mk("Frame",{Size=UDim2.new(1,0,0,34),BackgroundTransparency=1,BorderSizePixel=0,Parent=speedHackSec})
mk("TextLabel",{Size=UDim2.new(0.38,0,0,16),BackgroundTransparency=1,Text="Speed",TextColor3=Theme.txt_muted,FontFace=UIFont,TextSize=10,TextXAlignment=Enum.TextXAlignment.Left,Parent=speedHackSliderRow})
speedHackSliderValueLabel=mk("TextLabel",{Size=UDim2.new(0.62,0,0,16),Position=UDim2.fromScale(0.38,0),BackgroundTransparency=1,Text=string.format("%.2f",TASSpeedHack.Speed),TextColor3=Theme.accent,FontFace=UIFontBold,TextSize=10,TextXAlignment=Enum.TextXAlignment.Right,Parent=speedHackSliderRow})
applyTheme(speedHackSliderValueLabel,"TextColor3","accent")
speedHackTrack=mk("Frame",{Size=UDim2.new(1,0,0,6),Position=UDim2.fromOffset(0,22),BackgroundColor3=Theme.bg_deep,BorderSizePixel=2,BorderColor3=Theme.border,Parent=speedHackSliderRow})
applyTheme(speedHackTrack,"BackgroundColor3","bg_deep")
applyTheme(speedHackTrack,"BorderColor3","border")
addStroke(speedHackTrack,"outline",1)
speedHackSliderFill=mk("Frame",{Size=UDim2.new(0,0,1,0),BackgroundColor3=Theme.accent_dim,BorderSizePixel=0,Parent=speedHackTrack})
applyTheme(speedHackSliderFill,"BackgroundColor3","accent_dim")
speedHackSliderKnob=mk("Frame",{Size=UDim2.fromOffset(10,10),Position=UDim2.new(0,-5,0.5,-5),BackgroundColor3=Theme.accent,BorderSizePixel=2,BorderColor3=Theme.border,Parent=speedHackTrack})
applyTheme(speedHackSliderKnob,"BackgroundColor3","accent")
applyTheme(speedHackSliderKnob,"BorderColor3","border")
addStroke(speedHackSliderKnob,"outline",1)
speedHackTrack.InputBegan:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 then draggingSpeedHack=true setSpeedHackFromPointer(TASServices.Mouse.X) end end)
speedHackTrack.InputEnded:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 then draggingSpeedHack=false end end)
TASServices.UserInputService.InputChanged:Connect(function(input) if draggingSpeedHack and input.UserInputType==Enum.UserInputType.MouseMovement then setSpeedHackFromPointer(TASServices.Mouse.X) end end)

speedHackControlsWrap=mk("Frame",{Size=UDim2.new(1,0,0,22),BackgroundTransparency=1,BorderSizePixel=0,Parent=speedHackSec})
speedHackSpeedTextbox=addTextbox(speedHackControlsWrap,{Label="Speed value (0.1 - 1.0)",Value=string.format("%.2f",TASSpeedHack.Speed),Placeholder="0.50",Callback=function(_,v)
    local n=tonumber(v)
    if n then updateSpeedHackSliderVisual(math.clamp(n,0.1,1)) QueueSaveTasSettings() else speedHackSpeedTextbox.Value=string.format("%.2f",TASSpeedHack.Speed) end
end})
speedHackControlsWrap.Visible=TASSpeedHack.Enabled==true
updateSpeedHackSliderVisual(TASSpeedHack.Speed)

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
            if TASSpeedHack.RuntimeApplied then TASSpeedHack.BaseWalkSpeed = n end
            if TASCharacter.Character and TASCharacter.Character:FindFirstChild("Humanoid") and (not TASRuntime.Reading or not AllowChangingPhysics) then
                local target = (TASSpeedHack.RuntimeApplied and TASSpeedHack.Enabled) and (n * TASSpeedHack.Speed) or n
                TASCharacter.Character.Humanoid.WalkSpeed = target
            end
        end
    end})
JumpPowerTextbox = addTextbox(physSec, {Label = "JumpPower", Value = "50", Placeholder = "50",
    Callback = function(_, v)
        local n = tonumber(v)
        if n then
            TASCharacter.DefaultJumpPower = n
            if TASSpeedHack.RuntimeApplied then TASSpeedHack.BaseJumpPower = n end
            if TASCharacter.Character and TASCharacter.Character:FindFirstChild("Humanoid") and (not TASRuntime.Reading or not AllowChangingPhysics) then
                local target = (TASSpeedHack.RuntimeApplied and TASSpeedHack.Enabled) and (n * TASSpeedHack.Speed) or n
                TASCharacter.Character.Humanoid.JumpPower = target
            end
        end
    end})
GravityTextbox = addTextbox(physSec, {Label = "Gravity", Value = "196.2", Placeholder = "196.2",
    Callback = function(_, v)
        local n = tonumber(v)
        if n then
            TASCharacter.DefaultGravity = n
            if TASSpeedHack.RuntimeApplied then TASSpeedHack.BaseGravity = n end
            if not TASRuntime.Reading or not AllowChangingPhysics then
                workspace.Gravity = (TASSpeedHack.RuntimeApplied and TASSpeedHack.Enabled) and (n * TASSpeedHack.Speed * TASSpeedHack.Speed) or n
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

local coSettingsSec = addSection(settingsPage, "Client Object Recording")
local CORecordingRadiusTextbox
local allowClientObjectManipulation = addCheckbox(coSettingsSec, {
    Label = "Allow Client Object Manipulation",
    Default = TASConfig.AllowClientObjectManipulation ~= false,
    Callback = function(self)
        TASConfig.AllowClientObjectManipulation = self.Value == true
        _S.ClientObjectSync.SetCOManipulationEnabled(TASConfig.AllowClientObjectManipulation)
        if not TASConfig.AllowClientObjectManipulation then
            pcall(function()
                if CORef and CORef.ReleaseHeldState then CORef.ReleaseHeldState() end
                if CORef and CORef.RestoreAnchors then CORef.RestoreAnchors() end
                if CORef then
                    CORef._lerpTargets = {}
                    CORef._FullStateCache = nil
                end
            end)
        end
        if CORecordingRadiusTextbox then
            CORecordingRadiusTextbox:SetVisible(TASConfig.AllowClientObjectManipulation)
        end
        QueueSaveTasSettings()
    end,
})

CORecordingRadiusTextbox = addTextbox(coSettingsSec, {
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

-- GUI Functions (updated for fork GUI)
local SetColorCodeFrame
local GetColorCodeFrame
do
    ConsoleMessage = function(...)
        setthreadidentity(8)
        console:AppendText(...)
    end
    TASCharacter.ConsoleMessage = ConsoleMessage

    ConsoleMessage("Tasability loading...")

    SetColorCodeFrame = function(Name)
        pcall(function()
            if ColorCodeFrame then
                ColorCodeFrame.TextColor3 = _S.ColorCodes[Name] or _S.ColorCodes.None
                ColorCodeFrame.Text = "Status: "..(_S.ColorCodes[Name] and Name or "None")
            end
            if StatusPill then
                StatusPill.Text = "■ "..(_S.ColorCodes[Name] and Name or "None")
                StatusPill.TextColor3 = _S.ColorCodes[Name] or Theme.txt_muted
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

local g = getinfo or debug.getinfo
local d = false
local h = {}

local x, y

setthreadidentity(2)

for i, v in getgc(true) do
    if typeof(v) == "table" then
        local a = rawget(v, "Detected")
        local b = rawget(v, "Kill")
    
        if typeof(a) == "function" and not x then
            x = a
            
            local o; o = hookfunction(x, function(c, f, n)
                if c ~= "_" then
                    if d then
                        warn(`Adonis AntiCheat flagged\nMethod: {c}\nInfo: {f}`)
                    end
                end
                
                return true
            end)

            table.insert(h, x)
        end

        if rawget(v, "Variables") and rawget(v, "Process") and typeof(b) == "function" and not y then
            y = b
            local o; o = hookfunction(y, function(f)
                if d then
                    warn(`Adonis AntiCheat tried to kill (fallback): {f}`)
                end
            end)

            table.insert(h, y)
        end
    end
end

local o; o = hookfunction(getrenv().debug.info, newcclosure(function(...)
    local a, f = ...

    if x and a == x then
        if d then
            warn(`zins adonis bypassed`)
        end

        return coroutine.yield(coroutine.running())
    end
    
    return o(...)
end))

setthreadidentity(7)

end



-- Animation Functions
local StopAllAnimations -- StopAllAnimations() -> nil
local Reanimate -- Reanimate(Character) -> nil

local GetAnimationFunctionFromId -- GetAnimationFunctionFromId(Id) -> function
local onDied -- onDied() -> nil
local onRunning -- onRunning(Speed) -> nil
local onJumping -- onJumping() -> nil
local onClimbing -- onClimbing(Speed) -> nil
local onGettingUp -- onGettingUp() -> nil
local onFreeFall -- onFreeFall() -> nil
local onFallingDown -- onFallingDown() -> nil
local onSeated -- onSeated() -> nil
local onPlatformStanding -- onPlatformStanding() -> nil
local onSwimming -- onSwimming() -> nil

local PlayAnimation -- PlayAnimation() -> nil
local setAnimationSpeed -- setAnimationSpeed() -> nil

do
	StopAllAnimations = function()
		for _,v in pairs(_S.Humanoid:GetPlayingAnimationTracks()) do 
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
					if _S.BypassAntiExploit then
						Animate.Disabled = true
						if setparentinternal then
							setparentinternal(Animate, game.Lighting)
						else
							ConsoleMessage("Your exploit does not support setparentinternal, expect animation glitches")
						end
					else
						Animate:Destroy()
					end
					ConsoleMessage("Animate script found and disabled")
					break
				end
			end
		end
		
	
		if not animateFound then
			ConsoleMessage("[WARNING] Animate script not found - animations will be handled manually")
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
			_S.Humanoid = Figure:WaitForChild("Humanoid")

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

			local animator = _S.Humanoid and _S.Humanoid:FindFirstChildOfClass("Animator") or nil
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
				currentAnimInstance = nil
				if (currentAnimKeyframeHandler ~= nil) then
					currentAnimKeyframeHandler:disconnect()
				end
				if (currentAnimTrack ~= nil) then
					currentAnimTrack:Stop()
					currentAnimTrack:Destroy()
					currentAnimTrack = nil
				end
				return oldAnim
			end

			setAnimationSpeed = function(speed)
				if speed ~= currentAnimSpeed then
					currentAnimSpeed = speed
					currentAnimTrack:AdjustSpeed(currentAnimSpeed)
				end
			end

			function keyFrameReachedFunc(frameName)
				if (frameName == "End") then
					local repeatAnim = currentAnim
					if (emoteNames[repeatAnim] ~= nil and emoteNames[repeatAnim] == false) then
						repeatAnim = "idle"
					end
					local animSpeed = currentAnimSpeed
					playAnimation(repeatAnim, 0.0, _S.Humanoid)
					setAnimationSpeed(animSpeed)
				end
			end

			playAnimation = function(animName, transitionTime, humanoid, bypassAnimateDisabled) 
				pcall(function()
					if _S.AnimateDisabled and not bypassAnimateDisabled then
						return
					end
					
					table.insert(_S.AnimationQueue,{animName,transitionTime})
					
					local roll = math.random(1, animTable[animName].totalWeight) 
					local origRoll = roll
					local idx = 1
					while (roll > animTable[animName][idx].weight) do
						roll = roll - animTable[animName][idx].weight
						idx = idx + 1
					end
					local anim = animTable[animName][idx].anim

					if (anim ~= currentAnimInstance) then
						if (currentAnimTrack ~= nil) then
							currentAnimTrack:Stop(transitionTime)
							currentAnimTrack:Destroy()
						end
						currentAnimSpeed = 1.0
						currentAnimTrack = humanoid:LoadAnimation(anim)
						currentAnimTrack.Priority = Enum.AnimationPriority.Core
						currentAnimTrack:Play(transitionTime)
						currentAnim = animName
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
					playToolAnimation(toolAnimName, 0.0, _S.Humanoid)
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
					playAnimation("walk", 0.1, _S.Humanoid)
					if currentAnimInstance and currentAnimInstance.AnimationId == "http://www.roblox.com/asset/?id=180426354" then
						setAnimationSpeed(speed / 14.5)
					end
					pose = "Running"
				else
					if emoteNames[currentAnim] == nil then
						playAnimation("idle", 0.1, _S.Humanoid)
						pose = "Standing"
					end
				end
			end

			onDied = function()
				pose = "Dead"
			end

			onJumping = function()
				playAnimation("jump", 0.1, _S.Humanoid)
				jumpAnimTime = jumpAnimDuration
				pose = "Jumping"
			end

			onClimbing = function(speed)
				playAnimation("climb", 0.1, _S.Humanoid)
				setAnimationSpeed(speed / 12.0)
				pose = "Climbing"
			end

			onGettingUp = function()
				pose = "GettingUp"
			end

			onFreeFall = function()
				if (jumpAnimTime <= 0) then
					playAnimation("fall", fallTransitionTime, _S.Humanoid)
				end
				pose = "FreeFall"
			end

			onFallingDown = function()
				pose = "FallingDown"
			end

			onSeated = function()
				pose = "Seated"
			end

			onPlatformStanding = function()
				pose = "PlatformStanding"
			end

			onSwimming = function(speed)
				if speed > 0 then
					pose = "Running"
				else
					pose = "Standing"
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
					playToolAnimation("toolnone", toolTransitionTime, _S.Humanoid, Enum.AnimationPriority.Idle)
					return
				end
				if (toolAnim == "Slash") then
					playToolAnimation("toolslash", 0, _S.Humanoid, Enum.AnimationPriority.Action)
					return
				end
				if (toolAnim == "Lunge") then
					playToolAnimation("toollunge", 0, _S.Humanoid, Enum.AnimationPriority.Action)
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
				if _S.AnimateDisabled then
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

				if (pose == "FreeFall" and jumpAnimTime <= 0) then
					playAnimation("fall", fallTransitionTime, _S.Humanoid)
				elseif (pose == "Seated") then
					playAnimation("sit", 0.5, _S.Humanoid)
					return
				elseif (pose == "Running") then
					playAnimation("walk", 0.1, _S.Humanoid)
				elseif (pose == "Dead" or pose == "GettingUp" or pose == "FallingDown" or pose == "Seated" or pose == "PlatformStanding") then
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

			_S.Humanoid.Died:connect(function(...)
				if _S.AnimateDisabled then
					return
				end
				onDied(...)
			end)
			_S.Humanoid.Running:connect(function(Speed)
				if _S.AnimateDisabled then
					return
				end
				onRunning(Speed)
			end)
			_S.Humanoid.Jumping:connect(onJumping)
			_S.Humanoid.Climbing:connect(function(Speed)
				if _S.AnimateDisabled then
					return
				end
				onClimbing(Speed)
			end)
			_S.Humanoid.GettingUp:connect(function(...)
				if _S.AnimateDisabled then
					return
				end
				onGettingUp(...)
			end)
			_S.Humanoid.FreeFalling:connect(function(...)
				if _S.AnimateDisabled then
					return
				end
				onFreeFall(...)
			end)
			_S.Humanoid.FallingDown:connect(function(...)
				if _S.AnimateDisabled then
					return
				end
				onFallingDown(...)
			end)
			_S.Humanoid.Seated:connect(function(...)
				if _S.AnimateDisabled then
					return
				end
				onSeated(...)
			end)
			_S.Humanoid.PlatformStanding:connect(function(...)
				if _S.AnimateDisabled then
					return
				end
				onPlatformStanding(...)
			end)
			_S.Humanoid.Swimming:connect(function(...)
				if _S.AnimateDisabled then
					return
				end
				onSwimming(...)
			end)

			game:GetService("Players").LocalPlayer.Chatted:connect(function(msg)
				local emote = ""
				if msg == "/e dance" then
					emote = dances[math.random(1, #dances)]
				elseif (string.sub(msg, 1, 3) == "/e ") then
					emote = string.sub(msg, 4)
				elseif (string.sub(msg, 1, 7) == "/emote ") then
					emote = string.sub(msg, 8)
				end
				
				if (pose == "Standing" and emoteNames[emote] ~= nil) then
					playAnimation(emote, 0.1, _S.Humanoid)
				end
			end)

			playAnimation("idle", 0.1, _S.Humanoid)
			pose = "Standing"

			spawn(function()
				while Figure.Parent ~= nil do
					local _, time = wait(0.1)
					move(time)
				end
			end)
		end 
	end 
end 

-- Camera/Input Functions
local GetZoom -- GetZoom() -> number
local SetZoom -- SetZoom(Zoom) -> nil

local GetShiftLockEnabled -- GetShiftLockEnabled() -> bool
local SetShiftLockEnabled -- SetShiftLockEnabled(Enabled) -> nil

local SetCameraCFrame -- SetCameraCFrame(NewCFrame) -> nil

local BlockInputs -- BlockInputs() -> nil
local UnlockInputs -- UnlockInputs() -> nil

local SetCursorIcon -- SetCursorIcon(Icon) -> nil
local SetCursorSize -- SetCursorSize(Size) -> nil
local SetCursorOffset -- SetCursorOffset(Offset) -> nil
local SetCursor -- SetCursorIcon(CursorName) -> nil

do
	-- Load mouse lock action
	_S.VirtualInputManager:SendKeyEvent(true, 304, false, workspace)
	wait()
	_S.VirtualInputManager:SendKeyEvent(true, 304, false, workspace)
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
		ConsoleMessage(tostring(#ZoomControllers).." ZoomController"..(#ZoomControllers == 1 and "" or "s"))
	end
	GetZoom = function()
		for _,ZoomController in pairs(ZoomControllers) do
			local Zoom = ZoomController:GetCameraToSubjectDistance()
			if Zoom and Zoom ~= 12.5 then
				return Zoom
			end
		end
		return 12.5
	end
	local function SmoothSetZoom(zoom)
	TargetZoom = zoom
end

SetZoom = function(Zoom)
	for _,ZoomController in pairs(ZoomControllers) do
		pcall(function()
			ZoomController:SetCameraToSubjectDistance(Zoom)
		end)
	end
end

	
	GetShiftLockEnabled = function()
		return _S.ShiftLockEnabled
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

	SetShiftLockEnabled = function(Enabled)
		if _S.ShiftLockEnabled ~= Enabled then
			_S.ShiftLockEnabled = Enabled
			if Enabled then
				SetCursor("MouseLockedCursor")
			else
				SetCursor("ArrowFarCursor")
			end
			shiftLock(Enabled)
		end
	end
		
	SetCameraCFrame = function(NewCFrame)
		_S.CameraCFrame = NewCFrame
		workspace.CurrentCamera.CFrame = NewCFrame
	end

	_S.ClientObjectSync.StopPlaybackPauseAnimations = function()
		local HumanoidNow = Character and Character:FindFirstChildOfClass("Humanoid")
		if not HumanoidNow then
			return
		end
		if not _S.ClientObjectSync.PauseAnimationTracks then
			_S.ClientObjectSync.PauseAnimationTracks = {}
			for _,Track in ipairs(HumanoidNow:GetPlayingAnimationTracks()) do
				local Speed = 1
				pcall(function()
					Speed = Track.Speed
				end)
				table.insert(_S.ClientObjectSync.PauseAnimationTracks,{Track = Track,Speed = Speed})
				pcall(function()
					Track:AdjustSpeed(0)
				end)
			end
		else
			for _,Entry in ipairs(_S.ClientObjectSync.PauseAnimationTracks) do
				pcall(function()
					Entry.Track:AdjustSpeed(0)
				end)
			end
		end
	end

	_S.ClientObjectSync.ResumePlaybackPauseAnimations = function()
		for _,Entry in ipairs(_S.ClientObjectSync.PauseAnimationTracks or {}) do
			pcall(function()
				Entry.Track:AdjustSpeed(Entry.Speed or 1)
			end)
		end
		_S.ClientObjectSync.PauseAnimationTracks = nil
	end

	_S.ClientObjectSync.GetPlaybackPauseState = function(HumanoidNow)
		local FrameNow = _S.Reading and _S.ReplayTable and _S.ReplayStorage.Get(_S.ReplayTable,_S.ReplayTableIndex)
		if typeof(FrameNow) == "table" and FrameNow[4] then
			return FrameNow[4]
		end
		local State = HumanoidNow and HumanoidNow:GetState()
		return State and State.Value
	end

	_S.ClientObjectSync.SetPlaybackPausePhysics = function(Enabled)
		local CharacterNow = Character
		local HumanoidNow = _S.Humanoid
		local RootNow = CharacterNow and CharacterNow:FindFirstChild("HumanoidRootPart")
		if not CharacterNow or not HumanoidNow or not RootNow then
			return
		end
		if Enabled then
			local StateValue = _S.ClientObjectSync.GetPlaybackPauseState(HumanoidNow)
			if not _S.ClientObjectSync.PauseSnapshot then
				_S.ClientObjectSync.PauseSnapshot = {
					CFrame = RootNow.CFrame;
					CameraCFrame = workspace.CurrentCamera.CFrame;
					Zoom = GetZoom();
					AutoRotate = HumanoidNow.AutoRotate;
					PlatformStand = HumanoidNow.PlatformStand;
					State = StateValue;
					IsClimbing = StateValue == Enum.HumanoidStateType.Climbing.Value;
				}
			end
			_S.AnimateDisabled = true
			workspace.Gravity = 0
			HumanoidNow.WalkSpeed = 0
			HumanoidNow.JumpPower = 0
			HumanoidNow.PlatformStand = not _S.ClientObjectSync.PauseSnapshot.IsClimbing
			HumanoidNow.AutoRotate = false
			HumanoidNow:Move(Vector3.new(),true)
			if _S.ClientObjectSync.PauseSnapshot.IsClimbing then
				pcall(function()
					HumanoidNow:ChangeState(Enum.HumanoidStateType.Climbing)
				end)
			end
			RootNow.Anchored = true
			RootNow.CFrame = _S.ClientObjectSync.PauseSnapshot.CFrame
			RootNow.Velocity = Vector3.new()
			RootNow.RotVelocity = Vector3.new()
			pcall(function()
				RootNow.AssemblyLinearVelocity = Vector3.new()
				RootNow.AssemblyAngularVelocity = Vector3.new()
			end)
			SetCameraCFrame(_S.ClientObjectSync.PauseSnapshot.CameraCFrame)
			SetZoom(_S.ClientObjectSync.PauseSnapshot.Zoom)
			_S.ClientObjectSync.StopPlaybackPauseAnimations()
		else
			if _S.ClientObjectSync.PauseSnapshot then
				if HumanoidNow then
					HumanoidNow.AutoRotate = _S.ClientObjectSync.PauseSnapshot.AutoRotate
					HumanoidNow.PlatformStand = false
				end
				RootNow.Anchored = false
				RootNow.Velocity = Vector3.new()
				RootNow.RotVelocity = Vector3.new()
				pcall(function()
					RootNow.AssemblyLinearVelocity = Vector3.new()
					RootNow.AssemblyAngularVelocity = Vector3.new()
				end)
			end
			_S.ClientObjectSync.ResumePlaybackPauseAnimations()
			_S.ClientObjectSync.PauseSnapshot = nil
			_S.ClientObjectSync.ResetPlaybackStepTimer()
		end
	end
	
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
	BlockInputs = function()
		-- Do not place a full-screen TextButton over the game while replaying mouse input:
		-- that would swallow MouseEnter/MouseLeave/MouseButton events from the game.
		BlockGui.Enabled = not _S.PlaybackInputs
	end
	UnblockInputs = function()
		BlockGui.Enabled = false
	end
	
	CursorHolder = Instance.new("ScreenGui")
	CursorHolder.Name = "TasabilityCursor"
	CursorHolder.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	CursorHolder.IgnoreGuiInset = true
	CursorHolder.ResetOnSpawn = false
	CursorHolder.DisplayOrder = 10000
	CursorHolder.Parent = _S.Player.PlayerGui
	
	_S.Cursor.Name = "Cursor"
	_S.Cursor.BackgroundTransparency = 1
	_S.Cursor.ZIndex = 10000
	_S.Cursor.Active = false
	_S.Cursor.Parent = CursorHolder
	
	_S.Resolution = workspace.CurrentCamera.ViewportSize
	
	SetCursor = function(CursorName)
		local CursorData = _S.Cursors[CursorName]
		if CursorData then
			_S.CursorIcon = CursorData.Icon
			_S.CursorSize = CursorData.Size
			_S.CursorOffset = CursorData.Offset
		end
	end
	
	-- Initialize cursor
	SetCursor("ArrowFarCursor")
end



-- AHK Functions
local IsInstalled -- IsInstalled() -> bool
local SendSignal -- SendSignal(Signal) -> nil
do
	IsInstalled = function()
		return isfolder(_S.AHKConnectionFolderPath)
	end
	SendSignal = function(Signal)
		if IsInstalled() then
			writefile(_S.AHKConnectionRequestPath,Signal)
		else
			ConsoleMessage("AHK folder not found")
		end
	end
end


_S.ReplayStorage.CodecBuildCodec = function()
local CodecReplayMagic = "TAS\n"
local CodecLegacyReplayMagic = string.char(84,65,83,50,10)
_S.ReplayStorage.CodecReplayMagic = CodecReplayMagic
local CodecFrameFlags = {
	AnimationQueue = 1;
	AnimationSpeed = 2;
	HumanoidState = 4;
	Zoom = 8;
	Pose = 16;
	ShiftLock = 32;
	Mouse = 64;
	Inputs = 128;
	Objects = 256;
	States = 512;
	BeatBlocks = 1024;
}
local CodecScales = {
	CFramePosition = 1000;
	Quaternion = 10000;
	Vector = 1000;
	Number = 1000;
	Mouse = 1;
	Beat = 1000;
}
local CodecObjectVelocityInterval = 10

local function CodecHasFlag(Flags, Flag)
	return _S.floor(Flags / Flag) % 2 >= 1
end

local function CodecRoundInt(Value)
	Value = tonumber(Value) or 0
	if Value >= 0 then
		return _S.floor(Value + 0.5)
	end
	return _S.ceil(Value - 0.5)
end

local function CodecScale(Value, Scale)
	return CodecRoundInt((tonumber(Value) or 0) * Scale)
end

local function CodecUnscale(Value, Scale)
	return (tonumber(Value) or 0) / Scale
end

local function CodecTableHasEntries(Value)
	if type(Value) ~= "table" then
		return false
	end
	for _ in pairs(Value) do
		return true
	end
	return false
end

local function CodecInputsPresent(Value)
	if type(Value) ~= "table" then
		return false
	end
	for Index = 1,2 do
		if CodecTableHasEntries(Value[Index]) then
			return true
		end
	end
	return false
end

local function CodecJsonDecode(String, Default)
	local Success,Result = pcall(function()
		return json.decode(String)
	end)
	if Success and Result ~= nil then
		return Result
	end
	return Default
end

local function CodecNewWriter()
	local Writer = {
		Buffer = {};
		Count = 0;
	}
	function Writer:WriteByte(Value)
		self.Count = self.Count + 1
		self.Buffer[self.Count] = string.char(Value)
	end
	function Writer:WriteBytes(Value)
		if type(Value) == "string" and #Value > 0 then
			self.Count = self.Count + 1
			self.Buffer[self.Count] = Value
		end
	end
	function Writer:WriteUInt(Value)
		Value = _S.max(_S.floor(tonumber(Value) or 0),0)
		while Value >= 128 do
			self:WriteByte((Value % 128) + 128)
			Value = _S.floor(Value / 128)
		end
		self:WriteByte(Value)
	end
	function Writer:WriteInt(Value)
		Value = _S.floor(tonumber(Value) or 0)
		if Value < 0 then
			self:WriteUInt((-Value * 2) - 1)
		else
			self:WriteUInt(Value * 2)
		end
	end
	function Writer:WriteString(Value)
		Value = type(Value) == "string" and Value or ""
		self:WriteUInt(#Value)
		self:WriteBytes(Value)
	end
	function Writer:Result()
		return table.concat(self.Buffer)
	end
	return Writer
end

local function CodecNewReader(String, Index)
	local Reader = {
		String = String;
		Index = Index or 1;
		Length = #String;
	}
	function Reader:ReadByte()
		if self.Index > self.Length then
			return 0
		end
		local Value = string.byte(self.String,self.Index) or 0
		self.Index = self.Index + 1
		return Value
	end
	function Reader:ReadUInt()
		local Result = 0
		local Multiplier = 1
		while true do
			local Byte = self:ReadByte()
			Result = Result + ((Byte % 128) * Multiplier)
			if Byte < 128 then
				break
			end
			Multiplier = Multiplier * 128
		end
		return Result
	end
	function Reader:ReadInt()
		local Value = self:ReadUInt()
		if Value % 2 == 0 then
			return Value / 2
		end
		return -(Value + 1) / 2
	end
	function Reader:ReadString()
		local Length = self:ReadUInt()
		if Length <= 0 then
			return ""
		end
		local Start = self.Index
		local Finish = _S.min(self.Index + Length - 1,self.Length)
		self.Index = Finish + 1
		return string.sub(self.String,Start,Finish)
	end
	return Reader
end

local function CodecQuaternionFromCFrame(Value, Previous)
	Value = type(Value) == "table" and Value or {}
	local R00 = tonumber(Value[4]) or 1
	local R01 = tonumber(Value[5]) or 0
	local R02 = tonumber(Value[6]) or 0
	local R10 = tonumber(Value[7]) or 0
	local R11 = tonumber(Value[8]) or 1
	local R12 = tonumber(Value[9]) or 0
	local R20 = tonumber(Value[10]) or 0
	local R21 = tonumber(Value[11]) or 0
	local R22 = tonumber(Value[12]) or 1
	local Trace = R00 + R11 + R22
	local QX,QY,QZ,QW
	if Trace > 0 then
		local S = math.sqrt(Trace + 1) * 2
		QW = 0.25 * S
		QX = (R21 - R12) / S
		QY = (R02 - R20) / S
		QZ = (R10 - R01) / S
	elseif R00 > R11 and R00 > R22 then
		local S = math.sqrt(_S.max(1 + R00 - R11 - R22,0)) * 2
		if S == 0 then
			return 0,0,0,1
		end
		QW = (R21 - R12) / S
		QX = 0.25 * S
		QY = (R01 + R10) / S
		QZ = (R02 + R20) / S
	elseif R11 > R22 then
		local S = math.sqrt(_S.max(1 + R11 - R00 - R22,0)) * 2
		if S == 0 then
			return 0,0,0,1
		end
		QW = (R02 - R20) / S
		QX = (R01 + R10) / S
		QY = 0.25 * S
		QZ = (R12 + R21) / S
	else
		local S = math.sqrt(_S.max(1 + R22 - R00 - R11,0)) * 2
		if S == 0 then
			return 0,0,0,1
		end
		QW = (R10 - R01) / S
		QX = (R02 + R20) / S
		QY = (R12 + R21) / S
		QZ = 0.25 * S
	end
	local Magnitude = math.sqrt((QX * QX) + (QY * QY) + (QZ * QZ) + (QW * QW))
	if Magnitude <= 0 then
		QX,QY,QZ,QW = 0,0,0,1
	else
		QX,QY,QZ,QW = QX / Magnitude,QY / Magnitude,QZ / Magnitude,QW / Magnitude
	end
	if Previous then
		local PreviousScale = CodecScales.Quaternion
		local Dot = (QX * CodecUnscale(Previous[4],PreviousScale)) + (QY * CodecUnscale(Previous[5],PreviousScale)) + (QZ * CodecUnscale(Previous[6],PreviousScale)) + (QW * CodecUnscale(Previous[7],PreviousScale))
		if Dot < 0 then
			QX,QY,QZ,QW = -QX,-QY,-QZ,-QW
		end
	elseif QW < 0 then
		QX,QY,QZ,QW = -QX,-QY,-QZ,-QW
	end
	return QX,QY,QZ,QW
end

local function CodecCFrameIntegers(Value, Previous)
	Value = type(Value) == "table" and Value or {}
	local QX,QY,QZ,QW = CodecQuaternionFromCFrame(Value,Previous)
	return {
		CodecScale(Value[1],CodecScales.CFramePosition),
		CodecScale(Value[2],CodecScales.CFramePosition),
		CodecScale(Value[3],CodecScales.CFramePosition),
		CodecScale(QX,CodecScales.Quaternion),
		CodecScale(QY,CodecScales.Quaternion),
		CodecScale(QZ,CodecScales.Quaternion),
		CodecScale(QW,CodecScales.Quaternion)
	}
end

local function CodecCFrameFromIntegers(Value)
	local X = CodecUnscale(Value[1],CodecScales.CFramePosition)
	local Y = CodecUnscale(Value[2],CodecScales.CFramePosition)
	local Z = CodecUnscale(Value[3],CodecScales.CFramePosition)
	local QX = CodecUnscale(Value[4],CodecScales.Quaternion)
	local QY = CodecUnscale(Value[5],CodecScales.Quaternion)
	local QZ = CodecUnscale(Value[6],CodecScales.Quaternion)
	local QW = CodecUnscale(Value[7],CodecScales.Quaternion)
	local Magnitude = math.sqrt((QX * QX) + (QY * QY) + (QZ * QZ) + (QW * QW))
	if Magnitude <= 0 then
		QX,QY,QZ,QW = 0,0,0,1
	else
		QX,QY,QZ,QW = QX / Magnitude,QY / Magnitude,QZ / Magnitude,QW / Magnitude
	end
	local XX = QX * QX
	local YY = QY * QY
	local ZZ = QZ * QZ
	local XY = QX * QY
	local XZ = QX * QZ
	local YZ = QY * QZ
	local WX = QW * QX
	local WY = QW * QY
	local WZ = QW * QZ
	return {
		X,Y,Z,
		1 - (2 * (YY + ZZ)),
		2 * (XY - WZ),
		2 * (XZ + WY),
		2 * (XY + WZ),
		1 - (2 * (XX + ZZ)),
		2 * (YZ - WX),
		2 * (XZ - WY),
		2 * (YZ + WX),
		1 - (2 * (XX + YY))
	}
end

local function CodecWriteIntList(Writer, Value, Previous)
	for Index = 1,#Value do
		Writer:WriteInt(Value[Index] - (Previous and Previous[Index] or 0))
	end
end

local function CodecReadIntList(Reader, Count, Previous)
	local Value = {}
	for Index = 1,Count do
		Value[Index] = (Previous and Previous[Index] or 0) + Reader:ReadInt()
	end
	return Value
end

local function CodecWriteCFrame(Writer, Value, Store, Key)
	local Previous = Store[Key]
	local Current = CodecCFrameIntegers(Value,Previous)
	CodecWriteIntList(Writer,Current,Previous)
	Store[Key] = Current
end

local function CodecReadCFrame(Reader, Store, Key)
	local Current = CodecReadIntList(Reader,7,Store[Key])
	Store[Key] = Current
	return CodecCFrameFromIntegers(Current)
end

local function CodecVectorIntegers(Value, Count, Scale)
	Value = type(Value) == "table" and Value or {}
	local Result = {}
	for Index = 1,Count do
		Result[Index] = CodecScale(Value[Index],Scale)
	end
	return Result
end

local function CodecVectorFromIntegers(Value, Count, Scale)
	local Result = {}
	for Index = 1,Count do
		Result[Index] = CodecUnscale(Value[Index],Scale)
	end
	return Result
end

local function CodecWriteVector(Writer, Value, Store, Key, Count, Scale)
	local Previous = Store[Key]
	local Current = CodecVectorIntegers(Value,Count,Scale)
	CodecWriteIntList(Writer,Current,Previous)
	Store[Key] = Current
end

local function CodecReadVector(Reader, Store, Key, Count, Scale)
	local Current = CodecReadIntList(Reader,Count,Store[Key])
	Store[Key] = Current
	return CodecVectorFromIntegers(Current,Count,Scale)
end

local function CodecNewFrameState()
	return {
		ObjectCFrames = {};
		ObjectVelocities = {};
		ObjectAngularVelocities = {};
		ObjectVelocityCounts = {};
	}
end

local function CodecWriteObjectSnapshots(Writer, Snapshots, State)
	Writer:WriteUInt(#Snapshots)
	for _,Snapshot in ipairs(Snapshots) do
		local Id = _S.floor(tonumber(Snapshot[1]) or 0)
		Writer:WriteUInt(Id)
		local Flags = 0
		local Anchored = nil
		if type(Snapshot[3]) == "number" or type(Snapshot[3]) == "boolean" then
			Anchored = Snapshot[3] == true or Snapshot[3] == 1
		elseif Snapshot[5] ~= nil then
			Anchored = Snapshot[5] == true or Snapshot[5] == 1
		end
		if Anchored ~= nil then
			Flags = Flags + 1
			if Anchored then
				Flags = Flags + 2
			end
		end
		local HasLinearVelocity = type(Snapshot[3]) == "table"
		local HasAngularVelocity = type(Snapshot[4]) == "table"
		if HasLinearVelocity or HasAngularVelocity then
			local VelocityCount = (State.ObjectVelocityCounts[Id] or 0) + 1
			State.ObjectVelocityCounts[Id] = VelocityCount
			if VelocityCount == 1 or VelocityCount % CodecObjectVelocityInterval == 0 then
				if HasLinearVelocity then
					Flags = Flags + 4
				end
				if HasAngularVelocity then
					Flags = Flags + 8
				end
			end
		end
		Writer:WriteUInt(Flags)
		CodecWriteCFrame(Writer,Snapshot[2],State.ObjectCFrames,Id)
		if CodecHasFlag(Flags,4) then
			CodecWriteVector(Writer,Snapshot[3],State.ObjectVelocities,Id,3,CodecScales.Vector)
		end
		if CodecHasFlag(Flags,8) then
			CodecWriteVector(Writer,Snapshot[4],State.ObjectAngularVelocities,Id,3,CodecScales.Vector)
		end
	end
end

local function CodecReadObjectSnapshots(Reader, State)
	local Count = Reader:ReadUInt()
	if Count <= 0 then
		return nil
	end
	local Snapshots = {}
	for Index = 1,Count do
		local Id = Reader:ReadUInt()
		local Flags = Reader:ReadUInt()
		local Snapshot = {
			Id,
			CodecReadCFrame(Reader,State.ObjectCFrames,Id)
		}
		if CodecHasFlag(Flags,4) then
			Snapshot[3] = CodecReadVector(Reader,State.ObjectVelocities,Id,3,CodecScales.Vector)
			if CodecHasFlag(Flags,8) then
				Snapshot[4] = CodecReadVector(Reader,State.ObjectAngularVelocities,Id,3,CodecScales.Vector)
			end
			if CodecHasFlag(Flags,1) then
				Snapshot[5] = CodecHasFlag(Flags,2) and 1 or 0
			end
		elseif CodecHasFlag(Flags,1) then
			Snapshot[3] = CodecHasFlag(Flags,2) and 1 or 0
		end
		Snapshots[Index] = Snapshot
	end
	return Snapshots
end

local function CodecWriteStateSnapshots(Writer, Snapshots)
	Writer:WriteUInt(#Snapshots)
	for _,Snapshot in ipairs(Snapshots) do
		Writer:WriteUInt(_S.floor(tonumber(Snapshot[1]) or 0))
		Writer:WriteUInt((Snapshot[2] == true or Snapshot[2] == 1) and 1 or 0)
	end
end

local function CodecReadStateSnapshots(Reader)
	local Count = Reader:ReadUInt()
	if Count <= 0 then
		return nil
	end
	local Snapshots = {}
	for Index = 1,Count do
		Snapshots[Index] = {Reader:ReadUInt(),Reader:ReadUInt()}
	end
	return Snapshots
end

local function CodecWriteBeatBlockSnapshots(Writer, Snapshots)
	Writer:WriteUInt(#Snapshots)
	for _,Snapshot in ipairs(Snapshots) do
		local Flags = 0
		if type(Snapshot[2]) == "number" then
			Flags = Flags + 1
		end
		if Snapshot[3] ~= nil then
			Flags = Flags + 2
			if Snapshot[3] == true or Snapshot[3] == 1 then
				Flags = Flags + 4
			end
		end
		if type(Snapshot[4]) == "table" then
			Flags = Flags + 8
		end
		Writer:WriteUInt(_S.floor(tonumber(Snapshot[1]) or 0))
		Writer:WriteUInt(Flags)
		if CodecHasFlag(Flags,1) then
			Writer:WriteInt(CodecScale(Snapshot[2],CodecScales.Beat))
		end
		if CodecHasFlag(Flags,8) then
			for Index = 1,3 do
				Writer:WriteInt(CodecScale(Snapshot[4][Index],CodecScales.Beat))
			end
		end
	end
end

local function CodecReadBeatBlockSnapshots(Reader)
	local Count = Reader:ReadUInt()
	if Count <= 0 then
		return nil
	end
	local Snapshots = {}
	for Index = 1,Count do
		local Id = Reader:ReadUInt()
		local Flags = Reader:ReadUInt()
		local Snapshot = {Id}
		if CodecHasFlag(Flags,1) then
			Snapshot[2] = CodecUnscale(Reader:ReadInt(),CodecScales.Beat)
		end
		if CodecHasFlag(Flags,2) then
			Snapshot[3] = CodecHasFlag(Flags,4) and 1 or 0
		end
		if CodecHasFlag(Flags,8) then
			Snapshot[4] = {
				CodecUnscale(Reader:ReadInt(),CodecScales.Beat),
				CodecUnscale(Reader:ReadInt(),CodecScales.Beat),
				CodecUnscale(Reader:ReadInt(),CodecScales.Beat)
			}
		end
		Snapshots[Index] = Snapshot
	end
	return Snapshots
end

local function CodecEncodeFrame(Writer, Frame, State)
	Frame = type(Frame) == "table" and Frame or {}
	local Flags = 0
	_S.AnimationQueue = Frame[2]
	if CodecTableHasEntries(_S.AnimationQueue) then
		Flags = Flags + CodecFrameFlags.AnimationQueue
	end
	local AnimationSpeed = CodecScale(Frame[3],CodecScales.Number)
	if State.AnimationSpeed ~= AnimationSpeed then
		Flags = Flags + CodecFrameFlags.AnimationSpeed
	end
	local HumanoidState = _S.floor(tonumber(Frame[4]) or 0)
	if State.HumanoidState ~= HumanoidState then
		Flags = Flags + CodecFrameFlags.HumanoidState
	end
	local Zoom = CodecScale(Frame[8],CodecScales.Number)
	if State.Zoom ~= Zoom then
		Flags = Flags + CodecFrameFlags.Zoom
	end
	local Pose = type(Frame[9]) == "string" and Frame[9] or ""
	if State.Pose ~= Pose then
		Flags = Flags + CodecFrameFlags.Pose
	end
	local ShiftLock = (Frame[10] == true or Frame[10] == 1) and 1 or 0
	if State.ShiftLock ~= ShiftLock then
		Flags = Flags + CodecFrameFlags.ShiftLock
	end
	_S.Mouse = CodecVectorIntegers(Frame[11],2,CodecScales.Mouse)
	local PreviousMouse = State.Mouse
	if not PreviousMouse or PreviousMouse[1] ~= _S.Mouse[1] or PreviousMouse[2] ~= _S.Mouse[2] then
		Flags = Flags + CodecFrameFlags.Mouse
	end
	local Inputs = Frame[12]
	if CodecInputsPresent(Inputs) then
		Flags = Flags + CodecFrameFlags.Inputs
	end
	if CodecTableHasEntries(Frame[13]) then
		Flags = Flags + CodecFrameFlags.Objects
	end
	if CodecTableHasEntries(Frame[14]) then
		Flags = Flags + CodecFrameFlags.States
	end
	if CodecTableHasEntries(Frame[15]) then
		Flags = Flags + CodecFrameFlags.BeatBlocks
	end
	Writer:WriteUInt(Flags)
	CodecWriteCFrame(Writer,Frame[1],State,"RootCFrame")
	CodecWriteVector(Writer,Frame[5],State,"RootVelocity",3,CodecScales.Vector)
	CodecWriteVector(Writer,Frame[6],State,"RootRotVelocity",3,CodecScales.Vector)
	CodecWriteCFrame(Writer,Frame[7],State,"CameraCFrame")
	if CodecHasFlag(Flags,CodecFrameFlags.AnimationQueue) then
		Writer:WriteString(json.encode(_S.AnimationQueue))
	end
	if CodecHasFlag(Flags,CodecFrameFlags.AnimationSpeed) then
		Writer:WriteInt(AnimationSpeed)
		State.AnimationSpeed = AnimationSpeed
	end
	if CodecHasFlag(Flags,CodecFrameFlags.HumanoidState) then
		Writer:WriteUInt(HumanoidState)
		State.HumanoidState = HumanoidState
	end
	if CodecHasFlag(Flags,CodecFrameFlags.Zoom) then
		Writer:WriteInt(Zoom)
		State.Zoom = Zoom
	end
	if CodecHasFlag(Flags,CodecFrameFlags.Pose) then
		Writer:WriteString(Pose)
		State.Pose = Pose
	end
	if CodecHasFlag(Flags,CodecFrameFlags.ShiftLock) then
		Writer:WriteUInt(ShiftLock)
		State.ShiftLock = ShiftLock
	end
	if CodecHasFlag(Flags,CodecFrameFlags.Mouse) then
		CodecWriteIntList(Writer,_S.Mouse,PreviousMouse)
		State.Mouse = _S.Mouse
	end
	if CodecHasFlag(Flags,CodecFrameFlags.Inputs) then
		Writer:WriteString(json.encode(Inputs))
	end
	if CodecHasFlag(Flags,CodecFrameFlags.Objects) then
		CodecWriteObjectSnapshots(Writer,Frame[13],State)
	end
	if CodecHasFlag(Flags,CodecFrameFlags.States) then
		CodecWriteStateSnapshots(Writer,Frame[14])
	end
	if CodecHasFlag(Flags,CodecFrameFlags.BeatBlocks) then
		CodecWriteBeatBlockSnapshots(Writer,Frame[15])
	end
end

local function CodecDecodeFrame(Reader, State)
	local Flags = Reader:ReadUInt()
	local Frame = {}
	Frame[1] = CodecReadCFrame(Reader,State,"RootCFrame")
	Frame[5] = CodecReadVector(Reader,State,"RootVelocity",3,CodecScales.Vector)
	Frame[6] = CodecReadVector(Reader,State,"RootRotVelocity",3,CodecScales.Vector)
	Frame[7] = CodecReadCFrame(Reader,State,"CameraCFrame")
	if CodecHasFlag(Flags,CodecFrameFlags.AnimationQueue) then
		Frame[2] = CodecJsonDecode(Reader:ReadString(),{})
	else
		Frame[2] = {}
	end
	if CodecHasFlag(Flags,CodecFrameFlags.AnimationSpeed) then
		State.AnimationSpeed = Reader:ReadInt()
	end
	Frame[3] = CodecUnscale(State.AnimationSpeed or CodecScale(1,CodecScales.Number),CodecScales.Number)
	if CodecHasFlag(Flags,CodecFrameFlags.HumanoidState) then
		State.HumanoidState = Reader:ReadUInt()
	end
	Frame[4] = State.HumanoidState or 0
	if CodecHasFlag(Flags,CodecFrameFlags.Zoom) then
		State.Zoom = Reader:ReadInt()
	end
	Frame[8] = CodecUnscale(State.Zoom or 0,CodecScales.Number)
	if CodecHasFlag(Flags,CodecFrameFlags.Pose) then
		State.Pose = Reader:ReadString()
	end
	Frame[9] = State.Pose or ""
	if CodecHasFlag(Flags,CodecFrameFlags.ShiftLock) then
		State.ShiftLock = Reader:ReadUInt()
	end
	Frame[10] = State.ShiftLock or 0
	if CodecHasFlag(Flags,CodecFrameFlags.Mouse) then
		State.Mouse = CodecReadIntList(Reader,2,State.Mouse)
	end
	Frame[11] = CodecVectorFromIntegers(State.Mouse or {0,0},2,CodecScales.Mouse)
	if CodecHasFlag(Flags,CodecFrameFlags.Inputs) then
		Frame[12] = CodecJsonDecode(Reader:ReadString(),{{},{}})
	else
		Frame[12] = {{},{}}
	end
	if CodecHasFlag(Flags,CodecFrameFlags.Objects) then
		Frame[13] = CodecReadObjectSnapshots(Reader,State)
	end
	if CodecHasFlag(Flags,CodecFrameFlags.States) then
		Frame[14] = CodecReadStateSnapshots(Reader)
	end
	if CodecHasFlag(Flags,CodecFrameFlags.BeatBlocks) then
		Frame[15] = CodecReadBeatBlockSnapshots(Reader)
	end
	return Frame
end

_S.ReplayStorage.CodecReplayEncode = function(Replay)
	local Count = _S.ReplayStorage.Length(Replay)
	local ChunkSize = Replay.ChunkSize or _S.max(_S.floor((_S.ClientObjectSync.TASFPS or 60) * _S.ReplayStorage.ChunkSeconds + 0.5),1)
	local Writer = CodecNewWriter()
	Writer:WriteBytes(CodecReplayMagic)
	Writer:WriteUInt(Count)
	Writer:WriteUInt(ChunkSize)
	Writer:WriteString(json.encode({
		ObjectSync = _S.ClientObjectSync.Registry;
		ObjectStateSync = _S.ClientObjectSync.StateRegistry;
		ObjectSyncFormat = 2;
		ObjectSyncRadius = _S.ClientObjectSync.Radius;
		Scales = CodecScales;
	}))
	local State = CodecNewFrameState()
	for Index = 1,Count do
		CodecEncodeFrame(Writer,_S.ReplayStorage.Get(Replay,Index),State)
	end
	return Writer:Result()
end

_S.ReplayStorage.CodecReplayDecode = function(String)
	if type(String) ~= "string" or #String <= #CodecReplayMagic then
		_S.ClientObjectSync.ResetRegistry()
		return nil
	end
	local MagicLength = #CodecReplayMagic
	if string.sub(String,1,#CodecReplayMagic) == CodecReplayMagic then
		MagicLength = #CodecReplayMagic
	elseif string.sub(String,1,#CodecLegacyReplayMagic) == CodecLegacyReplayMagic then
		MagicLength = #CodecLegacyReplayMagic
	else
		ConsoleMessage("This TAS file uses a different format")
		_S.ClientObjectSync.ResetRegistry()
		return nil
	end
	local Reader = CodecNewReader(String,MagicLength + 1)
	local FrameCount = Reader:ReadUInt()
	local ChunkSize = _S.max(Reader:ReadUInt(),1)
	local Header = CodecJsonDecode(Reader:ReadString(),{})
	_S.ClientObjectSync.LoadRegistry(Header.ObjectSync,Header.ObjectStateSync)
	local Replay = _S.ReplayStorage.New()
	Replay.ChunkSize = ChunkSize
	Replay.Chunks = {}
	Replay.EncodedChunks = {}
	Replay.Count = FrameCount
	local State = CodecNewFrameState()
	for Index = 1,FrameCount do
		local ChunkIndex = _S.floor((Index - 1) / ChunkSize) + 1
		local FrameIndex = ((Index - 1) % ChunkSize) + 1
		Replay.Chunks[ChunkIndex] = Replay.Chunks[ChunkIndex] or {}
		Replay.Chunks[ChunkIndex][FrameIndex] = CodecDecodeFrame(Reader,State)
	end
	return Replay
end

-- File format v4: JSON container + optional LZ4 around the existing binary TAS codec.
-- The replay codec itself is intentionally unchanged so CFrame/camera playback stays compatible.
local ReplayFileFormat = "TAS_REPLAY"
local ReplayFileVersion = 4
local ReplayOptimizerName = "TAS Compact"
local Base64Alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

local function Base64Encode(Data)
	if type(Data) ~= "string" or #Data == 0 then
		return ""
	end
	local Out = {}
	local OutIndex = 0
	local Length = #Data
	for Index = 1,Length,3 do
		local A = string.byte(Data,Index) or 0
		local B = string.byte(Data,Index + 1)
		local C = string.byte(Data,Index + 2)
		local Triple = A * 65536 + (B or 0) * 256 + (C or 0)
		OutIndex = OutIndex + 1
		Out[OutIndex] = Base64Alphabet:sub(_S.floor(Triple / 262144) % 64 + 1, _S.floor(Triple / 262144) % 64 + 1)
		OutIndex = OutIndex + 1
		Out[OutIndex] = Base64Alphabet:sub(_S.floor(Triple / 4096) % 64 + 1, _S.floor(Triple / 4096) % 64 + 1)
		OutIndex = OutIndex + 1
		Out[OutIndex] = B and Base64Alphabet:sub(_S.floor(Triple / 64) % 64 + 1, _S.floor(Triple / 64) % 64 + 1) or "="
		OutIndex = OutIndex + 1
		Out[OutIndex] = C and Base64Alphabet:sub(Triple % 64 + 1, Triple % 64 + 1) or "="
	end
	return table.concat(Out)
end

local function Base64Decode(Data)
	if type(Data) ~= "string" or Data == "" then
		return ""
	end
	Data = Data:gsub("%s+", "")
	if #Data % 4 ~= 0 then
		return nil, "Invalid base64 length"
	end
	local Lookup = {}
	for Index = 1,#Base64Alphabet do
		Lookup[Base64Alphabet:sub(Index,Index)] = Index - 1
	end
	local Out = {}
	local OutIndex = 0
	for Index = 1,#Data,4 do
		local A = Lookup[Data:sub(Index,Index)]
		local B = Lookup[Data:sub(Index + 1,Index + 1)]
		local CChar = Data:sub(Index + 2,Index + 2)
		local DChar = Data:sub(Index + 3,Index + 3)
		local C = CChar == "=" and 0 or Lookup[CChar]
		local D = DChar == "=" and 0 or Lookup[DChar]
		if A == nil or B == nil or C == nil or D == nil then
			return nil, "Invalid base64 data"
		end
		local Triple = A * 262144 + B * 4096 + C * 64 + D
		OutIndex = OutIndex + 1
		Out[OutIndex] = string.char(_S.floor(Triple / 65536) % 256)
		if CChar ~= "=" then
			OutIndex = OutIndex + 1
			Out[OutIndex] = string.char(_S.floor(Triple / 256) % 256)
		end
		if DChar ~= "=" then
			OutIndex = OutIndex + 1
			Out[OutIndex] = string.char(Triple % 256)
		end
	end
	return table.concat(Out)
end

_S.ReplayStorage._TryLZ4Compress = function(Data)
	if type(Data) ~= "string" or #Data == 0 then return nil end
	local Compressors = {
		function() return type(lz4compress) == "function" and lz4compress(Data) or nil end,
		function() return type(crypt) == "table" and type(crypt.lz4compress) == "function" and crypt.lz4compress(Data) or nil end,
		function() return type(syn) == "table" and type(syn.lz4compress) == "function" and syn.lz4compress(Data) or nil end,
	}
	for _,Fn in ipairs(Compressors) do
		local Ok,Result = pcall(Fn)
		if Ok and type(Result) == "string" and #Result > 0 and #Result < #Data then
			return Result
		end
	end
	return nil
end

_S.ReplayStorage._TryLZ4Decompress = function(Data, Size)
	if type(Data) ~= "string" then return nil end
	local Decompressors = {
		function() return type(lz4decompress) == "function" and lz4decompress(Data,Size) or nil end,
		function() return type(crypt) == "table" and type(crypt.lz4decompress) == "function" and crypt.lz4decompress(Data,Size) or nil end,
		function() return type(syn) == "table" and type(syn.lz4decompress) == "function" and syn.lz4decompress(Data,Size) or nil end,
	}
	for _,Fn in ipairs(Decompressors) do
		local Ok,Result = pcall(Fn)
		if Ok and type(Result) == "string" then return Result end
	end
	return nil
end

-- Pure-Luau fallback compressor used when the executor does not expose LZ4.
-- Format: \"RC1\" + packets. High bit set = repeated byte run; otherwise literal run.
_S.ReplayStorage._RLECompress = function(Data)
	if type(Data) ~= "string" or #Data == 0 then
		return Data
	end
	local Out = {"RC1"}
	local OutIndex = 1
	local Length = #Data
	local Index = 1
	while Index <= Length do
		local Byte = string.byte(Data,Index)
		local RunEnd = Index + 1
		while RunEnd <= Length and string.byte(Data,RunEnd) == Byte and (RunEnd - Index) < 127 do
			RunEnd = RunEnd + 1
		end
		local RunLength = RunEnd - Index
		if RunLength >= 3 then
			OutIndex = OutIndex + 1
			Out[OutIndex] = string.char(128 + RunLength, Byte)
			Index = RunEnd
		else
			local LiteralStart = Index
			local LiteralLength = 0
			while Index <= Length and LiteralLength < 127 do
				local B = string.byte(Data,Index)
				local Next = Index + 1
				while Next <= Length and string.byte(Data,Next) == B and (Next - Index) < 3 do
					Next = Next + 1
				end
				local Candidate = Next - Index
				if Candidate >= 3 then
					break
				end
				Index = Next
				LiteralLength = Index - LiteralStart
			end
			if LiteralLength <= 0 then
				LiteralLength = _S.min(127, Length - LiteralStart + 1)
				Index = LiteralStart + LiteralLength
			end
			OutIndex = OutIndex + 1
			Out[OutIndex] = string.char(LiteralLength) .. string.sub(Data,LiteralStart,LiteralStart + LiteralLength - 1)
		end
	end
	return table.concat(Out)
end

_S.ReplayStorage._RLEDecompress = function(Data)
	if type(Data) ~= "string" or #Data < 3 or string.sub(Data,1,3) ~= "RC1" then
		return nil
	end
	local Out = {}
	local OutIndex = 0
	local Index = 4
	local Length = #Data
	while Index <= Length do
		local Token = string.byte(Data,Index)
		Index = Index + 1
		if Token >= 128 then
			local Count = Token - 128
			if Count < 3 or Index > Length then return nil end
			local Byte = string.byte(Data,Index)
			Index = Index + 1
			OutIndex = OutIndex + 1
			Out[OutIndex] = string.rep(string.char(Byte),Count)
		else
			local Count = Token
			if Count < 1 or Index + Count - 1 > Length then return nil end
			OutIndex = OutIndex + 1
			Out[OutIndex] = string.sub(Data,Index,Index + Count - 1)
			Index = Index + Count
		end
	end
	return table.concat(Out)
end

_S.ReplayStorage.EncodeFile = function(Replay)
	local Packed = _S.ReplayStorage.CodecReplayEncode(Replay)
	local Candidates = {{Name = "RAW", Data = Packed}}
	local LZ4 = _S.ReplayStorage._TryLZ4Compress(Packed)
	if LZ4 then
		Candidates[#Candidates + 1] = {Name = "LZ4", Data = LZ4}
	end
	local RLE = _S.ReplayStorage._RLECompress(Packed)
	if type(RLE) == "string" and #RLE < #Packed then
		Candidates[#Candidates + 1] = {Name = "RLE", Data = RLE}
	end
	local Best = Candidates[1]
	for Index = 2,#Candidates do
		if #Candidates[Index].Data < #Best.Data then
			Best = Candidates[Index]
		end
	end
	local Stored = Best.Data
	local CodecName = Best.Name
	local Payload = {
		Format = ReplayFileFormat;
		Version = ReplayFileVersion;
		Optimizer = ReplayOptimizerName;
		Codec = CodecName;
		FPS = _S.max(tonumber(_S.ClientObjectSync.TASFPS) or 60,1);
		Frames = _S.ReplayStorage.Length(Replay);
		Binary = "base64";
		RawBytes = #Packed;
		PackedBytes = #Stored;
		Data = Base64Encode(Stored);
	}
	return json.encode(Payload)
end

_S.ReplayStorage.DecodeFile = function(String)
	if type(String) ~= "string" then return nil end
	local FirstChar = String:match("^%s*(.)")
	if FirstChar == "{" then
		local Payload = CodecJsonDecode(String,nil)
		if type(Payload) ~= "table" or Payload.Format ~= ReplayFileFormat then
			ConsoleMessage("This JSON file is not a TAS replay")
			return nil
		end
		local Stored, Error = Base64Decode(Payload.Data or "")
		if not Stored then
			ConsoleMessage("Replay JSON decode failed: "..tostring(Error))
			return nil
		end
		local Packed = Stored
		if Payload.Codec == "LZ4" then
			Packed = _S.ReplayStorage._TryLZ4Decompress(Stored, tonumber(Payload.RawBytes) or 0)
			if not Packed then
				ConsoleMessage("LZ4 replay decompression is unavailable in this executor")
				return nil
			end
		elseif Payload.Codec == "RLE" then
			Packed = _S.ReplayStorage._RLEDecompress(Stored)
			if not Packed then
				ConsoleMessage("RLE replay decompression failed")
				return nil
			end
		end
		local Replay = _S.ReplayStorage.CodecReplayDecode(Packed)
		return Replay, tonumber(Payload.FPS)
	end
	-- Backward compatibility: older .tas files still use the binary codec directly.
	return _S.ReplayStorage.CodecReplayDecode(String)
end
end -- close ReplayStorage.CodecBuildCodec
_S.ReplayStorage.CodecBuildCodec()
_S.ReplayStorage.CodecBuildCodec = nil

local Freeze -- Defined earlier so it can be used in replay functions


-- Replay Functions
local ReplayEncode -- ReplayEncode(Table) -> string
local RecordReplay -- RecordReplay() -> nil [Event]
local StartRecording -- StartRecording() -> nil
local StopRecording -- StopRecording() -> nil
local SaveRecording -- SaveRecording() -> nil
local DiscardRecording -- DiscardRecording() -> nil

local StartReading -- StartReading() -> nil

local GetCheckpoint -- GetCheckpoint(CheckpointNumber?) -> number
local SetCheckpoint -- SetCheckpoint(FrameIndex?) -> nil

local GotoFrame -- GotoFrame(Index) -> nil
do
	GetReplayFile = function()
		if not isfolder(string.split(_S.FolderPath,"/")[1]) then makefolder(string.split(_S.FolderPath,"/")[1]) end
		if not isfolder(_S.FolderPath) then makefolder(_S.FolderPath) end
		if not _S.ReplayPath or not isfile(_S.ReplayPath) then return nil end
		return readfile(_S.ReplayPath)
	end

	ReplayEncode = function(Table)
		ConsoleMessage("Encoding "..tostring(_S.ReplayStorage.Length(Table)).." frames")
		local StartTick = tick()
		local Encoded = _S.ReplayStorage.EncodeFile(Table)
		ConsoleMessage("Done encoding in",RoundNumber(tick()-StartTick,2),"seconds")
		return Encoded
	end
	ReplayDecode = function(String)
		if type(String) ~= "string" or #String <= 0 then
			ConsoleMessage("Nothing to read")
			_S.ClientObjectSync.ResetRegistry()
			return
		end
		ConsoleMessage("Decoding "..tostring(#String).." characters")
		local StartTick = tick()
		local Decoded, SourceFPS = _S.ReplayStorage.DecodeFile(String)
		ConsoleMessage("Done decoding in",RoundNumber(tick()-StartTick,2),"seconds")
		return Decoded, SourceFPS
	end
	
	
	RecordReplay = function()
		ConsoleMessage("Waiting for input")
		if _S.Writing then
			ConsoleMessage("Recording stopped")
			StopRecording()
			return
		end
		SetColorCodeFrame("WaitingForInput")
		WaitForInput()
		StartRecording()
		ConsoleMessage("Recording started")
	end
	StartRecording = function()
		if not _S.Reading then
			if _S.RecordingTable.FrameCount <= 0 then
				_S.RecordingTable.StartFrame = _S.ReplayStorage.Length(_S.ReplayTable)
			end
			if _S.ClientObjectSync.Enabled ~= false and _S.ClientObjectSync.COManipulation and _S.ClientObjectSync.COManipulation.Enabled ~= false then
				_S.ClientObjectSync.Scan(true)
			end
			_S.ClientObjectSync.ResetRecordingStepTimer()
			SetColorCodeFrame("Recording")
			_S.Writing = true
		end
	end
	StopRecording = function()
		if not _S.Reading then
			_S.Writing = false
		end
	end
	
	SaveToFile = function()
		if type(_S.ReplayTable) ~= "table" then
			return false
		end

		if string.lower(string.sub(_S.ReplayPath,-5)) ~= ".json" then
			ConsoleMessage("Only .json replay files can be saved")
			return false
		end

		if not _S.ReplayPath or not isfile(_S.ReplayPath) or string.lower(string.sub(_S.ReplayPath,-5)) ~= ".json" then
			ConsoleMessage("Select or create a .json replay file before saving")
			return false
		end

		local Revision = tonumber(_S.ReplayTable.Revision) or 0
		if _S.ReplaySaveCache.Replay == _S.ReplayTable and _S.ReplaySaveCache.Revision == Revision and _S.ReplaySaveCache.Path == _S.ReplayPath and _S.ReplaySaveCache.Encoded and isfile(_S.ReplayPath) then
			return true
		end

		local ReplayEncoded = ReplayEncode(_S.ReplayTable)
		local Success, Error = pcall(writefile,_S.ReplayPath,ReplayEncoded)
		if not Success then
			ConsoleMessage("Save failed: "..tostring(Error))
			return false
		end
		_S.ReplaySaveCache.Replay = _S.ReplayTable
		_S.ReplaySaveCache.Revision = Revision
		_S.ReplaySaveCache.Path = _S.ReplayPath
		_S.ReplaySaveCache.Encoded = ReplayEncoded
		return true
	end
	
	SaveRecording = function()
		if _S.RecordingTable.FrameCount > 0 then
			_S.ClientObjectSync.FlushRecordingBufferToReplay()
			ConsoleMessage("Saved")
		end
	end
	DiscardRecording = function()
		if _S.RecordingTable.FrameCount > 0 then
			_S.ReplayStorage.Truncate(_S.ReplayTable,_S.RecordingTable.StartFrame or _S.ReplayStorage.Length(_S.ReplayTable))
			_S.ClientObjectSync.ResetRecordingBuffer()
			ConsoleMessage("Discarded")
		end
	end
	ClearCurrentTAS = function()
		if _S.Writing then
			StopRecording()
		end
		if _S.Reading and StopReading then
			pcall(StopReading)
		end
		_S.Writing = false
		_S.Reading = false
		_S.Paused = false
		_S.ClientObjectSync.SetPlaybackPausePhysics(false)
		_S.ClientObjectSync.ReleasePlaybackInputs(true)
		_S.Frozen = false
		_S.SeekDirection = 0
		_S.ReplayTableIndex = 0
		_S.FreezeFrame = 1
		_S.ReplayTable = _S.ReplayStorage.New()
		_S.ReplaySaveCache.Replay = nil
		_S.ReplaySaveCache.Revision = -1
		_S.ReplaySaveCache.Path = nil
		_S.ReplaySaveCache.Encoded = nil
		_S.ClientObjectSync.ResetRecordingBuffer()
		_S.ClientObjectSync.ResetRegistry()
		_S.ClientObjectSync.ResetReplayInputDisplay()
		_S.ClientObjectSync.ClearRecordingFrameQueues()
		workspace.Gravity = _S.DefaultGravity
		if Character and Character:FindFirstChild("Humanoid") then
			Character.Humanoid.PlatformStand = false
			Character.Humanoid.JumpPower = _S.DefaultJumpPower
			Character.Humanoid.WalkSpeed = _S.DefaultWalkSpeed
		end
		SetColorCodeFrame("Idle")
		ConsoleMessage("Cleared TAS")
	end
	StartReading = function()
		if not _S.Reading then
			if _S.Writing then
				StopRecording()
				SaveRecording()
			end
			_S.Paused = false
			_S.ClientObjectSync.SetPlaybackPausePhysics(false)
			_S.ClientObjectSync.ReleasePlaybackInputs(true)
			if not _S.ReplayPath or not isfile(_S.ReplayPath) then
				ConsoleMessage("Select a replay file first")
				return
			end
			SaveToFile()
			local ReplayRaw = GetReplayFile()
			if not ReplayRaw then
				ConsoleMessage("Replay file is unavailable")
				return
			end
			_S.ReplayTable = ReplayDecode(ReplayRaw) -- Decode replay from file
			local ReplayReady,ReplayReason = _S.ReplayStorage.WaitUntilDecoded(_S.ReplayTable)
			if ReplayReady then
				-- Decoding successful
				Freeze(false) -- Unfreeze
				_S.AnimateDisabled = true -- Disable fake animate script
				Workspace.Gravity = 0
				if Character and Character:FindFirstChild("Humanoid") then
					Character.Humanoid.JumpPower = 0
					Character.Humanoid.WalkSpeed = 0
					Character.Humanoid.PlatformStand = true
				end
				local animScript = findAnimateScript and findAnimateScript(Character)
				if animScript then
					animScript.Disabled = true
				end
				_S.ReplayTableIndex = 1
				_S.ClientObjectSync.ResetPlaybackStepTimer()
				BlockInputs() -- Disable scrolling and clicks
				_S.Reading = true
				_S.ClientObjectSync.ApplyFPSCap()
				SetColorCodeFrame("Reading")
				ConsoleMessage("Reading started")
				ConsoleMessage("Length: "..RoundNumber(_S.ReplayStorage.Length(_S.ReplayTable)/_S.ClientObjectSync.TASFPS,2).." seconds")
			else
				-- Decoding failed
				ConsoleMessage(ReplayReason or "Replay was not ready")
				_S.ReplayTable = _S.ReplayStorage.New()
				SetColorCodeFrame("Idle")
			end
		else
			ConsoleMessage("You are already reading")
		end
	end
	StopReading = function()
		if _S.Reading then
			_S.Paused = false
			_S.ClientObjectSync.SetPlaybackPausePhysics(false)
			_S.ClientObjectSync.ReleasePlaybackInputs(true)
			UnblockInputs() -- Enable scrolling and clicks
			Character.Head.CanCollide = true -- Fix character collisions
			Character.Torso.CanCollide = true -- Fix character collisions
			Character.HumanoidRootPart.CanCollide = true -- Fix character collisions
			_S.AnimateDisabled = false -- Enable fake animate script
			_S.Reading = false
			_S.ClientObjectSync.ResetReplayInputDisplay()
			Character.Humanoid.JumpPower = _S.DefaultJumpPower
			Character.Humanoid.WalkSpeed = _S.DefaultWalkSpeed
			Workspace.Gravity = _S.DefaultGravity
			SetColorCodeFrame("Idle")
			_S.ClientObjectSync.ApplyFPSCap()
			ConsoleMessage("Reading stopped")
		else
			ConsoleMessage("You are not reading")
		end
	end
end

-- Tasability functions
do
	Freeze = function(NewFrozen,DoNotRecord)
		if _S.Frozen ~= NewFrozen and not _S.Reading then
			_S.SeekDirection = 0
			if NewFrozen then
				_S.Frozen = true
				StopRecording()
				SaveRecording()
				_S.FreezeFrame = _S.ReplayStorage.Length(_S.ReplayTable)
				_S.ClientObjectSync.ResetSeekStepTimer()
				SetColorCodeFrame("Frozen")
			else
				if DoNotRecord then
					if _S.ClientObjectSync.ReleasePlaybackObjectControl then
						_S.ClientObjectSync.ReleasePlaybackObjectControl(true)
					end
					_S.Frozen = false
					SetColorCodeFrame("Idle")
				else
					local TargetFrameIndex = math.max(_S.FreezeFrame - 1, 1)
					_S.ClientObjectSync.ApplyObjectsAtFrame(_S.ReplayTable, TargetFrameIndex)
					_S.ReplayStorage.Truncate(_S.ReplayTable, TargetFrameIndex)
					if _S.ClientObjectSync.ReleasePlaybackObjectControl then
						_S.ClientObjectSync.ReleasePlaybackObjectControl(true)
					end
					if _S.ClientObjectSync.PrepareFirstRecordingFrame then
						_S.ClientObjectSync.PrepareFirstRecordingFrame()
					end
					_S.Frozen = false
					StartRecording()
					SetColorCodeFrame("Recording")
				end
			end
		end
	end
end
-- Commands
local Commands = {}
do
	Commands["help"] = function(Args)
		if Args == "help" then
			ConsoleMessage("help <command>: Shows a list of all commands, or a specific command")
		else
			local Command = Args[1]
			if Command then
				Command = string.lower(Command)
				if Commands[Command] then
					Commands[Command]("help")
				else
					ConsoleMessage("Command", Command, "was not found")
				end
			else
				for _,Command in pairs(Commands) do
					Command("help")
				end
			end
		end
	end
	Commands["erase"] = function(Args)
		if Args == "help" then
			ConsoleMessage("erase: Erases all data from the folder",_S.PlaceId)
		else
			ClearCurrentTAS()
			return _S.ReplayPath.." has been erased"
		end
	end
	Commands["setsdm"] = function(Args)
		if Args == "help" then
			ConsoleMessage("setsdm <number SeekDirectionMultiplier>: Sets speed multiplier when using R and T while frozen")
		else
			local Number = tonumber(Args[1]) or 1
			if Number then
				local OldValue = _S.SeekDirectionMultiplier
				_S.SeekDirectionMultiplier = Number
				return "SeekDirectionMultiplier has been set from "..tostring(OldValue).." to "..tostring(Number)
			end
		end
	end
	Commands["rejoin"] = function(Args)
		if Args == "help" then
			ConsoleMessage("rejoin <bool SaveReplay>: Sets one of the configs at the top of the script (PlaybackInputs, etc)")
		else
			local SaveReplay = Args[1] and string.lower(Args[1])
			ConsoleMessage("Saving...")
			if SaveReplay == "true" or SaveReplay == "yes" or SaveReplay == "1" or SaveReplay == "save" then
				SaveToFile()
			end
			ConsoleMessage("Rejoining...")
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
			ConsoleMessage("invite: Invites you to Tasability Discord")
		else
			request({
				Url = "http://127.0.0.1:6463/rpc?v=1",
				Method = "POST",
				Headers = {
					["Content-Type"] = "application/json",
					["origin"] = "https://discord.com",
				},
				Body = game:GetService("HttpService"):JSONEncode({
					["args"] = {
						["code"] = "Shyfsc2cJ9",
					},
					["cmd"] = "INVITE_BROWSER",
					["nonce"] = "."
				})
			})
			return "Sent invite (if your exploit blocked it the invite is https://discord.gg/Shyfsc2cJ9)"
		end
	end
end

-- Connection Functions
local StateChanged
local CharacterAdded
local InputBegan
local RenderStepped
local Stepped
local CurrentCamera_Changed
do
	StateChanged = function(_,State)
		table.insert(_S.HumanoidStateQueue,State.Value)
	end
	CharacterAdded = function(NewCharacter)
		_S.Humanoid = NewCharacter:WaitForChild("Humanoid")
		_S.Humanoid.StateChanged:Connect(StateChanged)
		_S.RootPart = NewCharacter:WaitForChild("HumanoidRootPart")
		_S.DefaultJumpPower = _S.Humanoid.JumpPower
		_S.DefaultWalkSpeed = _S.Humanoid.WalkSpeed
		Reanimate(NewCharacter)
		Character = NewCharacter
		_S.Humanoid.Died:Connect(function()
			_S.Dead = true
		end)
		_S.Dead = false
	end
	InputBegan = function(Input,GameProcessed)
	if _S.IgnoreGameProcessed then
		GameProcessed = false
	end
	
	if Input.UserInputType == Enum.UserInputType.MouseButton1 then
		table.insert(_S.InputBeganQueue,"b1")
	elseif Input.UserInputType == Enum.UserInputType.MouseButton2 then
		table.insert(_S.InputBeganQueue,"b2")
	elseif Input.UserInputType == Enum.UserInputType.Keyboard then
		local InputName = string.split(tostring(Input.KeyCode),".")[3]
		if not _S.InputBlacklist[InputName] then
			table.insert(_S.InputBeganQueue,InputName)
		end
	end
	
	if Input.KeyCode == Enum.KeyCode.LeftShift and not _S.Reading and not GameProcessed then
		SetShiftLockEnabled(not _S.ShiftLockEnabled)
	end
	
	if Input.KeyCode == Recordkeybind.Value and not GameProcessed then
		-- Freeze/Unfreeze
		Freeze(not _S.Frozen)
	elseif Input.KeyCode == Gobackwardskeybind.Value and not GameProcessed then
		if not _S.Reading then
			Freeze(true)
			if _S.SeekDirection == 0 then
				_S.SeekDirection = -1*_S.SeekDirectionMultiplier -- Backwards
			end
		end
	elseif Input.KeyCode == Goforwardkeybind.Value and not GameProcessed then
		-- Seek fowards
		if not _S.Reading then
			Freeze(true)
			if _S.SeekDirection == 0 then
				_S.SeekDirection = 1*_S.SeekDirectionMultiplier -- Fowards
			end
		end
	elseif Input.KeyCode == Frameadvancebackwardskeybind.Value and not GameProcessed then
		-- Go 1 frame backwards
		Freeze(true)
		if _S.Frozen and _S.SeekDirection == 0 then
			local NewFreezeFrame = _S.FreezeFrame - 1
			if NewFreezeFrame > 0 and NewFreezeFrame <= _S.ReplayStorage.Length(_S.ReplayTable) then
				_S.FreezeFrame = NewFreezeFrame
			end
		end
	elseif Input.KeyCode == Frameadvanceforwardkeybind.Value and not GameProcessed then
		-- Go 1 frame fowards
		Freeze(true)
		if _S.Frozen and _S.SeekDirection == 0 then
			local NewFreezeFrame = _S.FreezeFrame + 1
			if NewFreezeFrame > 0 and NewFreezeFrame <= _S.ReplayStorage.Length(_S.ReplayTable) then
				_S.FreezeFrame = NewFreezeFrame
			end
		end
	elseif Input.KeyCode == Hideuikeybind.Value and not GameProcessed then
		-- Toggle UI
		if MainFrame then MainFrame.Visible = not MainFrame.Visible end
	elseif Input.KeyCode == Abortkeybind.Value and not GameProcessed then
		-- Stop reading
		StopReading()
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
		if _S.Reading then
			_S.Paused = not _S.Paused
			if _S.Paused then
				_S.ClientObjectSync.SetPlaybackPausePhysics(true)
				ConsoleMessage("Paused")
				SetColorCodeFrame("Frozen") 
			else
				_S.ClientObjectSync.SetPlaybackPausePhysics(false)
				ConsoleMessage("Resumed")
				SetColorCodeFrame("Reading")
			end
		end
	end
end
	InputChanged = function(Input,GameProcessed)
		if Input.UserInputType == Enum.UserInputType.MouseWheel then
			if Input.Position.Z > 0 then
				table.insert(_S.InputBeganQueue,"u")
			else
				table.insert(_S.InputBeganQueue,"d")
			end
		end
	end
	InputEnded = function(Input,GameProcessed)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 then
			table.insert(_S.InputEndedQueue,"b1")
		elseif Input.UserInputType == Enum.UserInputType.MouseButton2 then
			table.insert(_S.InputEndedQueue,"b2")
		elseif Input.UserInputType == Enum.UserInputType.MouseWheel then
			if Input.Position.Z > 0 then
				table.insert(_S.InputEndedQueue,"u")
			else
				table.insert(_S.InputEndedQueue,"d")
			end
		elseif Input.UserInputType == Enum.UserInputType.Keyboard then
			local InputName = string.split(tostring(Input.KeyCode),".")[3]
			table.insert(_S.InputEndedQueue,InputName)
		end
		
		if Input.KeyCode == Gobackwardskeybind.Value then
			-- Stop seeking backwards
			if _S.SeekDirection == -1*_S.SeekDirectionMultiplier then
				_S.SeekDirection = 0
			end
		elseif Input.KeyCode == Goforwardkeybind.Value then
			-- Stop seeking fowards
			if _S.SeekDirection == 1*_S.SeekDirectionMultiplier then
				_S.SeekDirection = 0
			end
		end
	end
	RenderStepped = function(...)
		for _,Function in pairs(_S.RenderSteppedConnections) do
			Function(...)
		end
	end
	Stepped = function(...)
		for _,Function in pairs(_S.SteppedConnections) do
			Function(...)
		end
	end
	ReadButton_MouseButton1Click = function()
		if _S.ReplayStartTime >= 1 then
			for i = _S.ReplayStartTime,1,-1 do
				ConsoleMessage("Reading in "..tostring(i).." seconds")
				wait(1)
			end
		end
		StartReading()
	end
	IdleButton_MouseButton1Click = function()
		if GetColorCodeFrame() == "Frozen" then
			Freeze(false,true)
		end
	end
	CurrentCamera_Changed = function()
		if _S.Reading then
			workspace.CurrentCamera.CFrame = _S.CameraCFrame
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
				ConsoleMessage(ReturnMessage)
			end
		else
			ConsoleMessage("Command",InputSplit[1],"was not found")
		end
		self:Clear()
	end
end

-- RenderStepped/Stepped connections
do
	_S.RenderSteppedConnections.UpdateFreezeFrame = function()
		RecordedFramesLabel.Text = "Frames: "..RoundNumber(_S.FreezeFrame,0)
	end
	_S.RenderSteppedConnections.SeekDirectionHandler = function(Delta)
		if _S.Frozen and _S.SeekDirection ~= 0 and _S.ClientObjectSync.ShouldSeekTASFrame(Delta) then
			local FrameStep = _S.SeekDirection > 0 and 1 or -1
			local NewFreezeFrame = _S.FreezeFrame + FrameStep
			if NewFreezeFrame < 1 then
				_S.FreezeFrame = 1
			elseif NewFreezeFrame > _S.ReplayStorage.Length(_S.ReplayTable) then
				_S.FreezeFrame = _S.ReplayStorage.Length(_S.ReplayTable)
			else
				_S.FreezeFrame = NewFreezeFrame
			end
		end
	end

    local PressedWriting = {}
	
_S.SteppedConnections.UpdateKeyboardOverlay = function()
    if getgenv().KeyboardOverlayEnabled and getgenv().KeyboardOverlayKeys then
        local keys = getgenv().KeyboardOverlayKeys
        local theme = KeyboardOverlayThemes[currentTheme]
        
        local keysToCheck = (_S.Reading or _S.Frozen) and _S.ClientObjectSync.ReplayPressed or (_S.Writing and PressedWriting or _S.Pressed)
        
        for keyName, keyFrame in pairs(keys) do
            local state = "normal"
            
            if keysToCheck[keyName] then
                state = _S.Writing and "writing" or "pressed"
            end
            
            theme.updateColors(keyFrame, state)
        end
    end
end

_S.SteppedConnections.UpdateInputPreview = function()
	if not _S.Reading then
		for _,Input in pairs(_S.InputBeganQueue) do
			if Input == "u" or Input == "d" then
				continue
			end
			_S.Pressed[Input] = true
		end
		for _,Input in pairs(_S.InputEndedQueue) do
			_S.Pressed[Input] = nil
		end
	end
	if _S.Frozen and _S.ReplayStorage.Length(_S.ReplayTable) > 0 then
		_S.ClientObjectSync.SetReplayKeyboardDisplayAtFrame(_S.ReplayTable,_S.FreezeFrame)
	end
	_S.ClientObjectSync.SetPressedKeysLabel((_S.Reading or _S.Frozen) and _S.ClientObjectSync.ReplayPressed or _S.Pressed,PressedKeysLabel)
	
	if _S.Writing then
		for _,Input in pairs(_S.InputBeganQueue) do
			if Input == "u" or Input == "d" then
			else
				PressedWriting[Input] = true
			end
		end
		for _,Input in pairs(_S.InputEndedQueue) do
			PressedWriting[Input] = nil
		end
		WritingPressedKeysLabel.Text = "Writing Pressed keys: |"
		for Input,_ in pairs(PressedWriting) do
			WritingPressedKeysLabel.Text = WritingPressedKeysLabel.Text..Input.."|"
            end
		end
	end

end

do -- Connections
	_S.UserInputService.InputBegan:Connect(InputBegan)
	_S.UserInputService.InputChanged:Connect(InputChanged)
	_S.UserInputService.InputEnded:Connect(InputEnded)
	_S.RunService.RenderStepped:Connect(RenderStepped)
	_S.RunService.Stepped:Connect(Stepped)
	_S.Player.CharacterAdded:Connect(CharacterAdded)
	workspace.CurrentCamera.Changed:Connect(CurrentCamera_Changed)
end

do -- Setup
	GetReplayFile() -- Create/migrate replay files for Tasability if needed
	if TASPaths then TASPaths.ReplayPath = _S.ReplayPath end
	SetCursor("ArrowFarCursor")
	-- Keep the real Roblox mouse visible so it can be displayed over Tasability's CoreGui.
	-- The old fake ImageLabel cursor remains available for internal positioning but is hidden.
	_S.UserInputService.MouseIconEnabled = true
	_S.DefaultGravity = Workspace.Gravity -- Set DefaultGravity
	_S.ShiftLockBoundKeys.Value = "" -- Remove shift lock keybinds
	CharacterAdded(_S.Player.Character) -- Set character
	SetColorCodeFrame("Idle") -- Set color code
end

local function findAnimateScript(character)
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

	local frameCache = {}
	local lastVelocity = Vector3.new()
	local idleFrameCount = 0
	local idle_threshold = 3 
	
	while true do
		if _S.Reading then
			if _S.Paused then
				_S.ClientObjectSync.SetPlaybackPausePhysics(true)
				_S.ClientObjectSync.ResetPlaybackStepTimer()
				_S.RunService.Heartbeat:Wait()
				continue
			end
			
			local Frame = _S.ReplayStorage.Get(_S.ReplayTable,_S.ReplayTableIndex)
			
			if Frame == 0 then
				_S.Humanoid:ChangeState(15)
				for _,Descendant in pairs(Character:GetDescendants()) do
					if Descendant:IsA("BasePart") then
						Descendant:Destroy()
					end
				end
				repeat wait() until not _S.Dead
				_S.RunService.Heartbeat:Wait()
				_S.ReplayTableIndex = _S.ReplayTableIndex + 1
				idleFrameCount = 0
				continue
			elseif Frame == 1 then
				_S.Humanoid:ChangeState(15)
				workspace.Gravity = _S.DefaultGravity
				repeat wait() until not _S.Dead
				_S.RunService.Heartbeat:Wait()
				_S.ReplayTableIndex = _S.ReplayTableIndex + 1
				idleFrameCount = 0
				continue
			end
			
			if not Frame or typeof(Frame) == "string" then
				StopReading()
				continue
			end
			
			local animateScript = findAnimateScript(Character)
			if animateScript then
				animateScript.Disabled = true
			end

			_S.AnimateDisabled = true
			workspace.Gravity = 0
			Character.Humanoid.JumpPower = 0
			Character.Humanoid.WalkSpeed = 0
			
			if not Character:FindFirstChild("HumanoidRootPart") then
				_S.RunService.Heartbeat:Wait()
				continue
			end
			
			local HRP = Character.HumanoidRootPart
			
			for _,v in pairs(Character:GetChildren()) do
				if v:IsA("BasePart") then
					v.CanCollide = true 
				end
			end
			
			_S.Humanoid.PlatformStand = true
			
			
			local cache = frameCache[_S.ReplayTableIndex]
			if not cache then
				cache = {
					hrpCFrame = FastTableToCFrame(Frame[1]),
					camCFrame = FastTableToCFrame(Frame[7]),
					hrpVel = FastTableToVector3(Frame[5]),
					hrpRotVel = FastTableToVector3(Frame[6]),
					mouseLocation = FastTableToVector2(Frame[11]),
					animations = Frame[2],
					animSpeed = Frame[3],
					humanoidState = Frame[4],
					zoom = Frame[8],
					animPose = Frame[9],
					shiftLock = (Frame[10] == 1),
					inputBegan = Frame[12][1],
					inputEnded = Frame[12][2]
				}
				frameCache[_S.ReplayTableIndex] = cache
			end

			_S.ClientObjectSync.ApplyFrame(Frame)
			local ReplayKeyboardState = _S.ClientObjectSync.SetReplayKeyboardDisplayAtFrame(_S.ReplayTable,_S.ReplayTableIndex)
			
			
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
			
			pose = cache.animPose
			_S.Humanoid:ChangeState(cache.humanoidState)
		
			if shouldForceIdle then
				playAnimation("idle", 0.1, _S.Humanoid, true)
				pcall(setAnimationSpeed, 1.0)
			else
				-- Animation playbacks
				for _, Arguments in pairs(cache.animations) do
					local animName = Arguments[1]
					local transitionTime = Arguments[2]
					playAnimation(animName, transitionTime, _S.Humanoid, true)
				end
				pcall(setAnimationSpeed, cache.animSpeed)
			end
			
			SetCameraCFrame(cache.camCFrame)
			SetZoom(cache.zoom)
			
			if cache.shiftLock ~= GetShiftLockEnabled() then
				SetShiftLockEnabled(cache.shiftLock)
			end
			
			if _S.PlaybackMouseLocation and not cache.shiftLock and cache.zoom > 0.52 then
				mousemoveabs(cache.mouseLocation.X, cache.mouseLocation.Y)
			else
				local CurrentResolution = workspace.CurrentCamera.ViewportSize
				local CurrentGuiInset = _S.GuiService:GetGuiInset()
				mousemoveabs(
					(CurrentResolution.X / 2) - CurrentGuiInset.X,
					(CurrentResolution.Y / 2) - CurrentGuiInset.Y
				)
			end
			
			if _S.PlaybackInputs then
				_S.ClientObjectSync.SyncMotionPlaybackInputs(ReplayKeyboardState)
				local Signal = {}
				for _, Input in pairs(cache.inputBegan) do
					if not _S.ClientObjectSync.IsRawKeyboardPlaybackInput(Input) then
						local SignalInput = _S.ClientObjectSync.PlaybackInputPress(Input)
						if SignalInput then
							table.insert(Signal,SignalInput)
						end
					end
				end
				for _, Input in pairs(cache.inputEnded) do
					if not _S.ClientObjectSync.IsRawKeyboardPlaybackInput(Input) then
						_S.ClientObjectSync.PlaybackInputRelease(Input)
					end
				end
				if #Signal > 0 then
					SendSignal(table.concat(Signal, ","))
				end
			end
			
			HRP.CFrame = cache.hrpCFrame
			HRP.Velocity = cache.hrpVel
			HRP.RotVelocity = cache.hrpRotVel
			
			lastVelocity = currentVelocity
			
			_S.ReplayTableIndex = _S.ReplayTableIndex + 1

			if _S.ReplayTableIndex > 100 then
				frameCache[_S.ReplayTableIndex - 100] = nil
			end
		else
			workspace.Gravity = _S.DefaultGravity
			pcall(function()
				if Character and Character:FindFirstChild("Humanoid") then
					Character.Humanoid.PlatformStand = false
				end
			end)
			frameCache = {}
			lastVelocity = Vector3.new()
			idleFrameCount = 0
		end
		
		_S.RunService.Heartbeat:Wait()
	end
end)

-- Clear input queues
_S.RunService.Heartbeat:Connect(function()
	if not _S.Writing then
		_S.InputBeganQueue = {}
		_S.InputEndedQueue = {}
	end
end)

spawn(function() -- Check if connected
	while true do
		wait(1)
		if not _S.Reading then
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
	while true do
		--print(currentAnimSpeed)
		--print(GetShiftLockEnabled())
		--table.foreach(InputEndedQueue,print)
		--print(GetZoom())
		if _S.Writing then
			if not _S.ClientObjectSync.ShouldRecordTASFrame() then
				_S.ClientObjectSync.ApplyFPSCap()
				_S.RunService.RenderStepped:Wait()
				continue
			end
			if (not Character or not Character.Parent) or (not Character:FindFirstChild("HumanoidRootPart")) then
				if type(_S.RecordingTable.LastFrame) == "table" then
					_S.ClientObjectSync.AppendRecordingFrame(0) -- Voided
				end
				_S.ClientObjectSync.ClearRecordingFrameQueues()
				_S.ClientObjectSync.ApplyFPSCap()
				_S.RunService.RenderStepped:Wait()
				continue
			end
			if (_S.Humanoid.Health == 0) then
				if type(_S.RecordingTable.LastFrame) == "table" then
					_S.ClientObjectSync.AppendRecordingFrame(1) -- Dead
				end
				_S.ClientObjectSync.ClearRecordingFrameQueues()
				_S.ClientObjectSync.ApplyFPSCap()
				_S.RunService.RenderStepped:Wait()
				continue
			end
			local Frame = {}
			Frame[1] = RoundCFrameToTable(Character.HumanoidRootPart.CFrame,_S.RoundDigits)
			Frame[2] = _S.AnimationQueue
			Frame[3] = RoundNumber(currentAnimSpeed,_S.RoundDigits)
			Frame[4] = _S.Humanoid:GetState().Value
			Frame[5] = RoundVector3ToTable(Character.HumanoidRootPart.Velocity,_S.RoundDigits)
			Frame[6] = RoundVector3ToTable(Character.HumanoidRootPart.RotVelocity,_S.RoundDigits)
			Frame[7] = RoundCFrameToTable(workspace.CurrentCamera.CFrame,_S.RoundDigits)
			Frame[8] = RoundNumber(GetZoom(),_S.RoundDigits)
			Frame[9] = pose
			Frame[10] = (GetShiftLockEnabled() and 1) or 0
			Frame[11] = RoundVector2ToTable(_S.UserInputService:GetMouseLocation(),_S.RoundDigits)
			Frame[12] = {_S.InputBeganQueue,_S.InputEndedQueue}
			Frame[13] = _S.ClientObjectSync.CaptureFrame()
			Frame[14] = _S.ClientObjectSync.CaptureStateFrame()
			Frame[15] = _S.ClientObjectSync.CaptureBeatBlockFrame()
			if (Frame[14] ~= nil or Frame[15] ~= nil) and Frame[13] == nil then
				Frame[13] = {}
			end
			_S.ClientObjectSync.AppendRecordingFrame(Frame)
			_S.ClientObjectSync.ClearRecordingFrameQueues()
		else
			_S.ClientObjectSync.ClearRecordingFrameQueues()
		end
		_S.ClientObjectSync.ApplyFPSCap()
		_S.RunService.RenderStepped:Wait()
	end
end)

spawn(function() -- Update cursor
	
	local maxWait = 0
	repeat 
		task.wait(0.1)
		maxWait = maxWait + 0.1
		if maxWait > 5 then
			break
		end
	until CursorHolder and _S.Cursor and _S.CursorIcon
	
	SetCursor("ArrowFarCursor")

	_S.Cursor.Image = _S.CursorIcon
	_S.Cursor.Size = _S.CursorSize
	_S.Cursor.Visible = false
	_S.Cursor.BackgroundTransparency = 1
	_S.Cursor.ZIndex = 10000

	
	local frameCount = 0
	while task.wait() do
		frameCount = frameCount + 1
		
		pcall(function()
			_S.Cursor.Image = _S.CursorIcon
			_S.Cursor.Size = _S.CursorSize
			_S.Cursor.Visible = false
			
			local MouseLocation = _S.UserInputService:GetMouseLocation()
			local ViewportSize = workspace.CurrentCamera.ViewportSize

			local cursorWidth = _S.CursorSize.X.Offset
			local cursorHeight = _S.CursorSize.Y.Offset
			local centerOffsetX = -cursorWidth / 2
			local centerOffsetY = -cursorHeight / 2
			
			if _S.ShiftLockEnabled then
				_S.Cursor.Position = UDim2.fromOffset(
					(ViewportSize.X / 2) + centerOffsetX,
					(ViewportSize.Y / 2) + centerOffsetY
				)
			else
				_S.Cursor.Position = UDim2.fromOffset(
					MouseLocation.X + centerOffsetX,
					MouseLocation.Y + centerOffsetY
				)
			end
			
			if frameCount % 60 == 0 then
			end
		end)
	end
end)

--[[local oldConsoleMessage
oldConsoleMessage = hookfunction(ConsoleMessage,function(...)
	if checkcaller() then
		return oldConsoleMessage(...)
	end
end)]]

spawn(function() -- Handling freezing
	while true do
		if _S.Frozen then
			Character.HumanoidRootPart.Anchored = true
			if _S.FreezeFrame > 0 and _S.FreezeFrame <= _S.ReplayStorage.Length(_S.ReplayTable) then
				local RoundedFreezeFrame = RoundNumber(_S.FreezeFrame,0)
				local Frame = _S.ReplayStorage.Get(_S.ReplayTable,RoundedFreezeFrame)
				
				if type(Frame) == "table" then
					
					local AnimatePose -- -2
					local Animation -- -1
					
					
					for Index = RoundedFreezeFrame,1,-1 do
						if AnimatePose and Animation then
							break
						end
						local Frame = _S.ReplayStorage.Get(_S.ReplayTable,Index)
						if type(Frame) == "table" then
							AnimatePose = Frame[9]
							Animation = Frame[2][#Frame[2]]
						end
					end
					
					
					local CurrentPressedKeys = _S.ClientObjectSync.SetReplayKeyboardDisplayAtFrame(_S.ReplayTable,RoundedFreezeFrame)
					
					-- Display keys pressed on WritingPressedKeysLabel
					WritingPressedKeysLabel.Text = "Writing Pressed keys: |"
					for Input,_ in pairs(CurrentPressedKeys) do
						WritingPressedKeysLabel.Text = WritingPressedKeysLabel.Text..Input.."|"
					end
					
					local HumanoidRootPartCFrame = TableToCFrame(Frame[1]) -- 4
					local AnimationSpeed = Frame[3] -- 9
					local HumanoidState = Frame[4] -- 1
					local HumanoidRootPartVelocity = TableToVector3(Frame[5]) -- 2
					local HumanoidRootPartRotVelocity = TableToVector3(Frame[6]) -- 3
					_S.CameraCFrame = TableToCFrame(Frame[7]) -- 5
					local Zoom = Frame[8] -- 6
					_S.ShiftLockEnabled = (Frame[10] == 1 and true) or false -- 7
					local MouseLocation = TableToVector2(Frame[11]) -- 8
					_S.ClientObjectSync.ApplyStateAtFrame(_S.ReplayTable,RoundedFreezeFrame)
					_S.ClientObjectSync.ApplyBeatBlocksAtFrame(_S.ReplayTable,RoundedFreezeFrame)
					_S.ClientObjectSync.ApplyObjectsAtFrame(_S.ReplayTable,RoundedFreezeFrame)
					_S.ClientObjectSync.ApplyFrame(Frame)
					
					local CurrentState = _S.Humanoid:GetState().Value
					
					-- -1
					if Animation then
						if Animation[1] == "walk" then
							if _S.Humanoid.FloorMaterial ~= Enum.Material.Air and CurrentState ~= 3 then
								playAnimation("walk",Animation[2],_S.Humanoid,true)
							end
						else
							playAnimation(Animation[1],Animation[2],_S.Humanoid,true)
						end
					end
					pcall(setAnimationSpeed,AnimationSpeed) -- 9
					pose = AnimatePose -- -2
					
					_S.Humanoid:ChangeState(HumanoidState) -- 1
					
					Character.HumanoidRootPart.Velocity = HumanoidRootPartVelocity -- 2
					Character.HumanoidRootPart.RotVelocity = HumanoidRootPartRotVelocity -- 3
					Character.HumanoidRootPart.CFrame = HumanoidRootPartCFrame -- 4
					_S.ClientObjectSync.ApplyFrame(Frame)
                    if not movecameraonfroze.Value then
                        workspace.CurrentCamera.CFrame = _S.CameraCFrame --5
                        SetZoom(Zoom) -- 6
                        if _S.ShiftLockEnabled ~= GetShiftLockEnabled() then
                            SetShiftLockEnabled(_S.ShiftLockEnabled) -- 7
                        end
                    end
					if _S.PlaybackMouseLocation then
						mousemoveabs(MouseLocation.X,MouseLocation.Y) -- 8
					end
				else
					-- Frame is not a table
					_S.RunService.RenderStepped:Wait()
				end
			else
				--ConsoleMessage("FreezeFrame is",FreezeFrame,"(not in range)")
			end
		else
			pcall(function()
				Character.HumanoidRootPart.Anchored = false
			end)
		end
		_S.RunService.RenderStepped:Wait()
	end
end)

do -- Set checkpoint
	ConsoleMessage("Loading from file...")
	_S.ReplayTable = ReplayDecode(GetReplayFile()) -- Decode replay from file
	_S.ReplayStorage.StartupDecodeReady,_S.ReplayStorage.StartupDecodeReason = _S.ReplayStorage.WaitUntilDecoded(_S.ReplayTable)
	if not _S.ReplayStorage.StartupDecodeReady then
		_S.ReplayTable = _S.ReplayStorage.New()
		ConsoleMessage(_S.ReplayStorage.StartupDecodeReason or "There is no replay folder for",_S.PlaceId)
	end
	_S.ReplayStorage.StartupDecodeReady = nil
	_S.ReplayStorage.StartupDecodeReason = nil
end

ConsoleMessage("Tasability",_S.Version,"loaded in",RoundNumber(tick()-_S.ExecutionTick,2),"seconds")
ConsoleMessage("Type help to see all commands")
