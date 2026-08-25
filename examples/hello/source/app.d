module hello;

import std.stdio;
import std.format : format;
import tgc.gcobj;
import dui;

void main()
{
    writeln("dui ", duiVersion, " / dew ", dewVersion, " — ", dewSlogan);

    State!int clicks = State!int(0);
    DuiApp app;
    app.bind(clicks);

    app.init((ref UiBuilder ui) {
        auto label = format("clicks: %s", clicks.value);
        return VStack(
            Text("dui hello").fontSize(20).bold(),
            Text(label).fontSize(14),
            Button("Tap me")
                .touchFriendly()
                .onClick(() { clicks.update(v => v + 1); })
        ).spacing(10).padding(16);
    }, new SoftwareBackend(640, 400));

    app.dew.resize(640, 400);
    app.frame();

    // Tap the laid-out button center (Down+Up — clicks fire on Up).
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
    assert(found, "button not laid out");

    const hit = app.tap(bx + bw * 0.5f, by + bh * 0.5f);
    assert(hit, "touch missed button");
    assert(clicks.value == 1, "state did not increment");

    writeln("clicks=", clicks.value, " cmds=", app.dew.list.cmds.length);
    writeln("hello OK");
}
