/// macOS desktop-first components (explicit `ThemeTokens` + style props).
module dui.components;

import dew;
import dui.theme;
import dui.theme_paint;
import dui.state;

private ThemePaintHints* tlsHints;

void beginThemeComponents(ThemePaintHints* hints) @trusted
{
    tlsHints = hints;
}

void endThemeComponents() @trusted
{
    tlsHints = null;
}

private void labelStyle(NodeId id, LabelStyle s) @safe nothrow
{
    if (tlsHints !is null)
        tlsHints.setLabelStyle(id, s);
}

private void buttonVariant(NodeId id, ButtonVariant v) @safe nothrow
{
    if (tlsHints !is null)
        tlsHints.setButtonVariant(id, v);
}

private void checkKind(NodeId id, CheckKind k) @safe nothrow
{
    if (tlsHints !is null)
        tlsHints.setCheckKind(id, k);
}

// --- Labels / text ---

Widget Label(const ref ThemeTokens tokens, const(char)[] text,
    LabelStyle style = LabelStyle.body) @safe
{
    auto w = Text(text).fontSize(tokens.metrics.fontBody);
    labelStyle(w.id, style);
    return w;
}

enum SeparatorAxis
{
    horizontal,
    vertical,
}

// --- Structure ---

/// Title-bar region hook (traffic lights live in the window host).
Widget windowChrome(const ref ThemeTokens tokens, const(char)[] title, Widget content) @safe
{
    return VStack(
        HStack(
            Label(tokens, title, LabelStyle.headline),
            Spacer()
        ).height(tokens.metrics.titleBarHeight).padding(tokens.metrics.insetStandard)
            .alignItems(AlignItems.Center)
            .background(tokens.colors.toolbarBackground),
        content
    ).spacing(0).width(Length.percent(100)).height(Length.percent(100))
        .background(tokens.colors.windowBackground);
}

Widget toolbar(const ref ThemeTokens tokens, Widget[] items...) @safe
{
    Widget[] kids;
    foreach (i; items)
        kids ~= i;
    return HStack(kids)
        .spacing(tokens.metrics.insetStandard)
        .padding(tokens.metrics.insetStandard)
        .height(tokens.metrics.toolbarHeight)
        .alignItems(AlignItems.Center)
        .background(tokens.colors.toolbarBackground);
}

Widget SplitView(const ref ThemeTokens tokens, Widget sidebar, Widget detail,
    float sidebarWidth = 0) @safe
{
    const sw = sidebarWidth > 0 ? sidebarWidth : tokens.metrics.sidebarWidth;
    return HStack(
        sidebar.width(sw),
        Separator(tokens, SeparatorAxis.vertical),
        detail.flexGrow(1)
    ).spacing(0).width(Length.percent(100)).height(Length.percent(100));
}

Widget TabView(const ref ThemeTokens tokens, ref State!int tabIndex,
    const(char)[][] labels, Widget[] pages) @safe
{
    Widget[] segments;
    foreach (i, lab; labels)
    {
        const selected = tabIndex.value == i;
        auto seg = PushButton(tokens, lab, ButtonVariant.segmented, () { tabIndex = cast(int) i; });
        if (tlsHints !is null)
            tlsHints.markSegmentSelected(seg.id, selected);
        segments ~= seg;
    }
    Widget body = pages.length ? pages[min(tabIndex.value, cast(int) pages.length - 1)]
        : Label(tokens, "");
    return VStack(
        HStack(segments).spacing(0),
        body.flexGrow(1)
    ).spacing(tokens.metrics.insetStandard).width(Length.percent(100));
}

Widget scrollView(const ref ThemeTokens tokens, Widget content) @safe
{
    return ScrollView(content).padding(tokens.metrics.insetCompact);
}

struct SectionParams
{
    const(char)[] header;
    bool hasHeader = true;
}

Widget Section(const ref ThemeTokens tokens, SectionParams p, Widget[] children...) @safe
{
    Widget[] kids;
    if (p.hasHeader && p.header.length)
        kids ~= Label(tokens, p.header, LabelStyle.secondary);
    foreach (c; children)
        kids ~= c;
    return VStack(kids)
        .spacing(tokens.metrics.insetTight)
        .padding(tokens.metrics.insetStandard);
}

Widget GroupBox(const ref ThemeTokens tokens, const(char)[] title, Widget[] children...) @safe
{
    Widget[] kids;
    if (title.length)
        kids ~= Label(tokens, title, LabelStyle.headline);
    foreach (c; children)
        kids ~= c;
    return VStack(kids)
        .spacing(tokens.metrics.insetStandard)
        .padding(tokens.metrics.insetComfortable)
        .background(tokens.colors.controlBackground);
}

