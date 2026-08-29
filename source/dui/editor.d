/// Multiline text editing helpers bound to `State`.
module dui.editor;

import dew;
import dui.state;

/**
 * Multiline text area bound to `State!string`.
 * Enter inserts a newline; Backspace deletes; printable keys append.
 */
Widget boundTextArea(ref State!string text, const(char)[] placeholder = "…",
    float minHeight = 160) @safe
{
    return TextField(text.value)
        .placeholder(placeholder)
        .multiline(true)
        .width(Length.percent(100))
        .height(minHeight)
        .focusable()
        .onKey((KeyEvent ev) {
            if (ev.phase != KeyPhase.Down && ev.phase != KeyPhase.Repeat)
                return;
            if (ev.key == "Backspace")
            {
                if (text.value.length)
                    text = text.value[0 .. $ - 1];
                return;
            }
            if (ev.key == "Enter")
            {
                text = text.value ~ "\n";
                return;
            }
            if (ev.key.length == 1 && !ev.ctrl && !ev.alt && !ev.meta)
                text = text.value ~ ev.key;
        });
}

unittest
{
    import dui.app;

    State!string body_ = State!string("a");
    DuiApp app;
    app.bind(body_);
    app.init((ref UiBuilder ui) {
        return boundTextArea(body_, "note", 80).width(200);
    }, new SoftwareBackend(220, 120));
    app.dew.resize(220, 120);
    app.frame();

    NodeId fieldId;
    foreach (i, ref n; app.dew.ui.store.nodes)
        if (n.kind == NodeKind.TextField)
        {
            fieldId = NodeId(cast(uint) i);
            break;
        }
    assert(fieldId.valid);
    app.dew.focus(fieldId);
    assert(app.key(keyDown("Enter")));
    assert(body_.value == "a\n");
    assert(app.key(keyDown("b")));
    assert(body_.value == "a\nb");
}
