local weapon_parts = require("Modules/weapon_parts")

local util = {}

local ranged_weapon_tag = nil

local smart_tag = nil
local tech_tag = nil
local power_tag = nil

local smg_tag = nil
local lmg_tag = nil
local shotgun_tag = nil
local sniper_tag = nil
local revolver_tag = nil
local pistol_tag = nil
local ar_tag = nil
local precision_tag = nil

local blade_tag = nil
local blunt_tag = nil
local throwable_tag = nil

local function merge_arrays(arr1, arr2)
    local merged = {}
    for i = 1, #arr1 do
        merged[#merged + 1] = arr1[i]
    end
    for i = 1, #arr2 do
        merged[#merged + 1] = arr2[i]
    end
    return merged
end

function util.initialize()
    ranged_weapon_tag = ToCName{ hash_lo = 0x63123D22, hash_hi = 0xF2EAC6B4 --[[ RangedWeapon --]] }

    smart_tag = ToCName{ hash_lo = 0x655F5112, hash_hi = 0xC8843E1C --[[ SmartWeapon --]] }
    tech_tag = ToCName{ hash_lo = 0xBF67028D, hash_hi = 0x7C3AD86F --[[ TechWeapon --]] }
    power_tag = ToCName{ hash_lo = 0x8E6D44B6, hash_hi = 0x251D1488 --[[ PowerWeapon --]] }

    smg_tag = ToCName{ hash_lo = 0xFA557ECE, hash_hi = 0x97F2E819 --[[ SMG --]] }
    lmg_tag = ToCName{ hash_lo = 0xB8E80CEF, hash_hi = 0x25678319 --[[ LMG --]] }
    shotgun_tag = ToCName{ hash_lo = 0xDF396951, hash_hi = 0xD7CB200B --[[ ShotgunWeapon --]] }
    sniper_tag = ToCName{ hash_lo = 0xF6B2FB58, hash_hi = 0x9E37D6B7 --[[ Rifle Sniper --]] }
    revolver_tag = ToCName{ hash_lo = 0xAED48796, hash_hi = 0x418864FB --[[ Revolver --]] }
    pistol_tag = ToCName{ hash_lo = 0x0C66071A, hash_hi = 0x683C1E08 --[[ Handgun --]] }
    ar_tag = ToCName{ hash_lo = 0x676F9116, hash_hi = 0xCD737D5B --[[ Rifle Assault --]] }
    precision_tag = ToCName{ hash_lo = 0x09179A25, hash_hi = 0xDA81C907 --[[ Rifle Precision --]] }

    blade_tag = ToCName{ hash_lo = 0x068BDF2D, hash_hi = 0xA950DCBC --[[ BladeWeapon --]] }
    blunt_tag = ToCName{ hash_lo = 0x311B252C, hash_hi = 0x8337025A --[[ BluntWeapon --]] }
    throwable_tag = ToCName{ hash_lo = 0xE0770A6B, hash_hi = 0xBCDBECAB --[[ ThrowableWeapon --]] }
end


function util.get_weapon_type(item_data)
    if item_data:HasTag(smg_tag) then
        return "SMG"
    elseif item_data:HasTag(pistol_tag) then
        return "Pistol"
    elseif item_data:HasTag(revolver_tag) then
        return "Revolver"
    elseif item_data:HasTag(ar_tag) then
        return "Assault Rifle"
    elseif item_data:HasTag(lmg_tag) then
        return "LMG"
    elseif item_data:HasTag(shotgun_tag) then
        return "Shotgun"
    elseif item_data:HasTag(sniper_tag) then
        return "Sniper"
    elseif item_data:HasTag(precision_tag) then
        return "Precision"
    end
end



function util.get_available_scopes(item_data)
    local item_type = util.get_weapon_type(item_data)
    if item_type == "SMG" or item_type == "Pistol" or item_type == "Revolver" or item_type == "Shotgun" then
        return weapon_parts.short_scopes
    elseif item_type == "Assault Rifle" or item_type == "Precision" then
        return merge_arrays(weapon_parts.short_scopes, weapon_parts.long_scopes)
    elseif item_type == "Sniper" then
        return weapon_parts.sniper_scopes
    end
end


function util.get_available_muzzles(item_data)
    local item_type = util.get_weapon_type(item_data)
    if item_type == "Pistol" then
        return merge_arrays(weapon_parts.silencers, weapon_parts.handgun_muzzlebreaks)
    elseif item_type == "SMG" or item_type == "Assault Rifle" then
        return merge_arrays(weapon_parts.silencers, weapon_parts.ar_smg_muzzlebreaks)
    end
end


function util.get_available_mods(item_data)
    local possible_mods = {}
    if item_data:HasTag(ranged_weapon_tag) then
        possible_mods = merge_arrays(possible_mods, weapon_parts.ranged_mod_any)
    else
        possible_mods = merge_arrays(possible_mods, weapon_parts.melee_mod_any)
    end  

    if item_data:HasTag(smart_tag) then
        possible_mods = merge_arrays(possible_mods, weapon_parts.smart_weapon_mods)
    end 

    if item_data:HasTag(tech_tag) then
        possible_mods = merge_arrays(possible_mods, weapon_parts.tech_weapon_mods)
    end

    if item_data:HasTag(power_tag) then
        possible_mods = merge_arrays(possible_mods, weapon_parts.power_weapon_mods)
    end

    if item_data:HasTag(smg_tag) or item_data:HasTag(ar_tag) or item_data:HasTag(lmg_tag) then
        possible_mods = merge_arrays(possible_mods, weapon_parts.ar_smg_lmg_mods)
    end

    if item_data:HasTag(shotgun_tag) then
        possible_mods = merge_arrays(possible_mods, weapon_parts.shotgun_mods)
    end

    if item_data:HasTag(sniper_tag) or item_data:HasTag(precision_tag) then
        possible_mods = merge_arrays(possible_mods, weapon_parts.sniper_precision_mods)
    end

    if item_data:HasTag(pistol_tag) or item_data:HasTag(revolver_tag) then
        possible_mods = merge_arrays(possible_mods, weapon_parts.pistol_revoler_mods)
    end

    if item_data:HasTag(blade_tag) then
        possible_mods = merge_arrays(possible_mods, weapon_parts.blade_mods)
    end

    if item_data:HasTag(blunt_tag) then
        possible_mods = merge_arrays(possible_mods, weapon_parts.blunt_mods)
    end

    if item_data:HasTag(throwable_tag) then
        possible_mods = merge_arrays(possible_mods, weapon_parts.throwable_mods)
    end

    return possible_mods
end


function util.roll_for_attachment(player_level)
    if player_level > 50 then 
        player_level = 50 
    end
    return math.random() < player_level / 50
end


function util.get_tier_level(player_level)
    if player_level >= 51 then
        return 5
    elseif player_level >= 33 then
        return 4
    elseif player_level >= 25 then
        return 3
    elseif player_level >= 17 then
        return 2
    elseif player_level >= 9 then
        return 1
    end
end


function util.create_stat_mod(stat_type, amount)
    return RPGManager.CreateStatModifier(stat_type, "Additive", amount)
end

function util.is_iconic(item_data)
    return RPGManager.IsItemIconic(item_data)
end

function util.max_out_ammo(item_id, transaction_system, player)
    local ammo_type = Game["gameRPGManager::GetWeaponAmmoTDBID;ItemID"](item_id)
    local ammo_id = ItemID.FromTDBID(ammo_type)
    transaction_system:GiveItem(player, ammo_id, 999)
end

return util