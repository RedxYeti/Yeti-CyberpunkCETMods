mod = {
    ready = true
}

local GameSession = require("Modules/GameSession")
local GameHUD = require("Modules/GameHUD")

local all_weapon_types = require("Modules/weapon_types")
local util = require("Modules/util")

local last_id = nil

local vehicle_weapon_types = {all_weapon_types[3], all_weapon_types[5], all_weapon_types[8]}

math.randomseed(os.time())
math.random(); math.random(); math.random()

local function upgrade_weapon()
    -- most of this is from https://www.nexusmods.com/cyberpunk2077/mods/521
    -- if youre looking to upgrade items, id check their commands
    player = Game.GetPlayer()
    stat_system = Game.GetStatsSystem()

    local player_level = stat_system:GetStatValue(player:GetEntityID(), "PowerLevel")

    if player_level < 9 then
        return
    end

    player_equipment = player:GetEquipmentSystem():GetPlayerData(player)
    transaction_system = Game.GetTransactionSystem()

    local item_data = transaction_system:GetItemData(player, last_id)

    local object_stats = item_data:GetStatsObjectID()
    local item_quality = stat_system:GetStatValue(object_stats, "Quality")

    local level_mod = util.create_stat_mod("ItemLevel", player_level * 10)
    local power_mod = util.create_stat_mod("PowerLevel", player_level)
    
    stat_system:RemoveAllModifiers(object_stats, "ItemLevel", true)
    stat_system:RemoveAllModifiers(object_stats, "PowerLevel", true)
    
    stat_system:AddSavedModifier(object_stats, level_mod)
    stat_system:AddSavedModifier(object_stats, power_mod) 
   
    if last_id.tdbid.hash ~= 0 then 
        local new_quality = util.get_tier_level(player_level)

        if util.is_iconic(item_data) then
            player:RescaleOwnedIconicsToPlayerLevel(item_data)
        end

        if new_quality == 5 then
            new_quality = 4

            local plus_mod = util.create_stat_mod("IsItemPlus", 2)
            stat_system:RemoveAllModifiers(object_stats, "IsItemPlus", true)
            stat_system:AddSavedModifier(object_stats, plus_mod)  

            local item_dps = stat_system:GetStatValue(object_stats, "ItemPlusDPS")
            local new_dps = nil
            if item_dps < 0.3 then 
                new_dps = 0.3
            elseif item_dps >= 0.3 then 
                new_dps = nil 
            end 
            if new_dps then 
                local dps_mod = util.create_stat_mod("ItemPlusDPS", new_dps)
                stat_system:RemoveAllModifiers(object_stats, "ItemPlusDPS", true) 
                stat_system:AddSavedModifier(object_stats, dps_mod) 
            end
        end
        
        local quality_mod = util.create_stat_mod("Quality", new_quality)
        stat_system:RemoveAllModifiers(object_stats, "Quality", true) 
        stat_system:AddSavedModifier(object_stats, quality_mod)
    end
end



