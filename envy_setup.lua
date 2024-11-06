-- ENVY

function public.setup(env)
    if env == nil then
        env = envy.getfenv(2)
    end
    local wrapper = {}
    for k, v in pairs(public_things) do
        wrapper[k] = v
    end
    return wrapper
end


function public.auto()
    local env = envy.getfenv(2)
    local wrapper = public.setup(env)
    envy.import_as_shared(env, wrapper)
end
