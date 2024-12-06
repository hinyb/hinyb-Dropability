SkillModifier.register_modifier("echo_item", 3200, function(skill, data, item_id)
    local last_frame = 0
    local stack = 0
    local alarm_stop = function()
    end
    local stop_frame = 0
    SkillModifier.add_on_activate_callback(data, function(skill_)
        local current_frame = gm.variable_global_get("_current_frame")
        local base = math.max(skill_.cooldown_base, 10)
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
            skill_.use_next_frame = current_frame + (base + 30) * 4
        end, math.floor(base + 30))
    end)
end, function(skill, data)
    SkillModifier.remove_on_activate_callback(data)
end, function(ori_desc, skill, item_id)
    local item = Class.ITEM:get(item_id)
    return "<y>" .. Language.translate_token("skill_modifier.echo_item.name") .. ": " ..
               Language.translate_token("skill_modifier.echo_item.description") .. "\n" ..
               Language.translate_token(item:get(2)) .. ": " .. Language.translate_token(item:get(3)) .. "\n" ..
               ori_desc
end, function(skill)
    return Item.get_random().value
end)

SkillModifier.register_modifier("void_power", 250, function(skill, data)
    gm.get_script_ref(102397)(skill, skill.parent)
    SkillModifier.change_attr_func(skill, "damage", data, function(origin_value)
        return origin_value * 2 ^ Utils.empty_skill_num
    end)
    SkillPickup.add_local_drop_callback(skill, function()
        gm.get_script_ref(102397)(skill, skill.parent)
    end)
    SkillPickup.add_local_pick_callback(skill, function()
        gm.get_script_ref(102397)(skill, skill.parent)
    end)
end, function(skill, data)
    SkillPickup.remove_local_drop_callback(skill)
    SkillPickup.remove_local_pick_callback(skill)
    SkillModifier.restore_attr(skill, "damage", data)
end)

SkillModifier.register_modifier("life_burn", 250, function(skill, data)
    SkillModifier.add_on_can_activate_callback(data, function(skill_, result)
        if not result.value then
            local current_frame = gm.variable_global_get("_current_frame")
            if skill_.use_next_frame <= current_frame then
                if skill_.stock < skill_.max_stock then
                    Utils.sync_call("gml_Script_actor_skill_add_stock", "host", skill_.parent, skill_.slot_index)
                    gm.call("gml_Script_actor_skill_add_stock", skill_.parent, skill_.slot_index)
                    local num = Utils.get_handy_drone_type(skill_.skill_id) ~= nil and 25 or skill_.cooldown_base / 60 *
                                    5
                    Utils.set_and_sync_inst_from_table(skill_.parent, {
                        hp = skill_.parent.hp - num
                    })
                end
            end
        end
    end)
end, function(skill, data)
    SkillModifier.remove_on_can_activate_callback(data)
end)
SkillModifier.register_modifier("after_image", 3200, function(skill, data, item_id)
    SkillModifier.add_on_activate_callback(data, function(skill_)
        gm.apply_buff(skill_.parent, 44.0, skill_.cooldown_base)
    end)
end, function(skill, data)
    SkillModifier.remove_on_activate_callback(data)
end)
local function register_buffer(attr, fn)
    SkillModifier.register_modifier("flux_" .. attr, 125, function(skill, data, value)
        SkillModifier.change_attr(skill, attr, data, value)
    end, function(skill, data)
        SkillModifier.restore_attr(skill, attr, data)
    end, function(ori_desc, skill)
        return Language.translate_token("skill_modifier.flux.name") .. "•" ..
                   Language.translate_token("skill_modifier.flux." .. attr) .. ": " ..
                   Language.translate_token("skill_modifier.flux.description") .. "\n" .. ori_desc
    end, function(skill)
        return fn(skill)
    end)
end

register_buffer("max_stock", function(skill)
    return Utils.round(Utils.get_gaussian_random(1.36, 1))
end)
register_buffer("damage", function(skill)
    return Utils.round(Utils.get_gaussian_random(skill.damage * 1.36, skill.damage * 1.36))
end)
register_buffer("cooldown", function(skill)
    return Utils.round(Utils.get_gaussian_random(skill.cooldown * 1.36, skill.cooldown * 1.36))
end)
register_buffer("slot_index", function(skill)
    return Utils.get_random(0, 3)
end)
