/// App-level state helpers wrapping dew.Signal.
module dui.state;

import dew;

/// Mutable cell that marks a `DuiApp` dirty on change (when hooked).
struct State(T)
{
    private Signal!T _sig;
    private void delegate() @safe _onDirty;

    this(T initial) @safe
    {
        _sig = Signal!T(initial);
    }

    @property T value() const @safe @nogc pure nothrow
    {
        return _sig.value;
    }

    @property void value(T v) @safe
    {
        _sig.value = v;
        if (_onDirty !is null)
            _onDirty();
    }

    void opAssign(T v) @safe
    {
        value = v;
    }

    void bindRebuild(void delegate() @safe dg) @safe
    {
        _onDirty = dg;
        _sig.subscribe(dg);
    }
}

unittest
{
    int hits;
    State!int s = State!int(0);
    s.bindRebuild(() { hits++; });
    s = 1;
    assert(s.value == 1);
    assert(hits >= 1);
}
