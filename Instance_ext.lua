Instance_ext = {}
local callbacks = {
    pre_destroy = {}
}
function Instance_ext.add_callback(self, callback, name, fn)
    if callbacks[callback] == nil then
        log.error("Can't add Instance_ext callback", 2)
    end
    if callbacks[callback][self.id] == nil then
        callbacks[callback][self.id] = {}
    end
    if callbacks[callback][self.id][name] == nil then
        callbacks[callback][self.id][name] = {}
    end
    table.insert(callbacks[callback][self.id][name], fn)
end
function Instance_ext.remove_callback(self, callback, name)
    if callbacks[callback][self.id] and callbacks[callback][self.id][name] then
        callbacks[callback][self.id][name] = {}
    end
end

gm.pre_script_hook(gm.constants.instance_destroy, function(self, other, result, args)
    local id = type(args[1].value) == "number" and args[1].value or args[1].value.id
    if callbacks["pre_destroy"][id] then
        local flag = true
        for _, funcs in pairs(callbacks["pre_destroy"][id]) do
            for i = 1, #funcs do
                if funcs[i](gm.CInstance.instance_id_to_CInstance[id]) == false then
                    flag = false
                end
            end
        end
        return flag
    end
end)
