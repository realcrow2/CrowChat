-- Check if resource is named correctly
if GetCurrentResourceName() ~= "CrowChat" then
	print("^1[CrowChat] ERROR: This resource must be named 'CrowChat' to work properly!^7")
	print("^1[CrowChat] Current resource name: " .. GetCurrentResourceName() .. "^7")
	print("^1[CrowChat] Please rename the resource folder to 'CrowChat' and restart the server.^7")
	return
end

RegisterServerEvent('chat:init')
RegisterServerEvent('chat:addTemplate')
RegisterServerEvent('chat:addMessage')
RegisterServerEvent('chat:addSuggestion')
RegisterServerEvent('chat:removeSuggestion')
RegisterServerEvent('_chat:messageEntered')
RegisterServerEvent('chat:server:ClearChat')
RegisterServerEvent('__cfx_internal:commandFallback')
RegisterServerEvent('CrowChat:setChatLock')

-- Cooldown tracking for normal OOC chat
local normalChatCooldowns = {}

-- Chat lock state (global for access from commands.lua)
chatLocked = false

-- Function to get nearest postal code for a player
function GetNearestPostal(source)
	local postal = nil
	
	-- Get player's current coordinates
	local ped = GetPlayerPed(source)
	if not ped or ped == 0 then
		return "N/A"
	end
	
	local coords = GetEntityCoords(ped)
	if not coords or coords.x == 0 and coords.y == 0 and coords.z == 0 then
		return "N/A"
	end
	
	-- Try olsun nearest postals with coordinates (primary method)
	local success1, result1 = pcall(function()
		return exports['olsun_nearest_postals']:GetNearestPostal(coords.x, coords.y, coords.z)
	end)
	if success1 and result1 and result1 ~= "" then
		postal = result1
	end
	
	-- Try alternative olsun method with coordinates
	if not postal then
		local success2, result2 = pcall(function()
			return exports['olsun_nearest_postals']:GetPostal(coords.x, coords.y, coords.z)
		end)
		if success2 and result2 and result2 ~= "" then
			postal = result2
		end
	end
	
	-- Try olsun with source
	if not postal then
		local success3, result3 = pcall(function()
			return exports['olsun_nearest_postals']:GetNearestPostal(source)
		end)
		if success3 and result3 and result3 ~= "" then
			postal = result3
		end
	end
	
	-- Try olsun GetPostal with source
	if not postal then
		local success4, result4 = pcall(function()
			return exports['olsun_nearest_postals']:GetPostal(source)
		end)
		if success4 and result4 and result4 ~= "" then
			postal = result4
		end
	end
	
	-- Try olsun GetPostalFromCoords
	if not postal then
		local success5, result5 = pcall(function()
			return exports['olsun_nearest_postals']:GetPostalFromCoords(coords.x, coords.y, coords.z)
		end)
		if success5 and result5 and result5 ~= "" then
			postal = result5
		end
	end
	
	-- Fallback to other common postal resources
	if not postal then
		local success6, result6 = pcall(function()
			return exports['qb-postal']:GetPostal(source)
		end)
		if success6 and result6 and result6 ~= "" then
			postal = result6
		end
	end
	
	if not postal then
		local success7, result7 = pcall(function()
			return exports['postal']:GetPostal(source)
		end)
		if success7 and result7 and result7 ~= "" then
			postal = result7
		end
	end
	
	return postal or "N/A"
end

-- Function to get Discord user ID
function GetDiscordId(source)
	local discordId = nil
	
	-- Try Badger Discord API
	local success1, result1 = pcall(function()
		return exports.Badger_Discord_API:GetDiscordId(source)
	end)
	if success1 and result1 then
		discordId = result1
	end
	
	-- Try alternative method
	if not discordId then
		for _, identifier in ipairs(GetPlayerIdentifiers(source)) do
			if string.find(identifier, "discord:") then
				discordId = string.gsub(identifier, "discord:", "")
				break
			end
		end
	end
	
	return discordId
end

