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

    const cube = asset_manager.getModel("cube.obj");

    const terrain: @import("Terrain.zig") = try .init(allocator, .{ 500, 500 });
    defer terrain.deinit(allocator);
    const terrain_model = try terrain.toModel(allocator);

    var time: f32 = 0;
    while (!window.shouldClose()) {
        const delta_time = window.getDeltaTime();
        time += delta_time;
        try gfx_context.clear();

        // std.debug.print("FPS: {d:.2}\n", .{1 / delta_time});

        pipeline.bind();
        try free_camera.update(pipeline, window, delta_time);

        for (0..100) |i| {
            const f: f32 = @floatFromInt(i);
            var transform: nz.Transform(f32) = .{ .position = .{ std.math.round(@mod(f, 10) * 3), @sin(time + f), std.math.round(f / 10 * 3) } };

            transform.rotation = @splat(@mod(transform.rotation[1] + 30 * window.getDeltaTime(), 360));
            asset_manager.getTexture("error_wall.jpg").bind(0);
            try pipeline.setUniform("u_model", .{ .mat4x4 = transform.toMat4x4().d });
            cube.draw();
        }

        asset_manager.getTexture("grass.jpg").bind(0);
        try pipeline.setUniform("u_model", .{ .mat4x4 = nz.Transform(f32).toMat4x4(.{}).d });
        terrain_model.draw();

        try gfx_context.present();

        if (window.isKeyDown(.up)) volume += 0.01;
        if (window.isKeyDown(.down)) volume -= 0.01;

        if (window.isKeyDown(.o)) {
            volume = @max(0, volume);
            try asset_manager.getSound("bell.wav").play(volume);
        }

        // std.debug.print("{d:.1}%\n", .{volume * 100});
    }
}
