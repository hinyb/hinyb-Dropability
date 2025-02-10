InstanceExtManager = {}
InstanceExtManager.callback_types = {}
local resolve_pre_script_callbacks = function(result, callbacks, ...)
    local flag = false
    for _, callback in pairs(callbacks) do
        local flag_, result_ = callback(...)
        flag = flag or flag_ == false
        if result_ then
            result.value = result_
        end
    end
    return not flag
end
local resolve_post_script_callbacks = function(result, callbacks, ...)
    for _, callback in pairs(callbacks) do
        local result_ = callback(...)
        if result_ then
            result.value = result_
        end
    end
end
local callbacks = {}
local enable_callbacks = {}
local script_callback_deal_funcs = {}
local enable_pre_script_callbacks = {}
local enable_post_script_callbacks = {}
function InstanceExtManager.register_script_callback(script_index, callback_name, deal_func)
    if not script_callback_deal_funcs[script_index] then
        script_callback_deal_funcs[script_index] = {}
    end
    if script_callback_deal_funcs[script_index][callback_name] then
        log.warning("try to override existings script callback")
    end
    script_callback_deal_funcs[script_index][callback_name] = deal_func
end
function InstanceExtManager.enable_pre_script_callback(script_index, callback_name)
    if not script_callback_deal_funcs[script_index] then
        log.error("Need to register before enable", 2)
    end
    if not enable_pre_script_callbacks[script_index] then
        enable_pre_script_callbacks[script_index] = {}
        local script_callbacks = enable_pre_script_callbacks[script_index]
        gm.pre_script_hook(script_index, function(self, other, result, args)
            local need_to_interrupt = false
            for callback_name, deal_func in pairs(script_callbacks) do
                local id, params_table = deal_func(self, other, result, args)
                local actor_callbacks = callbacks[id]
                local actor_script_callbacks = actor_callbacks and actor_callbacks[script_index]
                if actor_script_callbacks then
                    need_to_interrupt = need_to_interrupt or
                                            resolve_pre_script_callbacks(result, actor_script_callbacks[callback_name],
                            table.unpack(params_table)) == false
                end
            end
            return not need_to_interrupt
        end)
    end
    enable_pre_script_callbacks[script_index][callback_name] = script_callback_deal_funcs[script_index][callback_name]
    enable_callbacks[callback_name] = true
end
function InstanceExtManager.enable_post_script_callback(script_index)
    if not script_callback_deal_funcs[script_index] then
        log.error("Need to register before enable", 2)
    end
    if not enable_post_script_callbacks[script_index] then
        log.error("Alreadly been enabled", 2)
    end
    enable_post_script_callbacks[script_index] = true
    gm.post_script_hook(script_index, function(self, other, result, args)
        local script_callbacks = script_callback_deal_funcs[script_index]
        for callback_name, deal_func in pairs(script_callbacks) do
            local id, params_table = deal_func(self, other, result, args)
            local actor_callbacks = callbacks[id]
            local actor_script_callbacks = actor_callbacks and actor_callbacks[script_index]
            if actor_script_callbacks then
                resolve_post_script_callbacks(result, actor_script_callbacks[callback_name], table.unpack(params_table))
            end
        end
    end)
end
local resolve_pre_code_callbacks = function(callbacks, ...)
    local flag = false
    for _, callback in pairs(callbacks) do
        local flag_ = callback(...)
        flag = flag or flag_ == false
    end
    return not flag
end
local resolve_post_code_callbacks = function(callbacks, ...)
    for _, callback in pairs(callbacks) do
        callback(...)
    end
end
local code_callbacks_table = {}
local enable_pre_code_callbacks = {}
local enable_post_code_callbacks = {}
function InstanceExtManager.register_code_callback(code_name, callback_name, deal_func)
    if not code_callbacks_table[code_name] then
        code_callbacks_table[code_name] = {}
    end
    code_callbacks_table[code_name][callback_name] = deal_func
