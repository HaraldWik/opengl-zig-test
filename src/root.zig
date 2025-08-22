pub const c = @import("c");
pub const AssetManager = @import("AssetManager.zig");
pub const audio = @import("audio.zig");
pub const gfx = @import("gfx.zig");
pub const Obj = @import("Obj.zig");
pub const Window = @import("window.zig");
pub const Key = @import("window.zig").Key;

const nz = @import("numz");

pub fn sdlCheck(result: anytype) !void {
    if (!switch (@typeInfo(@TypeOf(result))) {
        .bool => !result,
        .optional => result == null,
        else => @compileError("unsupported type for sdl check"),
    }) return;

    @import("std").log.err("sdl: {s}\n", .{c.SDL_GetError()});
    return error.Sdl;
}
