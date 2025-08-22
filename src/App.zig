const std = @import("std");
const ui = @import("ui.zig");
const sdl = @import("sdl");
const sdlCheck = @import("root.zig").sdlCheck;

window: *Window,

pub const Window = opaque {
    pub inline fn toC(self: *@This()) *sdl.SDL_Window {
        return @ptrCast(self);
    }

    pub fn init(title: [*:0]const u8, width: usize, height: usize) !*@This() {
        try sdlCheck(sdl.SDL_Init(sdl.SDL_INIT_VIDEO | sdl.SDL_INIT_EVENTS | sdl.SDL_INIT_AUDIO));

        const window = sdl.SDL_CreateWindow(title, @intCast(width), @intCast(height), sdl.SDL_WINDOW_OPENGL | sdl.SDL_WINDOW_RESIZABLE);
        try sdlCheck(window);

        return @ptrCast(window.?);
    }

    pub fn deinit(self: *@This()) void {
        sdl.SDL_DestroyWindow(self.toC());
        sdl.SDL_Quit();
    }

    pub fn getSize(self: *@This()) !struct { usize, usize } {
        var size: struct { c_int, c_int } = undefined;
        try sdlCheck(sdl.SDL_GetWindowSize(self.toC(), &size.@"0", &size.@"1"));
        return .{ @intCast(size.@"0"), @intCast(size.@"1") };
    }

    pub fn getAspect(self: *@This()) !f32 {
        const width, const height: usize = try self.getSize();
        return @as(f32, @floatFromInt(width)) / @as(f32, @floatFromInt(height));
    }
};

pub fn init(title: [*:0]const u8, width: usize, height: usize) !@This() {
    const window: *Window = try .init(title, width, height);
    return .{ .window = window };
}

pub fn deinit(self: @This()) void {
    self.window.deinit();
}

pub fn shouldClose(_: @This()) bool {
    var event: sdl.SDL_Event = undefined;
    while (sdl.SDL_PollEvent(&event)) {
        switch (event.type) {
            sdl.SDL_EVENT_QUIT, sdl.SDL_EVENT_TERMINATING => return true,
            else => {},
        }
    }
    return false;
}

pub fn getDeltaTime(_: @This()) f32 {
    const Static = struct {
        var last_time: u64 = 0;
    };
    const now = sdl.SDL_GetPerformanceCounter();
    const freq = sdl.SDL_GetPerformanceFrequency();
    const delta_time = @as(f32, @floatFromInt(now - Static.last_time)) / @as(f32, @floatFromInt(freq));
    Static.last_time = now;
    return delta_time;
}

pub inline fn isKeyDown(_: @This(), key: Key) bool {
    const keyboard = sdl.SDL_GetKeyboardState(null) orelse return false;
    return keyboard[@intFromEnum(key)];
}

pub const Key = enum(usize) {
    // Letters
    a = sdl.SDL_SCANCODE_A,
    b = sdl.SDL_SCANCODE_B,
    c = sdl.SDL_SCANCODE_C,
    d = sdl.SDL_SCANCODE_D,
    e = sdl.SDL_SCANCODE_E,
    f = sdl.SDL_SCANCODE_F,
    g = sdl.SDL_SCANCODE_G,
    h = sdl.SDL_SCANCODE_H,
    i = sdl.SDL_SCANCODE_I,
    j = sdl.SDL_SCANCODE_J,
    k = sdl.SDL_SCANCODE_K,
    l = sdl.SDL_SCANCODE_L,
    m = sdl.SDL_SCANCODE_M,
    n = sdl.SDL_SCANCODE_N,
    o = sdl.SDL_SCANCODE_O,
    p = sdl.SDL_SCANCODE_P,
    q = sdl.SDL_SCANCODE_Q,
    r = sdl.SDL_SCANCODE_R,
    s = sdl.SDL_SCANCODE_S,
    t = sdl.SDL_SCANCODE_T,
    u = sdl.SDL_SCANCODE_U,
    v = sdl.SDL_SCANCODE_V,
    w = sdl.SDL_SCANCODE_W,
    x = sdl.SDL_SCANCODE_X,
    y = sdl.SDL_SCANCODE_Y,
    z = sdl.SDL_SCANCODE_Z,

    // Numbers
    @"1" = sdl.SDL_SCANCODE_1,
    @"2" = sdl.SDL_SCANCODE_2,
    @"3" = sdl.SDL_SCANCODE_3,
    @"4" = sdl.SDL_SCANCODE_4,
    @"5" = sdl.SDL_SCANCODE_5,
    @"6" = sdl.SDL_SCANCODE_6,
    @"7" = sdl.SDL_SCANCODE_7,
    @"8" = sdl.SDL_SCANCODE_8,
    @"9" = sdl.SDL_SCANCODE_9,
    @"0" = sdl.SDL_SCANCODE_0,

    // Control keys
    escape = sdl.SDL_SCANCODE_ESCAPE,
    space = sdl.SDL_SCANCODE_SPACE,
    enter = sdl.SDL_SCANCODE_RETURN,
    tab = sdl.SDL_SCANCODE_TAB,
    backspace = sdl.SDL_SCANCODE_BACKSPACE,

    // Arrows
    up = sdl.SDL_SCANCODE_UP,
    down = sdl.SDL_SCANCODE_DOWN,
    left = sdl.SDL_SCANCODE_LEFT,
    right = sdl.SDL_SCANCODE_RIGHT,

    // Function keys
    f1 = sdl.SDL_SCANCODE_F1,
    f2 = sdl.SDL_SCANCODE_F2,
    f3 = sdl.SDL_SCANCODE_F3,
    f4 = sdl.SDL_SCANCODE_F4,
    f5 = sdl.SDL_SCANCODE_F5,
    f6 = sdl.SDL_SCANCODE_F6,
    f7 = sdl.SDL_SCANCODE_F7,
    f8 = sdl.SDL_SCANCODE_F8,
    f9 = sdl.SDL_SCANCODE_F9,
    f10 = sdl.SDL_SCANCODE_F10,
    f11 = sdl.SDL_SCANCODE_F11,
    f12 = sdl.SDL_SCANCODE_F12,

    // Modifiers
    lshift = sdl.SDL_SCANCODE_LSHIFT,
    rshift = sdl.SDL_SCANCODE_RSHIFT,
    lctrl = sdl.SDL_SCANCODE_LCTRL,
    rctrl = sdl.SDL_SCANCODE_RCTRL,
    lalt = sdl.SDL_SCANCODE_LALT,
    ralt = sdl.SDL_SCANCODE_RALT,
};
