
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
# Node Input State
In order to query input state a node has to have a unique ID set by either passing a string or a number to `push_node()`/`emit_node()` or by pushing an ID using the `push_id()`/`pop_id()` pair. If the node has no id the input state will be equivalent to all of the following being false.

Any node can be in the following states:
- [ ] MOUSE_OVER (based on last position)
- [ ] SELECTED
- [ ] MOUSE_ENTER (based on last position)
- [ ] MOUSE_LEAVE (based on last position)
- [ ] MOUSE_DOWN => MOUSE_OVER
- [ ] MOUSE_UP => MOUSE_OVER
- [ ] MOUSE_PRESS => MOUSE_OVER
- [ ] MOUSE_RELEASE => MOUSE_OVER
- [ ] KEY_DOWN => MOUSE_OVER or SELECTED
- [ ] KEY_UP => MOUSE_OVER or SELECTED
- [ ] KEY_PRESS => MOUSE_OVER or SELECTED
- [ ] KEY_RELEASE => MOUSE_OVER or SELECTED
- [ ] DRAGGED
- [ ] DRAG_START => MOUSE_OVER
- [ ] DRAG_END
- [ ] DRAG_AND_DROP_OVER => MOUSE_OVER
- [ ] DRAG_AND_DROP_ENTER => MOUSE_ENTER
- [ ] DRAG_AND_DROP_LEAVE => MOUSE_LEAVE
- [ ] DROP => MOUSE_OVER
- [ ] DOUBLE_CLICKED => MOUSE_OVER
- [ ] SCROLLED => MOUSE_OVER
- [ ] ABORTED
- [ ] DESELECTED
- [ ] TEXT_INPUT => SELECTED or MOUSE_OVER
- [ ] COPY
- [ ] PASTE

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
### ~~Input Delay~~
Input is delayed by one frame in some cases. That is because we need to react to input before we know the final layout. Example:
```c++
set_alignment(.CENTER, .CENTER);
push_node();

do_text("This is some text.");
if(do_button("Click me.").clicked)
{
    printf("I have been clicked.\n");
}

if(do_toggle("Toggle me."))
{
    do_text("More text.");
    if(do_button("Click me too!").clicked)
    {
        printf("I was visible and clicked.\n");
    }
}

pop_node();
```
In this example the position of the first button depends on how many siblings it has, since they will all be centered. This means that we won't actually be able to know if the button is pressed until we pack the root node.

In a retained-mode gui this is the flow:
- Process input based on last frame layout
- Update layout
- Reprocess input?
- Render updated layout
 
The only difference here is that during the first frame we don't know the layout.
#### Solution with Callbacks
One possible solution to this problem is using callbacks and deferring the call until after packing. This means however that the callback functions won't be able to draw UI.
Not only that but here's now the issue xxx by "show_hidden_info"; user code now needs to manage some internal state for the library; and in any case, it's not possible to know if the toggle is active during the current frame before its content is generated. 
```c++

void click_me_button(Button *button, Event e) {
    if(e == .CLICKED) {
        printf("I have been clicked.\n")
    }
}

void click_me_too_button(Button *button, Event e) {
    if(e == .CLICKED) {
        printf("I was visible and clicked.\n");
    }
}

...

set_alignment(.CENTER, .CENTER);
push_node();

do_text("This is some text.");

do_button("Click me.", click_me_button);
do_toggle("Toggle me.", &show_hidden_info);

if(show_hidden_info) {
    do_text("More text.");
    do_button("Click me too!", click_me_too_button);
}

pop_node();
```

# Scratch Example
```c++
...
```
