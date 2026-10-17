/// Minimal token-aware paint (default dew chrome with `ThemeTokens` colors).
module dui.theme_paint;

import dew;
import dui.theme;

/// Reserved for future per-node paint hints; cleared each rebuild.
struct ThemePaintHints
{
    void clear() @safe nothrow
    {
    }
}

void paintThemedTree(ref NodeStore store, NodeId root, ref DisplayList list,
    const ref ThemeTokens tokens, const ref ThemePaintHints) @safe
{
    if (!root.valid)
        return;
    paintThemedNode(store, root, list, tokens);
}

private void paintThemedNode(ref NodeStore store, NodeId id, ref DisplayList list,
    const ref ThemeTokens tokens) @safe
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
            list.fillRoundedRect(n.x, n.y, n.w, n.h, m.radiusControl, n.bgColor);
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
        list.textRun(n.x + n.padding, n.y + n.padding + n.fontSize,
            n.fontSize, n.bold, n.text, c.label);
        break;
    case NodeKind.Button:
        list.fillRoundedRect(n.x, n.y, n.w, n.h, m.radiusControl, c.accent);
        list.strokeRect(n.x, n.y, n.w, n.h, c.accentPressed);
        list.textRun(n.x + n.padding + 8, n.y + n.h * 0.5f + n.fontSize * 0.35f,
            n.fontSize, true, n.text, c.onAccent);
        break;
    case NodeKind.TextField:
        list.fillRoundedRect(n.x, n.y, n.w, n.h, m.radiusControl,
            n.fillBackground ? n.bgColor : c.textFieldBackground);
        list.strokeRect(n.x, n.y, n.w, n.h, c.controlBorder);
        auto shown = n.text.length ? n.text : n.placeholder;
        auto col = n.text.length ? c.label : c.quaternaryLabel;
        list.textRun(n.x + n.padding + 6, n.y + n.h * 0.5f + n.fontSize * 0.35f,
            n.fontSize, n.bold, shown, col);
        break;
    case NodeKind.CheckBox:
        paintCheckBox(list, n, c);
        break;
    }

    for (auto ch = n.firstChild; ch.valid; ch = store[ch].nextSibling)
        paintThemedNode(store, ch, list, tokens);

    if (clip)
        list.clipPop();
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
