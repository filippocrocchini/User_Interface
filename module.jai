#module_parameters(Texture : Type, Color: Type);

groups         : [..] Node_Group;
prepared_nodes : [..] Glyph_Node;
node_stack     : [..] int;
id_stack       : [..] u64;

next_node   : Glyph_Node;
node_states : Table(u64, Persistent_State);

Persistent_State :: struct 
{
    last_position_min: Vector2;
    last_size:         Vector2;
}

Node_Group_ID :: struct 
{
    id : int;
}

Sizing_Method :: enum 
{
    AUTO;
    FIXED;
}

Positioning_Method :: enum 
{
    AUTO;
    // FIXED;
    ABSOLUTE;
}

GROUP_BUCKET_SIZE :: 16;

Node_Group :: struct 
{
    members : [GROUP_BUCKET_SIZE]int = ---;

    count := 0;
    next  := Node_Group_ID.{-1};
}

Directional_Size :: struct 
{
    using #as vec : Vector4;
    #place vec;
    left, right, top, bottom: float;
}

Concatenation :: enum 
{
    TOP_TO_BOTTOM;
    RIGHT_TO_LEFT;
    LEFT_TO_RIGHT;
    BOTTOM_TO_TOP;
}

Node_Locks :: struct 
{
    position          : bool;
    content_size      : bool;
    texture           : bool;
    border            : bool;
    padding           : bool;
    margin            : bool;
    alignment         : bool;
    content_alignment : bool;
    concatenation     : bool;
}

Glyph_Node :: struct 
{
    positioning      : Positioning_Method;
    position_min     : Vector2;

    sizing               : Sizing_Method;
    content_size         : Vector2;

    color           : Color;
    texture         : *Texture;
    texture_min     : Vector2;
    texture_size    : Vector2;

    border_color : Color; // = .{0,0,0,100};

    border  : Directional_Size;
    padding : Directional_Size;
    margin  : Directional_Size;

    vertical_alignment   : float;
    horizontal_alignment : float;
    content_vertical_alignment   : float;
    content_horizontal_alignment : float;

    concatenation         : Concatenation;

    locks : Node_Locks;

    // Set automatically 
    
    size    : Vector2;
    z_index : float;

    persistent_id : u64;
    children      := Node_Group_ID.{-1};
}

set_concatenation :: inline (concatenation : Concatenation)
{
    if next_node.locks.concatenation then return;
    next_node.locks.concatenation = true;

    next_node.concatenation = concatenation;
}

set_alignment :: inline (horizontal : float, vertical : float)
{
    if next_node.locks.alignment then return;
    next_node.locks.alignment = true;

    next_node.vertical_alignment   = vertical;
    next_node.horizontal_alignment = horizontal;
}

set_content_alignment :: inline (horizontal : float, vertical : float)
{
    if next_node.locks.content_alignment then return;
    next_node.locks.content_alignment = true;

    next_node.content_vertical_alignment   = vertical;
    next_node.content_horizontal_alignment = horizontal;
}

set_margin :: inline (margin_left: float, margin_right: float, margin_top: float, margin_bottom: float)
{
    if next_node.locks.margin then return;
    next_node.locks.margin = true;

    next_node.margin = .{left = margin_left, right = margin_right, top = margin_top, bottom = margin_bottom};
}

set_margin :: inline (margin: float)
{
    set_margin(margin, margin, margin, margin);
}

set_padding :: inline (padding_left: float, padding_right: float, padding_top: float, padding_bottom: float)
{
    if next_node.locks.padding then return;
    next_node.locks.padding = true;

    next_node.padding = .{left = padding_left, right = padding_right, top = padding_top, bottom = padding_bottom};
}

set_padding :: inline (padding: float)
{
    set_padding(padding, padding, padding, padding);
}

set_border :: inline (border_left: float, border_right: float, border_top: float, border_bottom: float, border_color: Color)
{
    if next_node.locks.border then return;
    next_node.locks.border = true;

    next_node.border_color = border_color;
    next_node.border = .{left = border_left, right = border_right, top = border_top, bottom = border_bottom};
}

set_border :: inline (border: float, border_color: Color)
{
    set_border(border, border, border, border, border_color);
}

