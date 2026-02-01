-- Check if resource is named correctly
if GetCurrentResourceName() ~= "CrowChat" then
	print("^1[CrowChat] ERROR: This resource must be named 'CrowChat' to work properly!^7")
	print("^1[CrowChat] Current resource name: " .. GetCurrentResourceName() .. "^7")
	print("^1[CrowChat] Please rename the resource folder to 'CrowChat' and restart the server.^7")
	return
end

local canAdvertise = true
-- Cooldown tracking - per command type
local chatCooldowns = {} -- Track player cooldowns for commands by command name

-- Helper functions for color and HTML escaping
local function getColorFromCode(colorCode)
	local colorMap = {
		['^0'] = '#ffffff', ['^1'] = '#ff0000', ['^2'] = '#00ff00', ['^3'] = '#ffff00',
		['^4'] = '#0000ff', ['^5'] = '#00ffff', ['^6'] = '#ff00ff', ['^7'] = '#ffffff',
		['^8'] = '#888888', ['^9'] = '#ff6b9d',
	}
	return colorMap[colorCode] or '#ffffff'
end

local function escapeHtml(text)
	if not text then return '' end
	return string.gsub(tostring(text), "([&<>\"'])", {
		["&"] = "&amp;", ["<"] = "&lt;", [">"] = "&gt;", ['"'] = "&quot;", ["'"] = "&#039;"
	})
end

-- Function to check if message contains blacklisted words
local function ContainsBlacklistedWord(message)
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

-- Helper function to check if player has a Discord role ID
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

-- Helper function to check if player has any of the Staff Announcement roles (for /staff and SEE /staffteammsg)
function canUseStaffAnnouncements(source)
	if not Config.StaffAnnouncementRoleIds then
		return false
	end
	
	for _, roleId in ipairs(Config.StaffAnnouncementRoleIds) do
		if hasDiscordRole(source, roleId) then
			return true
		end
	end
	return false
end

-- Helper function to check if player has any of the Staff Management roles (for /staffteammsg and /clearchat)
function canUseStaffManagement(source)
	if not Config.StaffManagementRoleIds then
		return false
	end
	
	for _, roleId in ipairs(Config.StaffManagementRoleIds) do
		if hasDiscordRole(source, roleId) then
			return true
		end
	end
	return false
end

-- Helper function to get all staff players who can see /staffteammsg messages
-- Includes both Staff Announcement roles (read-only) and Staff Management roles (can send)
function showOnlyForStaff(callback)
	local players = GetPlayers()
	for _, playerId in ipairs(players) do
		local source = tonumber(playerId)
		-- Staff Announcement roles can SEE /staffteammsg messages (read-only)
		-- Staff Management roles can SEE and SEND /staffteammsg messages
		if canUseStaffAnnouncements(source) or canUseStaffManagement(source) then
			callback(source)
		end
	end
end

-- Helper function to check if player can lock/unlock chat
function canLockChat(source)
	if not Config.ChatLockRoleIds then
		return false
	end
	
	for _, roleId in ipairs(Config.ChatLockRoleIds) do
		if hasDiscordRole(source, roleId) then
			return true
		end
	end
	return false
end

-- Helper function to check if player can use commands when chat is locked
function canUseCommandsWhenLocked(source)
	-- If chat is not locked, allow all commands
	if not chatLocked then
		return true
	end
	
	-- If chat is locked, check if player has lock permission
	return canLockChat(source)
end


-- Lock Chat command
RegisterCommand('lockchat', function(source, args, rawCommand)
	local time = os.date(Config.DateFormat)
	local playerName = GetPlayerName(source)

	if canLockChat(source) then
		-- Set chat as locked (chatLocked is global in server.lua)
		chatLocked = true
		
		TriggerClientEvent('chat:addMessage', -1, {
			template = '<div class="chat-message system"><i class="fas fa-lock"></i> <b><span style="color: #df7b00">SYSTEM</span>&nbsp;<span style="font-size: 14px; color: #e1e1e1;">' .. time .. '</span></b><div style="margin-top: 5px; font-weight: 300;">Chat has been locked by ' .. escapeHtml(playerName) .. '. Only staff with lock permissions can send messages.</div></div>'
		})
		
		-- Log to Discord webhook
		SendWebhookLog("Chat Locked", playerName, source, "Chat has been locked")
	else
		TriggerClientEvent('chat:addMessage', source, {
			template = '<div class="chat-message system"><i class="fas fa-exclamation-triangle"></i> <b><span style="color: #df7b00">SYSTEM</span></b><div style="margin-top: 5px; font-weight: 300;">You do not have permission to use this command.</div></div>'
		})
	end
end)

