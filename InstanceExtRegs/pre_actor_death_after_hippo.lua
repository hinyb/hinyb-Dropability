HookSystem.clean_hook()
local callbacks = InstanceExtManager.callbacks
InstanceExtManager.enable_callback("pre_actor_death_after_hippo")
HookSystem.pre_script_hook(gm.constants.actor_death, function(self, other, result, args)
    if gm.array_get(self.inventory_item_stack, 76) == 0 then -- temporary solution.
        local id = self.id
        local inst_callbacks = callbacks[id]
        if not inst_callbacks then
            return
        end
        local pre_actor_death_after_hippo_callbacks = inst_callbacks.pre_actor_death_after_hippo
        if not pre_actor_death_after_hippo_callbacks then
            return
        end
        local need_to_interrupt = false
        for _, callback in pairs(pre_actor_death_after_hippo_callbacks) do
            --- actor ---
            local flag, result_ = callback(self)
            need_to_interrupt = need_to_interrupt or flag == false
            if result_ then
                result.value = result_
            end
        end
        return not need_to_interrupt
    end
end)
