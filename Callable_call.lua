HookSystem.clean_hook()
Callable_call = {}
local pre_callbacks = {}
local post_callbacks = {}
function Callable_call.add_pre_callback(callback_name, name, fn)
    if pre_callbacks[callback_name] == nil then
        pre_callbacks[callback_name] = {}
    end
    pre_callbacks[callback_name][name] = fn
end
function Callable_call.add_post_callback(callback_name, name, fn)
    if post_callbacks[callback_name] == nil then
        post_callbacks[callback_name] = {}
    end
    post_callbacks[callback_name][name] = fn
end
function Callable_call.remove_pre_callback(callback_name, name)
    if pre_callbacks[callback_name] and pre_callbacks[callback_name][name] then
        pre_callbacks[callback_name][name] = nil
        if Utils.table_get_length(pre_callbacks[callback_name]) == 0 then
            pre_callbacks[callback_name] = nil
        end
    end
end
function Callable_call.remove_post_callback(callback_name, name)
    if post_callbacks[callback_name] and post_callbacks[callback_name][name] then
        post_callbacks[callback_name][name] = nil
        if Utils.table_get_length(post_callbacks[callback_name]) == 0 then
            post_callbacks[callback_name] = nil
        end
    end
end

function Callable_call.add_capture_instance(callback_name, name, deal_func, check_func, pre_ext_func, post_ext_func)
    check_func = check_func or function(...)
        return true
    end
    Callable_call.add_pre_callback(callback_name, name, function(self, other, result, args)
        if check_func(self, other, result, args) then
            Utils.hook_instance_create({gm.constants.oActorTargetEnemy, gm.constants.oActorTargetPlayer})
        end
        if pre_ext_func then
            pre_ext_func(self, other, result, args)
        end
    end)
    Callable_call.add_post_callback(callback_name, name, function(self, other, result, args)
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
function Callable_call.remove_capture_instance(callback_name, name)
    Callable_call.remove_pre_callback(callback_name, name)
    Callable_call.remove_post_callback(callback_name, name)
end

HookSystem.pre_script_hook(gm.constants.callable_call, function(self, other, result, args)
    local script = args[1].value
    local callable_value = script.callable_value
    if script and type(callable_value) ~= "number" then
        local pre_callbacks = pre_callbacks[callable_value.script_name]
        if pre_callbacks then
            for _, fn in pairs(pre_callbacks) do
                fn(self, other, result, args)
            end
        end
    end
end)

HookSystem.post_script_hook(gm.constants.callable_call, function(self, other, result, args)
    local script = args[1].value
    local callable_value = script.callable_value
    if script and type(callable_value) ~= "number" then
        local post_callbacks = post_callbacks[callable_value.script_name]
        if post_callbacks then
            for _, fn in pairs(post_callbacks) do
                fn(self, other, result, args)
            end
        end
    end
end)
return Callable_call