-- Unlock Chat command
RegisterCommand('unlockchat', function(source, args, rawCommand)
	local time = os.date(Config.DateFormat)
	local playerName = GetPlayerName(source)

	if canLockChat(source) then
		-- Set chat as unlocked (chatLocked is global in server.lua)
		chatLocked = false
		
		TriggerClientEvent('chat:addMessage', -1, {
			template = '<div class="chat-message system"><i class="fas fa-unlock"></i> <b><span style="color: #df7b00">SYSTEM</span>&nbsp;<span style="font-size: 14px; color: #e1e1e1;">' .. time .. '</span></b><div style="margin-top: 5px; font-weight: 300;">Chat has been unlocked by ' .. escapeHtml(playerName) .. '. Everyone can now send messages.</div></div>'
		})
	else
		TriggerClientEvent('chat:addMessage', source, {
			template = '<div class="chat-message system"><i class="fas fa-exclamation-triangle"></i> <b><span style="color: #df7b00">SYSTEM</span></b><div style="margin-top: 5px; font-weight: 300;">You do not have permission to use this command.</div></div>'
		})
	end
end)

if Config.AllowStaffsToClearEveryonesChat then
	RegisterCommand(Config.ClearEveryonesChatCommand, function(source, args, rawCommand)
		-- Check if chat is locked and player doesn't have permission
		if not canUseCommandsWhenLocked(source) then
			TriggerClientEvent('chat:addMessage', source, {
				template = '<div class="chat-message system"><i class="fas fa-lock"></i> <b><span style="color: #df7b00">SYSTEM</span></b><div style="margin-top: 5px; font-weight: 300;">Chat is currently locked. Only staff with lock permissions can use commands.</div></div>'
			})
			return
		end
		
		local time = os.date(Config.DateFormat)

		if canUseStaffManagement(source) then
			local playerName = GetPlayerName(source)
			TriggerClientEvent('chat:client:ClearChat', -1)
			TriggerClientEvent('chat:addMessage', -1, {
				template = '<div class="chat-message system"><i class="fas fa-cog"></i> <b><span style="color: #df7b00">SYSTEM</span>&nbsp;<span style="font-size: 14px; color: #e1e1e1;">{0}</span></b><div style="margin-top: 5px; font-weight: 300;">The chat has been cleared!</div></div>',
				args = { time }
			})
			
			-- Log to Discord webhook
			SendWebhookLog("Chat Cleared", playerName, source, "Chat has been cleared")
		end
	end)
end

