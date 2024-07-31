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
