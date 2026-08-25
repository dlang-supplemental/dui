/// Simple navigation stack of root builders.
module dui.nav;

import dew;
import dui.app;
import dui.state;

alias PageBuilder = RootBuilder;

struct NavPage
{
    string title;
    PageBuilder build;
}

/**
 * Stack navigator. Push/pop swap the `DuiApp` root builder and request rebuild.
 * Hosts should `app.bind` any shared state; page-local state lives in closures.
 */
struct NavStack
{
    NavPage[] stack;
    DuiApp* app;

    void attach(ref DuiApp host) @trusted
    {
        app = &host;
    }

    @property size_t depth() const @safe @nogc pure nothrow
    {
        return stack.length;
    }

    @property string title() const @safe pure nothrow
    {
        return stack.length ? stack[$ - 1].title : "";
    }

    void replaceRoot(string title, PageBuilder build) @safe
    {
        stack.length = 0;
        push(title, build);
    }

    void push(string title, PageBuilder build) @safe
    {
        stack ~= NavPage(title, build);
        applyTop();
    }

    bool pop() @safe
    {
        if (stack.length <= 1)
            return false;
        stack = stack[0 .. $ - 1];
        applyTop();
        return true;
    }

    private void applyTop() @safe
    {
        if (app is null || !stack.length)
            return;
        app.buildRoot = stack[$ - 1].build;
        app.requestRebuild();
    }
}

/// Back button wired to `NavStack.pop`.
Widget backButton(ref NavStack nav, const(char)[] label = "Back") @safe
{
    return Button(label).touchFriendly().onClick(() { nav.pop(); });
}

unittest
{
    DuiApp app;
    NavStack nav;
    nav.attach(app);

    State!string page = State!string("home");
    app.bind(page);

    app.init((ref UiBuilder ui) {
        return Text("boot");
    }, new SoftwareBackend(240, 160));

    nav.replaceRoot("home", (ref UiBuilder ui) {
        page = "home";
        return VStack(
            Text("Home"),
            Button("Open").touchFriendly().onClick(() {
                nav.push("detail", (ref UiBuilder ui2) {
                    page = "detail";
                    return VStack(
                        Text("Detail"),
                        backButton(nav)
                    ).spacing(8).padding(12);
                });
            })
        ).spacing(8).padding(12);
    });
    app.frame();
    assert(nav.title == "home");
    assert(page.value == "home");

    // Tap Open
    float bx, by, bw, bh;
    bool found;
    foreach (ref n; app.dew.ui.store.nodes)
        if (n.kind == NodeKind.Button && n.text == "Open")
        {
            bx = n.x;
            by = n.y;
            bw = n.w;
            bh = n.h;
            found = true;
            break;
        }
    assert(found);
    assert(app.tap(bx + bw / 2, by + bh / 2));
    assert(nav.title == "detail");
    assert(page.value == "detail");
    assert(nav.depth == 2);

    found = false;
    foreach (ref n; app.dew.ui.store.nodes)
        if (n.kind == NodeKind.Button && n.text == "Back")
        {
            bx = n.x;
            by = n.y;
            bw = n.w;
            bh = n.h;
            found = true;
            break;
        }
    assert(found);
    assert(app.tap(bx + bw / 2, by + bh / 2));
    assert(nav.title == "home");
    assert(nav.depth == 1);
}
