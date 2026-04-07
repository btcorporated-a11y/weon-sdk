//
// * @file serializer.zig
// * @brief High-performance Binary Serializer Implementation
// * @copyright Copyright (c) 2026 WeOn SDK
//

const std = @import("std");
const abi = @import("abi");

const ENDIAN = std.builtin.Endian.little;

inline fn reserveBytes(w: *abi.Writer, len: u32) ?[]u8 {
    if (w.has_error or w.data == null) return null;

    const start = w.pos;
    const end = start + len;

    if (end > w.capacity) {
        w.has_error = true;
        return null;
    }

    w.pos = end;
    return w.data.?[start..end];
}

fn ffi_init(view: abi.View) callconv(.c) abi.Writer {
    return abi.Writer{
        .data = view.data,
        .capacity = view.size,
        .pos = 0,
        .has_error = (view.data == null),
    };
}

fn ffi_u8(w: *abi.Writer, v: u8) callconv(.c) void {
    if (reserveBytes(w, 1)) |slice| {
        slice[0] = v;
    }
}

fn ffi_u32(w: *abi.Writer, v: u32) callconv(.c) void {
    if (reserveBytes(w, 4)) |slice| {
        const bytes: *[4]u8 = slice[0..4];
        std.mem.writeInt(u32, bytes, v, ENDIAN);
    }
}

fn ffi_u64(w: *abi.Writer, v: u64) callconv(.c) void {
    if (reserveBytes(w, 8)) |slice| {
        const bytes: *[8]u8 = slice[0..8];
        std.mem.writeInt(u64, bytes, v, ENDIAN);
    }
}

fn ffi_f32(w: *abi.Writer, v: f32) callconv(.c) void {
    if (reserveBytes(w, 4)) |slice| {
        const bytes: *[4]u8 = slice[0..4];
        const int_val: u32 = @bitCast(v);
        std.mem.writeInt(u32, bytes, int_val, ENDIAN);
    }
}

fn ffi_str(w: *abi.Writer, str: [*]const u8, len: u32) callconv(.c) void {
    if (reserveBytes(w, 4 + len)) |slice| {
        const len_bytes: *[4]u8 = slice[0..4];
        std.mem.writeInt(u32, len_bytes, len, ENDIAN);

        const src_slice = str[0..len];
        @memcpy(slice[4..], src_slice);
    }
}

fn ffi_raw(w: *abi.Writer, data: ?*const anyopaque, len: u32) callconv(.c) void {
    if (data == null or len == 0) return;

    if (reserveBytes(w, len)) |slice| {
        const src_ptr: [*]const u8 = @ptrCast(data.?);
        const src_slice = src_ptr[0..len];
        @memcpy(slice, src_slice);
    }
}

pub const api_instance = abi.SerializerApi{
    .init = ffi_init,
    .u8 = ffi_u8,
    .u32 = ffi_u32,
    .u64 = ffi_u64,
    .f32 = ffi_f32,
    .str = ffi_str,
    .raw = ffi_raw,
};