if Config.EnableStaffCommand then
	RegisterCommand(Config.StaffCommand, function(source, args, rawCommand)
		-- Check if chat is locked and player doesn't have permission
		if not canUseCommandsWhenLocked(source) then
			TriggerClientEvent('chat:addMessage', source, {
				template = '<div class="chat-message system"><i class="fas fa-lock"></i> <b><span style="color: #df7b00">SYSTEM</span></b><div style="margin-top: 5px; font-weight: 300;">Chat is currently locked. Only staff with lock permissions can use commands.</div></div>'
			})
			return
		end
		
		local length = string.len(Config.StaffCommand)
		local message = rawCommand:sub(length + 2) -- Skip command name + space
		local time = os.date(Config.DateFormat)
		local playerName = GetPlayerName(source)
		local playerRank = GetPlayerRank(source)

		-- Check if player has Staff Coordinator role (ONLY Staff Coordinators can use /staffannonce)
		-- Staff Coordinator role ID: 1455019888346136698
		if hasDiscordRole(source, 1455019888346136698) then
			-- Check 30 second cooldown for staffannonce command
			if not chatCooldowns[source] then chatCooldowns[source] = {} end
			if chatCooldowns[source]['staff'] and os.time() < chatCooldowns[source]['staff'] then
				local timeLeft = chatCooldowns[source]['staff'] - os.time()
				TriggerClientEvent('chat:addMessage', source, {
					template = '<div class="chat-message system"><i class="fas fa-clock"></i> <b><span style="color: #df7b00">SYSTEM</span></b><div style="margin-top: 5px; font-weight: 300;">Please wait ' .. timeLeft .. ' seconds before using this command again.</div></div>'
				})
				return
			end
			
			-- Set 30 second cooldown for staffannonce command
			chatCooldowns[source]['staff'] = os.time() + 30
			
			-- Format name with rank if available
			local displayName = playerName
			if playerRank and playerRank.label then
				local rankColor = getColorFromCode(playerRank.color)
				local rankLabelEscaped = escapeHtml(playerRank.label)
				local nameEscaped = escapeHtml(playerName)
				displayName = '<span style="color: ' .. rankColor .. '">' .. rankLabelEscaped .. '</span> | <span style="color: #ffffff">' .. nameEscaped .. '</span>'
			else
				displayName = '<span style="color: #ffffff">' .. escapeHtml(playerName) .. '</span>'
			end
			
			-- Escape message
			local messageEscaped = escapeHtml(message)
			
			-- Build template with [Staff Announcement] and rank | name (everyone can see it -1)
			local templateStr = '<div class="chat-message staff"><i class="fas fa-shield-alt"></i> <b><span style="color: #ffffff">[Staff Announcement] {0}</span>&nbsp;<span style="font-size: 14px; color: #e1e1e1;">{1}</span></b><div style="margin-top: 5px; font-weight: 300;">{2}</div></div>'
			
			TriggerClientEvent('chat:addMessage', -1, {
				template = string.gsub(string.gsub(string.gsub(templateStr, '{0}', displayName), '{1}', time), '{2}', messageEscaped)
			})
			
			-- Log to Discord webhook
			SendWebhookLog("Staff", playerName, source, message)
		else
			-- Player doesn't have permission
			TriggerClientEvent('chat:addMessage', source, {
				template = '<div class="chat-message system"><i class="fas fa-exclamation-triangle"></i> <b><span style="color: #df7b00">SYSTEM</span></b><div style="margin-top: 5px; font-weight: 300;">You do not have permission to use this command. Only Staff Coordinators can use /staffannonce.</div></div>'
			})
		end
	end)
end

if Config.EnableStaffOnlyCommand then
	RegisterCommand(Config.StaffOnlyCommand, function(source, args, rawCommand)
		-- Check if chat is locked and player doesn't have permission
		if not canUseCommandsWhenLocked(source) then
			TriggerClientEvent('chat:addMessage', source, {
				template = '<div class="chat-message system"><i class="fas fa-lock"></i> <b><span style="color: #df7b00">SYSTEM</span></b><div style="margin-top: 5px; font-weight: 300;">Chat is currently locked. Only staff with lock permissions can use commands.</div></div>'
			})
			return
		end
		
		local length = string.len(Config.StaffOnlyCommand)
		local message = rawCommand:sub(length + 2) -- Skip command name + space
		local time = os.date(Config.DateFormat)
		local playerName = GetPlayerName(source)
		local playerRank = GetPlayerRank(source)

		-- Check if player has Staff Management role (ONLY these roles can send /staffteammsg)
		if canUseStaffManagement(source) then
			-- Check 30 second cooldown for staffteammsg command
			if not chatCooldowns[source] then chatCooldowns[source] = {} end
			if chatCooldowns[source]['staffteammsg'] and os.time() < chatCooldowns[source]['staffteammsg'] then
				local timeLeft = chatCooldowns[source]['staffteammsg'] - os.time()
				TriggerClientEvent('chat:addMessage', source, {
					template = '<div class="chat-message system"><i class="fas fa-clock"></i> <b><span style="color: #df7b00">SYSTEM</span></b><div style="margin-top: 5px; font-weight: 300;">Please wait ' .. timeLeft .. ' seconds before using this command again.</div></div>'
				})
				return
			end
			
			-- Set 30 second cooldown for staffteammsg command
			chatCooldowns[source]['staffteammsg'] = os.time() + 30
			
			-- Format name with rank if available
			local displayName = playerName
			if playerRank and playerRank.label then
				local rankColor = getColorFromCode(playerRank.color)
				local rankLabelEscaped = escapeHtml(playerRank.label)
				local nameEscaped = escapeHtml(playerName)
				displayName = '<span style="color: ' .. rankColor .. '">' .. rankLabelEscaped .. '</span> | <span style="color: #ffffff">' .. nameEscaped .. '</span>'
			else
				displayName = '<span style="color: #ffffff">' .. escapeHtml(playerName) .. '</span>'
			end
			
			-- Escape message
			local messageEscaped = escapeHtml(message)
			
			-- Build template with rank | name
			local templateStr = '<div class="chat-message staffonly"><i class="fas fa-eye-slash"></i> <b><span style="color: #ffffff">[Staff Only Announcement] {0}</span>&nbsp;<span style="font-size: 14px; color: #e1e1e1;">{1}</span></b><div style="margin-top: 5px; font-weight: 300;">{2}</div></div>'
			
			showOnlyForStaff(function(staffSource)
				TriggerClientEvent('chat:addMessage', staffSource, {
					template = string.gsub(string.gsub(string.gsub(templateStr, '{0}', displayName), '{1}', time), '{2}', messageEscaped)
				})
			end)
			
			-- Log to Discord webhook
			SendWebhookLog("Staff Team", playerName, source, message)
		end
	end)
