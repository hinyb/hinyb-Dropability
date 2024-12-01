SkillModifier.register_modifier("echo_item", function(skill, data, item_id)
    local current_frame = gm.variable_global_get("_current_frame")
    if gm.array_length(data) < 1 then
        gm.array_resize(data, 1)
    end
    local base = math.max(skill.cooldown_base, skill.animation)
    log.info(skill.cooldown_base, skill.animation)
    if current_frame - gm.array_get(data, 0) >= base * 2.4 then
        gm.item_give(skill.parent, item_id, 1, 0)
        gm.array_set(data, 0, current_frame)
        Alarm.create(function()
            log.info(" try to delete ")
            if Instance.exists(skill.parent) then
                gm.item_take(skill.parent, item_id, 1, 0)
            end
        end, math.floor(base * 1.2))
    end
end, nil, function(ori_desc, skill, item_id)
    local item = Class.ITEM:get(item_id)
    return "<y>"..Language.translate_token("skill_modifier.echo_item.name") .. "</c>: " ..
               Language.translate_token("skill_modifier.echo_item.description") .. "\n" ..
               Language.translate_token(item:get(2)) .. ": " .. Language.translate_token(item:get(3)) .. "\n" ..
               ori_desc
end)
