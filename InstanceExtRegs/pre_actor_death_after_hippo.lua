HookSystem.clean_hook()
local callbacks = InstanceExtManager.callbacks
InstanceExtManager.enable_callback("on_actor_death_after_hippo")
local hippt_ptr = gm.get_script_function_address(gm.constants.actor_death):add(3213)
memory.dynamic_hook_mid("on_actor_death_after_hippo", {"[rbp+2880h+10h]"}, {"CInstance*"}, 0,
    gm.get_script_function_address(gm.constants.actor_death):add(3276), function(args)
        local id = args[1].id
        local inst_callbacks = callbacks[id]
        if not inst_callbacks then
            return
        end
        local on_actor_death_after_hippo_callbacks = inst_callbacks.on_actor_death_after_hippo
        if not on_actor_death_after_hippo_callbacks then
            return
        end
        local need_to_interrupt = false
        for _, callback in pairs(on_actor_death_after_hippo_callbacks) do
            local flag = callback(args[1])
            need_to_interrupt = need_to_interrupt or flag == false
        end
        if need_to_interrupt then
            return hippt_ptr
        end
    end)