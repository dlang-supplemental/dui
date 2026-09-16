/// Overlay / menu host API stubs (window host wires these later).
module dui.overlay_stub;

import dew;
import dui.theme;

struct AlertDialogParams
{
    const(char)[] title;
    const(char)[] message;
    const(char)[] defaultButton = "OK";
    const(char)[] cancelButton;
    void delegate() onDefault;
    void delegate() onCancel;
}

struct SheetParams
{
    const(char)[] title;
    Widget content;
    void delegate() onDismiss;
}

struct PopoverParams
{
    float anchorX;
    float anchorY;
    Widget content;
}

struct ContextMenuItem
{
    const(char)[] title;
    bool enabled = true;
    void delegate() action;
}

struct ContextMenuParams
{
    ContextMenuItem[] items;
}

/** Host hook — no UI until a window shell presents modals. */
void presentAlert(AlertDialogParams) @safe @nogc nothrow
{
}

void presentSheet(SheetParams) @safe @nogc nothrow
{
}

void presentPopover(PopoverParams) @safe @nogc nothrow
{
}

void presentContextMenu(ContextMenuParams) @safe @nogc nothrow
{
}
