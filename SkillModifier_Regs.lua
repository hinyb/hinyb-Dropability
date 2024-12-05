SkillModifier.register_modifier("echo_item", function(skill, item_id)
    local last_frame = 0
    local stack = 0
    local alarm_stop = function()
    end
    local stop_frame = 0
    SkillModifier.add_on_activate_callback(skill, function(skill_)
        local current_frame = gm.variable_global_get("_current_frame")
        if current_frame <= stop_frame then
            return false
        end
        local base = math.max(skill_.cooldown_base, skill_.animation)
        if current_frame - last_frame >= base and stack < 4 then
            stack = stack + 1
            gm.item_give(skill_.parent, item_id, 1, 0)
            last_frame = current_frame
        end
        alarm_stop()
        alarm_stop = Utils.add_alarm(function()
            if Instance.exists(skill_.parent) then
                gm.item_take(skill_.parent, item_id, stack, 0)
            end
            stack = 0
            stop_frame = current_frame + base * 8
        end, math.floor(base * 2.4))
    end)
end, function(skill)
    SkillModifier.remove_on_activate_callback(skill)
end, function(ori_desc, skill, item_id)
    local item = Class.ITEM:get(item_id)
    return "<y>" .. Language.translate_token("skill_modifier.echo_item.name") .. ": " ..
               Language.translate_token("skill_modifier.echo_item.description") .. "\n" ..
               Language.translate_token(item:get(2)) .. ": " .. Language.translate_token(item:get(3)) .. "\n" ..
               ori_desc
end)

SkillModifier.register_modifier("void_power", function(skill, item_id)
    gm.get_script_ref(102397)(skill, skill.parent)
    SkillModifier.change_attr_func(skill, "damage", function(origin_value)
        return origin_value * 2 ^ Utils.empty_skill_num
    end)
    SkillPickup.add_local_drop_callback(skill, function()
        gm.get_script_ref(102397)(skill, skill.parent)
    end)
    SkillPickup.add_local_pick_callback(skill, function()
        gm.get_script_ref(102397)(skill, skill.parent)
    end)
end, function(skill)
    SkillPickup.remove_local_drop_callback(skill)
    SkillPickup.remove_local_pick_callback(skill)
    SkillModifier.restore_attr(skill, "damage")
end)

local function register_buffer(attr, mu, sigma)
    SkillModifier.register_modifier("booster_" .. attr, function(skill)
        SkillModifier.change_attr(skill, attr, Utils.round(Utils.get_gaussian_random(mu(skill), sigma(skill))))
    end, function(skill)
        SkillModifier.restore_attr(skill, attr)
    end, function(ori_desc, skill)
        return Language.translate_token("skill_modifier.booster.name") .. " • " ..
                   Language.translate_token("skill_modifier.booster" .. attr) .. ": " ..
                   Language.translate_token("skill_modifier.booster.description") .. "\n" .. ori_desc
    end)
end

register_buffer("max_stock", function ()
    return 1.36
end, function ()
    return 1
end)
register_buffer("damage", function (skill)
    return skill.damage * 1.36
end, function (skill)
    return skill.damage * 1.36
end)
register_buffer("cooldown", function (skill)
    return skill.cooldown / 1.36
end, function (skill)
    return skill.cooldown / 1.36
end)