set_texture :: inline (texture: *Texture, texture_min: Vector2, texture_size: Vector2, color: Color)
{
    if next_node.locks.texture then return;
    next_node.locks.texture = true;

    next_node.texture      = texture;
    next_node.texture_min  = texture_min;
    next_node.texture_size = texture_size;
    next_node.color        = color;
}

set_content_size :: inline (sizing: Sizing_Method, content_size: Vector2 = .{}, node_id: int = -1)
{
    node : *Glyph_Node;
    
    if node_id >= 0
    {
        node = *prepared_nodes[node_id];
    }
    else 
    {
        node = *next_node;
    }

    if node.locks.content_size then return;
    node.locks.content_size = true;

    node.sizing = sizing;
    
    if sizing == .FIXED
    {
        node.content_size = content_size;
    }
}

set_position :: inline (positioning: Positioning_Method, position: Vector2 = .{})
{
    if next_node.locks.position then return;
    next_node.locks.position = true;

    next_node.positioning = positioning;

    if positioning != .AUTO
    {
        next_node.position_min = position;
    }
}

add_to_group :: (group_id: *Node_Group_ID, node_index: int)
{
    target_group_id := group_id;

    while target_group_id.id >= 0
    {
        target_group := *groups[target_group_id.id];

        if target_group.count < GROUP_BUCKET_SIZE break;

        target_group_id = *target_group.next;
    }

    if target_group_id.id < 0
    {
        target_group_id.id = groups.count;
        array_add(*groups, .{});
    }

    assert(target_group_id.id >= 0);

    target_group := *groups[target_group_id.id];

    assert(target_group.count < GROUP_BUCKET_SIZE);
    
    target_group.members[target_group.count] = node_index; 
    target_group.count += 1;
}

add_child :: inline (parent: int, child: int)
{
    parent_node := *prepared_nodes[parent];
    add_to_group(*parent_node.children, child);
}

children_of :: (index: int) -> Node_Group_ID 
{
    node := *prepared_nodes[index];
    return node.children;
}

emit_node :: ()
{
    self := begin_node();
    end_node(self);
}

emit_node :: inline (id: $T)
{
    push_id(id);
    emit_node();
    pop_id();
}

begin_node :: inline (id: $T) -> int
{
    push_id(id);
    return begin_node();    
}

begin_node :: () -> int
{
    parent_index := -1;

    if node_stack.count 
    {
        parent_index = peek(node_stack);
    }
    
    array_add(*node_stack, prepared_nodes.count);
    
    array_add(*prepared_nodes, next_node);
    
    next_node = .{};

    self_index := prepared_nodes.count - 1;
    self       := *prepared_nodes[self_index];

    self.persistent_id = get_id();

    if parent_index >= 0
    {
        add_child(parent_index, self_index);
        self.z_index = prepared_nodes[parent_index].z_index + 1;
    }

    return self_index;
}