end

if Config.EnableAdvertisementCommand then
	RegisterCommand(Config.AdvertisementCommand, function(source, args, rawCommand)
		-- Check if chat is locked and player doesn't have permission
		if not canUseCommandsWhenLocked(source) then
			TriggerClientEvent('chat:addMessage', source, {
				template = '<div class="chat-message system"><i class="fas fa-lock"></i> <b><span style="color: #df7b00">SYSTEM</span></b><div style="margin-top: 5px; font-weight: 300;">Chat is currently locked. Only staff with lock permissions can use commands.</div></div>'
			})
			return
		end
		
		local length = string.len(Config.AdvertisementCommand)
		local message = rawCommand:sub(length + 2) -- Skip command name + space
		local time = os.date(Config.DateFormat)
		local playerName = GetPlayerName(source)
		local playerRank = GetPlayerRank(source)

		-- Check 30 second cooldown for ad command
		if not chatCooldowns[source] then chatCooldowns[source] = {} end
		if chatCooldowns[source]['ad'] and os.time() < chatCooldowns[source]['ad'] then
			local timeLeft = chatCooldowns[source]['ad'] - os.time()
			TriggerClientEvent('chat:addMessage', source, {
				template = '<div class="chat-message system"><i class="fas fa-clock"></i> <b><span style="color: #df7b00">SYSTEM</span></b><div style="margin-top: 5px; font-weight: 300;">Please wait ' .. timeLeft .. ' seconds before using this command again.</div></div>'
			})
			return
		end
		
		-- Set 30 second cooldown for ad command
		chatCooldowns[source]['ad'] = os.time() + 30

		-- Note: Money checking removed for standalone version
		-- If you have a money system, integrate it here
		if canAdvertise then
			-- Format name with rank if available
			local displayName = playerName
			if playerRank and playerRank.label then
				local rankColor = getColorFromCode(playerRank.color)
				local rankLabelEscaped = escapeHtml(playerRank.label)
				local nameEscaped = escapeHtml(playerName)
				displayName = '<span style="color: ' .. rankColor .. '">' .. rankLabelEscaped .. '</span> | <span style="color: #ffffff">' .. nameEscaped .. '</span>'
			else
				displayName = '<span style="color: #ffffff">' .. escapeHtml(playerName) .. '</span>'
			end
			
			-- Escape message
			local messageEscaped = escapeHtml(message)
			
			-- Build template with [Ad] and rank | name
			local templateStr = '<div class="chat-message advertisement"><i class="fas fa-ad"></i> <b><span style="color: #81db44">[Ad] {0}</span>&nbsp;<span style="font-size: 14px; color: #e1e1e1;">{1}</span></b><div style="margin-top: 5px; font-weight: 300;">{2}</div></div>'
			
			-- Show green ad message to everyone
			TriggerClientEvent('chat:addMessage', -1, {
				template = string.gsub(string.gsub(string.gsub(templateStr, '{0}', displayName), '{1}', time), '{2}', messageEscaped)
			})
			
			-- Log to Discord webhook
			SendWebhookLog("Advertisement", playerName, source, message)

			local cooldownTime = Config.AdvertisementCooldown * 60
			local pastTime = 0
			canAdvertise = false

			while (cooldownTime > pastTime) do
				Citizen.Wait(1000)
				pastTime = pastTime + 1
			end
			canAdvertise = true
		end
	end)
