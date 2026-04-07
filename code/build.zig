const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const os_tag = target.result.os.tag;
    const os_name = @tagName(os_tag);
    const arch_name = @tagName(target.result.cpu.arch);
    const platform_dir = b.fmt("{s}-{s}", .{ os_name, arch_name });

    const abi_module = b.createModule(.{
        .root_source_file = b.path("src/ffi/abi.zig"),
    });

    const weon_module = b.addModule("weon-sdk", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    weon_module.addImport("abi", abi_module);

    const lib = b.addLibrary(.{
        .name = "weon-sdk",
        .root_module = weon_module,
        .linkage = .dynamic,
    });

    lib.out_filename = switch (os_tag) {
        .windows => "weon-sdk.dll",
        .macos, .tvos, .watchos, .ios => "weon-sdk.dylib",
        else => "weon-sdk.so", // Для Linux и остальных Unix-подобных систем
    };

    // 1. Линкуем стандартную C библиотеку
    lib.linkLibC();

    // 2. ФИКС ДЛЯ ARCH LINUX (чтобы не подхватывался текстовый /usr/lib/libc.so)
    if (os_tag == .linux) {
        // Добавляем флаг, чтобы линковщик предпочитал динамические библиотеки с версиями (so.6)
        // и не пытался линковаться со скриптами в /usr/lib напрямую через -lc
        lib.addLibraryPath(.{ .cwd_relative = "/usr/lib" });
    }

    lib.addIncludePath(b.path("include"));

    b.install_path = "../bin";

    const install_lib = b.addInstallArtifact(lib, .{
        .dest_dir = .{ .override = .{ .custom = platform_dir } },
    });

    b.getInstallStep().dependOn(&install_lib.step);
}
