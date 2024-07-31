
A node is the basic component of this UI system, think of it as a div in html. Every node has the following properties:

Graphical:
- Color
- Texture
- Texture Region
- Border Color

Layout:
![](layout_illustrations-0001%201.png)
- Z-Index
- Border and Padding
- [Concatenation and Alignment](Concatenation%20and%20Alignment.md)
- [Positioning Method](Positioning%20Method.md)
- [Sizing Method](Sizing%20Method.md)

### Node Lifetime

Parent nodes throughout their lifetime go through the following phases:
- OPEN
    - After calling `push_node()`
    - All parameters set on children during this phase must be either fixed or depend on their children.
    - The node is the currently active one on the stack, after sealing you will need the id to refer to it again.
- SEALED
    - After calling `pop_node()` or `emit_node()`
    - During this phase it's possible to query the size of the node. All sealed nodes can be modified. Relative parameters are calculated based on the value the parameter they depend on had when it was sealed.
    - It's NOT possible to add new children after sealing.
- LAYOUT_COMPLETED
    - After calling `pack_node()`
    - All children have been laid out and are now PACKED. Further modifications to parameters and/or children that affect layout will be ignored.
- PACKED
    - After calling `pack_node()` on the parent.
    - The node has been positioned within the parent and it's now ready for rendering. Further modifications to parameters and/or children that affect layout will be ignored.

Controlling lifetime in code:
```c++
push_node(); 
auto child_node = emit_node(); // SEALED
auto my_node    = pop_node(); // SEALED

auto size = get_node_size(my_node);
set_size(child_node, size.x * 0.5, size.y); // Available on sealed nodes.

pack_node(child_node); // child_node: LAYOUT_COMPLETED
pack_node(my_node); // my_node: LAYOUT_COMPLETED, child_node: PACKED
```
Packing a node means laying out all children and setting their state to PACKED, the node that is packed will be then set to LAYOUT_COMPLETED. Packed means that the node has been positioned within its parent.
Don't pack a node until you need information about the layout of its children. Keeping it sealed but not packed allows later code to still modify its parameters and have them be taken into account during layout.

All nodes will be packed before rendering, there's no need to pack explicitly unless strictly necessary.
## Setting Node Parameters

### Before Sealing
This is crucial, as it allows user code to change how components look, without changing their implementation. And without passing an obnoxious amount of arguments.
```c++
Node_State do_button(string label) {
    push_node(label);
        set_size(.RELATIVE, 1, 1);
        do_text(label);
    
    auto button_node = pop_node();
    auto result      = get_node_state(button_node); // Requires an id
    
    return result;
}

void menu() {
    set_position(.ABSOLUTE, WINDOW_WIDTH / 2, WINDOW_HEIGHT / 2);
    set_size(.FIXED, 100, 20);
    set_alignment(.CENTER, .CENTER);
    set_origin(0.5, 0.5); // Default is 0, 0 (left, top)
    
    if (do_button("Quit").clicked) {
        quit();
    }
}
```
### After Sealing
This in used to set relative sizes or in general dynamically calculated parameters that depend on the parent node.
```c++
set_size(WINDOW_WIDTH, WINDOW_HEIGHT);
set_alignment(.CENTER, .CENTER);

push_node();
    set_size(200, 200);
    emit_node();
    
    set_padding(10);
    auto child_node = emit_node();
     
    // set_size(child_node, get_size(parent_node).x * 0.5, 200);
    // Error: get_size(...), "parent_node" not sealed.
    
auto parent_node = pop_node();

set_size(child_node, Mathf.sin(get_size(parent_node).x), 200);

```
### Overriding node parameters

In the following example the `set_size()` in the `example()` function overrides the size that is set by `do_node_example()`. The call to `set_size(.AUTO, 0, 0)` effectively does nothing since a value was previously set.

The idea behind this behavior is to allow user code to change parameters that have been chosen by default by the UI library. 

```c++
void do_node_example()
{
    set_size(.AUTO, 0, 0);
    emit_node();
}

void example()
{
    set_size(.FIXED, 100, 100);
    do_node_example(); 
}
```
# Issues

### Layout vs Rendering
Style information that doesn't affect layout must go through an alternative path. Ideally a path that is completely unrelated to the layout.

#### Hypothetical solution
Setting a render function callback on nodes instead. The provided "render" code will then just use the callbacks to render.

Potential problems with this solution:
- If you want to change render functions you have to re-implement the library, even though you only need to change a pointer. Here maybe the UI library developer can provide facilities for that?
- Loss of type safety through callback. And in general weird void* dance unless we cast function pointers.
```c++

void draw_subtexture(int node_index, void* user_data, int user_data_size)
{
    auto node_rect  = get_node_rect(node_index);
    Texture_Region* region = (Texture_Region*) user_data;
    
    auto glyph_texture_rect = region.rect;
    draw_texture_region(region.texture, node_rect, glyph_texture_rect);
}

void do_text(char* text)
{
    auto positions = get_text_glyphs_positions(text);
    auto sizes     = get_text_glyphs_sizes(text);
    auto indexes   = get_text_glyphs_indexes(text);
    
    push_node();
        for(int i = 0; auto index : indexes)
        {
            push_id(i);
            set_position(.ABSOLUTE, positions[i].x, positions[i].y);
            set_size(.FIXED, sizes[i].x, sizes[i].y);
            
            Texture_Region glyph_texture = {};
            glyph_texture.texture = font_texture;
            glyph_texture.rect    = get_glyph_rect(index);
            
            set_render_data(&glyph_texture, sizeof(glyph_texture));
            set_render_func(draw_glyph);
            emit_node();
            i += 1;
        }
    auto self = pop_node();  
}
```

# Scratch Example
```c++
...
```