end

-- Global Me command
RegisterCommand('gme', function(source, args, rawCommand)
	-- Check if chat is locked and player doesn't have permission
	if not canUseCommandsWhenLocked(source) then
		TriggerClientEvent('chat:addMessage', source, {
			template = '<div class="chat-message system"><i class="fas fa-lock"></i> <b><span style="color: #df7b00">SYSTEM</span></b><div style="margin-top: 5px; font-weight: 300;">Chat is currently locked. Only staff with lock permissions can use commands.</div></div>'
		})
		return
	end
	
	local message = rawCommand:sub(5) -- Skip "gme " (4 chars + space)
	
	-- Check for blacklisted words
	if ContainsBlacklistedWord(message) then
		TriggerClientEvent('chat:addMessage', source, {
			template = '<div class="chat-message system"><i class="fas fa-ban"></i> <b><span style="color: #df7b00">SYSTEM</span></b><div style="margin-top: 5px; font-weight: 300;">Your message contains inappropriate language and cannot be sent.</div></div>'
		})
		return
	end
	
	local time = os.date(Config.DateFormat)
	local playerName = GetPlayerName(source)
	local playerRank = GetPlayerRank(source)
	
	-- Check 30 second cooldown for gme command
	if not chatCooldowns[source] then chatCooldowns[source] = {} end
	if chatCooldowns[source]['gme'] and os.time() < chatCooldowns[source]['gme'] then
		local timeLeft = chatCooldowns[source]['gme'] - os.time()
		TriggerClientEvent('chat:addMessage', source, {
			template = '<div class="chat-message system"><i class="fas fa-clock"></i> <b><span style="color: #df7b00">SYSTEM</span></b><div style="margin-top: 5px; font-weight: 300;">Please wait ' .. timeLeft .. ' seconds before using this command again.</div></div>'
		})
		return
	end
	
	-- Set 30 second cooldown for gme command
	chatCooldowns[source]['gme'] = os.time() + 30
	
	-- Format name with rank if available
	local displayName = playerName
	if playerRank and playerRank.label then
		local rankColor = getColorFromCode(playerRank.color)
		local rankLabelEscaped = escapeHtml(playerRank.label)
		local nameEscaped = escapeHtml(playerName)
		displayName = '<span style="color: ' .. rankColor .. '">' .. rankLabelEscaped .. '</span> | <span style="color: #ffffff">' .. nameEscaped .. '</span>'
	else
		displayName = '<span style="color: #ffffff">' .. escapeHtml(playerName) .. '</span>'
	end
	
	-- Escape message
	local messageEscaped = escapeHtml(message)
	
	-- Build template
	local templateStr = '<div class="chat-message gme"><i class="fas fa-user-circle"></i> <b><span style="color: #9b59b6">[GME] {0}</span>&nbsp;<span style="font-size: 14px; color: #e1e1e1;">{1}</span></b><div style="margin-top: 5px; font-weight: 300;">{2}</div></div>'
	
	TriggerClientEvent('chat:addMessage', -1, {
		template = string.gsub(string.gsub(string.gsub(templateStr, '{0}', displayName), '{1}', time), '{2}', messageEscaped)
	})
	
	-- Log to Discord webhook
	SendWebhookLog("GME", playerName, source, message)
end)

