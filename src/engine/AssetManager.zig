const std = @import("std");
const audio = @import("audio.zig");
const gfx = @import("gfx.zig");
const img = @cImport(@cInclude("SDL3_image/SDL_image.h")); // TODO: remove C import, for more information read 'build.zig'
const Obj = @import("Obj.zig");

textures: std.AutoArrayHashMapUnmanaged(u64, gfx.Texture),
models: std.AutoArrayHashMapUnmanaged(u64, gfx.Model),
sounds: std.AutoArrayHashMapUnmanaged(u64, audio.Sound),

pub fn init(allocator: std.mem.Allocator, audio_device: audio.Device) !@This() {
    return .{
        .textures = try loadAssets(gfx.Texture, *anyopaque, allocator, "assets/textures", ".jpg", loadTexture, null),
        .models = try loadAssets(gfx.Model, *anyopaque, allocator, "assets/models", ".obj", loadModel, null),
        .sounds = try loadAssets(audio.Sound, audio.Device, allocator, "assets/sounds", ".wav", loadSound, audio_device),
    };
}

pub fn deinit(self: @This()) void {
    var texture_it = self.textures.iterator();
    while (texture_it.next()) |entry| entry.value_ptr.deinit();

    var model_it = self.textures.iterator();
    while (model_it.next()) |entry| entry.value_ptr.deinit();

    var sound_it = self.sounds.iterator();
    while (sound_it.next()) |entry| entry.value_ptr.deinit();
}

pub fn loadTexture(_: std.mem.Allocator, _: ?*anyopaque, file_path: []const u8) !gfx.Texture {
    const surface = img.IMG_Load(@ptrCast(file_path)) orelse return error.LoadImage; // TODO: Change out image loading liberary
    const texture: gfx.Texture = try .init(@ptrCast(surface.*.pixels.?), @intCast(surface.*.w), @intCast(surface.*.h));

    return texture;
}

pub fn loadModel(allocator: std.mem.Allocator, _: ?*anyopaque, file_path: []const u8) !gfx.Model {
    const obj: Obj = try .init(allocator, file_path);
    defer obj.deinit(allocator);

    const model: gfx.Model = try .init(&.{
        .{ .type = .f32, .count = 3 },
        .{ .type = .f32, .count = 2 },
        .{ .type = .f32, .count = 3 },
    }, obj.vertices, obj.indices);

    return model;
}

pub fn loadSound(allocator: std.mem.Allocator, audio_device: ?audio.Device, file_path: []const u8) !audio.Sound {
    const sound: audio.Sound = try .init(allocator, audio_device.?, @ptrCast(file_path));
    return sound;
}

pub fn getTexture(self: @This(), key: []const u8) ?gfx.Texture {
    const hash: u64 = std.hash.Wyhash.hash(0, key);
    return self.textures.get(hash);
}

pub fn getModel(self: @This(), key: []const u8) ?gfx.Model {
    const hash: u64 = std.hash.Wyhash.hash(0, key);
    return self.models.get(hash);
}

pub fn getSound(self: @This(), key: []const u8) ?audio.Sound {
    const hash: u64 = std.hash.Wyhash.hash(0, key);
    return self.sounds.get(hash);
}

fn loadAssets(
    comptime Asset: type,
    comptime UserData: type,
    allocator: std.mem.Allocator,
    dir_path: []const u8,
    extension: []const u8,
    func: *const fn (std.mem.Allocator, ?UserData, []const u8) anyerror!Asset,
    user_data: ?UserData,
) !std.AutoArrayHashMapUnmanaged(u64, Asset) {
    var hash_map: std.AutoArrayHashMapUnmanaged(u64, Asset) = .empty;

    const files = try findAssetsFromDir(allocator, dir_path, extension);
    for (files) |file| {
        const file_path = try std.fs.path.join(allocator, &.{ dir_path, file });
        const asset = try func(allocator, user_data, file_path);

        const hash: u64 = std.hash.Wyhash.hash(0, file);
        try hash_map.put(allocator, hash, asset);
    }

    return hash_map;
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
    return assets.toOwnedSlice(allocator);
}