local function get_weapon()
    local item_given = false
    local weapon_type = nil
    local new_weapon = nil
    local item_id = nil
    local in_vehicle = (player:GetCurrentVehicleState() == gamePSMVehicle.Combat)
 
    while not item_given do
        if not in_vehicle then
            weapon_type = all_weapon_types[ math.random( #all_weapon_types ) ]
        else
            weapon_type = vehicle_weapon_types[ math.random( #vehicle_weapon_types ) ]
        end
        new_weapon = string.format("Items.%s", weapon_type[ math.random( #weapon_type ) ] )
        item_id = ItemID.FromTDBID(TweakDBID.new(new_weapon))
        item_given = transaction_system:GiveItem(player, item_id, 1)
    end
    
    last_id = item_id
    return item_id
end


local function randomize_weapon()
    player = Game.GetPlayer()
    local vehicle_state = player:GetCurrentVehicleState()
    if player:GetMountedVehicle() ~= nil and vehicle_state ~= gamePSMVehicle.Combat then
        GameHUD.ShowWarning("Can't do that right now!", 1, 2)
        return
    end

    if player:GetSceneTier() > 2 then
        GameHUD.ShowWarning("Can't do that right now!", 1, 2)
        return
    end

    player_equipment = player:GetEquipmentSystem():GetPlayerData(player)
    transaction_system = Game.GetTransactionSystem()
    stat_system = Game.GetStatsSystem()
    player_level = stat_system:GetStatValue(player:GetEntityID(), "PowerLevel")

    player_equipment:UnequipItem(last_id)
    player_equipment:ClearAllWeaponSlots()
    transaction_system:RemoveItem(player, last_id, 1)

    local new_weapon = get_weapon()

    if player_level >= 9 then
        upgrade_weapon()
    end

    local item_data = transaction_system:GetItemData(player, new_weapon)

    local empty_slots = item_data:GetEmptySlotsOnItem()

    if next(empty_slots) then
        print("new item>>>>>>>>>>>>>>")
        for index, empty_slot in ipairs(empty_slots) do
            print(tostring(empty_slot))
            if tostring(empty_slot):find("Scope") then
                local possible_scopes = util.get_available_scopes(item_data)
                if possible_scopes then 
                    local random_scope = string.format("Items.%s", possible_scopes[ math.random( #possible_scopes ) ] )
                    local item_id = ItemID.FromTDBID(TweakDBID.new(random_scope))
                    if util.roll_for_attachment(player_level) and transaction_system:GiveItem(player, item_id, 1) then
                        print(string.format("adding %s ", random_scope))
                        transaction_system:AddPart(player, new_weapon, item_id, empty_slot)
                    end
                else
                    print(string.format("failed scope on weapon type %s", util.get_weapon_type(item_data)))
                end
            
            elseif tostring(empty_slot):find("PowerModule") then
                local possible_muzzles = util.get_available_muzzles(item_data)
                if possible_muzzles then
                    local random_muzzle = string.format("Items.%s", possible_muzzles[ math.random( #possible_muzzles ) ] )
                    local item_id = ItemID.FromTDBID(TweakDBID.new(random_muzzle))
                    if util.roll_for_attachment(player_level) and transaction_system:GiveItem(player, item_id, 1) then
                        print(string.format("adding %s ", random_muzzle))
                        transaction_system:AddPart(player, new_weapon, item_id, empty_slot)
                    end
                else
                    print(string.format("failed muzzle on weapon type %s", util.get_weapon_type(item_data)))
                end
            else
                local possible_mods = util.get_available_mods(item_data)
                if possible_mods then 
                    local random_mod = string.format("Items.%s", possible_mods[ math.random( #possible_mods ) ] )
                    local item_id = ItemID.FromTDBID(TweakDBID.new(random_mod))
                    if util.roll_for_attachment(player_level) and transaction_system:GiveItem(player, item_id, 1) then
                        print(string.format("adding %s ", random_mod))
                        transaction_system:AddPart(player, new_weapon, item_id, empty_slot)
                    end
                else
                    print(string.format("failed mod on weapon type %s", util.get_weapon_type(item_data)))
                end
            end   
        end
    end

    util.max_out_ammo(new_weapon, transaction_system, player)
    player:UpdateWeaponRightEquippedItemInfo() 
    player_equipment:EquipItem(new_weapon, false, true)
    player_equipment:GetInventoryManager():SetActiveWeapon(new_weapon)

    --name = Game["gameRPGManager::GetItemRecord;ItemID"](new_weapon):FriendlyName()
    --if name then
    --    GameHUD.ShowMessage(string.format("New Weapon: %s", name))
    --end
end


registerForEvent("onInit", function()
    util.initialize()
    GameHUD.Initialize()

    Observe("TargetHitIndicatorGameController", "OnKillAdded", function(self, value)
        randomize_weapon()
    end)

    Override('PlayerPuppet', 'OnWeaponEquipEvent', function(self, evt, wrappedMethod)

        evt.animFeature.firstEquip = false
        wrappedMethod(evt)
        
    end)

    GameSession.OnStart(function()
        local player = Game.GetPlayer()
        local player_equipment = player:GetEquipmentSystem():GetPlayerData(player)
        if player_equipment:GetActiveWeapon() then
            last_id = player_equipment:GetActiveWeapon()
        end
    end)

end)

registerHotkey("random_weapon", "Randomize New Weapon", function()
    randomize_weapon()
end)

return mod

--todo