end_node :: inline (index: int)
{
    popped := pop(*node_stack);
    pop_id();

    node := *prepared_nodes[index];

    // Calculate alignment and concatenation direction

    concatenation_direction := Vector2.{1, 0};

    if node.concatenation == .LEFT_TO_RIGHT || node.concatenation == .RIGHT_TO_LEFT
    {
        concatenation_direction = .{0, 1};
    }

    alignment_direction := Vector2.{concatenation_direction.y, concatenation_direction.x};

    // Calculate size in alignment direction

    size_alignment_direction           := Vector2.{};
    size_alignment_direction_no_margin := Vector2.{};

    for * node.children
    {
        if it.positioning == .ABSOLUTE then continue;

        size_alignment_direction_no_margin.y = max(size_alignment_direction_no_margin.y, it.size.y);
        size_alignment_direction_no_margin.x = max(size_alignment_direction_no_margin.x, it.size.x);

        size_alignment_direction.y = max(size_alignment_direction.y, it.size.y + it.margin.top  + it.margin.bottom);
        size_alignment_direction.x = max(size_alignment_direction.x, it.size.x + it.margin.left + it.margin.right);
    }

    // Initialize cursor and cursor direction 

    cursor           := Vector2.{0, 0};
    cursor_direction := Vector2.{0, 0};

    if #complete node.concatenation ==
    {
        case .TOP_TO_BOTTOM;
            cursor_direction = .{ 0,  1};
        
        case .BOTTOM_TO_TOP;
            cursor_direction = .{ 0, -1};
        
        case .LEFT_TO_RIGHT;
            cursor_direction = .{ 1,  0};
        
        case .RIGHT_TO_LEFT;
            cursor_direction = .{ -1,  0 };
    }

    // Position children according to concatenation, don't double count margins

    last_margin : float = 0;

    for * node.children
    {
        if it.positioning == .ABSOLUTE then continue;

        if cursor_direction.x < 0
        {
            cursor.x += (it.size.x + max(0.0, it.margin.right - last_margin)) * cursor_direction.x;
        }

        if cursor_direction.y < 0
        {
            cursor.y += (it.size.y + max(0.0, it.margin.bottom - last_margin)) * cursor_direction.y;
        }

        if cursor_direction.x > 0
        {
            cursor.x += max(0.0, it.margin.left - last_margin) * cursor_direction.x;
        }
        
        if cursor_direction.y > 0
        {
            cursor.y += max(0.0, it.margin.top - last_margin) * cursor_direction.y;
        }

        translate(it, cursor);

        if cursor_direction.x < 0
        {
            cursor.x   += it.margin.left * cursor_direction.x;
            last_margin = it.margin.left;
        }
        
        if cursor_direction.y < 0
        {
            cursor.y   += it.margin.top * cursor_direction.y;
            last_margin = it.margin.top;
        }

        if cursor_direction.x > 0
        {
            cursor.x   += (it.size.x + it.margin.right) * cursor_direction.x;
            last_margin = it.margin.right;
        }
        
        if cursor_direction.y > 0
        {
            cursor.y   += (it.size.y + it.margin.bottom) * cursor_direction.y;
            last_margin = it.margin.bottom;
        }
    }

    // Make sure the first node starts at {0, 0}
    
    if cursor_direction.x < 0 || cursor_direction.y < 0 
    {
        cursor = -cursor;

        for * node.children
        {
            translate(it, cursor);
        }
    }

    // Calculate content size

    total_size := size_alignment_direction * concatenation_direction + cursor * alignment_direction;

    if node.sizing == .AUTO
    {
        node.content_size = total_size;
    }

    // Calculate final node size

    node.size = node.content_size;
    node.size += Vector2.{ node.border.left  + node.border.right,  node.border.top  + node.border.bottom };
    node.size += Vector2.{ node.padding.left + node.padding.right, node.padding.top + node.padding.bottom };

    // Set default content alignment if it wasn't set by user

    if !node.locks.content_alignment
    {
        node.content_horizontal_alignment = node.horizontal_alignment;
        node.content_vertical_alignment   = node.vertical_alignment;
    }

    // Align children ignoring margins

    content_alignment := Vector2.{node.content_horizontal_alignment, node.content_vertical_alignment};

    for * node.children
    {
        if it.positioning == .AUTO
        {
            margin_top_left     := Vector2.{it.margin.left, it.margin.top};
            margin_bottom_right := Vector2.{it.margin.right, it.margin.bottom};

            it_size_including_margin := it.size + margin_top_left + margin_bottom_right;

            translate(it, ((total_size - it_size_including_margin) * content_alignment + margin_top_left) * concatenation_direction);
        }
    }

    offset := Vector2.{node.border.left + node.padding.left, node.border.top + node.padding.top};

    for * node.children
    {
        if it.positioning == .ABSOLUTE
        {
            offset += node.position_min;
        }

        translate(it, offset);
    }

    if node.sizing == .FIXED
    {
        offset := node.content_size - total_size;
        offset *= Vector2.{node.horizontal_alignment, node.vertical_alignment};

        for * node.children
        {
            if it.positioning != .AUTO then continue;

            translate(it, offset);
        }
    }

    assert(popped == index, "Ended a node before it's children.");
}

