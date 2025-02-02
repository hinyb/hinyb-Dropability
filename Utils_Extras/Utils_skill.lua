-- These ranges may have an error of around 10.
-- But most can use.
local range_table = {
    [1] = 1427,
    [2] = 1427,
    [4] = 1413,
    [5] = 1413,
    [6] = 100,
    [8] = 178,
    [9] = 178,
    [10] = 224,
    [11] = 69,
    [12] = 132,
    [13] = 819,
    [14] = 819,
    [15] = 288,
    [17] = 161,
    [18] = 350,
    [19] = 146,
    [20] = 177,
    [21] = 1427,
    [22] = 225,
    [24] = 1413,
    [25] = 1413,
    [26] = 163,
    [28] = 1413,
    [29] = 1413,
    [30] = 2194,
    [31] = 6553,
    [33] = 5460,
    [34] = 5460,
    [35] = 3257,
    [36] = 147,
    [37] = 225,
    [38] = 116,
    [41] = 194,
    [42] = 194,
    [46] = 147,
    [47] = 147,
    [48] = 507,
    [49] = 69,
    [50] = 819,
    [51] = 616,
    [52] = 616,
    [53] = 30,
    [54] = 69,
    [55] = 1300,
    [56] = 1300,
    [60] = 116,
    [61] = 163,
    [62] = 147,
    [63] = 319,
    [64] = 100,
    [65] = 489,
    [66] = 319,
    [57] = 85,
    [58] = 161,
    [59] = 83,
    [72] = 100,
    [73] = 68,
    [74] = 38,
    [75] = 85,
    [76] = 178,
    [78] = 1569,
    [79] = 1507,
    [80] = 85,
    [81] = 147,
    [82] = 178,
    [83] = 85,
    [84] = 100,
    [85] = 130,
    [86] = 225,
    [87] = 225,
    [88] = 85,
    [89] = 146,
    [92] = 85,
    [94] = 694,
    [95] = 38,
    [96] = 38,
    [97] = 163,
    [98] = 241,
    [99] = 38,
    [100] = 38,
    [101] = 553,
    [102] = 272,
    [106] = 132,
    [108] = 132,
    [109] = 132,
    [110] = 413,
    [111] = 38,
    [112] = 69,
    [113] = 69,
    [114] = 69,
    [115] = 1427,
    [117] = 819,
    [118] = 819,
    [119] = 147,
    [120] = 147,
    [121] = 32,
    [122] = 147,
    [123] = 147,
    [124] = 694,
    [125] = 83,
    [126] = 116,
    [127] = 116,
    [128] = 116,
    [129] = 350,
    [130] = 100,
    [133] = 178,
    [134] = 85,
    [138] = 1427,
    [139] = 177,
    [143] = 85,
    [144] = 100,
    [145] = 132,
    [146] = 1928,
    [147] = 53,
    [149] = 116,
    [150] = 69,
    [151] = 194,
    [152] = 194,
    [153] = 413,
    [154] = 413,
    [156] = 69,
    [158] = 69,
    [159] = 69,
    [162] = 84,
    [163] = 1239,
    [164] = 69,
    [166] = 225,
    [167] = 694,
    [171] = 460,
    [173] = 428,
    [174] = 1882,
    [175] = 85,
    [177] = 600,
    [186] = 319,
    [187] = 163,
    [190] = 132,
    [191] = 38,
    [192] = 53,
    [199] = 131,
    [200] = 116,
    [201] = 100,
    [202] = 366,
    [203] = 1132,
    [204] = 319
}
Utils.skill_set_range = function(inst, slot_index, skill_id)
    if slot_index == 0 then
        inst.z_range = Utils.skill_get_range(skill_id)
    elseif slot_index == 1 then
        inst.x_range = Utils.skill_get_range(skill_id)
    elseif slot_index == 2 then
        inst.c_range = Utils.skill_get_range(skill_id)
    elseif slot_index == 3 then
        inst.v_range = Utils.skill_get_range(skill_id)
    end
end
Utils.skill_get_range = function(skill_id)
    return range_table[skill_id] or 40
