/// Token-aware paint pass with macOS-style control chrome.
module dui.theme_paint;

import dew;
import dui.theme;

enum CheckKind : ubyte
{
    checkbox,
    radio,
    toggle,
}

struct ThemePaintHints
{
    private ubyte[] _labelStyle;
    private ubyte[] _buttonVariant;
    private ubyte[] _checkKind;
    private bool[] _segmentSelected;
    private bool[] _searchField;
    private bool[] _listRowSelected;
    private bool[] _disclosureOpen;
    private bool[] _sliderTrack;

    void clear() @safe nothrow
    {
        _labelStyle = null;
        _buttonVariant = null;
        _checkKind = null;
        _segmentSelected = null;
        _searchField = null;
        _listRowSelected = null;
        _disclosureOpen = null;
        _sliderTrack = null;
    }

    void setLabelStyle(NodeId id, LabelStyle s) @safe nothrow
    {
        grow(_labelStyle, id);
        _labelStyle[id.index] = cast(ubyte) s;
    }

    void setButtonVariant(NodeId id, ButtonVariant v) @safe nothrow
    {
        grow(_buttonVariant, id);
        _buttonVariant[id.index] = cast(ubyte) v;
    }

    void setCheckKind(NodeId id, CheckKind k) @safe nothrow
    {
        grow(_checkKind, id);
        _checkKind[id.index] = cast(ubyte) k;
    }

    void markSegmentSelected(NodeId id, bool selected) @safe nothrow
    {
        grow(_segmentSelected, id);
        _segmentSelected[id.index] = selected;
    }

    void markSearchField(NodeId id) @safe nothrow
    {
        grow(_searchField, id);
        _searchField[id.index] = true;
    }

    void markListRowSelected(NodeId id, bool selected) @safe nothrow
    {
        grow(_listRowSelected, id);
        _listRowSelected[id.index] = selected;
    }

    void markDisclosureOpen(NodeId id, bool open) @safe nothrow
    {
        grow(_disclosureOpen, id);
        _disclosureOpen[id.index] = open;
    }

    void markSliderTrack(NodeId id) @safe nothrow
    {
        grow(_sliderTrack, id);
        _sliderTrack[id.index] = true;
    }

    LabelStyle labelStyle(NodeId id) const @safe @nogc nothrow
    {
        if (!id.valid || id.index >= _labelStyle.length)
            return LabelStyle.body;
        return cast(LabelStyle) _labelStyle[id.index];
    }

    ButtonVariant buttonVariant(NodeId id) const @safe @nogc nothrow
    {
        if (!id.valid || id.index >= _buttonVariant.length)
            return ButtonVariant.accent;
        return cast(ButtonVariant) _buttonVariant[id.index];
    }

    CheckKind checkKind(NodeId id) const @safe @nogc nothrow
    {
        if (!id.valid || id.index >= _checkKind.length)
            return CheckKind.checkbox;
        return cast(CheckKind) _checkKind[id.index];
    }

    bool segmentSelected(NodeId id) const @safe @nogc nothrow
    {
        return id.valid && id.index < _segmentSelected.length && _segmentSelected[id.index];
    }

    bool isSearchField(NodeId id) const @safe @nogc nothrow
    {
        return id.valid && id.index < _searchField.length && _searchField[id.index];
    }

    bool listRowSelected(NodeId id) const @safe @nogc nothrow
    {
        return id.valid && id.index < _listRowSelected.length && _listRowSelected[id.index];
    }

    bool disclosureOpen(NodeId id) const @safe @nogc nothrow
    {
        return id.valid && id.index < _disclosureOpen.length && _disclosureOpen[id.index];
    }

    bool isSliderTrack(NodeId id) const @safe @nogc nothrow
    {
        return id.valid && id.index < _sliderTrack.length && _sliderTrack[id.index];
    }

