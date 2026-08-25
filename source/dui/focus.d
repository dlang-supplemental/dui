/// Focus helpers on top of dew's Tab cycle.
module dui.focus;

import dew;
import dui.app;

/// Move focus forward / backward and paint a frame.
bool focusNext(ref DuiApp app, bool forward = true) @safe
{
    auto ev = keyDown("Tab", !forward);
    const hit = app.key(ev);
    app.frame();
    return hit;
}

/// Focus the first focusable node in the tree.
bool focusFirst(ref DuiApp app) @safe
{
    app.dew.focus(NodeId.init);
    return focusNext(app, true);
}

/// Activate the focused control (Enter).
bool activateFocused(ref DuiApp app) @safe
{
    const hit = app.key(keyDown("Enter"));
    app.frame();
    return hit;
}

unittest
{
    import dui.state;
    import std.format : format;

    State!int n = State!int(0);
    DuiApp app;
    app.bind(n);
    app.init((ref UiBuilder ui) {
        return VStack(
            Button("A").touchFriendly().onClick(() { n = 1; }),
            Button("B").touchFriendly().onClick(() { n = 2; })
        ).spacing(8).padding(8);
    }, new SoftwareBackend(200, 160));
    app.dew.resize(200, 160);
    app.frame();

    assert(focusFirst(app));
    assert(app.dew.focused.valid);
    assert(activateFocused(app));
    assert(n.value == 1);

    assert(focusNext(app));
    assert(activateFocused(app));
    assert(n.value == 2);
}
