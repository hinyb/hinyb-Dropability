-- Need this to interrupte instance_destroy
-- Some Instance don't use instance_destroy, like bullet.
local cache_id = -4
local cache_execute_event_flag
local cache_instance_map = gm.CInstance.instance_id_to_CInstance
-- self(or 0) other(or 0) instance_id(or -1) execute_event_flag rollback_flag
local callbacks = InstanceExtManager.callbacks
InstanceExtManager.enable_callback("pre_destroy")
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
        if callbacks[id] and callbacks[id]["pre_destroy"] then
            local inst = cache_instance_map[id]
            local flag = true
            for _, func in pairs(callbacks[id]["pre_destroy"]) do
                if func(inst) == false then
                    flag = false
                    cache_execute_event_flag = 1
                end
            end
            return flag
        end
    end, function(ret_val, a1, a2, a3, execute_event_flag, rollback_flag)
        if cache_execute_event_flag ~= 1 then
            return
        end
        callbacks[cache_id] = nil
    end)
