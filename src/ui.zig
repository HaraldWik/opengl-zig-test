const std = @import("std");
const sdl = @import("sdl");

pub const Context = struct {
    pub fn init(_: @import("App.zig")) !@This() {
        return .{};
    }

    pub fn deinit(_: @This()) void {}

    pub fn setEvent(_: @This()) void {}

    pub fn draw(_: @This()) void {}
};