    private static void grow(T)(ref T[] arr, NodeId id) @safe nothrow
    {
        if (!id.valid)
            return;
        const idx = id.index;
        if (arr.length <= idx)
            arr.length = idx + 1;
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
        {
            const r = hints.isSliderTrack(id) ? 2f : m.radiusControl;
            list.fillRoundedRect(n.x, n.y, n.w, n.h, r, n.bgColor);
        }
        break;
    case NodeKind.Canvas:
        list.fillRect(n.x, n.y, n.w, n.h,
            n.fillBackground ? n.bgColor : c.controlBackground);
        list.strokeRect(n.x, n.y, n.w, n.h, c.controlBorder);
        break;
    case NodeKind.MeshView:
        if (n.meshPixels.length && n.meshSrcW && n.meshSrcH)
            list.imageBlit(n.x, n.y, n.w, n.h, n.meshSrcW, n.meshSrcH, n.meshPixels);
        else
            list.fillRect(n.x, n.y, n.w, n.h, c.groupedBackground);
        break;
    case NodeKind.Text:
        paintLabel(list, n, tokens, hints.labelStyle(id));
        break;
    case NodeKind.Button:
        paintButton(list, n, c, m, hints, id);
        break;
    case NodeKind.TextField:
        paintTextField(list, n, c, m, hints, id);
        break;
    case NodeKind.CheckBox:
        final switch (hints.checkKind(id))
        {
        case CheckKind.toggle:
            paintToggle(list, n, c, m);
            break;
        case CheckKind.radio:
            paintRadio(list, n, c);
            break;
        case CheckKind.checkbox:
            paintCheckBox(list, n, c);
            break;
        }
        break;
    }

    for (auto ch = n.firstChild; ch.valid; ch = store[ch].nextSibling)
        paintThemedNode(store, ch, list, tokens, hints);

    if (clip)
        list.clipPop();
}

private void paintLabel(ref DisplayList list, ref Node n, const ref ThemeTokens tokens,
    LabelStyle style) @safe nothrow
{
    const m = tokens.metrics;
    const c = tokens.colors;
    float size = m.fontBody;
    bool bold = n.bold;
    ColorRgba col = c.label;
    final switch (style)
    {
    case LabelStyle.largeTitle:
        size = m.fontLargeTitle;
        bold = true;
        break;
    case LabelStyle.title1:
        size = m.fontTitle1;
        bold = true;
        break;
    case LabelStyle.title2:
        size = m.fontTitle2;
        bold = true;
        break;
    case LabelStyle.title3:
        size = m.fontTitle3;
        bold = true;
        break;
    case LabelStyle.headline:
        size = m.fontHeadline;
        bold = true;
        break;
    case LabelStyle.body:
        size = m.fontBody;
        break;
    case LabelStyle.secondary:
        size = m.fontSubheadline;
        col = c.secondaryLabel;
        break;
    case LabelStyle.tertiary:
        size = m.fontFootnote;
        col = c.tertiaryLabel;
        break;
    case LabelStyle.caption:
        size = m.fontCaption;
        col = c.quaternaryLabel;
        break;
    }
    if (n.fontSize > 0 && n.fontSize != 14)
        size = n.fontSize;
    list.textRun(n.x + n.padding, n.y + n.padding + size * 0.85f,
        size, bold, n.text, col);
}

private void paintButton(ref DisplayList list, ref Node n, const ref ThemeColors c,
    const ref ThemeMetrics m, const ref ThemePaintHints hints, NodeId id) @safe nothrow
{
    const v = hints.buttonVariant(id);
    ColorRgba fill;
    ColorRgba border = c.controlBorder;
    ColorRgba text = c.label;
    bool drawBorder = true;
    bool fillBg = true;
    final switch (v)
    {
    case ButtonVariant.accent:
        fill = c.accent;
        text = c.onAccent;
        border = c.accentPressed;
        break;
    case ButtonVariant.destructive:
        fill = c.destructive;
        text = c.onDestructive;
        border = c.destructive;
        break;
    case ButtonVariant.secondary:
    case ButtonVariant.bordered:
        fill = c.controlBackground;
        text = c.label;
        break;
    case ButtonVariant.plain:
        fillBg = false;
        drawBorder = false;
        text = c.accent;
        break;
    case ButtonVariant.segmented:
        fillBg = hints.segmentSelected(id);
        fill = c.controlBackground;
        text = c.label;
        drawBorder = false;
        break;
    }
    if (fillBg)
        list.fillRoundedRect(n.x, n.y, n.w, n.h, m.radiusControl, fill);
    if (drawBorder && v != ButtonVariant.plain)
        list.strokeRect(n.x, n.y, n.w, n.h, border);
    if (v == ButtonVariant.segmented && hints.segmentSelected(id))
        list.strokeRect(n.x, n.y, n.w, n.h, c.controlBorder);
    const bold = v == ButtonVariant.accent || v == ButtonVariant.destructive;
    list.textRun(n.x + n.padding + 4, n.y + n.h * 0.5f + n.fontSize * 0.35f,
        n.fontSize, bold, n.text, text);
}