-- Function to send Discord webhook log
function SendWebhookLog(messageType, playerName, playerId, message, additionalInfo)
	if not Config.EnableWebhookLogging or not Config.WebhookURL or Config.WebhookURL == "" then
		return
	end
	
	local embedColor = 0x808080 -- Default gray
	
	-- Set color based on message type
	if messageType == "OOC" then
		embedColor = 0x7d7d7d -- Gray
	elseif messageType == "GME" then
		embedColor = 0x9b59b6 -- Purple
	elseif messageType == "DO" then
		embedColor = 0xffff00 -- Yellow
	elseif messageType == "Social" then
		embedColor = 0x0077ff -- Blue
	elseif messageType == "SMS" then
		embedColor = 0x0077ff -- Blue
	elseif messageType == "Staff" then
		embedColor = 0xff0000 -- Red
	elseif messageType == "Staff Team" then
		embedColor = 0xff0000 -- Red
	elseif messageType == "Advertisement" then
		embedColor = 0x81db44 -- Green
	elseif messageType == "Chat Locked" then
		embedColor = 0xff6b00 -- Orange
	elseif messageType == "Chat Unlocked" then
		embedColor = 0x00ff00 -- Green
	elseif messageType == "Chat Cleared" then
		embedColor = 0xff0000 -- Red
	end
	
	-- Get Discord ID
	local discordId = GetDiscordId(playerId)
	
	-- Create user mention for inside embed
	local userMention = ""
	if discordId then
		userMention = "<@" .. discordId .. ">"
	else
		userMention = playerName
	end
	
	-- Format message description nicely: Player:\nCrow: `message`
	local description = ""
	if message and message ~= "" then
		description = "**Player:**\n" .. playerName .. ": ``" .. message .. "``"
	else
		description = "**Player:**\n" .. playerName
	end
	
	local embed = {
		{
			["title"] = messageType,
			["description"] = description,
			["type"] = "rich",
			["color"] = embedColor,
			["fields"] = {
				{
					["name"] = "👤 Player",
					["value"] = userMention,
					["inline"] = true
				},
				{
					["name"] = "🆔 Server ID",
					["value"] = tostring(playerId),
					["inline"] = true
				}
			},
			["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ"),
			["footer"] = {
				["text"] = "CrowChat Logs"
			}
		}
	}
	
	-- Add additional info if provided (but skip Rank)
	if additionalInfo then
		for key, value in pairs(additionalInfo) do
			if key ~= "Rank" then -- Skip Rank field
				local emoji = "📝"
				if key == "To" then
					emoji = "➡️"
				end
				table.insert(embed[1].fields, {
					["name"] = emoji .. " " .. key,
					["value"] = tostring(value),
					["inline"] = true
				})
			end
		end
	end
	
	local webhookData = {
		username = Config.WebhookUsername or "CrowChat Logs",
		embeds = embed
	}
	
	if Config.WebhookAvatarURL and Config.WebhookAvatarURL ~= "" then
		webhookData.avatar_url = Config.WebhookAvatarURL
	end
	
	PerformHttpRequest(Config.WebhookURL, function(err, text, headers) end, 'POST', json.encode(webhookData), { ['Content-Type'] = 'application/json' })
end

-- Function to check if message contains blacklisted words
function ContainsBlacklistedWord(message)
	if not Config.EnableWordBlacklist or not Config.BlacklistedWords then
		return false
	end
	
	local lowerMessage = string.lower(message)
	
	-- Check each blacklisted word
	for _, word in ipairs(Config.BlacklistedWords) do
		if word and word ~= "" then
			local lowerWord = string.lower(word)
			-- Escape special pattern characters
			local escapedWord = lowerWord:gsub("([%(%)%.%+%-%*%?%[%]%^%$%%])", "%%%1")
			-- Use word boundary matching: %f[%A] matches at start of alphanumeric sequence
			-- Check if word appears as a whole word (preceded by non-alphanumeric or start, followed by non-alphanumeric or end)
			local pattern = "(%A)" .. escapedWord .. "(%A)"
			local patternStart = "^" .. escapedWord .. "(%A)"
			local patternEnd = "(%A)" .. escapedWord .. "$"
			local patternExact = "^" .. escapedWord .. "$"
			
			if string.find(lowerMessage, pattern) or 
			   string.find(lowerMessage, patternStart) or 
			   string.find(lowerMessage, patternEnd) or 
			   string.find(lowerMessage, patternExact) then
				return true
			end
		end
	end
	
	return false
end

-- Export function to check if chat is locked
exports('IsChatLocked', function()
	return chatLocked
end)

-- Export function to set chat lock state (for commands.lua)
function SetChatLock(locked)
	chatLocked = locked
