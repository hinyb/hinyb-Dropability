Instance_ext = {}
local callbacks = {}
local callbacks_check_table = {
    pre_destroy = true,
    post_local_drop = true,
    post_local_pickup = true
}
function Instance_ext.add_callback(self, callback, name, fn)
    if not callbacks_check_table[callback] then
        log.error("Can't add Instance_ext callback", 2)
    end
    if callbacks[self.id] == nil then
        callbacks[self.id] = {}
    end
    if callbacks[self.id][callback] == nil then
        callbacks[self.id][callback] = {}
    end
    callbacks[self.id][callback][name] = fn
end
function Instance_ext.remove_callback(self, callback, name)
    if callbacks[self.id] and callbacks[self.id][callback] and callbacks[self.id][callback][name] then
        callbacks[self.id][callback][name] = nil
    end
end
SkillPickup.add_post_local_drop_func(function (inst, skill)
    if callbacks[inst.id] and callbacks[inst.id]["post_local_drop"] then
        for _, func in pairs(callbacks[inst.id]["post_local_drop"]) do
            func(inst, skill)
        end
    end
end)
SkillPickup.add_post_local_pickup_func(function (inst, skill)
    if callbacks[inst.id] and callbacks[inst.id]["post_local_pickup"] then
        for _, func in pairs(callbacks[inst.id]["post_local_pickup"]) do
            func(inst, skill)
        end
    end
end)

gm.pre_script_hook(gm.constants.instance_destroy, function(self, other, result, args)
    local id = type(args[1].value) == "number" and args[1].value or args[1].value.id
    if callbacks[id] and callbacks[id]["pre_destroy"] then
        local flag = true
        for _, func in pairs(callbacks[id]["pre_destroy"]) do
            if func(gm.CInstance.instance_id_to_CInstance[id]) == false then
                flag = false
            end
        end
        return flag
    end
end)
gm.post_script_hook(gm.constants.instance_destroy, function(self, other, result, args)
    local id = type(args[1].value) == "number" and args[1].value or args[1].value.id
    callbacks[id] = nil
end)
gm.post_script_hook(gm.constants.run_destroy, function(self, other, result, args)
    callbacks = {}
end)
