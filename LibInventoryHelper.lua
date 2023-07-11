assert(LibStub, "LibStub not found.");

local major, minor = "LibInventoryHelper", 1;

--- @class LibInventoryHelper
local InventoryHelper = LibStub:NewLibrary(major, minor);

if not InventoryHelper then return end;

---@enum TradeSkillItemSubTypes
InventoryHelper.TradeskillItemSubTypes = {
    ["Parts"] = 1,
    ["Jewelcrafting"] = 4,
    ["Cloth"] = 5,
    ["Leather"] = 6,
    ["MetalStone"] = 7,
    ["Cooking"] = 8,
    ["Herb"] = 9,
    ["Elemental"] = 10,
    ["Other"] = 11,
    ["Enchanting"] = 12,
    ["Inscription"] = 16,
};

---Stores which bag families can hold which item subTypes
---@enum BagFamily
InventoryHelper.BagFamilies = {
    [2^(4-1)] = InventoryHelper.TradeskillItemSubTypes.Leather,
    [2^(5-1)] = InventoryHelper.TradeskillItemSubTypes.Inscription,
    [2^(6-1)] = InventoryHelper.TradeskillItemSubTypes.Herb,
    [2^(7-1)] = InventoryHelper.TradeskillItemSubTypes.Enchanting,
    [2^(8-1)] = InventoryHelper.TradeskillItemSubTypes.Parts,
    [2^(10-1)] = InventoryHelper.TradeskillItemSubTypes.Jewelcrafting,
    [2^(11-1)] = InventoryHelper.TradeskillItemSubTypes.MetalStone,
};

InventoryHelper.TradeSkillItemTypeID = 7;

function InventoryHelper.Profile(func, ...)
    local startTime = debugprofilestop();
    local results = {func(...);}
    local endTime = debugprofilestop();
    print("Execution took " .. endTime - startTime .. "ms");
    return unpack(results);
end

---Checks if a given itemID is in a given bag and returns true/false and the ItemLocation, if possible
---@private
---@param bag number
---@param itemID number
---@return boolean
---@return ItemLocationMixin?
function InventoryHelper.IsItemIDInBag(bag, itemID)
    for slot = 1, C_Container.GetContainerNumSlots(bag) do
        local itemLoc = ItemLocation:CreateFromBagAndSlot(bag, slot);
        if C_Item.DoesItemExist(itemLoc) then
            if C_Item.GetItemID(itemLoc) == itemID then
                return true, itemLoc;
            end
        end
    end
	return false;
end

---Checks if a given itemID is in the player's inventory, checking all equipped bags
---@private
---@param itemID number
---@return boolean
---@return ItemLocationMixin?
function InventoryHelper.IsItemIDInInventory(itemID)
    for bag = Enum.BagIndex.Backpack, NUM_TOTAL_BAG_FRAMES do
        local isInBag, itemLoc = InventoryHelper.IsItemIDInBag(bag, itemID);
        if isInBag then
            return true, itemLoc;
        end
    end
    return false;
end

---Returns an ItemLocation for a given itemID, if it's in the player's inventory
---@param itemID number
---@return ItemLocationMixin?
function InventoryHelper.GetItemLocationFromItemID(itemID)
    local inBag, itemLoc = InventoryHelper.IsItemIDInInventory(itemID);
    if inBag and (itemLoc and itemLoc:IsValid()) then
        return itemLoc;
    end
end

---Returns a table, keyed by itemID, of all items in the player's inventory. I know keying by itemID is horrifying, but it's fast.
---@return table<number, ItemLocationMixin>
function InventoryHelper.GetAllItemsInInventoryByID()
    local itemIDs = {};
    for bag = Enum.BagIndex.Backpack, NUM_TOTAL_BAG_FRAMES do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local itemLoc = ItemLocation:CreateFromBagAndSlot(bag, slot);
            if C_Item.DoesItemExist(itemLoc) then
                itemIDs[C_Item.GetItemID(itemLoc)] = itemLoc;
            end
        end
    end
    return itemIDs;