Widget Separator(const ref ThemeTokens tokens, SeparatorAxis axis = SeparatorAxis.horizontal) @safe
{
    if (axis == SeparatorAxis.vertical)
        return Container().width(tokens.metrics.splitDivider).height(Length.percent(100))
            .background(tokens.colors.separator);
    return Container().height(tokens.metrics.splitDivider).width(Length.percent(100))
        .background(tokens.colors.separator);
}

// --- Controls ---

Widget PushButton(const ref ThemeTokens tokens, const(char)[] label,
    ButtonVariant variant = ButtonVariant.accent, ClickHandler onClick = null) @safe
{
    auto w = Button(label)
        .fontSize(tokens.metrics.fontBody)
        .height(tokens.metrics.controlHeight)
        .padding(tokens.metrics.insetStandard)
        .touchFriendly();
    buttonVariant(w.id, variant);
    if (onClick !is null)
        w.onClick(onClick);
    return w;
}

Widget SegmentedControl(const ref ThemeTokens tokens, ref State!int index,
    const(char)[][] segments) @safe
{
    Widget[] parts;
    foreach (i, seg; segments)
    {
        const sel = index.value == i;
        auto b = PushButton(tokens, seg, ButtonVariant.segmented, () { index = cast(int) i; });
        if (tlsHints !is null)
            tlsHints.markSegmentSelected(b.id, sel);
        parts ~= b;
    }
    return HStack(parts).spacing(0);
}

Widget Toggle(const ref ThemeTokens tokens, const(char)[] label, bool on,
    ClickHandler onClick = null) @safe
{
    auto w = CheckBox(label, on)
        .fontSize(tokens.metrics.fontBody)
        .height(tokens.metrics.controlHeight)
        .focusable()
        .touchFriendly();
    checkKind(w.id, CheckKind.toggle);
    if (onClick !is null)
        w.onClick(onClick);
    return w;
}

Widget boundToggle(ref State!bool flag, const ref ThemeTokens tokens, const(char)[] label) @safe
{
    return Toggle(tokens, label, flag.value, () { flag = !flag.value; });
}

Widget Checkbox(const ref ThemeTokens tokens, const(char)[] label, bool checked,
    ClickHandler onClick = null) @safe
{
    auto w = CheckBox(label, checked)
        .fontSize(tokens.metrics.fontBody)
        .height(tokens.metrics.controlHeight)
        .focusable()
        .touchFriendly();
    checkKind(w.id, CheckKind.checkbox);
    if (onClick !is null)
        w.onClick(onClick);
    return w;
}

Widget boundCheckbox(ref State!bool flag, const ref ThemeTokens tokens, const(char)[] label) @safe
{
    return Checkbox(tokens, label, flag.value, () { flag = !flag.value; });
}

Widget Radio(const ref ThemeTokens tokens, const(char)[] label, bool selected,
    ClickHandler onClick = null) @safe
{
    auto w = CheckBox(label, selected)
        .fontSize(tokens.metrics.fontBody)
        .height(tokens.metrics.controlHeight)
        .focusable()
        .touchFriendly();
    checkKind(w.id, CheckKind.radio);
    if (onClick !is null)
        w.onClick(onClick);
    return w;
}

Widget RadioGroup(const ref ThemeTokens tokens, ref State!int selected,
    const(char)[][] options) @safe
{
    Widget[] rows;
    foreach (i, opt; options)
    {
        const sel = selected.value == i;
        rows ~= Radio(tokens, opt, sel, () { selected = cast(int) i; });
    }
    return VStack(rows).spacing(tokens.metrics.insetTight);
}

Widget Slider(const ref ThemeTokens tokens, ref State!float value, float minVal = 0,
    float maxVal = 1) @safe
{
    const v = clamp(value.value, minVal, maxVal);
    const t = (v - minVal) / (maxVal - minVal);
    auto track = Container()
        .height(4)
        .width(Length.percent(100))
        .background(tokens.colors.separator);
    if (tlsHints !is null)
        tlsHints.markSliderTrack(track.id);
    const thumbX = 180f * t;
    auto thumb = Container()
        .width(14)
        .height(14)
        .background(tokens.colors.accent);
    return HStack(track, thumb)
        .spacing(0)
        .height(tokens.metrics.controlHeight)
        .onPointer((PointerEvent ev) {
            if (ev.phase == PointerPhase.Up)
            {
                const nt = clamp(ev.x / 180f, 0f, 1f);
                value = minVal + nt * (maxVal - minVal);
            }
        })
        .touchFriendly();
}

/// API placeholder — functional stepper deferred to host/gesture follow-up.
Widget StepperPlaceholder(const ref ThemeTokens tokens) @safe
{
    return Label(tokens, "Stepper — deferred", LabelStyle.caption);
}

Widget TextFieldControl(const ref ThemeTokens tokens, const(char)[] value,
    const(char)[] placeholder = "") @safe
{
    return TextField(value)
        .placeholder(placeholder)
        .fontSize(tokens.metrics.fontBody)
        .height(tokens.metrics.controlHeight + 4)
        .background(tokens.colors.textFieldBackground)
        .focusable();
}