end

-- Export function to check if player can send messages (has lock permission)
exports('CanPlayerSendMessage', function(source)
	if not chatLocked then
		return true
	end
	
	-- If chat is locked, check if player has permission
	if not Config.ChatLockRoleIds then
		return false
	end
	
	-- Helper to check Discord role
	local function hasDiscordRole(source, roleId)
		local success, roleIDs = pcall(function()
			return exports.Badger_Discord_API:GetDiscordRoles(source)
		end)
		
		if success and roleIDs and roleIDs ~= false then
			for _, playerRoleId in ipairs(roleIDs) do
				if exports.Badger_Discord_API:CheckEqual(roleId, playerRoleId) then
					return true
				end
			end
		end
		return false
	end
	
	for _, roleId in ipairs(Config.ChatLockRoleIds) do
		if hasDiscordRole(source, roleId) then
			return true
		end
	end
	return false
end)

-- Event handler to set chat lock state (called from commands.lua)
AddEventHandler('CrowChat:setChatLock', function(locked)
	chatLocked = locked
end)

-- Function to get player's rank based on Discord roles (like Badger's DiscordChatRoles)
function GetPlayerRank(source)
	if not Config.ChatRanks then
		return nil
	end
	
	-- Try to get Discord roles using Badger Discord API (like DiscordChatRoles does)
	local success, roleIDs = pcall(function()
		return exports.Badger_Discord_API:GetDiscordRoles(source)
	end)
	
	-- If API call worked and player has Discord roles
	if success and roleIDs and roleIDs ~= false then
		-- Check ranks in reverse order (highest priority last) - last match wins
		local highestRank = nil
		for _, rank in ipairs(Config.ChatRanks) do
			if rank.roleId then
				-- Check if player has this Discord role ID
				for _, playerRoleId in ipairs(roleIDs) do
					if exports.Badger_Discord_API:CheckEqual(rank.roleId, playerRoleId) then
						highestRank = rank -- Last match is highest priority
					end
				end
			end
		end
		if highestRank then
			return highestRank
		end
	end
	
	return nil
end

AddEventHandler('_chat:messageEntered', function(author, color, message)
	if not message or not author then
		return
	end

	-- Check for blacklisted words
	if ContainsBlacklistedWord(message) then
		TriggerClientEvent('chat:addMessage', source, {
			template = '<div class="chat-message system"><i class="fas fa-ban"></i> <b><span style="color: #df7b00">SYSTEM</span></b><div style="margin-top: 5px; font-weight: 300;">Your message contains inappropriate language and cannot be sent.</div></div>'
		})
		return
	end

	-- Check if chat is locked and player doesn't have permission
	if chatLocked and not exports['CrowChat']:CanPlayerSendMessage(source) then
		TriggerClientEvent('chat:addMessage', source, {
			template = '<div class="chat-message system"><i class="fas fa-lock"></i> <b><span style="color: #df7b00">SYSTEM</span></b><div style="margin-top: 5px; font-weight: 300;">Chat is currently locked. Only staff with lock permissions can send messages.</div></div>'
		})
		return
	end

	-- Check 5 second cooldown for normal OOC chat
	if normalChatCooldowns[source] and os.time() < normalChatCooldowns[source] then
		-- Notify player they need to wait
		local timeLeft = normalChatCooldowns[source] - os.time()
		TriggerClientEvent('chat:addMessage', source, {
			template = '<div class="chat-message system"><i class="fas fa-clock"></i> <b><span style="color: #df7b00">SYSTEM</span></b><div style="margin-top: 5px; font-weight: 300;">Please wait ' .. timeLeft .. ' seconds before sending another message.</div></div>'
		})
		return
	end
	
	-- Set 5 second cooldown
	normalChatCooldowns[source] = os.time() + 5

	-- Convert regular chat messages to OOC format with distance checking
	local time = os.date(Config.DateFormat)
	local playerRank = GetPlayerRank(source)
	TriggerClientEvent('chat:ooc', -1, source, author, message, time, playerRank)
	
	-- Log to Discord webhook (AFTER message is sent)
	SendWebhookLog("OOC", author, source, message)
end)

AddEventHandler('__cfx_internal:commandFallback', function(command)
	local name = GetPlayerName(source)

	TriggerEvent('chatMessage', source, name, '/' .. command)

	if not WasEventCanceled() then
		TriggerClientEvent('chatMessage', -1, name, {255, 255, 255}, '/' .. command) 
	end

	CancelEvent()
end)