-- Do command (for actions like towing a car)
RegisterCommand('do', function(source, args, rawCommand)
	-- Check if chat is locked and player doesn't have permission
	if not canUseCommandsWhenLocked(source) then
		TriggerClientEvent('chat:addMessage', source, {
			template = '<div class="chat-message system"><i class="fas fa-lock"></i> <b><span style="color: #df7b00">SYSTEM</span></b><div style="margin-top: 5px; font-weight: 300;">Chat is currently locked. Only staff with lock permissions can use commands.</div></div>'
		})
		return
	end
	
	local message = rawCommand:sub(4) -- Skip "do " (2 chars + space)
	
	-- Check if message is empty
	if not message or message == "" then
		TriggerClientEvent('chat:addMessage', source, {
			template = '<div class="chat-message system"><i class="fas fa-exclamation-triangle"></i> <b><span style="color: #df7b00">SYSTEM</span></b><div style="margin-top: 5px; font-weight: 300;">Usage: /do [action]</div></div>'
		})
		return
	end
	
	-- Check for blacklisted words
	if ContainsBlacklistedWord(message) then
		TriggerClientEvent('chat:addMessage', source, {
			template = '<div class="chat-message system"><i class="fas fa-ban"></i> <b><span style="color: #df7b00">SYSTEM</span></b><div style="margin-top: 5px; font-weight: 300;">Your message contains inappropriate language and cannot be sent.</div></div>'
		})
		return
	end
	
	local time = os.date(Config.DateFormat)
	local playerName = GetPlayerName(source)
	local playerRank = GetPlayerRank(source)
	
	-- Check 30 second cooldown for do command
	if not chatCooldowns[source] then chatCooldowns[source] = {} end
	if chatCooldowns[source]['do'] and os.time() < chatCooldowns[source]['do'] then
		local timeLeft = chatCooldowns[source]['do'] - os.time()
		TriggerClientEvent('chat:addMessage', source, {
			template = '<div class="chat-message system"><i class="fas fa-clock"></i> <b><span style="color: #df7b00">SYSTEM</span></b><div style="margin-top: 5px; font-weight: 300;">Please wait ' .. timeLeft .. ' seconds before using this command again.</div></div>'
		})
		return
	end
	
	-- Set 30 second cooldown for do command
	chatCooldowns[source]['do'] = os.time() + 30
	
	-- Format name with rank if available
	local displayName = playerName
	if playerRank and playerRank.label then
		local rankColor = getColorFromCode(playerRank.color)
		local rankLabelEscaped = escapeHtml(playerRank.label)
		local nameEscaped = escapeHtml(playerName)
		displayName = '<span style="color: ' .. rankColor .. '">' .. rankLabelEscaped .. '</span> | <span style="color: #ffffff">' .. nameEscaped .. '</span>'
	else
		displayName = '<span style="color: #ffffff">' .. escapeHtml(playerName) .. '</span>'
	end
	
	-- Escape message
	local messageEscaped = escapeHtml(message)
	
	-- Build template (same as GME but yellow)
	local templateStr = '<div class="chat-message do"><i class="fas fa-user-circle"></i> <b><span style="color: #ffff00">[DO] {0}</span>&nbsp;<span style="font-size: 14px; color: #e1e1e1;">{1}</span></b><div style="margin-top: 5px; font-weight: 300;">{2}</div></div>'
	
	TriggerClientEvent('chat:addMessage', -1, {
		template = string.gsub(string.gsub(string.gsub(templateStr, '{0}', displayName), '{1}', time), '{2}', messageEscaped)
	})
	
	-- Log to Discord webhook
	SendWebhookLog("DO", playerName, source, message)
end)

