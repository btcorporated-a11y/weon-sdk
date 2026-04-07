//
// * @file shared_request.zig
// * @brief High-speed Command Bus Implementation
// * @copyright Copyright (c) 2026 WeOn SDK
//

const std = @import("std");
const abi = @import("abi");

const CommandHeader = extern struct {
    cmd_hash: abi.Hash,
    data_size: u32,
};

const BufferKey = struct {
    namespace_id: abi.Hash,
    buffer_alias: abi.Hash,
};

const RequestBuffer = struct {
    data: []u8,
    cursor: u32,
    cmd_count: u32,
    owner_id: abi.Hash,
    mutex: std.Thread.Mutex,
};

var g_allocator: std.mem.Allocator = undefined;
var g_buffers: std.AutoHashMap(BufferKey, *RequestBuffer) = undefined;
var g_registry_mutex: std.Thread.Mutex = .{};

pub fn init(allocator: std.mem.Allocator) void {
    g_allocator = allocator;
    g_buffers = std.AutoHashMap(BufferKey, *RequestBuffer).init(allocator);
}

fn ffi_create_buffer(req: *const abi.BufferReq, capacity: u32) callconv(.c) abi.BufferHandle {
    g_registry_mutex.lock();
    defer g_registry_mutex.unlock();

    const key = BufferKey{ .namespace_id = req.namespace_id, .buffer_alias = req.buffer_alias };

    if (g_buffers.contains(key)) return null;

    const buffer_mem = g_allocator.alloc(u8, capacity) catch return null;
    const buf_struct = g_allocator.create(RequestBuffer) catch {
        g_allocator.free(buffer_mem);
        return null;
    };

    buf_struct.* = .{
        .data = buffer_mem,
        .cursor = 0,
        .cmd_count = 0,
        .owner_id = req.requestor_id,
        .mutex = .{},
    };

    g_buffers.put(key, buf_struct) catch return null;
    return @ptrCast(buf_struct);
}

fn ffi_get_buffer(req: *const abi.BufferReq) callconv(.c) abi.BufferHandle {
    g_registry_mutex.lock();
    defer g_registry_mutex.unlock();

    const key = BufferKey{ .namespace_id = req.namespace_id, .buffer_alias = req.buffer_alias };
    return @ptrCast(g_buffers.get(key) orelse return null);
}

fn ffi_reserve_space(handle: abi.BufferHandle, cmd_hash: abi.Hash, data_size: u32) callconv(.c) abi.View {
    const buf: *RequestBuffer = @ptrCast(@alignCast(handle orelse return .{ .data = null, .size = 0 }));

    const header_size = @sizeOf(CommandHeader);
    const total_needed = header_size + data_size;

    buf.mutex.lock();
    defer buf.mutex.unlock();

    if (buf.cursor + total_needed > buf.data.len) {
        return .{ .data = null, .size = 0 };
    }

    const header_ptr: *CommandHeader = @ptrCast(@alignCast(buf.data.ptr + buf.cursor));
    header_ptr.* = .{
        .cmd_hash = cmd_hash,
        .data_size = data_size,
    };

    const data_ptr = buf.data.ptr + buf.cursor + header_size;

    buf.cursor += @intCast(total_needed);
    buf.cmd_count += 1;

    return .{ .data = data_ptr, .size = data_size };
}

fn ffi_read_buffer(handle: abi.BufferHandle) callconv(.c) abi.BufferView {
    const buf: *RequestBuffer = @ptrCast(@alignCast(handle orelse return .{ .data = null, .command_count = 0, .total_bytes = 0 }));

    return .{
        .data = buf.data.ptr,
        .command_count = buf.cmd_count,
        .total_bytes = buf.cursor,
    };
}

fn ffi_clear_buffer(handle: abi.BufferHandle) callconv(.c) void {
    const buf: *RequestBuffer = @ptrCast(@alignCast(handle orelse return));

    buf.mutex.lock();
    defer buf.mutex.unlock();

    buf.cursor = 0;
    buf.cmd_count = 0;
}

fn ffi_destroy_buffer(req: *const abi.BufferReq) callconv(.c) abi.Status {
    g_registry_mutex.lock();
    defer g_registry_mutex.unlock();

    const key = BufferKey{ .namespace_id = req.namespace_id, .buffer_alias = req.buffer_alias };

    if (g_buffers.get(key)) |buf| {
        if (buf.owner_id != req.requestor_id) return .access_denied;

        g_allocator.free(buf.data);
        g_allocator.destroy(buf);
        _ = g_buffers.remove(key);
        return .ok;
    }

    return .not_found;
}

pub const api_instance = abi.RequestManager{
    .create_buffer = ffi_create_buffer,
    .get_buffer = ffi_get_buffer,
    .reserve_space = ffi_reserve_space,
    .read_buffer = ffi_read_buffer,
    .clear_buffer = ffi_clear_buffer,
    .destroy_buffer = ffi_destroy_buffer,
};