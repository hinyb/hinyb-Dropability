-- maybe useless
InstanceExtManager = {}
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
local pre_script_callbacks = {}
local post_script_callbacks = {}
local script_callbacks_check_table = {}
local script_callbacks_extra_check_table = {}
function InstanceExtManager.register_script(script_index, deal_func, extra_check)
    script_callbacks_check_table[script_index] = true
    script_callbacks_extra_check_table[script_index] = extra_check
    gm.pre_script_hook(script_index, function(self, other, result, args)
        local id, params_table = deal_func(self, other, result, args)
        local actor_callbacks = pre_script_callbacks[id]
        if actor_callbacks and actor_callbacks[script_index] then
            return resolve_pre_script_callbacks(result, actor_callbacks[script_index], table.unpack(params_table))
        end
    end)
    gm.post_script_hook(script_index, function(self, other, result, args)
        local id, params_table = deal_func(self, other, result, args)
        local actor_callbacks = post_script_callbacks[id]
        if actor_callbacks then
            local script_callbacks = actor_callbacks[script_index]
            if script_callbacks then
                resolve_post_script_callbacks(result, script_callbacks, table.unpack(params_table))
            end
        end
    end)
end
local function add_callback_internal(self, callback, name, fn, check_table, extra_check_table, callbacks)
    if not check_table[callback] then
        log.error("Can't add Instance_ext callback", 2)
    end
    local extra_check = extra_check_table[callback]
    if extra_check then
        extra_check(self, callback, name, fn)
    end
    local id = self.id
    if callbacks[id] == nil then
        callbacks[id] = {}
    end
    if callbacks[id][callback] == nil then
        callbacks[id][callback] = {}
    end
    if callbacks[id][callback][name] then
        log.warning("try to override", callback, name)
    end
    callbacks[id][callback][name] = fn
end
local function remove_callback_internal(self, callback, name, callbacks)
    local id = self.id
    if callbacks[id] and callbacks[id][callback] and callbacks[id][callback][name] then
        callbacks[id][callback][name] = nil
    end
end
function InstanceExtManager.add_pre_script_callback(self, callback, name, fn)
    add_callback_internal(self, callback, name, fn, script_callbacks_check_table, script_callbacks_extra_check_table, pre_script_callbacks)
end
function InstanceExtManager.add_post_script_callback(self, callback, name, fn)
    add_callback_internal(self, callback, name, fn, script_callbacks_check_table, script_callbacks_extra_check_table, post_script_callbacks)
end
function InstanceExtManager.remove_pre_script_callback(self, callback, name)
    remove_callback_internal(self, callback, name, pre_script_callbacks)
end
function InstanceExtManager.remove_post_script_callback(self, callback, name)
    remove_callback_internal(self, callback, name, post_script_callbacks)
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
local pre_code_callbacks = {}
local post_code_callbacks = {}
local code_callbacks_check_table = {}
local code_callbacks_extra_check_table = {}
function InstanceExtManager.register_code(code_name, deal_func, extra_check)
    code_callbacks_check_table[code_name] = true
    code_callbacks_extra_check_table[code_name] = extra_check
    gm.pre_code_execute(code_name, function(self, other)
        local id, params_table = deal_func(self, other)
        local actor_callbacks = pre_code_callbacks[id]
        if actor_callbacks and actor_callbacks[code_name] then
            return resolve_pre_code_callbacks(actor_callbacks[code_name], table.unpack(params_table))
        end
    end)
    gm.post_script_hook(code_name, function(self, other)
        local id, params_table = deal_func(self, other)
        local actor_callbacks = post_code_callbacks[id]
        if actor_callbacks then
            local script_callbacks = actor_callbacks[code_name]
            if script_callbacks then
                resolve_post_code_callbacks(script_callbacks, table.unpack(params_table))
            end
        end
    end)
end
function InstanceExtManager.add_pre_code_callback(self, callback, name, fn)
    add_callback_internal(self, callback, name, fn, code_callbacks_check_table, code_callbacks_extra_check_table, pre_code_callbacks)
end
function InstanceExtManager.add_post_code_callback(self, callback, name, fn)
    add_callback_internal(self, callback, name, fn, code_callbacks_check_table, code_callbacks_extra_check_table, post_code_callbacks)
end
function InstanceExtManager.remove_pre_code_callback(self, callback, name)
    remove_callback_internal(self, callback, name, pre_code_callbacks)
end
function InstanceExtManager.remove_post_code_callback(self, callback, name)
    remove_callback_internal(self, callback, name, post_code_callbacks)
end
