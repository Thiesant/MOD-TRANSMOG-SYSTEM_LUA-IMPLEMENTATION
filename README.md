# MOD-TRANSMOG-SYSTEM_LUA-IMPLEMENTATION

A modular **Transmogrification System** for World of Warcraft 3.3.5a private servers, combining:

* A **client-side AddOn** (UI, preview grid, localization, set management)
* A **server-side Lua bridge** (AIO / Mod-Ale (Azerothcore's ELuna fork)
* **SQL ** for persistent character transmogrification data

Designed to provide better flexibility when adding new appearances to account collection.
Dedicated UI interface addon instead to bypass standard NPC gossip, which is constrained by the client’s 16-page limit.

---

## Features

* In-game transmogrification interface
* Class-specific dressing room backgrounds
* Grid-based item preview system
* Search bar per name, item ID, display ID
* Sets management
* Persistent collection account wide
* Persistent sets account wide
* Can transmog weapons visual enchantment
* Multi-language support (EN / FR)
* Server–client communication via AIO

---

## Project Structure

```
(MOD-TRANSMOG-SYSTEM_LUA-IMPLEMENTATION):
.
├───Interface
│   └───AddOns
│       └───MOD-TRANSMOG-SYSTEM
│           ├───Assets
│           │   ├───dressingroomdeathknight.blp
│           │   ├───dressingroomdemonhunter.blp
│           │   ├───dressingroomdruid.blp
│           │   ├───dressingroomhunter.blp
│           │   ├───dressingroommage.blp
│           │   ├───dressingroompaladin.blp
│           │   ├───dressingroompriest.blp
│           │   ├───dressingroomrogue.blp
│           │   ├───dressingroomshaman.blp
│           │   ├───dressingroomwarlock.blp
│           │   ├───dressingroomwarrior.blp
│           │   └───uiframediamondmetalclassicborder.blp
│           ├───Grid-Preview-DB.lua
│           ├───Locale
│           │   ├───enUS.lua
│           │   └───frFR.lua
│           ├───mod-transmog-system.lua
│           └───mod-transmog-system.toc
├───lua_scripts
│   └───TransmogSystem
│       └───TransmogSystem_AIO_Bridge.lua
└───sql
    ├───db-auth
    ├───db-characters
    │   └───transmog_characters_base.sql
    └───db-world
```

---

## Requirements

### Server

* Azerothcore compatible core or forks [https://github.com/azerothcore/azerothcore-wotlk](https://github.com/azerothcore/azerothcore-wotlk)
* Mod-Ale [https://github.com/azerothcore/mod-ale](https://github.com/azerothcore/mod-ale)
* AIO [https://github.com/Rochet2/AIO](https://github.com/Rochet2/AIO)

### Client

* World of Warcraft 3.3.5a
* AIO [https://github.com/Rochet2/AIO](https://github.com/Rochet2/AIO)
* AddOns enabled

### This Project

* MOD-TRANSMOG-SYSTEM_LUA-IMPLEMENTATION [https://github.com/Thiesant/MOD-TRANSMOG-SYSTEM_LUA-IMPLEMENTATION](https://github.com/Thiesant/MOD-TRANSMOG-SYSTEM_LUA-IMPLEMENTATION)

---

## Installation

### 1. Client AddOn

Copy the AddOn folder to your client:

```
World of Warcraft/
└── Interface/
    └── AddOns/
        ├───AIO_Client
        └── MOD-TRANSMOG-SYSTEM/
```

---

### 2. Server Lua Script

Place the Lua bridge file into your server Lua scripts directory:

```
(Azerothcore Build):
.
└───lua_scripts
    ├───AIO_Server
    └───TransmogSystem
        └───TransmogSystem_AIO_Bridge.lua
```

Restart the server or reload Lua scripts with .reload Ale

---

### 3. Database Setup

Import the character database schema:

```sql
Import transmog_characters_base.sql to Acore_characters
```

Ensure it is applied to the **characters database**.

---

## Localization

Supported locales:

* `enUS`
* `frFR`

Fallback to enUS if missing other locale.
Add additional locales by creating new files in:

```
Interface\AddOns\MOD-TRANSMOG-SYSTEM\Locale\<yournewlocale>.lua
```

`if GetLocale() ~= <locale> then return end` must be used, see the `frFR` locale template
otherwise it will fallback to enUS

Set your new locale path under enUS path in:

```
Interface\AddOns\MOD-TRANSMOG-SYSTEM\mod-transmog-system.toc
```

---

## Assets

Class-specific dressing room backgrounds:

* Warrior
* Paladin
* Hunter
* Rogue
* Priest
* Death Knight
* Shaman
* Mage
* Warlock
* Druid
* Demon Hunter (fall back for custom classes)

---

## Configuration

Configuration options are handled within:

* `TransmogSystem_AIO_Bridge.lua`

Adjust item rules, UI behavior, or server validation logic as needed.

---

## Development Notes

* All validation and persistence occurs server-side
* AIO bridge handles secure communication

---

## Known Limitations

* Requires client AddOn (not fully server-driven)
* Item availability rules depend on server implementation
* Core compatibility may vary
* Work around used for items obtained from AH, Trade, Mail (character must equip item or logout and login to add them to the collection)

---

## License

MIT

---

## Credits

* Inspired by rochet2 transmog system [https://rochet2.github.io/Transmogrification.html](https://rochet2.github.io/Transmogrification.html)
* Inspired by DressMe addon and using grid preview settings from [https://github.com/GetLocalPlayer/DressMe](https://github.com/GetLocalPlayer/DressMe)

---
