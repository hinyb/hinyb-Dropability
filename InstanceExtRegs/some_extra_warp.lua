--- actually post_step with some checks.
function InstanceExtManager.add_on_anim_end(instance, name, fn)
    name = name .. "on_anim_end"
    if not InstanceExtManager.callback_exists(instance, "pre_step", name) then
        local flag
        InstanceExtManager.add_callback(instance, "pre_step", name, function(instance, event_number)
            if event_number:get() ~= 2 then
                return
            end
            if flag == nil then
                flag = gm.bool(instance.state_strafe_half)
                return
            end
            if flag == false then
                local image_index = instance.image_index
                local image_number = instance.image_number
                if not (math.abs(image_index - image_number + 1) <= 0.0001 or image_index >= image_number - 1) then
                    return
                end
            elseif gm.bool(instance.state_strafe_half) == flag then
                return
            end
            return (fn(instance) or HookFlags.fNone) | HookFlags.fDelete
        end)
    end
end

function InstanceExtManager.add_post_other_fire(instance, name, fn)
    InstanceExtManager.add_callback(instance, "post_other_fire_explosion", name, fn)
    InstanceExtManager.add_callback(instance, "post_other_fire_direct", name, fn)
    InstanceExtManager.add_callback(instance, "post_other_fire_bullet", name, fn)
end

function InstanceExtManager.remove_post_other_fire(instance, name)
    InstanceExtManager.remove_callback(instance, "post_other_fire_explosion", name)
    InstanceExtManager.remove_callback(instance, "post_other_fire_direct", name)
    InstanceExtManager.remove_callback(instance, "post_other_fire_bullet", name)
end
