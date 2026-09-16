/// macOS-inspired design tokens, light/dark themes, and color transitions.
module dui.theme;

import dew;

enum ThemeMode
{
    light,
    dark,
}

/**
 * Semantic colors (HIG-style names). No vibrancy/blur tokens — solid fills only.
 */
struct ThemeColors
{
    ColorRgba windowBackground;
    ColorRgba controlBackground;
    ColorRgba groupedBackground;
    ColorRgba sidebarBackground;
    ColorRgba toolbarBackground;
    ColorRgba label;
    ColorRgba secondaryLabel;
    ColorRgba tertiaryLabel;
    ColorRgba quaternaryLabel;
    ColorRgba separator;
    ColorRgba accent;
    ColorRgba accentPressed;
    ColorRgba onAccent;
    ColorRgba controlBorder;
    ColorRgba focusRing;
    ColorRgba destructive;
    ColorRgba onDestructive;
    ColorRgba textFieldBackground;
    ColorRgba searchFieldBackground;
    ColorRgba selectedContentBackground;
    ColorRgba selectedText;
    ColorRgba checkboxStroke;
    ColorRgba checkboxFill;
    ColorRgba switchTrackOff;
    ColorRgba switchTrackOn;
    ColorRgba switchThumb;
}

/// SF-like type scale + dense desktop spacing (logical px).
struct ThemeMetrics
{
    float insetTight = 4;
    float insetCompact = 6;
    float insetStandard = 8;
    float insetComfortable = 12;
    float insetSection = 16;
    float insetWindow = 20;

    float controlHeight = 22;
    float toolbarHeight = 38;
    float titleBarHeight = 28;
    float rowHeight = 20;
    float sidebarWidth = 200;
    float splitDivider = 1;

    float radiusControl = 5;
    float radiusGroup = 6;
    float radiusSheet = 10;

    float fontLargeTitle = 26;
    float fontTitle1 = 22;
    float fontTitle2 = 17;
    float fontTitle3 = 15;
    float fontHeadline = 13;
    float fontBody = 13;
    float fontCallout = 12;
    float fontSubheadline = 11;
    float fontFootnote = 10;
    float fontCaption = 10;
}

struct ThemeTokens
{
    ThemeColors colors;
    ThemeMetrics metrics;
}

struct Theme
{
    ThemeMode mode;
    ThemeTokens tokens;

    static Theme light() @safe @nogc pure nothrow
    {
        Theme t;
        t.mode = ThemeMode.light;
        t.tokens = lightTokens();
        return t;
    }

    static Theme dark() @safe @nogc pure nothrow
    {
        Theme t;
        t.mode = ThemeMode.dark;
        t.tokens = darkTokens();
        return t;
    }
}

/// Typography / emphasis for `Label` (explicit prop — not a cascade).
enum LabelStyle : ubyte
{
    largeTitle,
    title1,
    title2,
    title3,
    headline,
    body,
    secondary,
    tertiary,
    caption,
}

/// macOS-style push button roles.
enum ButtonVariant : ubyte
{
    accent,
    secondary,
    destructive,
    plain,
    bordered,
    segmented,
}

ColorRgba lerpColor(ColorRgba a, ColorRgba b, float t) @safe @nogc pure nothrow
{
    if (t <= 0)
        return a;
    if (t >= 1)
        return b;
    ubyte lerpU(ubyte x, ubyte y)
    {
        return cast(ubyte)(x + (y - x) * t);
    }
    return ColorRgba(lerpU(a.r, b.r), lerpU(a.g, b.g), lerpU(a.b, b.b), lerpU(a.a, b.a));
}

