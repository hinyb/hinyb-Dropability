HookSystem.clean_hook()
local callbacks = InstanceExtManager.callbacks
InstanceExtManager.enable_callback("on_kill_other")
InstanceExtManager.enable_callback("on_killed_by")
Callback_ext.add_post_callback(40, "instance_on_kill", function(self, other, result, args)
    local victim = args[2].value
    local attacker = args[3].value

    local victim_cbs = callbacks[victim.id]
    if victim_cbs and victim_cbs.on_killed_by then
        for _, callback in pairs(victim_cbs.on_killed_by) do
            callback(victim, attacker)
        end
    end

    local attacker_cbs = callbacks[attacker.id]
    if attacker_cbs and attacker_cbs.on_kill_other then
        for _, callback in pairs(attacker_cbs.on_kill_other) do
            callback(attacker, victim)
        end
    end
end)
