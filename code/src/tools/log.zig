//
// * @file log.zig
// * @brief Thread-safe Logger Implementation with ANSI Color Support
// * @copyright Copyright (c) 2026 WeOn SDK
//

const std = @import("std");
const abi = @import("abi");

// --- Global State ---
var current_log_level: abi.LogLevel = .info;

// --- ANSI Escape Codes ---
const CLR_RESET: []const u8 = "\x1b[0m";
const CLR_GREY:  []const u8 = "\x1b[90m";
const CLR_CYAN:  []const u8 = "\x1b[36m";
const CLR_GOLD:  []const u8 = "\x1b[33m";
const CLR_RED:   []const u8 = "\x1b[31m";

// --- Internal Helpers ---

fn getLevelString(level: abi.LogLevel) []const u8 {
    return switch (level) {
        .debug => "DEBUG",
        .info  => "INFO ",
        .warn  => "WARN ",
        .err   => "ERROR",
        .off   => "OFF  ",
        else   => "UNKWN",
    };
}

fn getLevelColor(level: abi.LogLevel) []const u8 {
    return switch (level) {
        .debug => CLR_GREY,
        .info  => CLR_CYAN,
        .warn  => CLR_GOLD,
        .err   => CLR_RED,
        else   => CLR_RESET,
    };
}

// --- FFI Implementation ---

fn ffi_set_level(level: abi.LogLevel) callconv(.c) void {
    current_log_level = level;
}

fn ffi_print(level: abi.LogLevel, tag: [*:0]const u8, msg: [*:0]const u8) callconv(.c) void {
    const level_val = @intFromEnum(level);
    const current_val = @intFromEnum(current_log_level);

    if (level_val < current_val or current_log_level == .off) return;

    const safe_tag = std.mem.span(tag);
    const safe_msg = std.mem.span(msg);
    const color = getLevelColor(level);
    const level_str = getLevelString(level);

    const now_ms = std.time.milliTimestamp();
    const ms = @mod(now_ms, 1000);

    const c = @cImport({
        @cInclude("time.h");
    });

    var raw_time: c.time_t = @intCast(@divFloor(now_ms, 1000));
    const time_info = c.localtime(&raw_time);

    // High-performance atomic console output
    std.debug.print("{s}[{:0>2}:{:0>2}:{:0>2}.{:0>3}] [{s}] [{s:<8}] {s}{s}\n", .{
        color,
        time_info.*.tm_hour,
        time_info.*.tm_min,
        time_info.*.tm_sec,
        ms,
        level_str,
        safe_tag,
        safe_msg,
        CLR_RESET,
    });
}

// --- Module Instance ---

pub const api_instance = abi.LogApi{
    .print = ffi_print,
    .set_level = ffi_set_level,
};