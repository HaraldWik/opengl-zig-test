const std = @import("std");
const sdl = @import("sdl");
const gl = @import("gl");
const nk = @import("nuklear");

pub const Context = struct {
    pub fn init(_: @import("App.zig")) !@This() {
        return .{};
    }

    pub fn deinit(_: @This()) void {}

    pub fn setEvent(_: @This()) void {}

    pub fn draw(_: @This()) void {}
};
