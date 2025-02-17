local step = 1
local sprite_top_edge_cache = {}
Utils.get_sprite_top_edge = function(sprite_index, image_index, x_offset)
    --[[
    I think the check is unnecessary.
    local sprite_number = gm.sprite_get_number(sprite_index)
    if image_index >= sprite_number then
        log.error("image_index is our of range")
    end
    ]]
    image_index = math.floor(image_index + 1e-5) -- when climbing down, it may become negative due to precision errors.
    if sprite_top_edge_cache[sprite_index] and sprite_top_edge_cache[sprite_index][image_index] then
        return sprite_top_edge_cache[sprite_index][image_index]
    end
    local img_height = gm.sprite_get_height(sprite_index);
    local result = img_height - 1;
    local my_surface = gm.surface_create(128, 128)
    gm.surface_set_target(my_surface)
    gm.draw_sprite(sprite_index, image_index, gm.sprite_get_xoffset(sprite_index), gm.sprite_get_yoffset(sprite_index))
    for y = 0, img_height - 1, step do
        local col = gm.surface_getpixel_ext(my_surface, x_offset, y)
        local alpha = (col >> 24) & 255
        if alpha ~= 0 then
            result = y
            break
        end
    end
    gm.surface_reset_target()
    gm.surface_free(my_surface)
    if not sprite_top_edge_cache[sprite_index] then
        sprite_top_edge_cache[sprite_index] = {}
    end
    sprite_top_edge_cache[sprite_index][image_index] = result
    return result
end
local sprite_bottom_edge_cache = {}
Utils.get_sprite_bottom_edge = function(sprite_index, image_index, x_offset)
    --[[
    I think the check is unnecessary.
    local sprite_number = gm.sprite_get_number(sprite_index)
    if image_index >= sprite_number then
        log.error("image_index is our of range")
    end
    ]]
    image_index = math.floor(image_index + 1e-5) -- when climbing down, it may become negative due to precision errors.
    if sprite_bottom_edge_cache[sprite_index] and sprite_bottom_edge_cache[sprite_index][image_index] then
        return sprite_bottom_edge_cache[sprite_index][image_index]
    end
    local img_height = gm.sprite_get_height(sprite_index);
    local result = 0;
    local my_surface = gm.surface_create(128, 128)
    gm.surface_set_target(my_surface)
    gm.draw_sprite(sprite_index, image_index, gm.sprite_get_xoffset(sprite_index), gm.sprite_get_yoffset(sprite_index))
    for y = img_height - 1, 0, step do
        local col = gm.surface_getpixel_ext(my_surface, x_offset, y)
        local alpha = (col >> 24) & 255
        if alpha ~= 0 then
            result = y
            break
        end
    end
    gm.surface_reset_target()
    gm.surface_free(my_surface)
    if not sprite_bottom_edge_cache[sprite_index] then
        sprite_bottom_edge_cache[sprite_index] = {}
    end
    sprite_bottom_edge_cache[sprite_index][image_index] = result
    return result
end
local sprite_left_edge_cache = {}
Utils.get_sprite_left_edge = function(sprite_index, image_index, y_offset)
    --[[
    I think the check is unnecessary.
    local sprite_number = gm.sprite_get_number(sprite_index)
    if image_index >= sprite_number then
        log.error("image_index is our of range")
    end
    ]]
    image_index = math.floor(image_index + 1e-5) -- when climbing down, it may become negative due to precision errors.
    if sprite_left_edge_cache[sprite_index] and sprite_left_edge_cache[sprite_index][image_index] then
        return sprite_left_edge_cache[sprite_index][image_index]
    end
    local img_width = gm.sprite_get_width(sprite_index);
    local result = img_width - 1;
    local my_surface = gm.surface_create(128, 128)
    gm.surface_set_target(my_surface)
    gm.draw_sprite(sprite_index, image_index, gm.sprite_get_xoffset(sprite_index), gm.sprite_get_yoffset(sprite_index))
    for x = 0, img_width - 1, step do
        local col = gm.surface_getpixel_ext(my_surface, x, y_offset)
        local alpha = (col >> 24) & 255
        if alpha ~= 0 then
            result = x
            break
        end
    end
    gm.surface_reset_target()
    gm.surface_free(my_surface)
    if not sprite_left_edge_cache[sprite_index] then
        sprite_left_edge_cache[sprite_index] = {}
    end
    sprite_left_edge_cache[sprite_index][image_index] = result
    return result
end
local sprite_right_edge_cache = {}
Utils.get_sprite_right_edge = function(sprite_index, image_index, y_offset)
    --[[
    I think the check is unnecessary.
    local sprite_number = gm.sprite_get_number(sprite_index)
    if image_index >= sprite_number then
        log.error("image_index is our of range")
    end
    ]]
    image_index = math.floor(image_index + 1e-5) -- when climbing down, it may become negative due to precision errors.
    if sprite_right_edge_cache[sprite_index] and sprite_right_edge_cache[sprite_index][image_index] then
        return sprite_right_edge_cache[sprite_index][image_index]
    end
    local img_width = gm.sprite_get_width(sprite_index);
    local result = 0;
    local my_surface = gm.surface_create(128, 128)
    gm.surface_set_target(my_surface)
    gm.draw_sprite(sprite_index, image_index, gm.sprite_get_xoffset(sprite_index), gm.sprite_get_yoffset(sprite_index))
    for x = img_width - 1, 0, step do
        local col = gm.surface_getpixel_ext(my_surface, x, y_offset)
        local alpha = (col >> 24) & 255
        if alpha ~= 0 then
            result = x
            break
        end
    end
    gm.surface_reset_target()
    gm.surface_free(my_surface)
    if not sprite_right_edge_cache[sprite_index] then
        sprite_right_edge_cache[sprite_index] = {}
    end
    sprite_right_edge_cache[sprite_index][image_index] = result
    return result
end
local sprite_yoffset_cache = {}
Utils.sprite_get_yoffset = function(sprite_index)
    if not sprite_yoffset_cache[sprite_index] then
        sprite_yoffset_cache[sprite_index] = gm.sprite_get_yoffset(sprite_index)
    end
    return sprite_yoffset_cache[sprite_index]
end
local sprite_xoffset_cache = {}
Utils.sprite_get_xoffset = function(sprite_index)
    if not sprite_xoffset_cache[sprite_index] then
        sprite_xoffset_cache[sprite_index] = gm.sprite_get_xoffset(sprite_index)
    end
    return sprite_xoffset_cache[sprite_index]
end
local sprite_width_cache = {}
Utils.sprite_get_width = function(sprite_index)
    if not sprite_width_cache[sprite_index] then
        sprite_width_cache[sprite_index] = gm.sprite_get_width(sprite_index)
    end
    return sprite_width_cache[sprite_index]
end
local sprite_height_cache = {}
Utils.sprite_get_height = function(sprite_index)
    if not sprite_height_cache[sprite_index] then
        sprite_height_cache[sprite_index] = gm.sprite_get_height(sprite_index)
    end
    return sprite_height_cache[sprite_index]
end
Utils.sprite_get_width_dynamic = function(sprite_index, image_index, y_offset)
    return Utils.get_sprite_right_edge(sprite_index, image_index, y_offset) -
               Utils.get_sprite_left_edge(sprite_index, image_index, y_offset)
end
Utils.sprite_get_height_dynamic = function(sprite_index, image_index, y_offset)
    return Utils.get_sprite_bottom_edge(sprite_index, image_index, y_offset) -
               Utils.get_sprite_top_edge(sprite_index, image_index, y_offset)
end