commit_prepared_nodes :: ()
{

    compare_nodes :: (a: Glyph_Node, b: Glyph_Node) -> s64
    {
        delta := a.z_index - b.z_index;
        if delta < 0 return -1;
        if delta > 0 return 1;
        return 0;
    }

    intro_sort(prepared_nodes, compare_nodes);

    for * prepared_nodes
    {
        persistent_state := table_find_pointer(*node_states, it.persistent_id);
        
        if persistent_state
        {
            persistent_state.last_position_min = it.position_min;
            persistent_state.last_size         = it.size;
        }

        if it.size.x == 0 || it.size.y == 0 continue; 

        it.position_min.x = floor(it.position_min.x);
        it.position_min.y = floor(it.position_min.y);


        if it.border_color.w && (it.border.left > 0 || it.border.right > 0 || it.border.top > 0 || it.border.bottom > 0)
        {
            // rec : Rectangle;
            // rec.x      = it.position_min.x;
            // rec.y      = it.position_min.y;
            // rec.width  = it.size.x;
            // rec.height = it.size.y;

            // DrawRectangleLinesEx(rec, it.border_size, it.border_color);

            draw_rect_outline(it.position_min, it.position_min + it.size, it.border.left, it.border.right, it.border.top, it.border.bottom, it.border_color);
            draw_rect_outline(it.position_min - .{it.margin.left, it.margin.top}, it.position_min + it.size + .{it.margin.right, it.margin.bottom}, it.border.left, it.border.right, it.border.top, it.border.bottom, it.border_color);
        }

        if it.texture
        {
            // sprite : Sprite;
            // sprite.texture       = <<it.texture;
            // sprite.region.x      = it.texture_min.x;
            // sprite.region.y      = it.texture_min.y;
            // sprite.region.width  = it.texture_size.x;
            // sprite.region.height = it.texture_size.y;

            // draw_sprite(sprite, Vector2.{it.position_min.x, it.position_min.y}, color = it.color);

            min_texture_uv := it.texture_min * .{1.0/it.texture.width, 1.0/it.texture.height};
            texture_size_uv := it.texture_size * .{1.0/it.texture.width, 1.0/it.texture.height};

            Simp.set_shader_for_images(it.texture);
            draw_rect(it.position_min, it.size, min_texture_uv, texture_size_uv, it.color);
        }
        else if it.color.w
        {
            // rec : Rectangle;
            // rec.x      = it.position_min.x;
            // rec.y      = it.position_min.y;
            // rec.width  = it.size.x;
            // rec.height = it.size.y;

            // DrawRectangleRec(rec, it.color);

            Simp.set_shader_for_color(true);
            draw_rect(it.position_min, it.size, .{}, .{}, it.color);
        }
    }
}

reset_prepared_nodes :: ()
{
    array_reset(*prepared_nodes);
    array_reset(*groups);
    array_reset(*node_stack);
}