ThemeColors lerpThemeColors(ThemeColors from, ThemeColors to, float t) @safe @nogc pure nothrow
{
    ThemeColors out_;
    out_.windowBackground = lerpColor(from.windowBackground, to.windowBackground, t);
    out_.controlBackground = lerpColor(from.controlBackground, to.controlBackground, t);
    out_.groupedBackground = lerpColor(from.groupedBackground, to.groupedBackground, t);
    out_.sidebarBackground = lerpColor(from.sidebarBackground, to.sidebarBackground, t);
    out_.toolbarBackground = lerpColor(from.toolbarBackground, to.toolbarBackground, t);
    out_.label = lerpColor(from.label, to.label, t);
    out_.secondaryLabel = lerpColor(from.secondaryLabel, to.secondaryLabel, t);
    out_.tertiaryLabel = lerpColor(from.tertiaryLabel, to.tertiaryLabel, t);
    out_.quaternaryLabel = lerpColor(from.quaternaryLabel, to.quaternaryLabel, t);
    out_.separator = lerpColor(from.separator, to.separator, t);
    out_.accent = lerpColor(from.accent, to.accent, t);
    out_.accentPressed = lerpColor(from.accentPressed, to.accentPressed, t);
    out_.onAccent = lerpColor(from.onAccent, to.onAccent, t);
    out_.controlBorder = lerpColor(from.controlBorder, to.controlBorder, t);
    out_.focusRing = lerpColor(from.focusRing, to.focusRing, t);
    out_.destructive = lerpColor(from.destructive, to.destructive, t);
    out_.onDestructive = lerpColor(from.onDestructive, to.onDestructive, t);
    out_.textFieldBackground = lerpColor(from.textFieldBackground, to.textFieldBackground, t);
    out_.searchFieldBackground = lerpColor(from.searchFieldBackground, to.searchFieldBackground, t);
    out_.selectedContentBackground = lerpColor(from.selectedContentBackground, to.selectedContentBackground, t);
    out_.selectedText = lerpColor(from.selectedText, to.selectedText, t);
    out_.checkboxStroke = lerpColor(from.checkboxStroke, to.checkboxStroke, t);
    out_.checkboxFill = lerpColor(from.checkboxFill, to.checkboxFill, t);
    out_.switchTrackOff = lerpColor(from.switchTrackOff, to.switchTrackOff, t);
    out_.switchTrackOn = lerpColor(from.switchTrackOn, to.switchTrackOn, t);
    out_.switchThumb = lerpColor(from.switchThumb, to.switchThumb, t);
    return out_;
}

ThemeTokens lerpThemeTokens(ThemeTokens from, ThemeTokens to, float t) @safe @nogc pure nothrow
{
    ThemeTokens out_;
    out_.colors = lerpThemeColors(from.colors, to.colors, t);
    out_.metrics = to.metrics;
    return out_;
}

struct ThemeController
{
    ThemeMode mode = ThemeMode.light;
    ThemeTokens current;
    bool animating;
    private ThemeTokens _from;
    private ThemeTokens _to;
    private float _progress;
    private float _durationMs = 225f;

    void reset(ThemeMode m = ThemeMode.light) @safe @nogc nothrow
    {
        mode = m;
        current = themeFor(m).tokens;
        animating = false;
        _progress = 1f;
    }

    void setMode(ThemeMode m, float durationMs = 225f) @safe @nogc nothrow
    {
        if (m == mode && !animating)
            return;
        _from = current;
        _to = themeFor(m).tokens;
        mode = m;
        _durationMs = durationMs > 0 ? durationMs : 225f;
        _progress = 0f;
        animating = true;
    }

    void tick(float dtMs) @safe @nogc nothrow
    {
        if (!animating)
            return;
        _progress += dtMs / _durationMs;
        if (_progress >= 1f)
        {
            _progress = 1f;
            animating = false;
            current = _to;
            return;
        }
        current = lerpThemeTokens(_from, _to, _progress);
    }

    private static Theme themeFor(ThemeMode m) @safe @nogc pure nothrow
    {
        return m == ThemeMode.dark ? Theme.dark() : Theme.light();
    }
}

