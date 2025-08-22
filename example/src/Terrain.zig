const std = @import("std");
const engine = @import("engine");
const nz = @import("numz");

size: nz.Vec2(usize),
height_map: []f32,

pub fn init(
    allocator: std.mem.Allocator,
    size: nz.Vec2(usize),
) !@This() {
    const height_map = try allocator.alloc(f32, size[0] * size[1]);

    const noise_scale = 0.01;

    for (height_map, 0..) |*point, i| {
        const x: f32 = @floatFromInt(i % size[0]);
        const y: f32 = @floatFromInt(i / size[0]);

        point.* = @import("noise.zig").noise(x * noise_scale, y * noise_scale) * 10 + std.crypto.random.float(f32);
    }

    return .{ .size = size, .height_map = height_map };
}

pub fn deinit(self: @This(), allocator: std.mem.Allocator) void {
    allocator.free(self.height_map);
}

pub fn toModel(self: @This(), allocator: std.mem.Allocator) !engine.gfx.Model {
    const vertex_count = self.size[0] * self.size[1];
    const index_count = (self.size[0] - 1) * (self.size[1] - 1) * 6;

    var vertices = try allocator.alloc(f32, vertex_count * 8);
    defer allocator.free(vertices);
    var indices = try allocator.alloc(u32, index_count);
    defer allocator.free(indices);

    for (0..self.size[1]) |y| {
        for (0..self.size[0]) |x| {
            const height_index = y * self.size[0] + x;
            const height = self.height_map[height_index];
            const i = height_index;

            var vertex = [_]f32{
                // Position
                @floatFromInt(x),
                height,
                @floatFromInt(y),
                // UV
                @as(f32, @floatFromInt(x)) / 10.0,
                @as(f32, @floatFromInt(y)) / 10.0,
                // Normal
                0.0,
                1.0,
                0.0,
            };

            @memcpy(vertices[i * vertex.len .. i * vertex.len + vertex.len], vertex[0..]);
        }
    }

    var i: usize = 0;
    for (0..self.size[1] - 1) |y| {
        for (0..self.size[0] - 1) |x| {
            const top_left = @as(u32, @intCast(y * self.size[0] + x));
            const top_right = @as(u32, @intCast(y * self.size[0] + x + 1));
            const bottom_left = @as(u32, @intCast((y + 1) * self.size[0] + x));
            const bottom_right = @as(u32, @intCast((y + 1) * self.size[0] + x + 1));

            // First triangle
            indices[i + 0] = top_left;
            indices[i + 1] = bottom_left;
            indices[i + 2] = top_right;

            // Second triangle
            indices[i + 3] = top_right;
            indices[i + 4] = bottom_left;
            indices[i + 5] = bottom_right;

            // var index = [_]u32{
            //     @intCast(y * self.size[0] + x),
            //     @intCast(y * self.size[0] + x + 1),
            //     @intCast((y + 1) * self.size[0] + x),
            //     @intCast((y + 1) * self.size[0] + x + 1),
            // };

            // @memcpy(indices[i * index.len .. i * index.len + index.len], index[0..]);

            i += 6;
        }
    }

    return .init(&.{
        .{ .type = .f32, .count = 3 },
        .{ .type = .f32, .count = 2 },
        .{ .type = .f32, .count = 3 },
    }, vertices, indices);
}
