module hello;

import std.stdio;
import tgc.gcobj;
import dui;

void main()
{
    writeln("dui ", duiVersion, " / dew ", dewVersion, " — ", dewSlogan);

    State!int clicks = State!int(0);
    DuiApp app;

    clicks.bindRebuild(() { app.requestRebuild(); });

    app.init((ref UiBuilder ui) {
        return VStack(
            Text("dui hello").fontSize(20).bold(),
            Text("clicks").fontSize(14),
            Button("Tap me")
                .touchFriendly()
                .onClick(() { clicks = clicks.value + 1; })
        ).spacing(10).padding(16);
    }, new SoftwareBackend(640, 400));

    app.dew.resize(640, 400);
    app.frame();

    // Simulate a touch tap on the button area (approximate)
    app.pointer(touchDown(40, 80));
    app.frame();

    writeln("clicks=", clicks.value, " cmds=", app.dew.list.cmds.length);
    writeln("hello OK");
}