end
-- Some skills may be missing
local non_instant_damage_skills = {
    [23] = true, -- banditC -- need to fix
    [39] = true, -- handX
    [43] = true, -- handX2
    [44] = true, -- handX3
    [45] = true, -- handX4
    [49] = true, -- engineerX
    [51] = true, -- engineerV
    [52] = true, -- engineerVBoosted
    [54] = true, -- engineerX2
    [55] = true, -- engineerV2
    [56] = true, -- engineerV2Boosted
    [95] = true, -- loaderV
    [96] = true, -- loaderVBoosted
    [99] = true, -- loaderV2
    [100] = true, -- loaderV2Boosted
    [77] = true, -- acridC -- hard to fix, this skill don't use damager_attack_process. -- apply_buff on_activate
    [147] = true -- monsterLemurianRiderLemC -- need to fix
}
Utils.is_instant_damage_skill = function(skill_id)
    return not non_instant_damage_skills[skill_id]
end
Utils.is_can_track_skill = function (skill_id)
    return not (skill_id == 77 or skill_id == 147)
end
local summon_skills = {
    [39] = true, -- handX
    [43] = true, -- handX2
    [44] = true, -- handX3
    [45] = true, -- handX4
    [49] = true, -- engineerX
    [51] = true, -- engineerV
    [52] = true, -- engineerVBoosted
    [54] = true, -- engineerX2
    [55] = true, -- engineerV2
    [56] = true, -- engineerV2Boosted
    [95] = true, -- loaderV
    [96] = true, -- loaderVBoosted
    [99] = true, -- loaderV2
    [100] = true, -- loaderV2Boosted
    [129] = true, -- drifterX
    [133] = true, -- drifterX2
    [193] = true  -- monsterShamGX
}
Utils.is_summon_skill = function(skill_id)
    return summon_skills[skill_id]
end
local no_damage_skills = {
    [3] = true, -- commandoC
    [7] = true, -- commandoC2
    [12] = true, -- enforcerC
    [27] = true, -- banditC2
    [32] = true, -- huntressC
    [40] = true, -- handC
    [68] = true, -- sniperV
    [69] = true, -- sniperVBoosted
    [90] = true, -- mercenaryV2
    [91] = true, -- mercenaryV2Boosted
    [93] = true, -- loaderX
    [103] = true, -- chefC
    [104] = true, -- chefV
    [105] = true, -- chefVBoosted
    [107] = true, -- chefC2
    [112] = true, -- pilotC
    [116] = true, -- pilotC2
    [131] = true, -- drifterV
    [132] = true, -- drifterVBoosted
    [135] = true, -- drifterV2
    [136] = true, -- drifterV2Boosted
    [140] = true, -- robomandoC
    [141] = true, -- robomandoV
    [142] = true, -- robomandoVBoosted
    [157] = true, -- monsterClayC
    [160] = true, -- monsterTrokkC
    [176] = true, -- monsterScavengerC
    [172] = true, -- monsterImpGC
    [188] = true, -- monsterMacropredX
    [195] = true, -- monsterTuberX
    [198] = true -- monsterSwiftZ
}
Utils.is_damage_skill = function(skill_id)
    return not no_damage_skills[skill_id]
end

local handy_skill_list = {
    [39] = 0,
    [43] = 1,
    [44] = 2,
    [45] = 3
}
-- 44 is like some unused skill
Utils.get_handy_drone_type = function(skill_id)
    return handy_skill_list[skill_id]
end
--[[
buff skill 90 91 68 69 40 105 107 103 104 27 12
]]
local random_skill_blacklist = {
    [0] = true, -- no skill
    [16] = true, -- enforcerZ2Reload Useless skills
    [70] = true, -- sniperZReload
    [71] = true, -- Spotter Recall   
    [178] = true, -- monsterWispBZ
    [179] = true, -- monsterBossZ    It seems like the Bosses' skills are different from normal skills
    [180] = true, -- monsterBossX
    [181] = true, -- monsterBossC
    [182] = true, -- monsterBossV
    [183] = true, -- monsterBossFinalZ
    [184] = true, -- monsterBossFinalX
    [185] = true, -- can't set
    [188] = true, -- useless skill just walk sprite
    [196] = true, -- monsterBrambleZ It need a head, and I don't think player can have a head.
    [205] = true, -- ImpfriendRecall
    [206] = true, -- can't set
    [207] = true -- can't set
}
local skill_id_to_slot = {
    [199] = 0, -- umbraWhip
    [200] = 0, -- umbraPunch
    [201] = 2, -- umbraExplode
    [202] = 2, -- umbraDash
    [203] = 2, -- umbraMissile
    [204] = 2 -- umbraSnipe
}
Utils.get_empty_skill_num = function(inst)
    local result = 0
    local skill_arr = Array.wrap(inst.skills)
    for i = 1, skill_arr:size() do
        if skill_arr:get(i - 1).active_skill.skill_id == 0 then
            result = result + 1
        end
    end
    return result
