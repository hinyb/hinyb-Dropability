-- Need this to interrupte instance_destroy
-- Some Instance don't use instance_destroy, like bullet.
local cache_id = -4
local cache_execute_event_flag
local cache_instance_map = gm.CInstance.instance_id_to_CInstance
-- self(or 0) other(or 0) instance_id(or -1) execute_event_flag rollback_flag
local callbacks = InstanceExtManager.callbacks
InstanceExtManager.enable_callback("pre_instance_destroy")
InstanceExtManager.enable_callback("post_instance_destroy")

memory.dynamic_hook("pre_destroy_deep", "int64_t", {"CInstance*", "CInstance*", "int", "char", "char"},
    Dynamic.instance_destroy_deep_ptr, function(ret_val, a1, a2, a3, execute_event_flag, rollback_flag)
        cache_execute_event_flag = execute_event_flag:get()
        if cache_execute_event_flag ~= 1 then
            return
        end
        local id = a3:get()
        if id == 4294967295 then -- It should be -1 here, but ReturnOfModdingBase handles all integers as int64_t.
            id = a1.id
        end
        cache_id = id
        local instance_callbacks = callbacks[id]
        if not instance_callbacks then
            return
        end
        local pre_instance_destroy_callbacks = instance_callbacks.pre_instance_destroy
        if pre_instance_destroy_callbacks then
            local inst = cache_instance_map[id]
            local flag = true
            for _, fn in pairs(pre_instance_destroy_callbacks) do
                if fn(inst) == false then
                    flag = false
                    cache_execute_event_flag = 0
                end
            end
            return flag
        end
    end, function(ret_val, a1, a2, a3, execute_event_flag, rollback_flag)
        if cache_execute_event_flag ~= 1 then
            return
        end
        local instance_callbacks = callbacks[cache_id]
        if instance_callbacks then
            local post_instance_destroy_callbacks = instance_callbacks.post_instance_destroy
            if post_instance_destroy_callbacks then
                local inst = cache_instance_map[cache_id]
                for _, fn in pairs(post_instance_destroy_callbacks) do
                    fn(inst)
                end
            end
        end
        callbacks[cache_id] = nil
    end)
