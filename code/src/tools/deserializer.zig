//
// * @file deserializer.zig
// * @brief Zero-Copy Binary Deserializer Implementation
// * @copyright Copyright (c) 2026 WeOn SDK
//

const std = @import("std");
const abi = @import("abi");

const ENDIAN = std.builtin.Endian.little;

inline fn readBytes(r: *abi.Reader, len: u32) ?[]const u8 {
    if (r.has_error or r.data == null) return null;
    
    const start = r.pos;
    const end = start + len;
    
    if (end > r.size) {
        r.has_error = true;
        return null;
    }
    
    r.pos = end;
    return r.data.?[start..end];
}

fn ffi_init(view: abi.ConstView) callconv(.c) abi.Reader {
    return abi.Reader{
        .data = view.data,
        .size = view.size,
        .pos = 0,
        .has_error = (view.data == null),
    };
}

fn ffi_u8(r: *abi.Reader) callconv(.c) u8 {
    if (readBytes(r, 1)) |slice| {
        return slice[0];
    }
    return 0;
}

fn ffi_u32(r: *abi.Reader) callconv(.c) u32 {
    if (readBytes(r, @sizeOf(u32))) |slice| {
        const bytes: *const [4]u8 = slice[0..4];
        return std.mem.readInt(u32, bytes, ENDIAN);
    }
    return 0;
}

fn ffi_u64(r: *abi.Reader) callconv(.c) u64 {
    if (readBytes(r, @sizeOf(u64))) |slice| {
        const bytes: *const [8]u8 = slice[0..8];
        return std.mem.readInt(u64, bytes, ENDIAN);
    }
    return 0;
}

fn ffi_f32(r: *abi.Reader) callconv(.c) f32 {
    if (readBytes(r, @sizeOf(f32))) |slice| {
        const bytes: *const [4]u8 = slice[0..4];
        const int_val = std.mem.readInt(u32, bytes, ENDIAN);
        return @bitCast(int_val);
    }
    return 0.0;
}

fn ffi_str(r: *abi.Reader, out_len: *u32) callconv(.c) ?[*]const u8 {
    if (readBytes(r, 4)) |len_bytes| {
        const bytes: *const [4]u8 = len_bytes[0..4];
        const len = std.mem.readInt(u32, bytes, ENDIAN);
        
        if (readBytes(r, len)) |str_bytes| {
            out_len.* = len;
            return str_bytes.ptr;
        }
    }
    
    out_len.* = 0;
    return null;
}

fn ffi_raw(r: *abi.Reader, out_len: *u32) callconv(.c) ?*const anyopaque {
    if (r.has_error or r.data == null) {
        out_len.* = 0;
        return null;
    }
    
    const remaining = r.size - r.pos;
    if (remaining > 0) {
        if (readBytes(r, remaining)) |raw_bytes| {
            out_len.* = remaining;
            return @ptrCast(raw_bytes.ptr);
        }
    }
    
    out_len.* = 0;
    return null;
}

pub const api_instance = abi.DeserializerApi{
    .init = ffi_init,
    .u8 = ffi_u8,
    .u32 = ffi_u32,
    .u64 = ffi_u64,
    .f32 = ffi_f32,
    .str = ffi_str,
    .raw = ffi_raw,
};