local function refreshCommands(player)
	if GetRegisteredCommands then
		local registeredCommands = GetRegisteredCommands()

		local suggestions = {}

		for _, command in ipairs(registeredCommands) do
			if IsPlayerAceAllowed(player, ('command.%s'):format(command.name)) then
				table.insert(suggestions, {
					name = '/' .. command.name,
					help = ''
				})
			end
		end

		TriggerClientEvent('chat:addSuggestions', player, suggestions)
	end
end

AddEventHandler('onServerResourceStart', function(resName)
	Wait(500)

	for _, player in ipairs(GetPlayers()) do
		refreshCommands(player)
	end
end)

AddEventHandler("chatMessage", function(source, color, message)
	local src = source
	args = stringsplit(message, " ")
	CancelEvent()
	if string.find(args[1], "/") then
		local cmd = args[1]
		table.remove(args, 1)
	end
end)

commands = {}
commandSuggestions = {}

function starts_with(str, start)
	return str:sub(1, #start) == start
end

function stringsplit(inputstr, sep)
	if sep == nil then
		sep = "%s"
	end
	local t={} ; i=1
	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
		t[i] = str
		i = i + 1
	end
	return t
end

-- Automated System Messages
if Config.EnableAutomatedMessages then
	local messageIndex = 1
	local automatedMessages = {}
	
	-- Build messages from config
	if Config.DiscordMessage and Config.DiscordMessage.enabled then
		table.insert(automatedMessages, {
			template = '<div class="chat-message system"><i class="fas fa-discord"></i> <b><span style="color: #df7b00">SYSTEM</span></b><div style="margin-top: 5px; font-weight: 300;">' .. 
				(Config.DiscordMessage.text or "Join our Discord at") .. 
				' <span style="color: ' .. (Config.DiscordMessage.linkColor or "#5865f2") .. '">' .. 
				(Config.DiscordMessage.link or "discord.gg/salrp") .. 
				'</span>' .. 
				(Config.DiscordMessage.additionalText or " for exclusive perks and updates!") .. 
				'</div></div>'
		})
	end
	
	if Config.ReportMessage and Config.ReportMessage.enabled then
		table.insert(automatedMessages, {
			template = '<div class="chat-message system"><i class="fas fa-exclamation-triangle"></i> <b><span style="color: #df7b00">SYSTEM</span></b><div style="margin-top: 5px; font-weight: 300;">' .. 
				(Config.ReportMessage.text or "Need to report a player? Use") .. 
				' <span style="color: ' .. (Config.ReportMessage.commandColor or "#ff6b6b") .. '">' .. 
				(Config.ReportMessage.command or "/easyadmin") .. 
				'</span>' .. 
				(Config.ReportMessage.additionalText or " to submit a report.") .. 
				'</div></div>'
		})
	end
	
	if Config.StoreMessage and Config.StoreMessage.enabled then
		table.insert(automatedMessages, {
			template = '<div class="chat-message system"><i class="fas fa-shopping-cart"></i> <b><span style="color: #df7b00">SYSTEM</span></b><div style="margin-top: 5px; font-weight: 300;">' .. 
				(Config.StoreMessage.text or "Check out our store for exclusive packs at") .. 
				' <span style="color: ' .. (Config.StoreMessage.urlColor or "#00d9ff") .. '">' .. 
				(Config.StoreMessage.url or "https://sanandreasliferp.tebex.io/") .. 
				'</span>' .. 
				(Config.StoreMessage.additionalText or "") .. 
				'</div></div>'
		})
	end

	-- Only start the thread if there are messages configured
	if #automatedMessages > 0 then
		CreateThread(function()
			while true do
				local interval = (Config.AutomatedMessageInterval or 10) * 60000 -- Convert minutes to milliseconds
				Wait(interval)
				
				-- Send message to all players
				if #GetPlayers() > 0 then
					local message = automatedMessages[messageIndex]
					if message then
						TriggerClientEvent('chat:addMessage', -1, message)
						
						-- Cycle to next message
						messageIndex = messageIndex + 1
						if messageIndex > #automatedMessages then
							messageIndex = 1
						end
					end
				end
			end
		end)
	end
end