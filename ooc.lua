-- Function to convert FiveM color codes to HTML/CSS colors
local function getColorFromCode(colorCode)
	local colorMap = {
		['^0'] = '#ffffff', -- White
		['^1'] = '#ff0000', -- Red
		['^2'] = '#00ff00', -- Green
		['^3'] = '#ffff00', -- Yellow
		['^4'] = '#0000ff', -- Blue
		['^5'] = '#00ffff', -- Cyan
		['^6'] = '#ff00ff', -- Purple/Magenta
		['^7'] = '#ffffff', -- White
		['^8'] = '#888888', -- Dark Grey
		['^9'] = '#ff6b9d', -- Pink/Grey
	}
	return colorMap[colorCode] or '#ffffff'
end

-- Helper function to escape HTML (for message content)
local function escapeHtml(text)
	if not text then return '' end
	return string.gsub(tostring(text), "([&<>\"'])", {
		["&"] = "&amp;",
		["<"] = "&lt;",
		[">"] = "&gt;",
		['"'] = "&quot;",
		["'"] = "&#039;"
	})
end

RegisterNetEvent('chat:ooc')
AddEventHandler('chat:ooc', function(id, name, message, time, playerRank)
	-- Show OOC messages to everyone regardless of distance
	local nameEscaped = escapeHtml(name)
	local messageEscaped = escapeHtml(message)
	local namePart = '<span style="color: #ffffff">' .. nameEscaped .. '</span>'
	local templateStr = ''
	
	-- Build template with rank color if player has a rank
	if playerRank and playerRank.label then
		local rankColor = getColorFromCode(playerRank.color)
		local rankLabelEscaped = escapeHtml(playerRank.label)
		templateStr = '<div class="chat-message ooc"><i class="fas fa-door-open"></i> <b><span style="color: #7d7d7d">[OOC]</span> <span style="color: ' .. rankColor .. '">' .. rankLabelEscaped .. '</span> | ' .. namePart .. '&nbsp;<span style="font-size: 14px; color: #e1e1e1;">' .. time .. '</span></b><div style="margin-top: 5px; font-weight: 300;">' .. messageEscaped .. '</div></div>'
	else
		templateStr = '<div class="chat-message ooc"><i class="fas fa-door-open"></i> <b><span style="color: #7d7d7d">[OOC]</span> ' .. namePart .. '&nbsp;<span style="font-size: 14px; color: #e1e1e1;">' .. time .. '</span></b><div style="margin-top: 5px; font-weight: 300;">' .. messageEscaped .. '</div></div>'
	end
	
	TriggerEvent('chat:addMessage', {
		template = templateStr
	})
end)
