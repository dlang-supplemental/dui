/// Minimal theme demo: light/dark toggle + color transition (no component host).
module gallery;

import std.stdio;
import std.format : format;
import tgc.gcobj;
import dui;

void main()
{
    writeln("dui ", duiVersion, " — theme toggle");

    State!bool dark = State!bool(false);

    DuiApp app;
    app.bind(dark);

    app.init((ref UiBuilder ui) {
        const t = app.theme.current;
        const label = format("Appearance: %s", dark.value ? "Dark" : "Light");
        return VStack(
            Text("Theme tokens").fontSize(t.metrics.fontTitle2).bold(),
            Text("Color lerp on mode switch; layout uses dew widgets.").fontSize(t.metrics.fontBody),
            Button(label).touchFriendly().onClick(() {
                dark = !dark.value;
                app.theme.setMode(dark.value ? ThemeMode.dark : ThemeMode.light);
            })
        ).spacing(t.metrics.insetStandard).padding(t.metrics.insetSection)
            .background(t.colors.windowBackground);
    }, new SoftwareBackend(480, 200));

    app.dew.resize(480, 200);
    app.frame();

    const bgBefore = windowBackgroundFill(app);
    dark = true;
    app.theme.setMode(ThemeMode.dark);
    app.frame(112f);
    const bgMid = windowBackgroundFill(app);
    app.frame(120f);
    assert(!app.theme.animating);
    assert(bgMid.r < bgBefore.r);

    float bx, by, bw, bh;
    foreach (ref n; app.dew.ui.store.nodes)
    {
        if (n.kind == NodeKind.Button)
        {
            bx = n.x;
            by = n.y;
            bw = n.w;
            bh = n.h;
            break;
        }
    }
    assert(app.tap(bx + bw * 0.5f, by + bh * 0.5f));
    assert(dark.value == false);

    writeln("theme OK");
}

ColorRgba windowBackgroundFill(DuiApp app)
{
    foreach (ref cmd; app.dew.list.cmds)
    {
        if ((cmd.op == DrawOp.FillRect || cmd.op == DrawOp.FillRoundedRect) && cmd.w > 400)
            return cmd.color;
    }
    return ColorRgba.init;
}
