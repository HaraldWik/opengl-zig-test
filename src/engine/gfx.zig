const std = @import("std");
const c = @import("c");
const gl = @import("gl");

// ...

pub const Context = struct {
    window: ?*c.SDL_Window,
    var procs: gl.ProcTable = undefined;

    pub fn init(window: ?*c.SDL_Window) !@This() {
        if (!procs.init(getProcAddress)) return error.InitFailed;
        gl.makeProcTableCurrent(&procs);

        if (!c.SDL_GL_SetAttribute(c.SDL_GL_CONTEXT_MAJOR_VERSION, 4) or
            !c.SDL_GL_SetAttribute(c.SDL_GL_CONTEXT_MINOR_VERSION, 6) or
            !c.SDL_GL_SetAttribute(c.SDL_GL_CONTEXT_PROFILE_MASK, c.SDL_GL_CONTEXT_PROFILE_CORE) or
            !c.SDL_GL_SetAttribute(c.SDL_GL_DEPTH_SIZE, 100) or
            !c.SDL_GL_SetAttribute(c.SDL_GL_FRAMEBUFFER_SRGB_CAPABLE, 1))
            return error.SdlSetOpenGLAttribute;

        _ = c.SDL_GL_CreateContext(window);

        return .{ .window = window };
    }

    pub fn deinit(_: @This()) void {
        const gl_context = c.SDL_GL_GetCurrentContext();
        _ = c.SDL_GL_DestroyContext(gl_context);

        gl.makeProcTableCurrent(null);
    }

    pub fn clear(self: @This()) !void {
        var width: c_int = undefined;
        var height: c_int = undefined;
        if (!c.SDL_GetWindowSize(self.window, &width, &height)) return error.SdlGetWindowSize;
        gl.Viewport(0, 0, width, height);
        gl.Enable(gl.FRAMEBUFFER_SRGB);
        gl.Enable(gl.DEPTH_TEST);
        gl.Enable(gl.CULL_FACE);
        gl.CullFace(gl.BACK);
        gl.ClearColor(0, 0.2, 0.7, 1);
        gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
    }

    pub fn present(self: @This()) !void {
        if (!c.SDL_GL_SwapWindow(self.window)) return error.SdlOpenGlSwapWindow;
    }

    fn getProcAddress(name: [*:0]const u8) ?gl.PROC {
        return @ptrCast(@alignCast(c.SDL_GL_GetProcAddress(std.mem.span(name))));
    }
};

pub const Pipeline = struct {
    program: u32,

    pub const Uniform = union(enum) {
        bool: bool,
        i32: i32,
        u32: u32,
        f32: f32,
        f64: f64,
        f32x2: [2]f32,
        f64x2: [2]f64,
        f32x3: [3]f32,
        f64x3: [3]f64,
        f32x4: [4]f32,
        f64x4: [4]f64,
        mat4x4: [16]f32,
    };

    pub fn init(vertex: [:0]const u8, fragment: [:0]const u8, geometry: ?[:0]const u8) !@This() {
        const program = gl.CreateProgram();

        const vertex_shaders = try compileShader(vertex, gl.VERTEX_SHADER);
        const fragment_shaders = try compileShader(fragment, gl.FRAGMENT_SHADER);
        const geometry_shaders = if (geometry != null) try compileShader(geometry.?, gl.GEOMETRY_SHADER) else null;

        gl.AttachShader(program, vertex_shaders);
        gl.AttachShader(program, fragment_shaders);
        if (geometry_shaders != null) gl.AttachShader(program, geometry_shaders.?);

        gl.LinkProgram(program);

        gl.DeleteShader(vertex_shaders);
        gl.DeleteShader(fragment_shaders);
        if (geometry_shaders != null) gl.DeleteShader(geometry_shaders.?);

        var success: c_int = undefined;

        gl.GetProgramiv(program, gl.LINK_STATUS, &success);
        if (success != gl.TRUE) {
            var info_log: [512]u8 = undefined;

            gl.GetProgramInfoLog(program, info_log.len, null, &info_log);
            std.log.err("Failed to create shader program: {s}", .{info_log});
            return error.PipelineProgramCreation;
        }

        return .{ .program = program };
    }

    pub inline fn deinit(self: @This()) void {
        gl.DeleteProgram(self.program);
    }

    pub inline fn bind(self: @This()) void {
        gl.UseProgram(self.program);
    }

    pub fn setUniform(self: @This(), name: [:0]const u8, data: Uniform) !void {
        const location = gl.GetUniformLocation(self.program, name);
        if (location == -1) return error.UniformNotFound;

        switch (data) {
            .bool => |d| gl.ProgramUniform1i(self.program, location, @intFromBool(d)),
            .i32 => |d| gl.ProgramUniform1i(self.program, location, d),
            .u32 => |d| gl.ProgramUniform1ui(self.program, location, d),
            .f32 => |d| gl.ProgramUniform1f(self.program, location, d),
            .f64 => |d| gl.ProgramUniform1d(self.program, location, d),
            .f32x2 => |d| gl.ProgramUniform2f(self.program, location, d[0], d[1]),
            .f64x2 => |d| gl.ProgramUniform2d(self.program, location, d[0], d[1]),
            .f32x3 => |d| gl.ProgramUniform3f(self.program, location, d[0], d[1], d[2]),
            .f64x3 => |d| gl.ProgramUniform3d(self.program, location, d[0], d[1], d[2]),
            .f32x4 => |d| gl.ProgramUniform4f(self.program, location, d[0], d[1], d[2], d[3]),
            .f64x4 => |d| gl.ProgramUniform4d(self.program, location, d[0], d[1], d[2], d[3]),
            .mat4x4 => |d| gl.ProgramUniformMatrix4fv(self.program, location, 1, c.false, @ptrCast(&d.@"0")),
        }
    }

    fn compileShader(source: [:0]const u8, kind: u32) !u32 {
        const shader: u32 = gl.CreateShader(@intCast(kind));
        gl.ShaderSource(shader, 1, @ptrCast(&source), null);
        gl.CompileShader(shader);

        var success: c_int = 0;
        gl.GetShaderiv(shader, gl.COMPILE_STATUS, &success);

        if (success != gl.TRUE) {
            var info_log: [512]u8 = undefined;
            gl.GetShaderInfoLog(shader, info_log.len, null, &info_log);
            c.err("Shader compile error: {s}", .{info_log});
            gl.DeleteShader(shader);
            return error.ShaderCompilation;
        }

        return shader;
    }
};

