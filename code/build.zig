//
// * @file build.zig
// * @brief Multi-platform Build System Configuration
// * @copyright Copyright (c) 2026 WeOn SDK
//

const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const os_tag = target.result.os.tag;
    const os_name = @tagName(os_tag);
    const arch_name = @tagName(target.result.cpu.arch);
    const platform_dir = b.fmt("{s}-{s}", .{ os_name, arch_name });

    // --- Module Definitions ---

    const abi_module = b.createModule(.{
        .root_source_file = b.path("src/ffi/abi.zig"),
    });

    const weon_module = b.addModule("weon-sdk", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    weon_module.addImport("abi", abi_module);

    // --- Library Configuration ---

    const lib = b.addLibrary(.{
        .name = "weon-sdk",
        .root_module = weon_module,
        .linkage = .dynamic,
    });

    lib.out_filename = switch (os_tag) {
        .windows => "weon-sdk.dll",
        .macos, .tvos, .watchos, .ios => "weon-sdk.dylib",
        else => "weon-sdk.so",
    };

    lib.linkLibC();

    // Linux-specific linker adjustments (Fix for Arch Linux libc.so script issues)
    if (os_tag == .linux) {
        lib.addLibraryPath(.{ .cwd_relative = "/usr/lib" });
    }

    lib.addIncludePath(b.path("include"));

    // --- Artifact Installation ---

    b.install_path = "../bin";

    const install_lib = b.addInstallArtifact(lib, .{
        .dest_dir = .{ .override = .{ .custom = platform_dir } },
    });

    b.getInstallStep().dependOn(&install_lib.step);
}