end

---Filters a list of itemIDs and returns a list containing only the itemIDs that are in the player's inventory, along with their ItemLocation
---@param itemIDs table<number>
---@return table<table<number, ItemLocationMixin>>?
function InventoryHelper.FilterOwnedItemsByItemID(itemIDs)
    local ownedItems = {};
    local itemIDsInInventory = InventoryHelper.GetAllItemsInInventoryByID();
    for _, itemID in ipairs(itemIDs) do
        if itemIDsInInventory[itemID] then
            ownedItems[itemID] = itemIDsInInventory[itemID];
        end
    end
    return ownedItems;
end

---Returns a bagID and slot index for a given itemGUID, if it exists in the player's inventory. Returns the first instance of the item in bags, if it's been split.
---@param itemGUID any
---@return number | nil bagID, number | nil slotIndex
function InventoryHelper.GetBagAndSlotFromItemGUID(itemGUID)
    local includeBank = false;
    local includeUses = false;
    local includeReagentBank = false;

    local itemID = C_Item.GetItemIDByGUID(itemGUID);
    if itemID and (GetItemCount(itemID, includeBank, includeUses, includeReagentBank) > 0) then
        local itemLoc = InventoryHelper.GetItemLocationFromItemID(itemID);
        if itemLoc then
            return itemLoc:GetBagAndSlot();
        end
    end
end

---Returns a bagID and slot index for a given itemID, if it exists in the player's inventory. Returns the first instance of the item in bags, if it's been split.
---@param itemID number
---@return number | nil bagID, number | nil slotIndex
function InventoryHelper.GetBagAndSlotFromItemID(itemID)
    local includeBank = false;
    local includeUses = false;
    local includeReagentBank = false;

    if GetItemCount(itemID, includeBank, includeUses, includeReagentBank) > 0 then
        local itemLoc = InventoryHelper.GetItemLocationFromItemID(itemID);
        if itemLoc then
            return itemLoc:GetBagAndSlot();
        end
    end
end

---Returns true if the player has room for a given itemID in their inventory, returns false for invalid itemIDs
---@param itemID number
---@return boolean
function InventoryHelper.HasRoomForItemByID(itemID)
    if not C_Item.DoesItemExistByID(itemID) then
        return false;
    end

    local includeBank = false;
    local includeUses = false;
    local includeReagentBank = false;

    local itemCount = GetItemCount(itemID, includeBank, includeUses, includeReagentBank);
    local itemInInventory = itemCount > 0;
    local itemType, itemSubType = select(6, GetItemInfoInstant(itemID));

    for bagIndex = Enum.BagIndex.Backpack, NUM_TOTAL_BAG_FRAMES do
        local bagFreeSlots, bagFamily = C_Container.GetContainerNumFreeSlots(bagIndex)
        if bagFreeSlots > 0 and bagFamily ~= 0 then
            local bagFamilyItemType = InventoryHelper.BagFamilies[bagFamily];
            if bagFamilyItemType then
                if itemType == InventoryHelper.TradeSkillItemTypeID then
                    if itemSubType == bagFamilyItemType then
                        return true;
                    end
                end
            end
        elseif bagFreeSlots > 0 then
            return true;
        end
    end

    if itemInInventory then
        local maxStack = C_Item.GetItemMaxStackSizeByID(itemID);
        if maxStack then
            if mod(itemCount, maxStack) ~= 0 then
                return true;
            end
        end
    end
    return false;
end

---Returns true if the player has room for a given itemGUID in their inventory, returns false for invalid itemGUIDs
---@param itemGUID any
---@return boolean
function InventoryHelper.HasRoomForItemByGUID(itemGUID)
    local itemID = C_Item.GetItemIDByGUID(itemGUID);
    if itemID then
        return InventoryHelper.HasRoomForItemByID(itemID);
    end
    return false;
end