const std = @import("std");
const engine = @import("engine");
const nz = @import("numz");
const gl = @import("gl");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    const window: *engine.Window = try .init("Super windows world", 900, 900);
    defer window.deinit();
    const audio_device: engine.audio.Device = try .init();
    defer audio_device.deinit();

    const gfx_context: engine.gfx.Context = try .init(window.toC());
    defer gfx_context.deinit();

    const asset_manager: engine.AssetManager = try .init(allocator, audio_device);
    defer asset_manager.deinit();

    var volume: f32 = 0.5;

    const pipeline: engine.gfx.Pipeline = try .init(@embedFile("shaders/def.vert"), @embedFile("shaders/def.frag"), null);
    defer pipeline.deinit();

    var vertices = [_]f32{
        // Position (x,y,z)       // Color (r,g,b)
        0.0, 0.5, 0.0, 1.0, 0.0, 0.0, // Top (Red)
        -0.5, -0.5, 0.0, 0.0, 1.0, 0.0, // Left (Green)
        0.5, -0.5, 0.0, 0.0, 0.0, 1.0, // Right (Blue)
    };
    var indices = [_]u32{ 0, 1, 2 };

    const mesh: engine.gfx.Mesh = try .init(&.{
        .{ .type = .f32, .count = 3 },
        .{ .type = .f32, .count = 3 },
    }, &vertices, &indices);

    while (!window.shouldClose()) {
        if (window.isKeyDown(.up)) volume += 0.001;
        if (window.isKeyDown(.down)) volume -= 0.001;

        volume = @max(0, volume);
        try asset_manager.getSound("bell.wav").?.play(volume);

        // std.debug.print("{d:.1}%\n", .{volume * 100});

        pipeline.bind();

        try gfx_context.clear();

        mesh.draw();

        try gfx_context.present();
    }
}