private void paintTextField(ref DisplayList list, ref Node n, const ref ThemeColors c,
    const ref ThemeMetrics m, const ref ThemePaintHints hints, NodeId id) @safe nothrow
{
    const bg = hints.isSearchField(id) ? c.searchFieldBackground : c.textFieldBackground;
    list.fillRoundedRect(n.x, n.y, n.w, n.h, m.radiusControl,
        n.fillBackground ? n.bgColor : bg);
    list.strokeRect(n.x, n.y, n.w, n.h, c.controlBorder);
    auto shown = n.text.length ? n.text : n.placeholder;
    auto col = n.text.length ? c.label : c.quaternaryLabel;
    if (hints.isSearchField(id) && !n.text.length)
        shown = n.placeholder.length ? n.placeholder : "Search";
    list.textRun(n.x + n.padding + 6, n.y + n.h * 0.5f + n.fontSize * 0.35f,
        n.fontSize, false, shown, col);
}

private void paintCheckBox(ref DisplayList list, ref Node n, const ref ThemeColors c) @safe nothrow
{
    const box = n.fontSize;
    const bx = n.x + n.padding;
    const by = n.y + (n.h - box) * 0.5f;
    list.strokeRect(bx, by, box, box, c.checkboxStroke);
    if (n.checked)
    {
        list.fillRect(bx + 2, by + 2, box - 4, box - 4, c.checkboxFill);
        list.pathBegin();
        list.pathMoveTo(bx + box * 0.22f, by + box * 0.55f);
        list.pathLineTo(bx + box * 0.42f, by + box * 0.75f);
        list.pathLineTo(bx + box * 0.8f, by + box * 0.28f);
        list.pathStroke(2, c.onAccent);
    }
    list.textRun(n.x + n.padding + box + 6, n.y + n.h * 0.5f + n.fontSize * 0.35f,
        n.fontSize, false, n.text, c.label);
}

private void paintRadio(ref DisplayList list, ref Node n, const ref ThemeColors c) @safe nothrow
{
    const d = n.fontSize;
    const cx = n.x + n.padding + d * 0.5f;
    const cy = n.y + n.h * 0.5f;
    list.strokeRect(cx - d * 0.5f, cy - d * 0.5f, d, d, c.checkboxStroke);
    if (n.checked)
        list.fillCircle(cx, cy, d * 0.28f, c.accent);
    list.textRun(n.x + n.padding + d + 6, n.y + n.h * 0.5f + n.fontSize * 0.35f,
        n.fontSize, false, n.text, c.label);
}

private void paintToggle(ref DisplayList list, ref Node n, const ref ThemeColors c,
    const ref ThemeMetrics m) @safe nothrow
{
    const trackW = n.fontSize * 1.75f;
    const trackH = n.fontSize;
    const bx = n.x + n.padding;
    const by = n.y + (n.h - trackH) * 0.5f;
    const track = n.checked ? c.switchTrackOn : c.switchTrackOff;
    list.fillRoundedRect(bx, by, trackW, trackH, trackH * 0.5f, track);
    const thumb = trackH * 0.88f;
    const tx = n.checked ? bx + trackW - thumb - 2
        : bx + 2;
    const ty = by + (trackH - thumb) * 0.5f;
    list.fillCircle(tx + thumb * 0.5f, ty + thumb * 0.5f, thumb * 0.5f, c.switchThumb);
    if (n.text.length)
        list.textRun(bx + trackW + m.insetStandard, n.y + n.h * 0.5f + n.fontSize * 0.35f,
            n.fontSize, false, n.text, c.label);
}
