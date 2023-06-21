# HUD for EQ 

LUA script that creates a HUD display for all running characters

## Requirements

- MQ
- MQ2Lua
- MQ2NetBots

## Installation
Download the latest `hud.zip` from the latest [release](https://github.com/peonMQ/hud/releases) and unzip the contents to its own directory inside `lua` folder of your MQ directory. 

ie `lua\hud`

## Usage

Start the application by running the following command in-game (using the foldername inside the lua folder as the scriptname to start).
```bash
/lua run hud
```

### Logging
User/character configs are located at `{MQConfigDir}\{ServerName}\{CharacterName}.json`

Valid log levels: `trace | debug | info | warn | error | fatal | help`
Default log level: `warn`
```json
{
	"logging": {
		"loglevel": "debug" 
	}
}
```

### Group sorter order in UI
User/character configs are located at `{MQConfigDir}\{ServerName}\{CharacterName}.json`
Each list is one group, which gets sorted in HUD and spaced out.
```json
{
  "grouplayout": [
    ["Eredhrin", "Hamfast", "Newt", "Bill", "Marillion", "Ithildin"]
    ,["Renaissance", "Magica", "Tedd", "Araushnee", "Freyja", "Milamber"]
    ,["Soundgarden", "Lolth", "Ronin", "Tyrion", "Sheperd", "Valsharess"]
    ,["Genesis", "Vierna", "Osiris", "Eilistraee", "Regis", "Aredhel"]
    ,["Mizzfit", "Komodo", "Izzy", "Lulz", "Tiamat", "Nozdormu"]
  ]
}
```
