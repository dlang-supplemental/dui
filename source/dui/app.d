/// Thin app host that owns dew.App + a root rebuild callback.
module dui.app;

import dew;

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

    bool pointer(PointerEvent ev) @safe
    {
        auto hit = dew.pointer(ev);
        return hit;
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
