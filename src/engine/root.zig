pub const c = @import("c");
pub const AssetManager = @import("AssetManager.zig");
pub const audio = @import("audio.zig");
pub const gfx = @import("gfx.zig");
pub const Obj = @import("Obj.zig");
pub const Window = @import("window.zig").Window;
pub const Key = @import("window.zig").Key;

const nz = @import("numz");

pub const Transform = struct {
    position: nz.Vec3(f32) = @splat(0),
    rotation: nz.Vec3(f32) = @splat(0),
    scale: nz.Vec3(f32) = @splat(1),

    pub fn toMat4x4(self: @This()) nz.Mat4x4(f32) {
        const std = @import("std");
        return nz.Mat4x4(f32).identity(1)
            .mul(.translate(self.position))
            .mul(.rotate(std.math.degreesToRadians(self.rotation[0]), .{ 1, 0, 0 }))
            .mul(.rotate(std.math.degreesToRadians(self.rotation[1]), .{ 0, 1, 0 }))
            .mul(.rotate(std.math.degreesToRadians(self.rotation[2]), .{ 0, 0, 2 }))
            .mul(.scale(self.scale));
    }
};

pub fn sdlCheck(result: anytype) !void {
    if (!switch (@typeInfo(@TypeOf(result))) {
        .bool => !result,
        .optional => result == null,
        else => @compileError("unsupported type for sdl check"),
    }) return;

    @import("std").log.err("sdl: {s}\n", .{c.SDL_GetError()});
    return error.Sdl;
}