pub const VertexAttribute = struct {
    type: enum(u32) {
        f64 = gl.DOUBLE,
        f32 = gl.FLOAT,
        f16 = gl.HALF_FLOAT,

        i64 = gl.INT64_ARB, // (ARB extension)
        i32 = gl.INT,
        i16 = gl.SHORT,
        i8 = gl.BYTE,

        u64 = gl.UNSIGNED_INT64_ARB, // (ARB extension)
        u32 = gl.UNSIGNED_INT,
        u16 = gl.UNSIGNED_SHORT,
        u8 = gl.UNSIGNED_BYTE,
    },
    count: usize,

    pub fn getType(self: @This()) type {
        return switch (self.type) {
            .f64 => f64,
            .f32 => f32,
            .f16 => f16,
            .i64 => i64,
            .i32 => i32,
            .i16 => i16,
            .i8 => i8,
            .u64 => u64,
            .u32 => u32,
            .u16 => u16,
            .u8 => u8,
        };
    }
};

pub const Mesh = struct {
    vao: u32,
    vbo: u32,
    ebo: u32,
    index_count: usize,

    pub fn init(comptime vertex_attributes: []VertexAttribute, vertices: []f32, indices: []u32) !@This() {
        var vao: u32 = undefined;
        var vbo: u32 = undefined;
        var ebo: u32 = undefined;

        gl.GenVertexArrays(1, @ptrCast(&vao));
        gl.GenBuffers(1, @ptrCast(&vbo));
        gl.GenBuffers(1, @ptrCast(&ebo));

        gl.BindVertexArray(vao);

        // VBO
        gl.BindBuffer(gl.ARRAY_BUFFER, vbo);
        gl.BufferData(
            gl.ARRAY_BUFFER,
            @intCast(vertices.len * @sizeOf(f32)),
            @ptrCast(vertices.ptr),
            gl.STATIC_DRAW,
        );

        // EBO
        gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo);
        gl.BufferData(
            gl.ELEMENT_ARRAY_BUFFER,
            @intCast(indices.len * @sizeOf(u32)),
            @ptrCast(indices.ptr),
            gl.STATIC_DRAW,
        );

        var stride: usize = 0;
        inline for (vertex_attributes) |vertex_attribute|
            stride += vertex_attribute.count * @sizeOf(vertex_attribute.getType());

        var offset: usize = 0;
        inline for (vertex_attributes, 0..) |vertex_attribute, i| {
            gl.VertexAttribPointer(i, vertex_attribute.count, @intFromEnum(vertex_attribute.type), gl.FALSE, @intCast(stride), offset);
            gl.EnableVertexAttribArray(i);
            offset += vertex_attribute.count * @sizeOf(vertex_attribute.getType());
        }

        // Only unbind ARRAY_BUFFER — keep EBO bound to VAO
        gl.BindBuffer(gl.ARRAY_BUFFER, 0);
        gl.BindVertexArray(0);

        return .{
            .vao = vao,
            .vbo = vbo,
            .ebo = ebo,
            .index_count = indices.len,
        };
    }

    pub fn deinit(self: @This()) void {
        gl.DeleteVertexArrays(1, @ptrCast(@constCast(&self.vao)));
        gl.DeleteBuffers(1, @ptrCast(@constCast(&self.vbo)));
        gl.DeleteBuffers(1, @ptrCast(@constCast(&self.ebo)));
    }

    pub fn draw(self: @This()) void {
        gl.BindVertexArray(self.vao);
        gl.DrawElements(gl.TRIANGLES, @intCast(self.index_count), gl.UNSIGNED_INT, 0);
        gl.BindVertexArray(0);
    }
};

pub const Texture = struct {
    id: u32,

    pub fn init(pixels: [*]u8, width: usize, height: usize) !@This() {
        var texture: u32 = 0;
        gl.GenTextures(1, @ptrCast(&texture));
        gl.BindTexture(gl.TEXTURE_2D, @intCast(texture));

        gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT);
        gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT);
        gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR);
        gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);

        gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGB, @intCast(width), @intCast(height), 0, gl.RGB, gl.UNSIGNED_BYTE, @ptrCast(pixels));
        gl.GenerateMipmap(gl.TEXTURE_2D);

        return .{ .id = texture };
    }

    pub fn deinit(self: @This()) void {
        gl.DeleteTextures(1, @ptrCast(@constCast(&self.id)));
    }

    /// Slot are from 0-31
    pub fn bind(self: @This(), slot: u32) void {
        gl.ActiveTexture(@intCast(gl.TEXTURE0 + slot));
        gl.BindTexture(gl.TEXTURE_2D, self.id);
    }
};
