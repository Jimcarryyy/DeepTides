# System Architecture

## Project Hierarchy (Argon Filesystem & Studio)

```text
src/
├── ReplicatedStorage/
│   ├── Config/
│   │   ├── LootConfig.luau
│   │   ├── GearConfig.luau
│   │   └── ZoneConfig.luau
│   ├── Modules/
│   │   └── Formatters.luau
│   └── Remotes/ (Folder: RemoteEvents & RemoteFunctions)
├── ServerScriptService/
│   ├── Core/
│   │   ├── PlayerDataManager.luau (ProfileService wrapper)
│   │   ├── OxygenServer.luau
│   │   ├── LootServer.luau
│   │   └── SellServer.luau
│   └── Libs/
│       └── ProfileService.luau
├── StarterPlayer/
│   └── StarterPlayerScripts/
│       ├── Controllers/
│       │   ├── OxygenClient.luau
│       │   └── UIController.luau
└── StarterGui/
    └── MainHUD/
        ├── OxygenBar
        ├── PearlsCounter
        └── BagCounter