-- Social Media command (FiveM TOS Friendly - no IRL branding)
RegisterCommand('social', function(source, args, rawCommand)
	-- Check if chat is locked and player doesn't have permission
	if not canUseCommandsWhenLocked(source) then
		TriggerClientEvent('chat:addMessage', source, {
			template = '<div class="chat-message system"><i class="fas fa-lock"></i> <b><span style="color: #df7b00">SYSTEM</span></b><div style="margin-top: 5px; font-weight: 300;">Chat is currently locked. Only staff with lock permissions can use commands.</div></div>'
		})
		return
	end
	
	local message = rawCommand:sub(8) -- Skip "social " (7 chars + space)
	
	-- Check for blacklisted words
	if ContainsBlacklistedWord(message) then
		TriggerClientEvent('chat:addMessage', source, {
			template = '<div class="chat-message system"><i class="fas fa-ban"></i> <b><span style="color: #df7b00">SYSTEM</span></b><div style="margin-top: 5px; font-weight: 300;">Your message contains inappropriate language and cannot be sent.</div></div>'
		})
		return
	end
	
	local time = os.date(Config.DateFormat)
	local playerName = GetPlayerName(source)
	local playerRank = GetPlayerRank(source)
	
	-- Check 30 second cooldown for social command
	if not chatCooldowns[source] then chatCooldowns[source] = {} end
	if chatCooldowns[source]['social'] and os.time() < chatCooldowns[source]['social'] then
		local timeLeft = chatCooldowns[source]['social'] - os.time()
		TriggerClientEvent('chat:addMessage', source, {
			template = '<div class="chat-message system"><i class="fas fa-clock"></i> <b><span style="color: #df7b00">SYSTEM</span></b><div style="margin-top: 5px; font-weight: 300;">Please wait ' .. timeLeft .. ' seconds before using this command again.</div></div>'
		})
		return
	end
	
	-- Set 30 second cooldown for social command
	chatCooldowns[source]['social'] = os.time() + 30
	
	-- Format name with rank if available
	local displayName = playerName
	if playerRank and playerRank.label then
		local rankColor = getColorFromCode(playerRank.color)
		local rankLabelEscaped = escapeHtml(playerRank.label)
		local nameEscaped = escapeHtml(playerName)
		displayName = '<span style="color: ' .. rankColor .. '">' .. rankLabelEscaped .. '</span> | <span style="color: #ffffff">' .. nameEscaped .. '</span>'
	else
		displayName = '<span style="color: #ffffff">' .. escapeHtml(playerName) .. '</span>'
	end
	
	-- Escape message
	local messageEscaped = escapeHtml(message)
	
	-- Build template
	local templateStr = '<div class="chat-message social"><i class="fas fa-share-alt"></i> <b><span style="color: #0077ff">[SOCIAL] {0}</span>&nbsp;<span style="font-size: 14px; color: #e1e1e1;">{1}</span></b><div style="margin-top: 5px; font-weight: 300;">{2}</div></div>'
	
	TriggerClientEvent('chat:addMessage', -1, {
		template = string.gsub(string.gsub(string.gsub(templateStr, '{0}', displayName), '{1}', time), '{2}', messageEscaped)
	})
	
	-- Log to Discord webhook
	SendWebhookLog("Social", playerName, source, message)
end)

