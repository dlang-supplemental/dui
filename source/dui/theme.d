/// Design tokens, light/dark themes, and animated color transitions.
module dui.theme;

import dew;

/// Light or dark baseline palette.
enum ThemeMode
{
    light,
    dark,
}

/// Semantic colors (logical units; alpha always 0–255).
struct ThemeColors
{
    ColorRgba background;
    ColorRgba surface;
    ColorRgba surfaceElevated;
    ColorRgba primary;
    ColorRgba onPrimary;
    ColorRgba primaryBorder;
    ColorRgba textPrimary;
    ColorRgba textSecondary;
    ColorRgba textMuted;
    ColorRgba border;
    ColorRgba borderFocus;
    ColorRgba divider;
    ColorRgba fieldFill;
    ColorRgba checkStroke;
    ColorRgba switchTrackOff;
    ColorRgba switchTrackOn;
    ColorRgba switchThumb;
    ColorRgba error;
}

/// Spacing, radii, and type scale in logical px (DIPs).
struct ThemeMetrics
{
    float spaceXs = 4;
    float spaceSm = 8;
    float spaceMd = 12;
    float spaceLg = 16;
    float spaceXl = 24;

    float radiusSm = 4;
    float radiusMd = 8;
    float radiusLg = 12;

    float fontSizeSm = 12;
    float fontSizeMd = 14;
    float fontSizeLg = 18;
    float fontSizeXl = 22;
}

/// Full token set for one resolved theme frame.
struct ThemeTokens
{
    ThemeColors colors;
    ThemeMetrics metrics;
}

/// Static light/dark token sources (non-animated endpoints).
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

/// Linear RGBA blend (local helper until dew exposes one — see dew follow-up).
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
    out_.background = lerpColor(from.background, to.background, t);
    out_.surface = lerpColor(from.surface, to.surface, t);
    out_.surfaceElevated = lerpColor(from.surfaceElevated, to.surfaceElevated, t);
    out_.primary = lerpColor(from.primary, to.primary, t);
    out_.onPrimary = lerpColor(from.onPrimary, to.onPrimary, t);
    out_.primaryBorder = lerpColor(from.primaryBorder, to.primaryBorder, t);
    out_.textPrimary = lerpColor(from.textPrimary, to.textPrimary, t);
    out_.textSecondary = lerpColor(from.textSecondary, to.textSecondary, t);
    out_.textMuted = lerpColor(from.textMuted, to.textMuted, t);
    out_.border = lerpColor(from.border, to.border, t);
    out_.borderFocus = lerpColor(from.borderFocus, to.borderFocus, t);
    out_.divider = lerpColor(from.divider, to.divider, t);
    out_.fieldFill = lerpColor(from.fieldFill, to.fieldFill, t);
    out_.checkStroke = lerpColor(from.checkStroke, to.checkStroke, t);
    out_.switchTrackOff = lerpColor(from.switchTrackOff, to.switchTrackOff, t);
    out_.switchTrackOn = lerpColor(from.switchTrackOn, to.switchTrackOn, t);
    out_.switchThumb = lerpColor(from.switchThumb, to.switchThumb, t);
    out_.error = lerpColor(from.error, to.error, t);
    return out_;
}

ThemeTokens lerpThemeTokens(ThemeTokens from, ThemeTokens to, float t) @safe @nogc pure nothrow
{
    ThemeTokens out_;
    out_.colors = lerpThemeColors(from.colors, to.colors, t);
    // Metrics stay on the target theme — no layout animation.
    out_.metrics = to.metrics;
    return out_;
}

/**
 * Holds the actively painted palette. Color fields animate on `setMode`;
 * metrics jump to the target theme immediately.
 */
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

    /// Begin a color transition (~200–250 ms default). Does not rebuild layout.
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
    t.colors.background = ColorRgba.rgb(245, 247, 250);
    t.colors.surface = ColorRgba.rgb(255, 255, 255);
    t.colors.surfaceElevated = ColorRgba.rgb(252, 252, 254);
    t.colors.primary = ColorRgba.rgb(45, 110, 200);
    t.colors.onPrimary = ColorRgba.rgb(255, 255, 255);
    t.colors.primaryBorder = ColorRgba.rgb(30, 80, 160);
    t.colors.textPrimary = ColorRgba.rgb(24, 28, 36);
    t.colors.textSecondary = ColorRgba.rgb(55, 62, 75);
    t.colors.textMuted = ColorRgba.rgb(120, 128, 140);
    t.colors.border = ColorRgba.rgb(180, 186, 198);
    t.colors.borderFocus = ColorRgba.rgb(45, 110, 200);
    t.colors.divider = ColorRgba.rgb(220, 224, 232);
    t.colors.fieldFill = ColorRgba.rgb(250, 251, 253);
    t.colors.checkStroke = ColorRgba.rgb(45, 110, 200);
    t.colors.switchTrackOff = ColorRgba.rgb(200, 204, 212);
    t.colors.switchTrackOn = ColorRgba.rgb(100, 160, 230);
    t.colors.switchThumb = ColorRgba.rgb(255, 255, 255);
    t.colors.error = ColorRgba.rgb(200, 50, 50);
    return t;
}

private ThemeTokens darkTokens() @safe @nogc pure nothrow
{
    ThemeTokens t;
    t.metrics = lightTokens().metrics;
    t.colors.background = ColorRgba.rgb(18, 20, 26);
    t.colors.surface = ColorRgba.rgb(28, 32, 42);
    t.colors.surfaceElevated = ColorRgba.rgb(36, 40, 52);
    t.colors.primary = ColorRgba.rgb(90, 150, 240);
    t.colors.onPrimary = ColorRgba.rgb(12, 16, 24);
    t.colors.primaryBorder = ColorRgba.rgb(60, 110, 190);
    t.colors.textPrimary = ColorRgba.rgb(236, 238, 242);
    t.colors.textSecondary = ColorRgba.rgb(190, 196, 208);
    t.colors.textMuted = ColorRgba.rgb(130, 138, 152);
    t.colors.border = ColorRgba.rgb(70, 76, 90);
    t.colors.borderFocus = ColorRgba.rgb(90, 150, 240);
    t.colors.divider = ColorRgba.rgb(48, 52, 64);
    t.colors.fieldFill = ColorRgba.rgb(22, 26, 34);
    t.colors.checkStroke = ColorRgba.rgb(90, 150, 240);
    t.colors.switchTrackOff = ColorRgba.rgb(60, 66, 80);
    t.colors.switchTrackOn = ColorRgba.rgb(70, 120, 200);
    t.colors.switchThumb = ColorRgba.rgb(230, 234, 242);
    t.colors.error = ColorRgba.rgb(240, 100, 100);
    return t;
}

unittest
{
    const a = ColorRgba.rgb(0, 0, 0);
    const b = ColorRgba.rgb(100, 200, 50);
    const mid = lerpColor(a, b, 0.5f);
    assert(mid.r == 50);
    assert(mid.g == 100);
    assert(mid.b == 25);

    ThemeController ctrl;
    ctrl.reset(ThemeMode.light);
    assert(ctrl.current.colors.background.r == 245);

    ctrl.setMode(ThemeMode.dark, 200f);
    assert(ctrl.animating);
    ctrl.tick(100f);
    assert(ctrl.current.colors.background.r < 245);
    assert(ctrl.current.colors.background.r > 18);
    ctrl.tick(100f);
    assert(!ctrl.animating);
    assert(ctrl.current.colors.background.r == 18);
}
