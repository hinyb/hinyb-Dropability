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
