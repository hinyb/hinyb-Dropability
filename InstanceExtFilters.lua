InstanceExtFilters = {}
InstanceExtFilters.filter_funcs = {}
InstanceExtFilters.filter_types = {}
InstanceExtFilters.filter_counts = 0
function InstanceExtFilters.register_filter(name, fn)
    local index = InstanceExtFilters.filter_counts + 1
    InstanceExtFilters.filter_funcs[index] = fn
    InstanceExtFilters.filter_types[name] = index
end
