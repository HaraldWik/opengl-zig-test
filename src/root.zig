pub const AssetManager = @import("AssetManager.zig");
pub const App = @import("App.zig");
pub const Obj = @import("Obj.zig");
pub const Key = @import("App.zig").Key;

pub const audio = @import("audio.zig");
pub const gfx = @import("gfx.zig");
pub const ui = @import("ui.zig");

pub const sdl = @import("sdl");
pub const gl = @import("gl");

pub fn sdlCheck(result: anytype) !void {
    if (!switch (@typeInfo(@TypeOf(result))) {
        .bool => !result,
        .optional => result == null,
        else => @compileError("unsupported type for sdl check"),
    }) return;

    @import("std").log.err("sdl: {s}\n", .{sdl.SDL_GetError()});
    return error.Sdl;
}
