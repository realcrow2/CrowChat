Config = {}
--------------------------------
-- [Date Format]

Config.DateFormat = '%H:%M' -- To change the date format check this website - https://www.lua.org/pil/22.1.html

-- [Staff Commands Permissions]
-- These use Discord Role IDs (same as ChatRanks) to determine who can use staff commands

-- Discord Role IDs that can use /staff (staff announcements) and SEE /staffteammsg messages (read-only)
-- Users with any of these roles can send staff announcements and see staff-only messages, but CANNOT send /staffteammsg
Config.StaffAnnouncementRoleIds = {
	1234, -- Staff Team (example - change to your role ID)
	-- Add more role IDs here for ranks that should have /staff access and can see /staffo (read-only)
}

-- Discord Role IDs that can use /staffteammsg (send staff-only messages) and /clearchat (clear everyone's chat)
-- Users with any of these roles can send staff-only messages and clear everyone's chat
-- These roles can also SEE /staffteammsg messages (same as StaffAnnouncementRoleIds)
Config.StaffManagementRoleIds = {
	1234, -- High Staff (example - change to your role ID)
	-- Add more role IDs here for ranks that should have /staffteammsg and /clearchat access
}

-- Discord Role IDs that can use /lockchat and /unlockchat commands
-- Users with any of these roles can lock and unlock the chat
-- Only Management role can lock/unlock chat
Config.ChatLockRoleIds = {
	1234, -- Management
}

--------------------------------
-- [Chat Ranks]

-- Map Discord Role IDs to display names in chat (like Badger's DiscordChatRoles)
-- Format: { discordRoleId, label, color }
-- Color uses FiveM color codes: ^0 (white), ^1 (red), ^2 (green), ^3 (yellow), ^4 (blue), ^5 (cyan), ^6 (magenta/purple), ^7 (white), ^8 (dark grey), ^9 (grey/pink)
-- Higher priority ranks should be listed last (checked in reverse order - last checked first)
Config.ChatRanks = {
	-- Member (Lowest Priority - listed first)
	{ roleId = 1234, label = 'Member', color = '^8' },                  -- Grey
	
	-- Agencies/Departments
	{ roleId = 1234, label = 'Pilot License', color = '^4' },     -- Blue
	{ roleId = 1234, label = 'Public Cop', color = '^4' },              -- Blue
	{ roleId = 1234, label = 'LEO', color = '^4' },                        -- Blue
	{ roleId = 1234, label = 'LEO Supervisor', color = '^4' },   -- Blue
	{ roleId = 1234, label = 'FIB', color = '^5' },                        -- Light Blue/Cyan
	{ roleId = 1234, label = 'LSPD', color = '^4' },                      -- Blue
	{ roleId = 1234, label = 'SAST', color = '^4' },                      -- Blue
	{ roleId = 1234, label = 'BCSO', color = '^5' },                      -- Cyan
	{ roleId = 1234, label = 'DHS', color = '^8' },                        -- Dark Grey/Black
	{ roleId = 1234, label = 'DHS Supervisor', color = '^8' },          -- Dark Grey/Black
	{ roleId = 1234, label = 'SIA', color = '^8' },                        -- Dark Grey/Black
	{ roleId = 1234, label = 'SIA Supervisor', color = '^8' },          -- Dark Grey/Black
	{ roleId = 1234, label = 'Department HC', color = '^5' },            -- Cyan
	{ roleId = 1234, label = 'Department Coordinator', color = '^5' }, -- Cyan
	
	-- Staff Teams
	{ roleId = 1234, label = 'Staff Coordinator', color = '^1' },   -- Red
	{ roleId = 1234, label = 'Staff Team', color = '^1' },           -- Red
	{ roleId = 1234, label = 'Senior Staff', color = '^1' },       -- Red
	{ roleId = 1234, label = 'High Staff', color = '^1' },           -- Red
	
	-- Moderators
	{ roleId = 1234, label = 'Trial Moderator', color = '^1' },           -- Red
	{ roleId = 1234, label = 'Moderator', color = '^1' },                  -- Red
	{ roleId = 1234, label = 'Senior Moderator', color = '^1' },         -- Red
	{ roleId = 1234, label = 'Head Moderator', color = '^1' },         -- Red
	
	-- Administration
	{ roleId = 1234, label = 'Administrator', color = '^1' },    -- Red
	{ roleId = 1234, label = 'Senior Admin', color = '^1' },           -- Red
	{ roleId = 1234, label = 'Dev Team', color = '^1' },               -- Red
	{ roleId = 1234, label = 'Junior Head Admin', color = '^3' }, -- Yellow
	{ roleId = 1234, label = 'Head Admin', color = '^2' },           -- Green
	
	-- Management (Higher Priority)
	{ roleId = 1234, label = 'Trial Manager', color = '^9' },               -- Pink
	{ roleId = 1234, label = 'Junior Management', color = '^9' },           -- Pink
	{ roleId = 1234, label = 'Management', color = '^9' },                   -- Pink
	{ roleId = 1234, label = 'Senior Management', color = '^9' },           -- Pink
	{ roleId = 1234, label = 'Community Director', color = '^9' },          -- Pink
	
	-- Ownership (Highest Priority - listed last)
	{ roleId = 1234, label = 'Co-Owner', color = '^6' },               -- Purple
	{ roleId = 1234, label = 'Owner', color = '^6' },                    -- Purple
}

--------------------------------
-- [Staff]

Config.EnableStaffCommand = true

Config.StaffCommand = 'staffa'

Config.AllowStaffsToClearEveryonesChat = true

Config.ClearEveryonesChatCommand = 'clearchat'

-- [Staff Only Chat]

Config.EnableStaffOnlyCommand = true

Config.StaffOnlyCommand = 'staffteammsg'

--------------------------------
-- [Advertisements]

Config.EnableAdvertisementCommand = true

Config.AdvertisementCommand = 'ad'

Config.AdvertisementPrice = 1000

Config.AdvertisementCooldown = 5 -- in minutes

--------------------------------
-- [Automated System Messages]

-- Enable/disable automated system messages
Config.EnableAutomatedMessages = true

-- Interval between automated messages (in minutes)
Config.AutomatedMessageInterval = 5

-- Discord message configuration
Config.DiscordMessage = {
	enabled = true, -- Set to false to disable this message
	text = "Join our Discord at",
	link = "discord.gg/YOUR_INVITE",
	linkColor = "#5865f2", -- Discord blue color
	additionalText = " for exclusive perks and updates!"
}

-- Report player message configuration
Config.ReportMessage = {
	enabled = true, -- Set to false to disable this message
	text = "Need to report a player? Use",
	command = "/calladmin",
	commandColor = "#ff6b6b", -- Red color
	additionalText = " to submit a report."
}

-- Store message configuration
Config.StoreMessage = {
	enabled = true, -- Set to false to disable this message
	text = "Check out our store for exclusive packs at",
	url = "STORE_LINK",
	urlColor = "#00d9ff", -- Cyan color
	additionalText = "" -- Optional additional text after the URL
}

--------------------------------
-- [Word Blacklist]

-- Enable/disable word blacklist filtering
Config.EnableWordBlacklist = true

-- Blacklisted words (slurs only - not cuss words)
-- These words will be blocked from chat messages
-- Case-insensitive matching
Config.BlacklistedWords = {
	-- Base slurs
	"faggot",
	"fag",
	"nigger",
	"chink",
	"beaner",
	"retard",
	"retarded",
	-- Character substitution variations (F@ggot, NlGGER, etc.)
	"f@ggot",
	"f@gg0t",
	"f@gg0ts",
	"f@ggots",
	"fagg0t",
	"fagg0ts",
	"f@gg",
	"f@gs",
	"f@g",
	"n1gger",
	"n1gg3r",
	"n1gg@",
	"nigg3r",
	"nigg@",
	"nigg@r",
	"nlgger",
	"nlgg3r",
	"nlgg@",
	"ch1nk",
	"ch1nks",
	"ch!nk",
	"ch!nks",
	"chinkz",
	"b3aner",
	"b3@ner",
	"b3@n3r",
	"bean3r",
	"b3an3r",
	"bean3rs",
	"b3aners",
	"r3tard",
	"r3t@rd",
	"r3t@rds",
	"ret@rd",
	"ret@rds",
	"r3tards",
	"ret@rded",
	"r3t@rded",
	-- Additional common variations
	"fagot",
	"fagots",
	"fag0t",
	"fag0ts",
	"niger",
	"niggers",
	"niggaz",
	"chinks",
	"beaners",
	"retards",
	-- Mixed case variations
	"Faggot",
	"FAG",
	"Nigger",
	"Chink",
	"Beaner",
	"Retard",
}

--------------------------------
-- [Discord Webhook Logging]

-- Enable/disable Discord webhook logging
Config.EnableWebhookLogging = true

-- Discord webhook URL for chat logs
-- Get this from Discord: Server Settings > Integrations > Webhooks > New Webhook
Config.WebhookURL = "https://discord.com/api/webhooks/YOUR_WEBHOOK_URL" -- Add your webhook URL here

-- Webhook username (optional)
Config.WebhookUsername = "Chat Logs"

-- Webhook avatar URL (optional)
Config.WebhookAvatarURL = "https://discord.com/api/webhooks/YOUR_WEBHOOK_URL"

--------------------------------