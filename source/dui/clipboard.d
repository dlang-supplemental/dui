/// Platform clipboard helpers (plain text + HTML fragment).
module dui.clipboard;

import std.string : toStringz;
import std.utf : toUTF16z;

version (Windows)
{
    import core.sys.windows.windows;
    import core.sys.windows.winuser;
    import core.sys.windows.winnls;
}

/// Copy UTF-8 plain text to the system clipboard.
bool copyText(string utf8) @trusted
{
    version (Windows)
    {
        if (!OpenClipboard(null))
            return false;
        scope (exit)
            CloseClipboard();
        EmptyClipboard();
        auto w = utf8.toUTF16z;
        size_t n = 0;
        while (w[n] != 0)
            n++;
        auto bytes = (n + 1) * wchar.sizeof;
        auto h = GlobalAlloc(GMEM_MOVEABLE, bytes);
        if (h is null)
            return false;
        auto p = cast(wchar*) GlobalLock(h);
        if (p is null)
        {
            GlobalFree(h);
            return false;
        }
        p[0 .. n + 1] = w[0 .. n + 1];
        GlobalUnlock(h);
        if (SetClipboardData(CF_UNICODETEXT, h) is null)
        {
            GlobalFree(h);
            return false;
        }
        return true;
    }
    else
    {
        // Non-Windows hosts: leave a hook for Wayland/X11 later.
        return false;
    }
}

/**
 * Copy HTML (fragment) plus plain-text fallback.
 * Windows uses the "HTML Format" clipboard descriptor.
 */
bool copyHtml(string htmlFragment, string plainFallback) @trusted
{
    version (Windows)
    {
        if (!copyText(plainFallback))
            return false;
        if (!OpenClipboard(null))
            return false;
        scope (exit)
            CloseClipboard();

        // CF_HTML descriptor — offsets are byte indices into the same buffer.
        auto marker = RegisterClipboardFormatA("HTML Format".toStringz);
        if (marker == 0)
            return true; // plain already set

        auto body = htmlFragment;
        // Build header with placeholders then patch Start*/End* offsets.
        string prefix =
            "Version:0.9\r\n" ~
            "StartHTML:00000000\r\n" ~
            "EndHTML:00000000\r\n" ~
            "StartFragment:00000000\r\n" ~
            "EndFragment:00000000\r\n";
        string fragOpen = "<!--StartFragment-->";
        string fragClose = "<!--EndFragment-->";
        string doc = "<html><body>" ~ fragOpen ~ body ~ fragClose ~ "</body></html>";
        auto full = prefix ~ doc;

        import std.format : format;
        import std.conv : to;

        auto startHtml = prefix.length;
        auto endHtml = full.length;
        auto startFrag = prefix.length + "<html><body>".length + fragOpen.length;
        auto endFrag = startFrag + body.length;

        prefix = format(
            "Version:0.9\r\nStartHTML:%08d\r\nEndHTML:%08d\r\nStartFragment:%08d\r\nEndFragment:%08d\r\n",
            cast(int) startHtml, cast(int) endHtml, cast(int) startFrag, cast(int) endFrag);
        full = prefix ~ doc;

        auto h = GlobalAlloc(GMEM_MOVEABLE, full.length + 1);
        if (h is null)
            return true;
        auto p = cast(char*) GlobalLock(h);
        if (p is null)
        {
            GlobalFree(h);
            return true;
        }
        p[0 .. full.length] = full[];
        p[full.length] = 0;
        GlobalUnlock(h);
        if (SetClipboardData(marker, h) is null)
            GlobalFree(h);
        return true;
    }
    else
        return copyText(plainFallback);
}
