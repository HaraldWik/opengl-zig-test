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

    // const noise_scale = 0.01;

    for (height_map, 0..) |*point, i| {
        const x: f32 = @floatFromInt(i % size[0]);
        const y: f32 = @floatFromInt(i / size[0]);

        point.* = (@sin(x / 25) + @sin(y / 25)) * 10; // @import("noise.zig").noise(x * noise_scale, y * noise_scale) * 100 + (std.crypto.random.float(f32) * 0.35);
    }

    return .{ .size = size, .height_map = height_map };
}

pub fn deinit(self: @This(), allocator: std.mem.Allocator) void {
    allocator.free(self.height_map);
}

pub fn get(self: @This(), x: usize, y: usize) ?f32 {
    if (x >= self.size[0] or y >= self.size[1]) return null;

    const index: usize = x + y * self.size[0];

    return self.height_map[index];
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
            const i = y * self.size[0] + x;
            const height = self.height_map[i];

            const normal: nz.Vec3(f32) = blk: {
                const next_x_index = @min(x +| 1, self.size[0] - 1);
                const prev_x_index = @max(x -| 1, 0);
                const next_y_index = @min(y +| 1, self.size[1] - 1);
                const prev_y_index = @max(y -| 1, 0);

                const next_x_height = self.height_map[y * self.size[0] + next_x_index];
                const prev_x_height = self.height_map[y * self.size[0] + prev_x_index];
                const next_y_height = self.height_map[next_y_index * self.size[0] + x];
                const prev_y_height = self.height_map[prev_y_index * self.size[0] + x];

                const delta_x = next_x_height - prev_x_height;
                const delta_y = next_y_height - prev_y_height;

                const vector = nz.Vec3(f32){ -delta_x, 1.0, -delta_y };

                break :blk nz.vec.normalize(vector);
            };

            var vertex = [_]f32{
                // Position
                @floatFromInt(x),
                height,
                @floatFromInt(y),
                // UV
                @as(f32, @floatFromInt(x)) / 40.0,
                @as(f32, @floatFromInt(y)) / 40.0,
                // Normal
                normal[0],
                normal[1],
                normal[2],
            };

            @memcpy(vertices[i * vertex.len .. i * vertex.len + vertex.len], vertex[0..]);
        }
    }

    var i: usize = 0;
    for (0..self.size[1] - 1) |y| {
        for (0..self.size[0] - 1) |x| {
            const top_left: u32 = @intCast(y * self.size[0] + x);
            const top_right: u32 = @intCast(y * self.size[0] + x + 1);
            const bottom_left: u32 = @intCast((y + 1) * self.size[0] + x);
            const bottom_right: u32 = @intCast((y + 1) * self.size[0] + x + 1);

            var index = [_]u32{
                top_left,
                bottom_left,
                top_right,
                top_right,
                bottom_left,
                bottom_right,
            };

            @memcpy(indices[i .. i + index.len], index[0..]);

            i += 6;
        }
    }

    return .init(&.{
        .{ .type = .f32, .count = 3 },
        .{ .type = .f32, .count = 2 },
        .{ .type = .f32, .count = 3 },
    }, vertices, indices);
}
