# CrowChat

A comprehensive, feature-rich chat system for FiveM servers with Discord integration, staff commands, and advanced moderation tools.

## Features

### Core Chat System
- **Custom UI**: Modern Vue.js-based chat interface with smooth animations
- **OOC Chat**: Out-of-character chat system with distance checking
- **Message History**: Navigate through previous messages with arrow keys
- **Auto-hide**: Chat window automatically hides after inactivity

### Staff Features
- **Staff Announcements** (`/staffa`): Send server-wide announcements (Staff Coordinators only)
- **Staff Team Messages** (`/staffteammsg`): Private staff-only chat channel
- **Chat Lock/Unlock**: Lock chat so only staff can send messages
- **Clear Chat**: Clear everyone's chat (Staff Management only)
- **Discord Role Integration**: Permission system based on Discord roles

### Chat Commands
- **`/gme`**: Global Me - Describe actions globally
- **`/do`**: Do - Describe actions you're performing
- **`/social`**: Post to social media (FiveM TOS friendly)
- **`/sms [player_id] [message]`**: Send private messages to players
- **`/ad [message]`**: Send advertisements (with cooldown)
- **`/lockchat`**: Lock chat (Management only)
- **`/unlockchat`**: Unlock chat (Management only)
- **`/clearchat`**: Clear everyone's chat (Staff Management only)

### Moderation & Security
- **Word Blacklist**: Automatic filtering of inappropriate language
- **Chat Cooldowns**: Prevents spam with configurable cooldowns
- **Message Logging**: Discord webhook integration for chat logs
- **HTML Escaping**: Protection against XSS attacks

### Additional Features
- **Chat Ranks**: Display player ranks based on Discord roles with custom colors
- **Automated Messages**: Rotating system messages (Discord, reports, store links)
- **Postal Code Integration**: Support for various postal code resources
- **Theme Support**: Extensible theme system for custom styling

## Installation

1. **Download** the resource and place it in your `resources` folder
2. **Rename** the folder to `CrowChat` (this is required!)
3. **Add** to your `server.cfg`:
   ```
   ensure CrowChat
   ```
4. **Configure** `config.lua` with your Discord role IDs and settings
5. **Restart** your server

## Requirements

### Required Dependencies
- **Badger_Discord_API**: For Discord role integration and permissions
  - Download: [Badger's Discord API](https://forum.cfx.re/t/badger-discord-api/4783879)

### Optional Dependencies
- **Postal Code Resource**: For location-based features
  - Supports: `olsun_nearest_postals`, `qb-postal`, `postal`

## Configuration

Edit `config.lua` to customize the chat system:

### Discord Role IDs
Configure Discord role IDs for:
- **Chat Ranks**: Display names and colors for different roles
- **Staff Announcement Roles**: Who can use `/staffa` and see `/staffteammsg`
- **Staff Management Roles**: Who can use `/staffteammsg` and `/clearchat`
- **Chat Lock Roles**: Who can lock/unlock chat

### Commands
- Enable/disable specific commands
- Customize command names
- Set cooldowns and prices

### Automated Messages
Configure rotating system messages:
- Discord invite link
- Report command
- Store URL

### Word Blacklist
Add words to filter from chat (case-insensitive, supports character substitution detection)

### Discord Webhook
Set up webhook logging for chat messages:
- Enable/disable logging
- Configure webhook URL
- Customize webhook appearance

## Commands

### Player Commands
| Command | Description | Cooldown |
|---------|-------------|----------|
| `/gme [message]` | Global Me - describe actions globally | 30s |
| `/do [action]` | Do - describe actions you're performing | 30s |
| `/social [message]` | Post to social media | 30s |
| `/sms [id] [message]` | Send private message to player | None |
| `/ad [message]` | Send advertisement | 5 min |

### Staff Commands
| Command | Description | Permission |
|---------|-------------|------------|
| `/staffa [message]` | Staff announcement | Staff Coordinator |
| `/staffteammsg [message]` | Staff-only message | Staff Management |
| `/clearchat` | Clear everyone's chat | Staff Management |
| `/lockchat` | Lock chat | Management |
| `/unlockchat` | Unlock chat | Management |

## Chat Ranks

The system displays player ranks based on Discord roles. Configure ranks in `config.lua`:

```lua
Config.ChatRanks = {
    { roleId = 1234, label = 'Member', color = '^8' },
    { roleId = 1234, label = 'Staff Team', color = '^1' },
    -- Add more ranks...
}
```

**Color Codes:**
- `^0` - White
- `^1` - Red
- `^2` - Green
- `^3` - Yellow
- `^4` - Blue
- `^5` - Cyan
- `^6` - Purple/Magenta
- `^7` - White
- `^8` - Dark Grey
- `^9` - Pink/Grey

## Permissions

### Staff Announcement Roles
- Can use `/staffa` command
- Can **see** `/staffteammsg` messages (read-only)
- Cannot send `/staffteammsg` messages

### Staff Management Roles
- Can use `/staffteammsg` command
- Can use `/clearchat` command
- Can **see** `/staffteammsg` messages
- Can use commands when chat is locked

### Chat Lock Roles
- Can use `/lockchat` and `/unlockchat` commands
- Can send messages when chat is locked
- Can use commands when chat is locked

## Discord Webhook Logging

All chat messages are logged to Discord via webhook (if enabled). Logs include:
- Message type (OOC, GME, DO, Social, SMS, Staff, etc.)
- Player name and Discord mention
- Server ID
- Message content
- Timestamp

## Troubleshooting

### Resource Not Working
- **Check resource name**: Must be exactly `CrowChat`
- **Check dependencies**: Ensure `Badger_Discord_API` is installed and started
- **Check console**: Look for error messages in server console

### Discord Roles Not Showing
- **Verify Badger_Discord_API**: Ensure it's properly configured
- **Check role IDs**: Verify Discord role IDs in `config.lua` are correct
- **Check permissions**: Ensure players have the Discord roles

### Chat Not Appearing
- **Check UI files**: Ensure all files in `web/` folder are present
- **Check browser console**: Press F8 in-game to see JavaScript errors
- **Verify NUI**: Ensure NUI is enabled in your server

## File Structure

```
CrowChat/
├── client.lua          # Client-side chat logic
├── server.lua          # Server-side chat logic
├── commands.lua        # Command handlers
├── ooc.lua            # OOC chat handler
├── config.lua          # Configuration file
├── fxmanifest.lua     # Resource manifest
└── web/
    ├── ui.html        # Chat UI HTML
    ├── app.js         # Vue.js application
    ├── styles.css     # Chat styles
    ├── message.js     # Message handling
    ├── suggestions.js # Command suggestions
    └── vue.js         # Vue.js library
```

## Support

For issues, questions, or feature requests, please contact the resource author or create an issue on the repository.

## License

This resource is provided as-is. Modify and use as needed for your server.

## Credits

- **Author**: Crow
- **Framework**: FiveM
- **UI Library**: Vue.js
- **Discord Integration**: Badger_Discord_API

---

**Note**: This resource requires the resource folder to be named exactly `CrowChat` to function properly. Make sure to configure all Discord role IDs in `config.lua` before using the resource.

