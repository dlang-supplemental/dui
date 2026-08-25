/// Thin app host that owns dew.App + a root rebuild callback.
module dui.app;

import dew;
import dui.state;

alias RootBuilder = Widget delegate(ref UiBuilder ui) @safe;

/// Opinionated host: rebuild root when any bound `State` dirties.
struct DuiApp
{
    App dew;
    RootBuilder buildRoot;
    bool needsRebuild = true;

    void init(RootBuilder builder, RenderBackend backend = null) @safe
    {
        buildRoot = builder;
        if (backend !is null)
            dew.backend = backend;
        beginUi(dew.ui);
        rebuild();
    }

    /// Bind a `State` so assignments set `needsRebuild`.
    void bind(T)(ref State!T state) @safe
    {
        state.bindRebuild(() { requestRebuild(); });
    }

    void rebuild() @safe
    {
        dew.ui.store.clear();
        beginUi(dew.ui);
        if (buildRoot !is null)
            dew.setRoot(buildRoot(dew.ui));
        needsRebuild = false;
    }

    void frame() @safe
    {
        if (needsRebuild)
            rebuild();
        dew.frame();
    }

    /// Dispatch pointer; handlers may dirty state — next `frame` rebuilds.
    bool pointer(PointerEvent ev) @safe
    {
        return dew.pointer(ev);
    }

    bool key(KeyEvent ev) @safe
    {
        return dew.key(ev);
    }

    /// Dispatch then rebuild+paint if dirty (handy for tests / single-shot hosts).
    bool pointerAndFrame(PointerEvent ev) @safe
    {
        const hit = pointer(ev);
        frame();
        return hit;
    }

    /// Synthetic tap: Down + Up at the same point (buttons click on Up).
    bool tap(float x, float y, uint id = 1) @safe
    {
        const a = pointerAndFrame(touchDown(x, y, id));
        const b = pointerAndFrame(touchUp(x, y, id));
        return a || b;
    }

    void resize(float w, float h) @safe
    {
        dew.resize(w, h);
        needsRebuild = true;
    }

    void requestRebuild() @safe @nogc nothrow
    {
        needsRebuild = true;
    }
}

unittest
{
    import std.format : format;

    State!int clicks = State!int(0);
    DuiApp app;
    app.bind(clicks);

    app.init((ref UiBuilder ui) {
        auto label = format("n=%s", clicks.value);
        return VStack(
            Text(label).fontSize(14),
            Button("Go").touchFriendly().onClick(() { clicks = clicks.value + 1; })
        ).spacing(8).padding(12);
    }, new SoftwareBackend(320, 240));

    app.dew.resize(320, 240);
    app.frame();

    float bx, by, bw, bh;
    bool found;
    foreach (ref n; app.dew.ui.store.nodes)
    {
        if (n.kind == NodeKind.Button)
        {
            bx = n.x;
            by = n.y;
            bw = n.w;
            bh = n.h;
            found = true;
            break;
        }
    }
    assert(found);
    assert(bw > 0 && bh > 0);

    assert(app.tap(bx + bw * 0.5f, by + bh * 0.5f));
    assert(clicks.value == 1);
    assert(!app.needsRebuild);

    // Second tap
    found = false;
    foreach (ref n; app.dew.ui.store.nodes)
    {
        if (n.kind == NodeKind.Button)
        {
            bx = n.x;
            by = n.y;
            bw = n.w;
            bh = n.h;
            found = true;
            break;
        }
    }
    assert(found);
    assert(app.tap(bx + bw * 0.5f, by + bh * 0.5f));
    assert(clicks.value == 2);
}
