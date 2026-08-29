/// Snapshot undo/redo stack for document-sized values.
module dui.undo;

/**
 * Push full snapshots before mutating actions (mode switches, bulk edits).
 * `T` should be a value type or deep-copied by the caller before `push`.
 */
struct UndoStack(T)
{
    T[] undo;
    T[] redo;
    size_t limit = 64;

    void clear() @safe nothrow
    {
        undo.length = 0;
        redo.length = 0;
    }

    void push(T snapshot) @safe nothrow
    {
        undo ~= snapshot;
        if (undo.length > limit)
            undo = undo[$ - limit .. $];
        redo.length = 0;
    }

    bool canUndo() const @safe @nogc pure nothrow
    {
        return undo.length > 0;
    }

    bool canRedo() const @safe @nogc pure nothrow
    {
        return redo.length > 0;
    }

    /// Apply undo: current becomes redo; returns previous snapshot.
    bool popUndo(ref T current) @safe nothrow
    {
        if (!undo.length)
            return false;
        redo ~= current;
        current = undo[$ - 1];
        undo = undo[0 .. $ - 1];
        return true;
    }

    bool popRedo(ref T current) @safe nothrow
    {
        if (!redo.length)
            return false;
        undo ~= current;
        current = redo[$ - 1];
        redo = redo[0 .. $ - 1];
        return true;
    }
}

unittest
{
    UndoStack!int s;
    int cur = 1;
    s.push(cur);
    cur = 2;
    s.push(cur);
    cur = 3;
    assert(s.popUndo(cur));
    assert(cur == 2);
    assert(s.popUndo(cur));
    assert(cur == 1);
    assert(s.popRedo(cur));
    assert(cur == 2);
}
