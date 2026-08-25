/// Gesture helpers layered on dew pointer capture / drag.
module dui.gesture;

import dew;
import dui.app;
import dui.state;
import std.math : abs, sqrt;

enum GestureKind : ubyte
{
    None,
    Tap,
    Drag,
    Swipe,
}

struct GestureEvent
{
    GestureKind kind;
    float x, y;
    float dx, dy;
    float startX, startY;
    uint id;
    bool ended;
}

alias GestureHandler = void delegate(GestureEvent ev) @safe;

enum float defaultSwipeMinDistance = 48;

/**
 * Attach a drag/swipe recognizer to a widget. Requires dew Drag capture
 * (`draggable`). Fires `Drag` on Move past slop and `Swipe` on Up when the
 * travel exceeds `swipeMin`.
 */
Widget onGesture(Widget w, GestureHandler handler, float swipeMin = defaultSwipeMinDistance) @safe
{
    float startX, startY;
    bool tracking;
    bool dragged;

    w.draggable().onPointer((PointerEvent ev) {
        final switch (ev.phase)
        {
        case PointerPhase.Down:
            startX = ev.x;
            startY = ev.y;
            tracking = true;
            dragged = false;
            break;
        case PointerPhase.Move:
            if (!tracking)
                return;
            const dx = ev.x - startX;
            const dy = ev.y - startY;
            if (!dragged && sqrt(dx * dx + dy * dy) >= defaultTouchSlop)
                dragged = true;
            if (dragged)
            {
                GestureEvent g;
                g.kind = GestureKind.Drag;
                g.x = ev.x;
                g.y = ev.y;
                g.dx = dx;
                g.dy = dy;
                g.startX = startX;
                g.startY = startY;
                g.id = ev.id;
                handler(g);
            }
            break;
        case PointerPhase.Up:
        case PointerPhase.Cancel:
            if (!tracking)
                return;
            tracking = false;
            const dx = ev.x - startX;
            const dy = ev.y - startY;
            const dist = sqrt(dx * dx + dy * dy);
            GestureEvent g;
            g.x = ev.x;
            g.y = ev.y;
            g.dx = dx;
            g.dy = dy;
            g.startX = startX;
            g.startY = startY;
            g.id = ev.id;
            g.ended = true;
            if (dragged && dist >= swipeMin)
                g.kind = GestureKind.Swipe;
            else if (!dragged)
                g.kind = GestureKind.Tap;
            else
                g.kind = GestureKind.Drag;
            handler(g);
            break;
        }
    });
    return w;
}

/// Convenience: scroll a `ScrollView` node id via vertical drag.
Widget scrollable(Widget scrollView, ref float scrollY, float contentSlack = 400) @safe
{
    return onGesture(scrollView, (GestureEvent g) {
        if (g.kind == GestureKind.Drag || (g.kind == GestureKind.Swipe && g.ended))
        {
            scrollY -= g.dy;
            if (scrollY < 0)
                scrollY = 0;
            if (scrollY > contentSlack)
                scrollY = contentSlack;
        }
    });
}

unittest
{
    DuiApp app;
    int swipes;
    int drags;
    app.init((ref UiBuilder ui) {
        return onGesture(
            Container().width(200).height(120).draggable(),
            (GestureEvent g) {
                if (g.kind == GestureKind.Drag && !g.ended)
                    drags++;
                if (g.kind == GestureKind.Swipe && g.ended)
                    swipes++;
            });
    }, new SoftwareBackend(200, 120));
    app.dew.resize(200, 120);
    app.frame();

    assert(app.pointerAndFrame(touchDown(50, 50)));
    assert(app.pointerAndFrame(touchMove(50, 50 + 80)));
    assert(drags >= 1);
    assert(app.pointerAndFrame(touchUp(50, 50 + 80)));
    assert(swipes == 1);
}