end
Utils.find_skill_id_with_name = function(name)
    for i = 0, Class.SKILL:size() - 1 do
        local skill = Class.SKILL:get(i)
        if type(skill) ~= "number" and skill:get(1) == name then
            return i
        end
    end
end
Utils.check_random_skill = function(skill_id)
    return not random_skill_blacklist[skill_id]
end
local need_scrap_bar_skill_id_list = {
    [129] = true,
    [133] = true,
    [131] = true,
    [132] = true,
    [135] = true,
    [136] = true
}
Utils.is_skill_need_scrap_bar = function(skill_id)
    return need_scrap_bar_skill_id_list[skill_id] or false
end
Utils.random_skill_id = function(random_seed)
    local random = Utils.LCG_random(random_seed)
    return function()
        while true do
            local rnd_skill_id = random(1, Class.SKILL:size()) - 1
            if Utils.check_random_skill(rnd_skill_id) then
                return rnd_skill_id
            end
        end
    end
end
Utils.get_slot_index_with_name = function(name)
    local type = string.match(name, ".*([ZXCV])")
    if type == "Z" then
        return 0
    elseif type == "X" then
        return 1
    elseif type == "C" then
        return 2
    elseif type == "V" then
        return 3
    end
    return nil
end
local slot_map = {"z", "x", "c", "v"}
Utils.get_name_with_slot_index = function(slot_index)
    return slot_map[slot_index + 1]
end
Utils.get_slot_index_with_skill_id = function(skill_id)
    local slot_index = skill_id_to_slot[skill_id] or Utils.get_slot_index_with_name(Class.SKILL:get(skill_id):get(1))
    if slot_index == nil then
        log.warning("Can't get the skill's slot_index " .. skill_id)
    end
    return slot_index
end
Utils.wrap_skill = function(skill_id)
    local skill = Class.SKILL:get(skill_id)
    if skill == nil or type(skill) == "number" then
        log.error("Can't get wrap skill with given skill_id" .. tostring(skill_id))
    end
    return {
        skill_id = skill_id,
        slot_index = Utils.get_slot_index_with_skill_id(skill_id),
        name = skill:get(2),
        description = skill:get(3),
        sprite_index = skill:get(4),
        image_index = skill:get(5),
        cooldown = skill:get(6),
        damage = skill:get(7),
        max_stock = skill:get(8)
    }
end
Utils.get_skill_diff_check_table = function()
    return {
        ["name"] = 2,
        ["description"] = 3,
        ["sprite"] = 4,
        ["subimage"] = 5,
        ["cooldown"] = 6,
        ["damage"] = 7,
        ["max_stock"] = 8,
        ["animation"] = 15
    }
end
Utils.get_active_skill_diff = function(skill)
    local result = {}
    result.skill_id = skill.skill_id
    result.slot_index = skill.slot_index
    result.stock = skill.stock
    if skill.ctm_sprite ~= nil then
        result.ctm_sprite = skill.ctm_sprite
    end
    if skill.ctm_arr_modifiers ~= nil then
        result.ctm_arr_modifiers = Utils.create_table_from_array(skill.ctm_arr_modifiers)
    end
    return result
end
Utils.find_skill_with_localized = function(name, player)
    local skills = Array.wrap(player.skills)
    for i = 0, skills:size() - 1 do
        local skill = skills:get(i).active_skill
        if (name == Language.translate_token(Class.SKILL:get(skill.skill_id):get(2))) then
            return skill
        end
    end
end
Initialize(function()
    local skill_t = {
        [6] = 0,
        [7] = 1,
        [8] = 2,
        [9] = 3
    }
    for sur_index = 0, #Class.Survivor - 1 do
        local survivor = Class.Survivor:get(sur_index)
        for skill_family_index, skill_slot in pairs(skill_t) do
            local skill_family = survivor:get(skill_family_index).elements
            for skill_index = 0, #skill_family - 1 do
                local skill = gm.array_get(skill_family, skill_index)
                skill_id_to_slot[skill.skill_id] = skill_slot
            end
        end
    end
end)
