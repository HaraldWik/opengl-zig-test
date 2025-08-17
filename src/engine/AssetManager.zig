const std = @import("std");
const audio = @import("audio.zig");
const gfx = @import("gfx.zig");
const img = @cImport(@cInclude("SDL3_image/SDL_image.h")); // TODO: remove C import, for more information read 'build.zig'

sounds: std.AutoArrayHashMapUnmanaged(u64, audio.Sound),
textures: std.AutoArrayHashMapUnmanaged(u64, gfx.Texture),

pub fn init(allocator: std.mem.Allocator, audio_device: audio.Device) !@This() {
    // Sounds
    const sound_files = try findAssetsFromDir(allocator, "assets/sounds", ".wav");
    defer allocator.free(sound_files);
    var sounds: std.AutoArrayHashMapUnmanaged(u64, audio.Sound) = .empty;

    for (sound_files) |file| {
        const path = try std.fs.path.join(allocator, &.{ "assets/sounds", file });
        const hash: u64 = std.hash.Wyhash.hash(0, file);

        try sounds.put(allocator, hash, try .init(audio_device, @ptrCast(path)));
    }

    // Textures
    const texture_files = try findAssetsFromDir(allocator, "assets/textures", ".jpg");
    defer allocator.free(texture_files);
    var textures: std.AutoArrayHashMapUnmanaged(u64, gfx.Texture) = .empty;

    for (texture_files) |file| {
        const path = try std.fs.path.join(allocator, &.{ "assets/textures", file });
        const hash: u64 = std.hash.Wyhash.hash(2, file);

        const surface = img.IMG_Load(@ptrCast(path)) orelse return error.LoadImage; // TODO: Change out image loading liberary
        const texture: gfx.Texture = try .init(@ptrCast(surface.*.pixels.?), @intCast(surface.*.w), @intCast(surface.*.h));

        try textures.put(allocator, hash, texture);
    }

    return .{ .sounds = sounds, .textures = textures };
}

pub fn deinit(self: @This()) void {
    var sound_it = self.sounds.iterator();
    while (sound_it.next()) |entry| entry.value_ptr.deinit();

    var texture_it = self.textures.iterator();
    while (texture_it.next()) |entry| entry.value_ptr.deinit();
}

pub fn getSound(self: @This(), key: []const u8) ?audio.Sound {
    const hash: u64 = std.hash.Wyhash.hash(0, key);
    return self.sounds.get(hash);
}

pub fn getTexture(self: @This(), key: []const u8) ?gfx.Texture {
    const hash: u64 = std.hash.Wyhash.hash(2, key);
    return self.textures.get(hash);
}

fn findAssetsFromDir(allocator: std.mem.Allocator, dir_path: []const u8, extension: []const u8) ![][]const u8 {
    var dir = try std.fs.cwd().openDir(dir_path, .{ .iterate = true });
    defer dir.close();

    var assets: std.ArrayListUnmanaged([]const u8) = .empty;

    var it = dir.iterate();

    while (try it.next()) |entry| {
        if (entry.kind == .file and std.mem.eql(u8, std.fs.path.extension(entry.name), extension)) {
            const name = try allocator.dupe(u8, entry.name);
            errdefer allocator.free(name);
            try assets.append(allocator, name);
        }
    }
    const slice = try assets.toOwnedSlice(allocator);
    assets.items = &.{}; // to prevent double-free probably idk i am writing this blindly i have no idea what i am doing
    return slice;
}
