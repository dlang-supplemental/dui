/// Seed components styled via explicit `ThemeTokens` (no cascade).
module dui.components;

import dew;
import dui.theme;
import dui.theme_paint;
import dui.state;

/// Optional per-widget overrides (explicit props only).
struct TextStyle
{
    float fontSize;
    bool bold;
    ColorRgba color;
    bool hasFontSize;
    bool hasBold;
    bool hasColor;
}

struct ButtonStyle
{
    float height = 40;
    bool touchFriendly = true;
}

private ThemePaintHints* tlsHints;

void beginThemeComponents(ThemePaintHints* hints) @trusted
{
    tlsHints = hints;
}

void endThemeComponents() @trusted
{
    tlsHints = null;
}

private void markSwitch(NodeId id) @safe nothrow
{
    if (tlsHints !is null)
        tlsHints.markSwitch(id);
}

Widget themedText(const ref ThemeTokens tokens, const(char)[] text,
    TextStyle style = TextStyle.init) @safe
{
    auto w = Text(text);
    w.fontSize(style.hasFontSize ? style.fontSize : tokens.metrics.fontSizeMd);
    if (style.hasBold)
        w.bold(style.bold);
    // Text color comes from themed paint; bg overrides not used.
    return w;
}

Widget themedButton(const ref ThemeTokens tokens, const(char)[] label,
    ClickHandler onClick = null, ButtonStyle style = ButtonStyle.init) @safe
{
    auto w = Button(label)
        .fontSize(tokens.metrics.fontSizeMd)
        .height(style.height)
        .padding(tokens.metrics.spaceMd);
    if (style.touchFriendly)
        w.touchFriendly();
    if (onClick !is null)
        w.onClick(onClick);
    return w;
}

Widget themedTextField(const ref ThemeTokens tokens, const(char)[] value,
    const(char)[] placeholder = "…") @safe
{
    return TextField(value)
        .placeholder(placeholder)
        .fontSize(tokens.metrics.fontSizeMd)
        .height(36)
        .background(tokens.colors.fieldFill)
        .focusable();
}

/// Text field bound to `State!string` with theme metrics.
Widget themedBoundTextField(ref State!string text, const ref ThemeTokens tokens,
    const(char)[] placeholder = "…") @safe
{
    return themedTextField(tokens, text.value, placeholder)
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

Widget themedCheckBox(const ref ThemeTokens tokens, const(char)[] label, bool checked,
    ClickHandler onClick = null) @safe
{
    auto w = CheckBox(label, checked)
        .fontSize(tokens.metrics.fontSizeMd)
        .focusable()
        .touchFriendly();
    if (onClick !is null)
        w.onClick(onClick);
    return w;
}

Widget themedBoundCheckBox(ref State!bool flag, const ref ThemeTokens tokens,
    const(char)[] label) @safe
{
    return themedCheckBox(tokens, label, flag.value, () { flag = !flag.value; });
}

Widget themedSwitch(const ref ThemeTokens tokens, const(char)[] label, bool on,
    ClickHandler onClick = null) @safe
{
    auto w = CheckBox(label, on)
        .fontSize(tokens.metrics.fontSizeMd)
        .focusable()
        .touchFriendly();
    markSwitch(w.id);
    if (onClick !is null)
        w.onClick(onClick);
    return w;
}

Widget themedBoundSwitch(ref State!bool flag, const ref ThemeTokens tokens,
    const(char)[] label) @safe
{
    return themedSwitch(tokens, label, flag.value, () { flag = !flag.value; });
}

Widget themedCard(const ref ThemeTokens tokens, Widget[] children...) @safe
{
    Widget[] kids;
    foreach (c; children)
        kids ~= c;
    return VStack(kids)
        .spacing(tokens.metrics.spaceMd)
        .padding(tokens.metrics.spaceLg)
        .background(tokens.colors.surface);
}

Widget themedDivider(const ref ThemeTokens tokens) @safe
{
    return Container()
        .height(1)
        .width(Length.percent(100))
        .background(tokens.colors.divider);
}

/// Screen root with themed background.
Widget themedScreen(const ref ThemeTokens tokens, Widget[] children...) @safe
{
    Widget[] kids;
    foreach (c; children)
        kids ~= c;
    return VStack(kids)
        .spacing(tokens.metrics.spaceMd)
        .padding(tokens.metrics.spaceLg)
        .width(Length.percent(100))
        .height(Length.percent(100))
        .background(tokens.colors.background);
}
