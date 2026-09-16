module gallery;

import std.stdio;
import std.format : format;
import std.algorithm : startsWith;
import tgc.gcobj;
import dui;

void main()
{
    writeln("dui gallery ", duiVersion, " — theme seed components");

    State!bool dark = State!bool(false);
    State!string name = State!string("");
    State!bool agree = State!bool(true);
    State!bool notifications = State!bool(false);
    State!int taps = State!int(0);

    DuiApp app;
    app.bind(dark);
    app.bind(name);
    app.bind(agree);
    app.bind(notifications);
    app.bind(taps);

    app.init((ref UiBuilder ui) {
        const tokens = app.theme.current;
        const modeLabel = dark.value ? "Dark" : "Light";
        return themedScreen(tokens,
            HStack(
                themedText(tokens, "Component gallery", TextStyle(fontSize: tokens.metrics.fontSizeXl, bold: true, hasFontSize: true, hasBold: true)),
                Spacer(),
                themedButton(tokens, format("Theme: %s", modeLabel), () {
                    dark = !dark.value;
                    app.theme.setMode(dark.value ? ThemeMode.dark : ThemeMode.light);
                }, ButtonStyle(height: 36))
            ),
            themedDivider(tokens),
            themedCard(tokens,
                themedText(tokens, "Typography", TextStyle(fontSize: tokens.metrics.fontSizeLg, bold: true, hasFontSize: true, hasBold: true)),
                themedText(tokens, "Body text uses theme tokens for color at paint time."),
                themedText(tokens, "Muted secondary line.", TextStyle.init)
            ),
            themedCard(tokens,
                themedText(tokens, "Inputs", TextStyle(fontSize: tokens.metrics.fontSizeLg, bold: true, hasFontSize: true, hasBold: true)),
                themedBoundTextField(name, tokens, "Your name"),
                themedBoundCheckBox(agree, tokens, "I agree to the terms"),
                themedBoundSwitch(notifications, tokens, "Push notifications")
            ),
            themedCard(tokens,
                themedText(tokens, "Actions", TextStyle(fontSize: tokens.metrics.fontSizeLg, bold: true, hasFontSize: true, hasBold: true)),
                themedButton(tokens, format("Tapped %s times", taps.value), () {
                    taps.update(v => v + 1);
                })
            )
        );
    }, new SoftwareBackend(480, 720));

    app.dew.resize(480, 720);
    app.frame();

    // Animate light → dark toggle colors without rebuilding layout.
    dark = true;
    app.theme.setMode(ThemeMode.dark);
    ColorRgba bgBefore;
    bgBefore = screenBackgroundColor(app);
    app.frame(112f);
    const bgMid = screenBackgroundColor(app);
    app.frame(120f);
    assert(!app.theme.animating);
    assert(bgMid.r < bgBefore.r, "background should darken mid-transition");

    // Tap theme toggle
    float tx, ty, tw, th;
    bool found;
    foreach (ref n; app.dew.ui.store.nodes)
    {
        if (n.kind == NodeKind.Button && n.text.startsWith("Theme:"))
        {
            tx = n.x;
            ty = n.y;
            tw = n.w;
            th = n.h;
            found = true;
            break;
        }
    }
    assert(found);
    assert(app.tap(tx + tw * 0.5f, ty + th * 0.5f));
    assert(dark.value == false);

    writeln("gallery OK — cmds=", app.dew.list.cmds.length);
}

ColorRgba screenBackgroundColor(DuiApp app)
{
    foreach (ref cmd; app.dew.list.cmds)
    {
        if ((cmd.op == DrawOp.FillRect || cmd.op == DrawOp.FillRoundedRect) && cmd.w > 400)
            return cmd.color;
    }
    return ColorRgba.init;
}
