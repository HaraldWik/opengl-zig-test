const std = @import("std");
const engine = @import("engine");
const nz = @import("numz");

transform: nz.Transform(f32) = .{},
sensitivity: f32,
speed: f32,
was_rotating: bool = false,

pub fn update(
    self: *@This(),
    pipeline: engine.gfx.Pipeline,
    window: engine.Window,
    delta_time: f32,
) !void {
    if (window.isKeyDown(.p)) std.debug.print("{any}\n", .{self.transform});
    const pitch = &self.transform.rotation[0];
    const yaw = &self.transform.rotation[1];

    const mouse = engine.c.SDL_GetMouseState(null, null);

    var relative_x: f32 = undefined;
    var relative_y: f32 = undefined;
    _ = engine.c.SDL_GetRelativeMouseState(&relative_x, &relative_y);

    if (mouse == 4) {
        if (!engine.c.SDL_HideCursor()) return error.SdlHideCursor;

        yaw.* += relative_x * self.sensitivity;
        pitch.* += relative_y * self.sensitivity;
        self.was_rotating = true;
    } else if (self.was_rotating) {
        _ = engine.c.SDL_GetRelativeMouseState(null, null);
        self.was_rotating = false;
        if (!engine.c.SDL_ShowCursor()) return error.SdlShowCursor;
    }

    pitch.* = std.math.clamp(pitch.*, -89.9, 89.9);

    const yaw_rad = std.math.degreesToRadians(yaw.*);
    const pitch_rad = std.math.degreesToRadians(pitch.*);

    const forward: nz.Vec3(f32) = nz.vec.normalize(nz.Vec3(f32){
        @cos(pitch_rad) * @sin(yaw_rad),
        -@sin(pitch_rad),
        -@cos(pitch_rad) * @cos(yaw_rad),
    });

    const right: nz.Vec3(f32) = nz.vec.normalize(nz.vec.cross(forward, .{ 0, 1, 0 }));

    const up = nz.vec.normalize(nz.vec.cross(right, forward));

    var move = nz.Vec3(f32){ 0, 0, 0 };
    const velocity = self.speed * delta_time;

    if (window.isKeyDown(.w)) move -= nz.vec.scale(forward, velocity);
    if (window.isKeyDown(.s)) move += nz.vec.scale(forward, velocity);
    if (window.isKeyDown(.a)) move += nz.vec.scale(right, velocity);
    if (window.isKeyDown(.d)) move -= nz.vec.scale(right, velocity);
    if (window.isKeyDown(.space)) move -= nz.vec.scale(up, velocity);
    if (window.isKeyDown(.lctrl)) move += nz.vec.scale(up, velocity);

    // if (keyboard[sdl.SDL_SCANCODE_UP])
    //     camera.speed += 10;
    // if (keyboard[sdl.SDL_SCANCODE_DOWN])
    //     camera.speed -= 10;

    const speed_multiplier: f32 = if (!window.isKeyDown(.lshift)) 1 else 4;

    self.speed = std.math.clamp(self.speed, 0, 1000);

    self.transform.position += nz.vec.scale(move, speed_multiplier);

    if (window.isKeyDown(.r)) {
        yaw.* = 0;
        pitch.* = 0;
        self.transform.position = .{ 0, 0, 0 };
    }

    var view: nz.Mat4x4(f32) = .identity(1);
    view = view.mul(.rotate(std.math.degreesToRadians(pitch.*), .{ 1, 0, 0 }));
    view = view.mul(.rotate(std.math.degreesToRadians(yaw.*), .{ 0, 1, 0 }));
    view = view.mul(.translate(self.transform.position));

    const projection: nz.Mat4x4(f32) = .perspective(std.math.degreesToRadians(45.0), try window.getAspect(), 1, 500.0);

    try pipeline.setUniform("u_projection", .{ .mat4x4 = projection.d });
    try pipeline.setUniform("u_view", .{ .mat4x4 = view.d });
}
