Callback_ext = {}
local pre_callbacks = {}
local post_callbacks = {}
function Callback_ext.add_pre_callback(callback_id, name, fn)
    if pre_callbacks[callback_id] == nil then
        pre_callbacks[callback_id] = {}
    end
    pre_callbacks[callback_id][name] = fn
end
function Callback_ext.add_post_callback(callback_id, name, fn)
    if post_callbacks[callback_id] == nil then
        post_callbacks[callback_id] = {}
    end
    if post_callbacks[callback_id][name] then
        log.warning("try to override", callback_id, name)
    end
    post_callbacks[callback_id][name] = fn
end
function Callback_ext.remove_pre_callback(callback_id, name)
    if pre_callbacks[callback_id] and pre_callbacks[callback_id][name] then
        pre_callbacks[callback_id][name] = nil
        if Utils.table_get_length(pre_callbacks[callback_id]) == 0 then
            pre_callbacks[callback_id] = nil
        end
    end
end
function Callback_ext.remove_post_callback(callback_id, name)
    if post_callbacks[callback_id] and post_callbacks[callback_id][name] then
        post_callbacks[callback_id][name] = nil
        if Utils.table_get_length(post_callbacks[callback_id]) == 0 then
            post_callbacks[callback_id] = nil
        end
    end
end
function Callback_ext.add_capture_instance(callback_id, name, deal_func, check_func, pre_ext_func, post_ext_func)
    check_func = check_func or function(...)
        return true
    end
    Callback_ext.add_pre_callback(callback_id, name, function(self, other, result, args)
        if check_func(self, other, result, args) then
            Utils.hook_instance_create({gm.constants.oActorTargetEnemy, gm.constants.oActorTargetPlayer})
        end
        if pre_ext_func then
            pre_ext_func(self, other, result, args)
        end
    end)
    Callback_ext.add_post_callback(callback_id, name, function(self, other, result, args)
        if check_func(self, other, result, args) then
            local list = Utils.get_tracked_instances()
            for i = 1, #list do
                deal_func(list[i])
            end
            Utils.unhook_instance_create()
        end
        if post_ext_func then
            post_ext_func(self, other, result, args)
        end
    end)
end
function Callback_ext.remove_capture_instance(callback_id, name)
    Callback_ext.remove_pre_callback(callback_id, name)
    Callback_ext.remove_post_callback(callback_id, name)
end

gm.pre_script_hook(gm.constants.callback_execute, function(self, other, result, args)
    if pre_callbacks[args[1].value] then
        for _, fn in pairs(pre_callbacks[args[1].value]) do
            fn(self, other, result, args)
        end
    end
end)
gm.post_script_hook(gm.constants.callback_execute, function(self, other, result, args)
    if post_callbacks[args[1].value] then
        for _, fn in pairs(post_callbacks[args[1].value]) do
            fn(self, other, result, args)
        end
    end
end)
return Callback_ext
