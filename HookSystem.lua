HookSystem = {}
local enable_pre_script_hooks = {}
local enable_post_script_hooks = {}
local enable_pre_code_executes = {}
local enable_post_code_executes = {}
local special_hooks = {}

local function clean_hook_internal(callbacks_table, identifier)
    for i = 1, #callbacks_table do
        if callbacks_table[i].id == identifier then
            table.remove(callbacks_table, i)
        end
    end
end

local exist_files_table = {}
function HookSystem.clean_hook()
    local caller_file = debug.getinfo(2, "S").source
    local identifier = caller_file:match("ReturnOfModding[/\\]plugins[/\\](.+)$")
    if not exist_files_table[identifier] then
        exist_files_table[identifier] = true
        return
    end
    clean_hook_internal(enable_pre_script_hooks, identifier)
    clean_hook_internal(enable_post_script_hooks, identifier)
    clean_hook_internal(enable_pre_code_executes, identifier)
    clean_hook_internal(enable_post_code_executes, identifier)
    for _, hooks in pairs(special_hooks) do
        clean_hook_internal(hooks, identifier)
    end
end
local function script_hook_internal(hook_table, script_index, fn)
    local caller_file = debug.getinfo(3, "S").source
    local identifier = caller_file:match("ReturnOfModding[/\\]plugins[/\\](.+)$")
    local script_hooks = hook_table[script_index]
    if not script_hooks then
        script_hooks = {}
        hook_table[script_index] = script_hooks
        if hook_table == enable_pre_script_hooks then
            gm.pre_script_hook(script_index, function(self, other, result, args)
                local need_to_interrupt = false
                for i = 1, #script_hooks do
                    need_to_interrupt = need_to_interrupt or script_hooks[i].fn(self, other, result, args) == false
                end
                return not need_to_interrupt
            end)
        else
            gm.post_script_hook(script_index, function(self, other, result, args)
                for i = 1, #script_hooks do
                    script_hooks[i].fn(self, other, result, args)
                end
            end)
        end
    end
    script_hooks[#script_hooks + 1] = {
        fn = fn,
        id = identifier
    }
end
function HookSystem.pre_script_hook(script_index, fn)
    script_hook_internal(enable_pre_script_hooks, script_index, fn)
end
function HookSystem.post_script_hook(script_index, fn)
    script_hook_internal(enable_post_script_hooks, script_index, fn)
end

local function code_execute_internal(execute_table, code_name, fn)
    local caller_file = debug.getinfo(3, "S").source
    local identifier = caller_file:match("ReturnOfModding[/\\]plugins[/\\](.+)$")
    local code_executes = execute_table[code_name]
    if not code_executes then
        code_executes = {}
        execute_table[code_name] = code_executes
        if execute_table == enable_pre_code_executes then
            gm.pre_code_execute(code_name, function(self, other)
                local need_to_interrupt = false
                for i = 1, #code_executes do
                    need_to_interrupt = need_to_interrupt or code_executes[i].fn(self, other) == false
                end
                return not need_to_interrupt
            end)
        else
            gm.post_code_execute(code_name, function(self, other)
                for i = 1, #code_executes do
                    code_executes[i].fn(self, other)
                end
            end)
        end
    end

    code_executes[#code_executes + 1] = {
        fn = fn,
        id = identifier
    }
end
function HookSystem.pre_code_execute(code_name, fn)
    code_execute_internal(enable_pre_code_executes, code_name, fn)
end
function HookSystem.post_code_execute(code_name, fn)
    code_execute_internal(enable_post_code_executes, code_name, fn)
end

function HookSystem.register_special_hook(hook_name, callbacks_table)
    if special_hooks[hook_name] then
        log.error("The special hook is alreadly existed", 2)
    end
    special_hooks[hook_name] = callbacks_table
end

function HookSystem.add_special_hook(hook_name, fn)
    local hooks = special_hooks[hook_name]
    if not hooks then
        log.error("Try to add a non-existed special hook", 2)
    end
    local caller_file = debug.getinfo(2, "S").source
    local identifier = caller_file:match("ReturnOfModding[/\\]plugins[/\\](.+)$")

    hooks[#hooks + 1] = {
        fn = fn,
        id = identifier
    }
end

local names = path.get_files(_ENV["!plugins_mod_folder_path"] .. "/DynamicRegs")
for _, name in ipairs(names) do
    require(name)
end
