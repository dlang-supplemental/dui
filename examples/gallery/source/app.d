module gallery;

import std.stdio;
import std.format : format;
import std.algorithm : startsWith;
import tgc.gcobj;
import dui;

void main()
{
    writeln("dui gallery ", duiVersion, " — macOS desktop slice");

    State!bool dark = State!bool(false);
    State!int sidebarSection = State!int(0);
    State!int appearanceTab = State!int(0);
    State!string search = State!string("");
    State!string name = State!string("Ryan");
    State!bool notifications = State!bool(true);
    State!int radioPick = State!int(0);
    State!float volume = State!float(0.6f);
    State!bool expanded = State!bool(true);
    State!int pushCount = State!int(0);

    DuiApp app;
    app.bind(dark);
    app.bind(sidebarSection);
    app.bind(appearanceTab);
    app.bind(search);
    app.bind(name);
    app.bind(notifications);
    app.bind(radioPick);
    app.bind(volume);
    app.bind(expanded);
    app.bind(pushCount);

    app.init((ref UiBuilder ui) {
        const tokens = app.theme.current;
        const modeLabel = dark.value ? "Dark" : "Light";

        Widget sidebar = VStack(
            Label(tokens, "Gallery", LabelStyle.headline),
            Separator(tokens),
            PushButton(tokens, "Appearance", ButtonVariant.plain, () { sidebarSection = 0; }),
            PushButton(tokens, "Controls", ButtonVariant.plain, () { sidebarSection = 1; }),
            PushButton(tokens, "Lists", ButtonVariant.plain, () { sidebarSection = 2; }),
            Spacer()
        ).spacing(0).padding(tokens.metrics.insetCompact)
            .background(tokens.colors.sidebarBackground)
            .width(tokens.metrics.sidebarWidth);

        Widget appearancePane = scrollView(tokens, VStack(
            TabView(tokens, appearanceTab, ["General", "Advanced"], [
                VStack(
                    Section(tokens, SectionParams("Typography"),
                        Label(tokens, "Large Title", LabelStyle.largeTitle),
                        Label(tokens, "Title 1", LabelStyle.title1),
                        Label(tokens, "Body copy at desktop density.", LabelStyle.body),
                        Label(tokens, "Secondary label", LabelStyle.secondary),
                        Label(tokens, "Caption", LabelStyle.caption)
                    ),
                    GroupBox(tokens, "Theme",
                        Toggle(tokens, "Dark appearance", dark.value, () {
                            dark = !dark.value;
                            app.theme.setMode(dark.value ? ThemeMode.dark : ThemeMode.light);
                        }),
                        Label(tokens, format("Active mode: %s", modeLabel), LabelStyle.secondary)
                    )
                ),
                Label(tokens, "Advanced settings deferred.", LabelStyle.secondary)
            ]),
            DisclosureTriangle(tokens, expanded, "More options",
                Label(tokens, "Disclosure content", LabelStyle.body))
        ).spacing(tokens.metrics.insetSection));

        Widget controlsPane = scrollView(tokens, VStack(
            Section(tokens, SectionParams("Buttons"),
                HStack(
                    PushButton(tokens, "Accent", ButtonVariant.accent, () { pushCount.update(v => v + 1); }),
                    PushButton(tokens, "Secondary", ButtonVariant.secondary),
                    PushButton(tokens, "Destructive", ButtonVariant.destructive),
                    PushButton(tokens, "Plain", ButtonVariant.plain)
                ).spacing(tokens.metrics.insetStandard),
                Label(tokens, format("Accent clicks: %s", pushCount.value), LabelStyle.caption)
            ),
            Section(tokens, SectionParams("Inputs"),
                SearchField(tokens, search),
                boundTextFieldControl(name, tokens, "Name"),
                boundCheckbox(notifications, tokens, "Enable notifications"),
                RadioGroup(tokens, radioPick, ["Option A", "Option B", "Option C"]),
                Slider(tokens, volume),
                StepperPlaceholder(tokens),
                MenuButton(tokens, "Actions")
            )
        ).spacing(tokens.metrics.insetSection));

        Widget listsPane = scrollView(tokens, VStack(
            Section(tokens, SectionParams("List rows"),
                ListRow(tokens, "Wi-Fi", "Connected"),
                ListRow(tokens, "Bluetooth", "On"),
                ListRow(tokens, "Selected row", "Sidebar selection", true)
            ),
            Card(tokens,
                Label(tokens, "Grouped card (secondary)", LabelStyle.secondary)
            )
        ).spacing(tokens.metrics.insetSection));

        Widget detail;
        if (sidebarSection.value == 0)
            detail = appearancePane;
        else if (sidebarSection.value == 1)
            detail = controlsPane;
        else
            detail = listsPane;

        return windowChrome(tokens, "System Settings — Gallery",
            VStack(
                toolbar(tokens,
                    SegmentedControl(tokens, sidebarSection, ["Appearance", "Controls", "Lists"]),
                    Spacer(),
                    PushButton(tokens, format("Appearance: %s", modeLabel), ButtonVariant.bordered, () {
                        dark = !dark.value;
                        app.theme.setMode(dark.value ? ThemeMode.dark : ThemeMode.light);
                    })
                ),
                SplitView(tokens, sidebar, detail)
            ).spacing(0).height(Length.percent(100))
        );
    }, new SoftwareBackend(920, 620));

    app.dew.resize(920, 620);
    app.frame();

    const bgBefore = windowBackgroundColor(app);
    dark = true;
    app.theme.setMode(ThemeMode.dark);
    app.frame(112f);
    const bgMid = windowBackgroundColor(app);
    app.frame(120f);
    assert(!app.theme.animating);
    assert(bgMid.r < bgBefore.r, "window background should darken mid-transition");

    float tx, ty, tw, th;
    bool found;
    foreach (ref n; app.dew.ui.store.nodes)
    {
        if (n.kind == NodeKind.Button && n.text.startsWith("Appearance:"))
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

ColorRgba windowBackgroundColor(DuiApp app)
{
    foreach (ref cmd; app.dew.list.cmds)
    {
        if ((cmd.op == DrawOp.FillRect || cmd.op == DrawOp.FillRoundedRect) && cmd.w > 800)
            return cmd.color;
    }
    return ColorRgba.init;
}
