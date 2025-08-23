const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const sdl = b.dependency("sdl", .{
        .target = target,
        .optimize = optimize,
        .lto = optimize != .Debug,
        .preferred_linkage = .static,
    });
    const sdl_translate_c = b.addTranslateC(.{
        .root_source_file = sdl.path("include/SDL3/SDL.h"),
        .target = target,
        .optimize = optimize,
    });
    sdl_translate_c.addIncludePath(sdl.path("include"));

    const gl = @import("zigglgen").generateBindingsModule(b, .{
        .api = .gl,
        .version = .@"4.6",
        .profile = .core,
        .extensions = &.{ .ARB_clip_control, .NV_scissor_exclusive },
    });

    // const nuklear = b.addTranslateC(.{
    //     .root_source_file = b.path("include/nuklear/nuklear.h"),
    //     .target = target,
    //     .optimize = optimize,
    // });
    // nuklear.defineCMacro("NK_INCLUDE_FIXED_TYPES", "1");
    // nuklear.defineCMacro("NK_INCLUDE_STANDARD_IO", "1");
    // nuklear.defineCMacro("NK_INCLUDE_DEFAULT_ALLOCATOR", "1");
    // nuklear.defineCMacro("NK_INCLUDE_VERTEX_BUFFER_OUTPUT", "1");
    // nuklear.defineCMacro("NK_INCLUDE_FONT_BAKING", "1");
    // nuklear.defineCMacro("NK_INCLUDE_DEFAULT_FONT", "1");
    // nuklear.defineCMacro("NK_IMPLEMENTATION", "1");
    // nuklear.defineCMacro("NK_SDL_GL3_IMPLEMENTATION", "1");
    // nuklear.defineCMacro("NK_SHADER_VERSION", "#version 460 core\n");

    const numz = b.dependency("numz", .{
        .target = target,
        .optimize = optimize,
    }).module("numz");

    const mod = b.addModule("engine", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "sdl", .module = sdl_translate_c.createModule() },
            .{ .name = "gl", .module = gl },
            // .{ .name = "nuklear", .module = nuklear.createModule() },
            .{ .name = "numz", .module = numz },
        },
    });
    mod.linkSystemLibrary("SDL3_image", .{});
    mod.linkSystemLibrary("SDL3", .{});

    const mod_tests = b.addTest(.{
        .root_module = mod,
    });

    const run_mod_tests = b.addRunArtifact(mod_tests);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_mod_tests.step);
}
