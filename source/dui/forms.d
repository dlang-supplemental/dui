/// Form helpers bound to `State` cells.
module dui.forms;

import dew;
import dui.state;

/**
 * Text field bound to `State!string`. Rebuilds on each key assignment from the
 * host; for headless tests, assign `text.value` directly then `requestRebuild`.
 */
Widget boundTextField(ref State!string text, const(char)[] placeholder = "…") @safe
{
    return TextField(text.value)
        .placeholder(placeholder)
        .width(Length.percent(100))
        .height(36)
        .focusable()
        .onKey((KeyEvent ev) {
            if (ev.phase != KeyPhase.Down)
                return;
            if (ev.key == "Backspace")
            {
                if (text.value.length)
                    text = text.value[0 .. $ - 1];
                return;
            }
            if (ev.key.length == 1 && !ev.ctrl && !ev.alt && !ev.meta)
                text = text.value ~ ev.key;
        });
}

/// Checkbox bound to `State!bool`.
Widget boundCheckBox(ref State!bool flag, const(char)[] label) @safe
{
    return CheckBox(label, flag.value)
        .onClick(() { flag = !flag.value; });
}

/// Label + control column for forms.
Widget formRow(const(char)[] label, Widget control) @safe
{
    return VStack(
        Text(label).fontSize(12).bold(),
        control
    ).spacing(4).alignItems(AlignItems.Stretch);
}

unittest
{
    import dui.app;

    State!string name = State!string("hi");
    State!bool agree = State!bool(false);
    DuiApp app;
    app.bind(name);
    app.bind(agree);

    app.init((ref UiBuilder ui) {
        return VStack(
            formRow("Name", boundTextField(name, "Your name")),
            boundCheckBox(agree, "I agree")
        ).spacing(12).padding(16).width(320).height(200);
    }, new SoftwareBackend(320, 200));

    app.dew.resize(320, 200);
    app.frame();

    // Focus the text field and type
    NodeId fieldId;
    foreach (i, ref n; app.dew.ui.store.nodes)
        if (n.kind == NodeKind.TextField)
        {
            fieldId = NodeId(cast(uint) i);
            break;
        }
    assert(fieldId.valid);
    app.dew.focus(fieldId);
    assert(app.key(keyDown("!")));
    assert(name.value == "hi!");

    // Toggle checkbox via tap
    float cx, cy, cw, ch;
    bool found;
    foreach (ref n; app.dew.ui.store.nodes)
        if (n.kind == NodeKind.CheckBox)
        {
            cx = n.x;
            cy = n.y;
            cw = n.w;
            ch = n.h;
            found = true;
            break;
        }
    assert(found);
    assert(app.tap(cx + cw * 0.5f, cy + ch * 0.5f));
    assert(agree.value == true);
}
