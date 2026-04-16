Utils.random_item_id = function(random_seed)
    local random = Utils.LCG_random(random_seed)
    return function()
        while true do
            local item = Class.Item[random(1, Class.Item:size())]
            if item.identifier ~= "dummyItem" then
                return item.value
            end
        end
    end
end