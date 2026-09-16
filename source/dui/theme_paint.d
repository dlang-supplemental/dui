/// Token-aware paint pass (mirrors dew.paint_pass with ThemeTokens colors).
module dui.theme_paint;

import dew;
import dui.theme;

/// Per-build paint hints (cleared each rebuild).
struct ThemePaintHints
{
    private bool[] _switch;

    void clear() @safe nothrow
    {
        _switch = null;
    }

    void markSwitch(NodeId id) @safe nothrow
    {
        if (!id.valid)
            return;
        const idx = id.index;
        if (_switch.length <= idx)
            _switch.length = idx + 1;
        _switch[idx] = true;
    }

    bool isSwitch(NodeId id) const @safe @nogc nothrow
    {
        if (!id.valid || id.index >= _switch.length)
            return false;
        return _switch[id.index];
    }
}

void paintThemedTree(ref NodeStore store, NodeId root, ref DisplayList list,
    const ref ThemeTokens tokens, const ref ThemePaintHints hints) @safe
{
    if (!root.valid)
        return;
    paintThemedNode(store, root, list, tokens, hints);
}

private void paintThemedNode(ref NodeStore store, NodeId id, ref DisplayList list,
    const ref ThemeTokens tokens, const ref ThemePaintHints hints) @safe
{
    ref Node n = store[id];
    const clip = n.clipContent || n.kind == NodeKind.ScrollView;
    if (clip)
        list.clipPush(n.x, n.y, n.w, n.h);

    const c = tokens.colors;
    const m = tokens.metrics;

    final switch (n.kind)
    {
    case NodeKind.VStack:
    case NodeKind.HStack:
    case NodeKind.Container:
    case NodeKind.ScrollView:
    case NodeKind.Spacer:
    case NodeKind.Custom:
        if (n.fillBackground)
            list.fillRoundedRect(n.x, n.y, n.w, n.h, m.radiusMd, n.bgColor);
        break;
    case NodeKind.Canvas:
        list.fillRect(n.x, n.y, n.w, n.h,
            n.fillBackground ? n.bgColor : c.surface);
        list.strokeRect(n.x, n.y, n.w, n.h, c.border);
        if (n.showGrid)
        {
            enum float step = 24;
            for (float gx = n.x + step; gx < n.x + n.w; gx += step)
                list.fillRect(gx, n.y, 1, n.h, ColorRgba.rgba(c.border.r, c.border.g, c.border.b, 80));
            for (float gy = n.y + step; gy < n.y + n.h; gy += step)
                list.fillRect(n.x, gy, n.w, 1, ColorRgba.rgba(c.border.r, c.border.g, c.border.b, 80));
        }
        break;
    case NodeKind.MeshView:
        if (n.meshPixels.length && n.meshSrcW && n.meshSrcH)
            list.imageBlit(n.x, n.y, n.w, n.h, n.meshSrcW, n.meshSrcH, n.meshPixels);
        else
            list.fillRect(n.x, n.y, n.w, n.h, c.surfaceElevated);
        break;
    case NodeKind.Text:
        list.textRun(n.x + n.padding, n.y + n.padding + n.fontSize,
            n.fontSize, n.bold, n.text, c.textPrimary);
        break;
    case NodeKind.Button:
        list.fillRoundedRect(n.x, n.y, n.w, n.h, m.radiusMd, c.primary);
        list.strokeRect(n.x, n.y, n.w, n.h, c.primaryBorder);
        list.textRun(n.x + n.padding + 8, n.y + n.h * 0.5f + n.fontSize * 0.35f,
            n.fontSize, true, n.text, c.onPrimary);
        break;
    case NodeKind.TextField:
        list.fillRect(n.x, n.y, n.w, n.h,
            n.fillBackground ? n.bgColor : c.fieldFill);
        list.strokeRect(n.x, n.y, n.w, n.h, c.border);
        auto shown = n.text.length ? n.text : n.placeholder;
        auto col = n.text.length ? c.textPrimary : c.textMuted;
        if (n.password && n.text.length)
        {
            list.fillRect(n.x + n.padding + 6, n.y + n.h * 0.45f,
                min(n.w - n.padding * 2 - 12, n.text.length * n.fontSize * 0.4f),
                n.fontSize * 0.2f, col);
        }
        else if (n.multiline)
        {
            float ly = n.y + n.padding + n.fontSize;
            size_t start = 0;
            foreach (i, ch; shown)
            {
                if (ch == '\n' || i + 1 == shown.length)
                {
                    const end = (ch == '\n') ? i : i + 1;
                    auto line = shown[start .. end];
                    if (line.length && line[$ - 1] == '\r')
                        line = line[0 .. $ - 1];
                    list.textRun(n.x + n.padding + 6, ly, n.fontSize, n.bold, line, col);
                    ly += n.fontSize * 1.35f;
                    start = i + 1;
                }
            }
            if (!shown.length)
                list.textRun(n.x + n.padding + 6, n.y + n.padding + n.fontSize,
                    n.fontSize, false, n.placeholder, c.textMuted);
        }
        else
        {
            list.textRun(n.x + n.padding + 6, n.y + n.h * 0.5f + n.fontSize * 0.35f,
                n.fontSize, n.bold, shown, col);
        }
        break;
    case NodeKind.CheckBox:
        if (hints.isSwitch(id))
            paintSwitch(list, n, c, m);
        else
            paintCheckBox(list, n, c);
        break;
    }

    for (auto ch = n.firstChild; ch.valid; ch = store[ch].nextSibling)
        paintThemedNode(store, ch, list, tokens, hints);

    if (clip)
        list.clipPop();
}

private void paintCheckBox(ref DisplayList list, ref Node n, const ref ThemeColors c) @safe nothrow
{
    const box = n.fontSize;
    const bx = n.x + n.padding;
    const by = n.y + (n.h - box) * 0.5f;
    list.strokeRect(bx, by, box, box, c.border);
    if (n.checked)
    {
        list.pathBegin();
        list.pathMoveTo(bx + box * 0.2f, by + box * 0.55f);
        list.pathLineTo(bx + box * 0.42f, by + box * 0.75f);
        list.pathLineTo(bx + box * 0.82f, by + box * 0.28f);
        list.pathStroke(2, c.checkStroke);
    }
    list.textRun(n.x + n.padding + box + 8, n.y + n.h * 0.5f + n.fontSize * 0.35f,
        n.fontSize, false, n.text, c.textPrimary);
}

private void paintSwitch(ref DisplayList list, ref Node n, const ref ThemeColors c,
    const ref ThemeMetrics m) @safe nothrow
{
    const trackW = n.fontSize * 1.8f;
    const trackH = n.fontSize * 1.05f;
    const bx = n.x + n.padding;
    const by = n.y + (n.h - trackH) * 0.5f;
    const track = n.checked ? c.switchTrackOn : c.switchTrackOff;
    list.fillRoundedRect(bx, by, trackW, trackH, trackH * 0.5f, track);
    const thumb = trackH * 0.85f;
    const tx = n.checked ? bx + trackW - thumb - (trackH - thumb) * 0.5f
        : bx + (trackH - thumb) * 0.5f;
    const ty = by + (trackH - thumb) * 0.5f;
    list.fillCircle(tx + thumb * 0.5f, ty + thumb * 0.5f, thumb * 0.5f, c.switchThumb);
    if (n.text.length)
        list.textRun(bx + trackW + m.spaceSm, n.y + n.h * 0.5f + n.fontSize * 0.35f,
            n.fontSize, false, n.text, c.textPrimary);
}

private float min(float a, float b) @safe @nogc pure nothrow
{
    return a < b ? a : b;
}
