groups         : [..] Node_Group;
prepared_nodes : [..] Glyph_Node;
node_stack     : [..] int;
id_stack       : [..] u64;

default_node : Glyph_Node = .{ ignore_locks = true };
next_node    : Glyph_Node;

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
    on_commit         : bool;
}

Node_On_Commit_Function :: #type (node: *Glyph_Node) -> void;

Glyph_Node :: struct 
{
    positioning      : Positioning_Method;
    position_min     : Vector2;

    sizing               : Sizing_Method;
    content_size         : Vector2;

    border  : Directional_Size;
    padding : Directional_Size;
    margin  : Directional_Size;

    vertical_alignment   : float;
    horizontal_alignment : float;
    content_vertical_alignment   : float;
    content_horizontal_alignment : float;

    concatenation : Concatenation;

    on_commit : Node_On_Commit_Function;

    ignore_locks : bool;
    locks        : Node_Locks;

    // Set automatically 
    
    size    : Vector2;
    z_index : float;

    persistent_id : u64;
    index         : u64;

    children      := Node_Group_ID.{-1};
}

get_default_node :: inline () -> *Glyph_Node
{
    return *default_node;
}

get_node :: (node_id: int) -> *Glyph_Node
{
    if node_id >= 0
    {
        return *prepared_nodes[node_id];
    }

    return *next_node;
}

set_concatenation :: inline (concatenation : Concatenation, node : *Glyph_Node = null)
{
    the_node := node; 
    if !node 
    {
        the_node = *next_node;
    }

    if !the_node.ignore_locks
    {
        if the_node.locks.concatenation then return;
        the_node.locks.concatenation = true;
    }

    the_node.concatenation = concatenation;
}

set_alignment :: inline (horizontal : float, vertical : float, node : *Glyph_Node = null)
{
    the_node := node; 
    if !node 
    {
        the_node = *next_node;
    }

    if !the_node.ignore_locks
    {
        if the_node.locks.alignment then return;
        the_node.locks.alignment = true;
    }

    the_node.vertical_alignment   = vertical;
    the_node.horizontal_alignment = horizontal;
}

set_content_alignment :: inline (horizontal : float, vertical : float, node : *Glyph_Node = null)
{
    the_node := node; 
    if !node 
    {
        the_node = *next_node;
    }

    if !the_node.ignore_locks
    {
        if the_node.locks.content_alignment then return;
        the_node.locks.content_alignment = true;
    }

    the_node.content_vertical_alignment   = vertical;
    the_node.content_horizontal_alignment = horizontal;
}

set_margin :: inline (margin_left: float, margin_right: float, margin_top: float, margin_bottom: float, node : *Glyph_Node = null)
{
    the_node := node; 
    if !node 
    {
        the_node = *next_node;
    }

    if !the_node.ignore_locks
    {
        if the_node.locks.margin then return;
        the_node.locks.margin = true;
    }

    the_node.margin = .{left = margin_left, right = margin_right, top = margin_top, bottom = margin_bottom};
}

set_margin :: inline (margin: float, node : *Glyph_Node = null)
{
    set_margin(margin, margin, margin, margin, node = node);
}

set_padding :: inline (padding_left: float, padding_right: float, padding_top: float, padding_bottom: float, node : *Glyph_Node = null)
{
    the_node := node; 
    if !node 
    {
        the_node = *next_node;
    }

    if !the_node.ignore_locks
    {
        if the_node.locks.padding then return;
        the_node.locks.padding = true;
    }

    the_node.padding = .{left = padding_left, right = padding_right, top = padding_top, bottom = padding_bottom};
}

set_padding :: inline (padding: float, node : *Glyph_Node = null)
{
    set_padding(padding, padding, padding, padding, node = node);
}

set_border :: inline (border_left: float, border_right: float, border_top: float, border_bottom: float, node : *Glyph_Node = null)
{
    the_node := node; 
    if !node 
    {
        the_node = *next_node;
    }

    if !the_node.ignore_locks
    {
        if the_node.locks.border then return;
        the_node.locks.border = true;
    }

    the_node.border = .{left = border_left, right = border_right, top = border_top, bottom = border_bottom};
}

set_border :: inline (border: float, node : *Glyph_Node = null)
{
    set_border(border, border, border, border, node = node);
}

/*
set_texture :: inline (texture: *Texture, texture_min: Vector2, texture_size: Vector2, color: Color, node : *Glyph_Node = null)
{
    the_node := node; 
    if !node 
    {
        the_node = *next_node;
    }

    if !the_node.ignore_locks
    {
        if the_node.locks.texture then return;
        the_node.locks.texture = true;
    }

    the_node.texture      = texture;
    the_node.texture_min  = texture_min;
    the_node.texture_size = texture_size;
    the_node.color        = color;
}
*/

set_content_size :: inline (sizing: Sizing_Method, content_size: Vector2 = .{}, node : *Glyph_Node = null)
{
    the_node := node; 
    if !node 
    {
        the_node = *next_node;
    }

    if !the_node.ignore_locks
    {
        if the_node.locks.content_size then return;
        the_node.locks.content_size = true;
    }

    the_node.sizing = sizing;
    
    if sizing == .FIXED
    {
        the_node.content_size = content_size;
    }
}

set_position :: inline (positioning: Positioning_Method, position: Vector2 = .{}, node : *Glyph_Node = null)
{
    the_node := node; 
    if !node 
    {
        the_node = *next_node;
    }

    if !the_node.ignore_locks
    {
        if the_node.locks.position then return;
        the_node.locks.position = true;
    }

    the_node.positioning = positioning;

    if positioning != .AUTO
    {
        the_node.position_min = position;
    }
}

set_on_commit_callback :: inline (on_commit : Node_On_Commit_Function, node : *Glyph_Node = null)
{
    the_node := node; 
    if !node 
    {
        the_node = *next_node;
    }

    if !the_node.ignore_locks
    {
        if the_node.locks.on_commit then return;
        the_node.locks.on_commit = true;
    }

    the_node.on_commit = on_commit;
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
    
    next_node       = default_node;
    next_node.locks = .{};

    self_index := prepared_nodes.count - 1;
    self       := *prepared_nodes[self_index];

    self.persistent_id = get_id();
    self.index         = xx self_index;

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
        if it.size.x == 0 || it.size.y == 0 continue; 

        if it.on_commit
        {
            it.on_commit(it);
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

get_index :: inline () -> u64
{
    return xx prepared_nodes.count;
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

#scope_file 

Hash :: #import "Hash";
#import "Math";

#import "IntroSort";
#import "Basic";