Widget boundTextFieldControl(ref State!string text, const ref ThemeTokens tokens,
    const(char)[] placeholder = "") @safe
{
    return TextFieldControl(tokens, text.value, placeholder)
        .width(Length.percent(100))
        .onKey((KeyEvent ev) {
            if (ev.phase != KeyPhase.Down)
                return;
            if (ev.key == "Backspace")
            {
                if (text.value.length)
                    text = text.value[0 .. $ - 1];
                return;
            }
            if (ev.key.length == 1 && !ev.ctrl && !ev.alt && !ev.meta)
                text = text.value ~ ev.key;
        });
}

Widget SearchField(const ref ThemeTokens tokens, ref State!string query,
    const(char)[] placeholder = "Search") @safe
{
    auto w = boundTextFieldControl(query, tokens, placeholder);
    if (tlsHints !is null)
        tlsHints.markSearchField(w.id);
    return w;
}

/// Pop-up menu surface stub — renders as bordered secondary button.
Widget MenuButton(const ref ThemeTokens tokens, const(char)[] title) @safe
{
    return PushButton(tokens, title ~ " ▾", ButtonVariant.secondary, null);
}

Widget DisclosureTriangle(const ref ThemeTokens tokens, ref State!bool expanded,
    const(char)[] title, Widget content) @safe
{
    const mark = expanded.value ? "▼" : "▶";
    auto head = PushButton(tokens, mark ~ " " ~ title, ButtonVariant.plain,
        () { expanded = !expanded.value; });
    if (tlsHints !is null)
        tlsHints.markDisclosureOpen(head.id, expanded.value);
    if (!expanded.value)
        return head;
    return VStack(head, content.padding(tokens.metrics.insetComfortable))
        .spacing(tokens.metrics.insetTight);
}

// --- Content rows ---

Widget ListRow(const ref ThemeTokens tokens, const(char)[] title, const(char)[] subtitle = null,
    bool selected = false) @safe
{
    Widget[] kids = [Label(tokens, title, LabelStyle.body)];
    if (subtitle.length)
        kids ~= Label(tokens, subtitle, LabelStyle.secondary);
    auto row = HStack(kids)
        .spacing(tokens.metrics.insetStandard)
        .padding(tokens.metrics.insetStandard)
        .height(tokens.metrics.rowHeight + tokens.metrics.insetComfortable)
        .width(Length.percent(100));
    if (selected)
    {
        row.background(tokens.colors.selectedContentBackground);
        if (tlsHints !is null)
            tlsHints.markListRowSelected(row.id, true);
    }
    return row;
}

Widget OutlineRow(const ref ThemeTokens tokens, int depth, const(char)[] title,
    bool selected = false) @safe
{
    const indent = tokens.metrics.insetComfortable + depth * tokens.metrics.insetSection;
    auto row = HStack(
        Container().width(indent),
        Label(tokens, title, LabelStyle.body)
    ).padding(tokens.metrics.insetStandard)
        .height(tokens.metrics.rowHeight + tokens.metrics.insetComfortable)
        .width(Length.percent(100));
    if (selected)
        row.background(tokens.colors.selectedContentBackground);
    return row;
}

/// Optional grouped surface (not the primary desktop metaphor).
Widget Card(const ref ThemeTokens tokens, Widget[] children...) @safe
{
    Widget[] kids;
    foreach (c; children)
        kids ~= c;
    return VStack(kids)
        .spacing(tokens.metrics.insetStandard)
        .padding(tokens.metrics.insetComfortable)
        .background(tokens.colors.groupedBackground);
}

Widget desktopRoot(const ref ThemeTokens tokens, Widget[] children...) @safe
{
    Widget[] kids;
    foreach (c; children)
        kids ~= c;
    return VStack(kids)
        .spacing(0)
        .width(Length.percent(100))
        .height(Length.percent(100))
        .background(tokens.colors.windowBackground);
}

private float clamp(float v, float lo, float hi) @safe @nogc pure nothrow
{
    if (v < lo)
        return lo;
    if (v > hi)
        return hi;
    return v;
}

private int min(int a, int b) @safe @nogc pure nothrow
{
    return a < b ? a : b;
}

// --- Legacy aliases (Material-ish seed names) ---

alias themedText = Label;
alias themedButton = PushButton;
alias themedDivider = Separator;
alias themedScreen = desktopRoot;
alias themedCard = Card;
alias themedCheckBox = Checkbox;
alias themedBoundCheckBox = boundCheckbox;
alias themedSwitch = Toggle;
alias themedBoundSwitch = boundToggle;
alias themedTextField = TextFieldControl;
alias themedBoundTextField = boundTextFieldControl;