private ThemeTokens lightTokens() @safe @nogc pure nothrow
{
    ThemeTokens t;
    t.colors.windowBackground = ColorRgba.rgb(236, 236, 236);
    t.colors.controlBackground = ColorRgba.rgb(255, 255, 255);
    t.colors.groupedBackground = ColorRgba.rgb(246, 246, 248);
    t.colors.sidebarBackground = ColorRgba.rgb(228, 228, 230);
    t.colors.toolbarBackground = ColorRgba.rgb(246, 246, 248);
    t.colors.label = ColorRgba.rgb(0, 0, 0);
    t.colors.secondaryLabel = ColorRgba.rgb(60, 60, 67);
    t.colors.tertiaryLabel = ColorRgba.rgb(90, 90, 98);
    t.colors.quaternaryLabel = ColorRgba.rgb(142, 142, 147);
    t.colors.separator = ColorRgba.rgb(198, 198, 200);
    t.colors.accent = ColorRgba.rgb(0, 122, 255);
    t.colors.accentPressed = ColorRgba.rgb(0, 100, 210);
    t.colors.onAccent = ColorRgba.rgb(255, 255, 255);
    t.colors.controlBorder = ColorRgba.rgb(190, 190, 194);
    t.colors.focusRing = ColorRgba.rgb(0, 122, 255);
    t.colors.destructive = ColorRgba.rgb(255, 59, 48);
    t.colors.onDestructive = ColorRgba.rgb(255, 255, 255);
    t.colors.textFieldBackground = ColorRgba.rgb(255, 255, 255);
    t.colors.searchFieldBackground = ColorRgba.rgb(232, 232, 234);
    t.colors.selectedContentBackground = ColorRgba.rgb(0, 122, 255);
    t.colors.selectedText = ColorRgba.rgb(255, 255, 255);
    t.colors.checkboxStroke = ColorRgba.rgb(120, 120, 128);
    t.colors.checkboxFill = ColorRgba.rgb(0, 122, 255);
    t.colors.switchTrackOff = ColorRgba.rgb(190, 190, 194);
    t.colors.switchTrackOn = ColorRgba.rgb(52, 199, 89);
    t.colors.switchThumb = ColorRgba.rgb(255, 255, 255);
    return t;
}

private ThemeTokens darkTokens() @safe @nogc pure nothrow
{
    ThemeTokens t;
    t.metrics = lightTokens().metrics;
    t.colors.windowBackground = ColorRgba.rgb(30, 30, 30);
    t.colors.controlBackground = ColorRgba.rgb(44, 44, 46);
    t.colors.groupedBackground = ColorRgba.rgb(28, 28, 30);
    t.colors.sidebarBackground = ColorRgba.rgb(36, 36, 38);
    t.colors.toolbarBackground = ColorRgba.rgb(40, 40, 42);
    t.colors.label = ColorRgba.rgb(255, 255, 255);
    t.colors.secondaryLabel = ColorRgba.rgb(172, 172, 178);
    t.colors.tertiaryLabel = ColorRgba.rgb(142, 142, 148);
    t.colors.quaternaryLabel = ColorRgba.rgb(99, 99, 102);
    t.colors.separator = ColorRgba.rgb(72, 72, 74);
    t.colors.accent = ColorRgba.rgb(10, 132, 255);
    t.colors.accentPressed = ColorRgba.rgb(0, 110, 220);
    t.colors.onAccent = ColorRgba.rgb(255, 255, 255);
    t.colors.controlBorder = ColorRgba.rgb(90, 90, 94);
    t.colors.focusRing = ColorRgba.rgb(10, 132, 255);
    t.colors.destructive = ColorRgba.rgb(255, 69, 58);
    t.colors.onDestructive = ColorRgba.rgb(255, 255, 255);
    t.colors.textFieldBackground = ColorRgba.rgb(30, 30, 32);
    t.colors.searchFieldBackground = ColorRgba.rgb(52, 52, 54);
    t.colors.selectedContentBackground = ColorRgba.rgb(10, 132, 255);
    t.colors.selectedText = ColorRgba.rgb(255, 255, 255);
    t.colors.checkboxStroke = ColorRgba.rgb(120, 120, 128);
    t.colors.checkboxFill = ColorRgba.rgb(10, 132, 255);
    t.colors.switchTrackOff = ColorRgba.rgb(72, 72, 74);
    t.colors.switchTrackOn = ColorRgba.rgb(48, 209, 88);
    t.colors.switchThumb = ColorRgba.rgb(255, 255, 255);
    return t;
}

unittest
{
    ThemeController ctrl;
    ctrl.reset(ThemeMode.light);
    assert(ctrl.current.colors.windowBackground.r == 236);

    ctrl.setMode(ThemeMode.dark, 200f);
    ctrl.tick(100f);
    ctrl.tick(100f);
    assert(!ctrl.animating);
    assert(ctrl.current.colors.windowBackground.r == 30);
}
