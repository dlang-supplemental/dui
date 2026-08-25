/// Mutable cell that marks a `DuiApp` dirty on change (when hooked).
module dui.state;

import dew;

/// App-level state helpers wrapping dew.Signal.
struct State(T)
{
    private Signal!T _sig;

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
        // Signal notifies subscribers (including bindRebuild).
        _sig.value = v;
    }

    void opAssign(T v) @safe
    {
        value = v;
    }

    /// Apply `dg` to the current value and store the result (marks dirty when changed).
    void update(scope T delegate(T) @safe dg) @safe
    {
        value = dg(value);
    }

    /// Wire dirty → rebuild. Safe to call once per `State` instance.
    void bindRebuild(void delegate() @safe dg) @safe
    {
        _sig.subscribe(dg);
    }

    /// True if this cell was marked dirty since the last take (via Signal).
    bool takeDirty() @safe @nogc nothrow
    {
        return _sig.takeDirty();
    }
}

unittest
{
    int hits;
    State!int s = State!int(0);
    s.bindRebuild(() { hits++; });
    s = 1;
    assert(s.value == 1);
    assert(hits == 1);
    s = 1; // no-op when unchanged
    assert(hits == 1);
    s.update(v => v + 2);
    assert(s.value == 3);
    assert(hits == 2);
}