end
function InstanceExtManager.enable_pre_code_callback(code_name)
    if not code_callbacks_table[code_name] then
        log.error("Need to register before enable", 2)
    end
    if not enable_pre_code_callbacks[code_name] then
        log.error("Alreadly been enabled", 2)
    end
    enable_pre_code_callbacks[code_name] = true
    gm.pre_code_execute(code_name, function(self, other)
        local need_to_interrupt = false
        local code_callbacks = code_callbacks_table[code_name]
        for callback_name, deal_func in pairs(code_callbacks) do
            local id, params_table = deal_func(self, other)
            local actor_callbacks = callbacks[id]
            local actor_code_callbacks = actor_callbacks and actor_callbacks[code_name]
            if actor_code_callbacks then
                need_to_interrupt = need_to_interrupt or
                                        resolve_pre_code_callbacks(actor_code_callbacks[callback_name],
                        table.unpack(params_table)) == false
            end
        end
        return not need_to_interrupt
    end)
end
function InstanceExtManager.enable_post_code_callback(code_name)
    if not code_callbacks_table[code_name] then
        log.error("Need to register before enable", 2)
    end
    if not enable_post_code_callbacks[code_name] then
        log.error("Alreadly been enabled", 2)
    end
    enable_post_code_callbacks[code_name] = true
    gm.post_code_execute(code_name, function(self, other)
        local code_callbacks = code_callbacks_table[code_name]
        for callback_name, deal_func in pairs(code_callbacks) do
            local id, params_table = deal_func(self, other)
            local actor_callbacks = callbacks[id]
            local actor_code_callbacks = actor_callbacks and actor_callbacks[code_name]
            if actor_code_callbacks then
                resolve_post_code_callbacks(actor_code_callbacks[callback_name], table.unpack(params_table))
            end
        end
    end)
end
local function add_callback_internal(check_callbacks, instance, callback_id, callback_name, name, fn)
    if not check_callbacks[callback_id] and not check_callbacks[callback_id][callback_name] then
        log.error("Can't add Instance_ext callback", 2)
    end
    local id = instance.id
    if callbacks[id] == nil then
        callbacks[id] = {}
    end
    if callbacks[id][callback_id] == nil then
        callbacks[id][callback_id] = {}
    end
    if callbacks[id][callback_id][callback_name] == nil then
        callbacks[id][callback_id][callback_name] = {}
    end
    if callbacks[id][callback_id][callback_name][name] then
        log.warning("try to override", callback_id, callback_name, name)
    end
    callbacks[id][callback_id][callback_name][name] = fn
end
local function remove_callback_internal(instance, callback_id, callback_name, name)
    local id = instance.id
    if callbacks[id] and callbacks[id][callback_id] and callbacks[id][callback_id][callback_name] and
        callbacks[id][callback_id][callback_name][name] then
        callbacks[id][callback_id][callback_name][name] = nil
    end
end
function InstanceExtManager.add_pre_script_callback(instance, script_index, callback_name, name, fn)
    add_callback_internal(enable_pre_script_callbacks, instance, script_index, callback_name, name, fn)
end
function InstanceExtManager.add_post_script_callback(instance, script_index, callback_name, name, fn)
    add_callback_internal(enable_post_script_callbacks, instance, script_index, callback_name, name, fn)
end
function InstanceExtManager.remove_pre_script_callback(instance, script_index, callback_name, name)
    remove_callback_internal(instance, script_index, callback_name, name)
end
function InstanceExtManager.remove_post_script_callback(instance, script_index, callback_name, name)
    remove_callback_internal(instance, script_index, callback_name, name)
end
function InstanceExtManager.add_pre_code_callback(instance, code_name, callback_name, name, fn)
    add_callback_internal(enable_pre_code_callbacks, instance, code_name, callback_name, name, fn)
end
function InstanceExtManager.add_post_code_callback(instance, code_name, callback_name, name, fn)
    add_callback_internal(enable_post_code_callbacks, instance, code_name, callback_name, name, fn)
end
function InstanceExtManager.remove_pre_code_callback(instance, code_name, callback_name, name)
    remove_callback_internal(instance, code_name, callback_name, name)
end
function InstanceExtManager.remove_post_code_callback(instance, code_name, callback_name, name)
    remove_callback_internal(instance, code_name, callback_name, name)
end