-- SMS (Private Message) command
RegisterCommand('sms', function(source, args, rawCommand)
	-- Check if chat is locked and player doesn't have permission
	if not canUseCommandsWhenLocked(source) then
		TriggerClientEvent('chat:addMessage', source, {
			template = '<div class="chat-message system"><i class="fas fa-lock"></i> <b><span style="color: #df7b00">SYSTEM</span></b><div style="margin-top: 5px; font-weight: 300;">Chat is currently locked. Only staff with lock permissions can use commands.</div></div>'
		})
		return
	end
	
	-- Check if player ID and message are provided
	if not args[1] or not args[2] then
		TriggerClientEvent('chat:addMessage', source, {
			template = '<div class="chat-message system"><i class="fas fa-exclamation-triangle"></i> <b><span style="color: #df7b00">SYSTEM</span></b><div style="margin-top: 5px; font-weight: 300;">Usage: /sms [player_id] [message]</div></div>'
		})
		return
	end
	
	local targetId = tonumber(args[1])
	if not targetId then
		TriggerClientEvent('chat:addMessage', source, {
			template = '<div class="chat-message system"><i class="fas fa-exclamation-triangle"></i> <b><span style="color: #df7b00">SYSTEM</span></b><div style="margin-top: 5px; font-weight: 300;">Invalid player ID. Please provide a valid number.</div></div>'
		})
		return
	end
	
	-- Check if target player exists
	if not GetPlayerName(targetId) then
		TriggerClientEvent('chat:addMessage', source, {
			template = '<div class="chat-message system"><i class="fas fa-exclamation-triangle"></i> <b><span style="color: #df7b00">SYSTEM</span></b><div style="margin-top: 5px; font-weight: 300;">Player ID ' .. targetId .. ' is not online.</div></div>'
		})
		return
	end
	
	-- Prevent sending SMS to yourself
	if targetId == source then
		TriggerClientEvent('chat:addMessage', source, {
			template = '<div class="chat-message system"><i class="fas fa-exclamation-triangle"></i> <b><span style="color: #df7b00">SYSTEM</span></b><div style="margin-top: 5px; font-weight: 300;">You cannot send a message to yourself.</div></div>'
		})
		return
	end
	
	-- Extract message (everything after player ID)
	-- Reconstruct message from args (args[2] onwards)
	local messageParts = {}
	for i = 2, #args do
		table.insert(messageParts, args[i])
	end
	local message = table.concat(messageParts, " ")
	
	if not message or message == "" then
		TriggerClientEvent('chat:addMessage', source, {
			template = '<div class="chat-message system"><i class="fas fa-exclamation-triangle"></i> <b><span style="color: #df7b00">SYSTEM</span></b><div style="margin-top: 5px; font-weight: 300;">You must provide a message.</div></div>'
		})
		return
	end
	
	-- Check for blacklisted words
	if ContainsBlacklistedWord(message) then
		TriggerClientEvent('chat:addMessage', source, {
			template = '<div class="chat-message system"><i class="fas fa-ban"></i> <b><span style="color: #df7b00">SYSTEM</span></b><div style="margin-top: 5px; font-weight: 300;">Your message contains inappropriate language and cannot be sent.</div></div>'
		})
		return
	end
	
	local time = os.date(Config.DateFormat)
	local senderName = GetPlayerName(source)
	local targetName = GetPlayerName(targetId)
	local senderRank = GetPlayerRank(source)
	
	-- Format sender name with rank if available
	local senderDisplayName = senderName
	if senderRank and senderRank.label then
		local rankColor = getColorFromCode(senderRank.color)
		local rankLabelEscaped = escapeHtml(senderRank.label)
		local nameEscaped = escapeHtml(senderName)
		senderDisplayName = '<span style="color: ' .. rankColor .. '">' .. rankLabelEscaped .. '</span> | <span style="color: #ffffff">' .. nameEscaped .. '</span>'
	else
		senderDisplayName = '<span style="color: #ffffff">' .. escapeHtml(senderName) .. '</span>'
	end
	
	-- Escape message
	local messageEscaped = escapeHtml(message)
	
	-- Send message to target player
	local targetTemplateStr = '<div class="chat-message sms"><i class="fas fa-envelope"></i> <b><span style="color: #0077ff">[SMS] From {0}</span>&nbsp;<span style="font-size: 14px; color: #e1e1e1;">{1}</span></b><div style="margin-top: 5px; font-weight: 300;">{2}</div></div>'
	TriggerClientEvent('chat:addMessage', targetId, {
		template = string.gsub(string.gsub(string.gsub(targetTemplateStr, '{0}', senderDisplayName), '{1}', time), '{2}', messageEscaped)
	})
	
	-- Send confirmation to sender
	local senderTemplateStr = '<div class="chat-message sms"><i class="fas fa-paper-plane"></i> <b><span style="color: #0077ff">[SMS] To ' .. escapeHtml(targetName) .. ' ({3})</span>&nbsp;<span style="font-size: 14px; color: #e1e1e1;">{1}</span></b><div style="margin-top: 5px; font-weight: 300;">{2}</div></div>'
	TriggerClientEvent('chat:addMessage', source, {
		template = string.gsub(string.gsub(string.gsub(string.gsub(senderTemplateStr, '{0}', senderDisplayName), '{1}', time), '{2}', messageEscaped), '{3}', tostring(targetId))
	})
	
	-- Log to Discord webhook
	local targetDiscordId = GetDiscordId(targetId)
	local targetMention = ""
	if targetDiscordId then
		targetMention = "<@" .. targetDiscordId .. ">"
	else
		targetMention = targetName
	end
	
	SendWebhookLog("SMS", senderName, source, message, {
		["To"] = targetMention .. " (ID: " .. targetId .. ")"
	})
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

