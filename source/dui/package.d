/**
 * dui — app-kit on top of dew.
 *
 * Tagline lives on the engine (`dewSlogan`); this package adds state helpers
 * and opinionated app scaffolding. Touch primitives stay in dew.
 */
module dui;

public import dew;
public import dui.app;
public import dui.state;

enum string duiVersion = {
    import std.string : strip;
    return import("VERSION").strip;
}();
