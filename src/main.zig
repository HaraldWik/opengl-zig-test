const std = @import("std");
const engine = @import("engine");
const nz = @import("numz");
const gl = @import("gl");
const c = @import("engine").c;
const sdlCheck = @import("engine").sdlCheck;

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

    while (!window.shouldClose()) {
        try gfx_context.clear();

        if (window.isKeyDown(.up)) volume += 0.001;
        if (window.isKeyDown(.down)) volume -= 0.001;

        volume = @max(0, volume);
        try asset_manager.getSound("bell.wav").?.play(volume);

        // std.debug.print("{d:.1}%\n", .{volume * 100});

        try gfx_context.present();
    }
}
