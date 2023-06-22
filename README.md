# LibInventoryHelper

A simple library to help with common inventory tasks.

## Usage

Add `LibInventoryHelper.lua` to your addon, either by downloading a packaged version from this repo, or by embedding `LibInventoryHelper.lua` into your own addon, then load it with a .toc/.xml file, then access it as follows from your own code:
```lua
local LibInventoryHelper = LibStub:GetLibrary("LibInventoryHelper")

local itemID = 17
local hasRoom = LibInventoryHelper.HasRoomForItemByID(17)
print(hasRoom)
```

For full documentation, see the wiki.