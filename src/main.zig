const std = @import("std");
const engine = @import("engine");
const nz = @import("numz");
const gl = @import("gl");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    const window: engine.Window = try .init("super-windows-world", 900, 900);
    defer window.deinit();

    const audio_device: engine.audio.Device = try .init();
    defer audio_device.deinit();

    const gfx_context: engine.gfx.Context = try .init(window.handle);
    defer gfx_context.deinit();

    const asset_manager: engine.AssetManager = try .init(allocator, audio_device);
    defer asset_manager.deinit();

    var volume: f32 = 0.5;

    const pipeline: engine.gfx.Pipeline = try .init(@embedFile("shaders/def.vert"), @embedFile("shaders/def.frag"), null);
    defer pipeline.deinit();

    var free_camera: @import("FreeCamera.zig") = .{ .sensitivity = 0.15, .speed = 120, .transform = .{ .position = .{ 0.0, 0.0, -5.0 } } };

    const obj: engine.Obj = try .init(allocator, "assets/models/cube.obj");
    defer obj.deinit(allocator);

    const mesh: engine.gfx.Mesh = try .init(&.{
        .{ .type = .f32, .count = 3 },
        .{ .type = .f32, .count = 2 },
        .{ .type = .f32, .count = 3 },
    }, obj.vertices, obj.indices);

    var transform: nz.Transform(f32) = .{ .scale = @splat(0.1) };

    while (!window.shouldClose()) {
        engine.c.SDL_Delay(16);
        transform.rotation[1] = @mod(transform.rotation[1] + 30 * window.getDeltaTime(), 360);
        try gfx_context.clear();

        pipeline.bind();
        try pipeline.setUniform("u_model", .{ .mat4x4 = transform.toMat4x4().d });
        try free_camera.update(window, pipeline);
        mesh.draw();

        try gfx_context.present();

        if (window.isKeyDown(.up)) volume += 0.01;
        if (window.isKeyDown(.down)) volume -= 0.01;

        // volume = @max(0, volume);
        // try asset_manager.getSound("bell.wav").?.play(volume);

        // std.debug.print("{d:.1}%\n", .{volume * 100});
    }
}
