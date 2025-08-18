const std = @import("std");
const c = @import("c");
const sdlCheck = @import("root.zig").sdlCheck;

handle: *c.SDL_Window,

pub fn init(title: [*:0]const u8, width: usize, height: usize) !@This() {
    try sdlCheck(c.SDL_Init(c.SDL_INIT_VIDEO | c.SDL_INIT_EVENTS | c.SDL_INIT_AUDIO));

    const window = c.SDL_CreateWindow(title, @intCast(width), @intCast(height), c.SDL_WINDOW_OPENGL | c.SDL_WINDOW_RESIZABLE);
    try sdlCheck(window);

    return .{ .handle = window.? };
}

pub fn deinit(self: @This()) void {
    c.SDL_DestroyWindow(self.handle);
    c.SDL_Quit();
}

pub fn shouldClose(_: @This()) bool {
    var event: c.SDL_Event = undefined;
    while (c.SDL_PollEvent(&event)) {
        switch (event.type) {
            c.SDL_EVENT_QUIT, c.SDL_EVENT_TERMINATING => return true,
            else => {},
        }
    }
    return false;
}

pub fn getSize(self: @This()) !struct { usize, usize } {
    var size: struct { c_int, c_int } = undefined;
    try sdlCheck(c.SDL_GetWindowSize(self.handle, &size.@"0", &size.@"1"));
    return .{ @intCast(size.@"0"), @intCast(size.@"1") };
}

pub fn getAspect(self: @This()) !f32 {
    const width, const height: usize = try self.getSize();
    return @as(f32, @floatFromInt(width)) / @as(f32, @floatFromInt(height));
}

pub fn getDeltaTime(_: @This()) f32 {
    const Static = struct {
        var last_time: u64 = 0;
    };
    const now = c.SDL_GetPerformanceCounter();
    const freq = c.SDL_GetPerformanceFrequency();
    const delta_time = @as(f32, @floatFromInt(now - Static.last_time)) / @as(f32, @floatFromInt(freq));
    Static.last_time = now;
    return delta_time;
}

pub inline fn isKeyDown(_: @This(), key: Key) bool {
    const keyboard = c.SDL_GetKeyboardState(null) orelse return false;
    return keyboard[@intFromEnum(key)];
}

pub const Key = enum(usize) {
    // Letters
    a = c.SDL_SCANCODE_A,
    b = c.SDL_SCANCODE_B,
    c = c.SDL_SCANCODE_C,
    d = c.SDL_SCANCODE_D,
    e = c.SDL_SCANCODE_E,
    f = c.SDL_SCANCODE_F,
    g = c.SDL_SCANCODE_G,
    h = c.SDL_SCANCODE_H,
    i = c.SDL_SCANCODE_I,
    j = c.SDL_SCANCODE_J,
    k = c.SDL_SCANCODE_K,
    l = c.SDL_SCANCODE_L,
    m = c.SDL_SCANCODE_M,
    n = c.SDL_SCANCODE_N,
    o = c.SDL_SCANCODE_O,
    p = c.SDL_SCANCODE_P,
    q = c.SDL_SCANCODE_Q,
    r = c.SDL_SCANCODE_R,
    s = c.SDL_SCANCODE_S,
    t = c.SDL_SCANCODE_T,
    u = c.SDL_SCANCODE_U,
    v = c.SDL_SCANCODE_V,
    w = c.SDL_SCANCODE_W,
    x = c.SDL_SCANCODE_X,
    y = c.SDL_SCANCODE_Y,
    z = c.SDL_SCANCODE_Z,

    // Numbers
    @"1" = c.SDL_SCANCODE_1,
    @"2" = c.SDL_SCANCODE_2,
    @"3" = c.SDL_SCANCODE_3,
    @"4" = c.SDL_SCANCODE_4,
    @"5" = c.SDL_SCANCODE_5,
    @"6" = c.SDL_SCANCODE_6,
    @"7" = c.SDL_SCANCODE_7,
    @"8" = c.SDL_SCANCODE_8,
    @"9" = c.SDL_SCANCODE_9,
    @"0" = c.SDL_SCANCODE_0,

    // Control keys
    escape = c.SDL_SCANCODE_ESCAPE,
    space = c.SDL_SCANCODE_SPACE,
    enter = c.SDL_SCANCODE_RETURN,
    tab = c.SDL_SCANCODE_TAB,
    backspace = c.SDL_SCANCODE_BACKSPACE,

    // Arrows
    up = c.SDL_SCANCODE_UP,
    down = c.SDL_SCANCODE_DOWN,
    left = c.SDL_SCANCODE_LEFT,
    right = c.SDL_SCANCODE_RIGHT,

    // Function keys
    f1 = c.SDL_SCANCODE_F1,
    f2 = c.SDL_SCANCODE_F2,
    f3 = c.SDL_SCANCODE_F3,
    f4 = c.SDL_SCANCODE_F4,
    f5 = c.SDL_SCANCODE_F5,
    f6 = c.SDL_SCANCODE_F6,
    f7 = c.SDL_SCANCODE_F7,
    f8 = c.SDL_SCANCODE_F8,
    f9 = c.SDL_SCANCODE_F9,
    f10 = c.SDL_SCANCODE_F10,
    f11 = c.SDL_SCANCODE_F11,
    f12 = c.SDL_SCANCODE_F12,

    // Modifiers
    lshift = c.SDL_SCANCODE_LSHIFT,
    rshift = c.SDL_SCANCODE_RSHIFT,
    lctrl = c.SDL_SCANCODE_LCTRL,
    rctrl = c.SDL_SCANCODE_RCTRL,
    lalt = c.SDL_SCANCODE_LALT,
    ralt = c.SDL_SCANCODE_RALT,
};
