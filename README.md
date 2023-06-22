# LibInventoryHelper

A simple library to help with common inventory tasks. Requires [LibStub](https://www.curseforge.com/wow/addons/libstub).

## Usage

Add `LibInventoryHelper.lua` to your addon, either by downloading a packaged version from this repo, or by embedding `LibInventoryHelper.lua` into your own addon, then load it with a .toc/.xml file, and access it from your own code as follows:
```lua
local LibInventoryHelper = LibStub:GetLibrary("LibInventoryHelper")

local itemID = 17
local hasRoom = LibInventoryHelper.HasRoomForItemByID(17)
print(hasRoom)

--- returns true
```

For full documentation, see the [wiki](https://github.com/Ghostamoose/LibInventoryHelper/wiki).