for_expansion :: (group_id: Node_Group_ID, body: Code, flags: For_Flags) #expand {
    
    current_group := group_id;

    for_index := 0;
    
    while current_group.id >= 0
    {
        group := *groups[current_group.id];
    
        for index: 0..group.count-1
        {  
            node_index := group.members[index];
            
            `it_index := for_index;
            for_index += 1;

            #if flags & .POINTER
            {
                `it := *prepared_nodes[node_index];
            }
            else
            {
                `it := prepared_nodes[node_index];
            }

            #insert body;
        }

        current_group = group.next;
    }
}

push_id :: inline (id: string)
{
    array_add(*id_stack, Hash.fnv1a_hash(xx id.data, id.count * size_of(u64)));
}

push_id :: inline (id: int)
{
    array_add(*id_stack, cast,no_check(u64) id);
}

pop_id :: inline ()
{
    if id_stack.count
    {
        pop(*id_stack);
    }
}

get_id :: inline () -> u64
{
    return Hash.fnv1a_hash(xx id_stack.data, id_stack.count * size_of(u64));
}

update_bounds :: inline (index: int) -> Vector2
{
    node := *prepared_nodes[index];
    offset := Vector2.{};

    if node.sizing == 
    {
        case .FIXED;
        // Nothing
        case .AUTO;
            if node.children.id >= 0
            {
                node.content_size, offset = get_bounds(node.children);
            }
    }

    node.size = node.content_size
        + 2 * Vector2.{node.border_size, node.border_size}
        + Vector2.{node.padding.left + node.padding.right, node.padding.top + node.padding.bottom};

    return offset;
}

get_bounds :: (nodes: Node_Group_ID) -> size: Vector2, min_pos: Vector2
{
    min_pos : Vector2 = .{ FLOAT32_INFINITY,  FLOAT32_INFINITY};
    max_pos : Vector2 = .{-FLOAT32_INFINITY, -FLOAT32_INFINITY};

    for * nodes
    {
        min_pos.x = min(min_pos.x, it.position_min.x - it.margin.left);
        min_pos.x = min(min_pos.x, it.position_min.x + it.size.x + it.margin.right);

        max_pos.x = max(max_pos.x, it.position_min.x - it.margin.left);
        max_pos.x = max(max_pos.x, it.position_min.x + it.size.x + it.margin.right);

        min_pos.y = min(min_pos.y, it.position_min.y - it.margin.top);
        min_pos.y = min(min_pos.y, it.position_min.y + it.size.y + it.margin.bottom);

        max_pos.y = max(max_pos.y, it.position_min.y - it.margin.top);
        max_pos.y = max(max_pos.y, it.position_min.y + it.size.y + it.margin.bottom);
    }

    return max_pos - min_pos, min_pos;
}

translate :: inline (index: int, offset: Vector2)
{
    node := *prepared_nodes[index];
    translate(node, offset);
}

translate :: (node: *Glyph_Node, offset: Vector2)
{
    for * node.children
    {
        translate(it, offset);
    }

    node.position_min += offset;
}

Button_State :: struct 
{
    #as clicked : bool;
    hovered : bool;

    index : int;
    label_node : int;
}

button :: (label: string, args: ..Any, label_style: Glyph_Cache.Style_Description, pixels_per_em: u32, color : Color, hovered_color : Color) -> Button_State
{
    result : Button_State;
    result.index = begin_node(label);

    persistent_state, _ := find_or_add(*node_states, prepared_nodes[result.index].persistent_id);

    mouse_position := GetMousePosition();

    if persistent_state.last_position_min.x <= mouse_position.x &&
        persistent_state.last_position_min.y <= mouse_position.y &&
        persistent_state.last_position_min.x + persistent_state.last_size.x > mouse_position.x &&  
        persistent_state.last_position_min.y + persistent_state.last_size.y > mouse_position.y
    {
        if IsMouseButtonReleased(xx MouseButton.LEFT)
        {
            result.clicked = true;
        }  

        result.hovered = true;
    }

    text_color := color;

    if result.hovered
    {
        text_color = hovered_color;
    }

    result.label_node = draw_text(label, ..args, style = label_style, line_height = pixels_per_em * 1.2, pixels_per_em = pixels_per_em, color = text_color);

    end_node(result.index);

    return result;
} @PrintLike


glyph_cache_texture : Texture;

draw_line :: (from: Vector2, to: Vector2, thick: float, color: Vector4) 
{
    Simp.set_shader_for_color(true);

    diff := (to - from);
    perp := Vector2.{-diff.y, diff.x};
    normalize(*perp);

    perp *= thick / 2;

    from0 := from - perp;
    from1 := from + perp;

    to0 := to - perp;
    to1 := to + perp;

    Simp.immediate_quad(from0, from1, to1, to0, color);
}

draw_rect_outline :: (min_corner: Vector2, max_corner: Vector2, thick_left: float, thick_right: float, thick_top: float, thick_bottom: float, color: Vector4) 
{
    draw_line(min_corner + Vector2.{thick_left/2, thick_left/2}, Vector2.{min_corner.x + thick_left / 2, max_corner.y - thick_left / 2}, thick_left, color);

    draw_line(Vector2.{min_corner.x + thick_bottom / 2, max_corner.y - thick_bottom / 2}, max_corner - Vector2.{thick_bottom/2, thick_bottom/2}, thick_bottom, color);

    draw_line(max_corner - Vector2.{thick_right/2, thick_right/2}, Vector2.{max_corner.x - thick_right/2, min_corner.y + thick_right / 2}, thick_right, color);

    draw_line(Vector2.{max_corner.x - thick_top/2, min_corner.y + thick_top/2}, min_corner + Vector2.{thick_top/2, thick_top/2}, thick_top, color);
}

draw_rect_outline :: inline (min_corner: Vector2, max_corner: Vector2, thick: float, color: Vector4) 
{
    draw_rect_outline(min_corner, max_corner, thick, thick, thick, thick, color);
}

draw_rect :: (position: Vector2, size: Vector2, region_min: Vector2, region_size: Vector2, color: Vector4) 
{
    p1 := position;
    p2 := position + .{ size.x, 0};
    p3 := position + size;
    p4 := position + .{ 0, size.y };
    
    u1 := region_min;
    u2 := region_min + .{ region_size.x, 0};
    u3 := region_min + region_size;
    u4 := region_min + .{ 0, region_size.y };

    Simp.immediate_quad(p1, p2, p3, p4, color, u1, u2, u3, u4);
}

text :: (format: string, args: ..Any, style: Glyph_Cache.Style_Description, pixels_per_em: u32, line_height: float, position: Vector2 = .{}, color: Color) -> int {
    text := tprint(format, ..args);
    
    cache_face := Glyph_Cache.find_best_face_for_style(style);

    Glyph_Cache.bind_face(cache_face, pixels_per_em);

    ft_face := Glyph_Cache.get_freetype_face(cache_face);

    // if !ft_face.generic.data
    // {
    hb_font := hb_ft_font_create(ft_face, null);
    defer hb_font_destroy(hb_font);

    hb_ft_font_set_funcs(hb_font);

    //    ft_face.generic.data = font;
    //} 

    // hb_font := cast(*hb_font_t) ft_face.generic.data;

    pixels_per_unit := 1 / 64.0;
 
    buf := hb_buffer_create();
    defer hb_buffer_destroy(buf);

    hb_buffer_add_utf8(buf, text.data, xx text.count, 0, xx text.count);
    hb_buffer_guess_segment_properties(buf);

    // hb_buffer_set_direction(buf, .HB_DIRECTION_LTR);
    // hb_buffer_set_script(buf, .HB_SCRIPT_LATIN);
    // hb_buffer_set_language(buf, hb_language_from_string("en", -1));

    features : [3]hb_feature_t;
    hb_feature_from_string("kern", 4, *features[0]);
    hb_feature_from_string("liga", 4, *features[1]);
    hb_feature_from_string("clig", 4, *features[2]);

    hb_shape(hb_font, buf, features.data, features.count);
    
    glyph_info := hb_buffer_get_glyph_infos(buf);
    glyph_pos  := hb_buffer_get_glyph_positions(buf);
    
    cursor_x : float = position.x;
    cursor_y : float = position.y;

    push_id(format);
    defer pop_id();

    result := begin_node();

    for glyph_pos
    {
        push_id(it_index);
        defer pop_id();

        // After hb_shape() these are not codepoints, they are glyph_indexes
        glyph_index := glyph_info[it_index].codepoint;
        
        glyph, found := Glyph_Cache.get_glyph(glyph_index);

		baseline_origin := Vector2.{ cursor_x, cursor_y };

        x0 := baseline_origin.x + it.x_offset * pixels_per_unit + glyph.bearing_x;
        y0 := baseline_origin.y - it.y_offset * pixels_per_unit - glyph.bearing_y;

        s0_px := glyph.x;
        t0_px := glyph.y;

        {
            set_content_size(.FIXED, .{ xx glyph.w, xx glyph.h });
            set_position(.ABSOLUTE, .{ x0, y0 });
            set_texture(*glyph_cache_texture, .{ xx s0_px, xx t0_px}, .{ xx glyph.w, xx glyph.h }, color);

            node_index := begin_node();
            end_node(node_index);
        }

        cursor_x += floor(it.x_advance * pixels_per_unit);
        cursor_y -= floor(it.y_advance * pixels_per_unit);
    }

    for * children_of(result)
    {
        it.position_min.y += cast(float) (ft_face.ascender) / cast(float) ft_face.height * line_height; 
    }

    children_size := get_bounds(children_of(result));
    set_content_size(.FIXED, .{children_size.x, line_height}, node_id = result);

    end_node(result);

    return result;
} @PrintLike

#scope_file 

Hash :: #import "Hash";
#import "Math";

Simp :: #import "Simp";

#import "Hash_Table";
#import "IntroSort";
#import "Basic";
#import "Harfbuzz"(FREETYPE_SUPPORT=true);
Glyph_Cache :: #import "Glyph_Cache";

