//
// * @file shared_state.zig
// * @brief Persistent Shared Memory Implementation
// * @copyright Copyright (c) 2026 WeOn SDK
//

const std = @import("std");
const abi = @import("abi");

const StateEntry = struct {
    data: []u8,
    owner_id: abi.Hash,
};

const StateKey = struct {
    namespace_id: abi.Hash,
    state_alias: abi.Hash,
};

var g_allocator: std.mem.Allocator = undefined;
var g_registry: std.AutoHashMap(StateKey, StateEntry) = undefined;
var g_mutex: std.Thread.Mutex = .{};

pub fn init(allocator: std.mem.Allocator) void {
    g_allocator = allocator;
    g_registry = std.AutoHashMap(StateKey, StateEntry).init(allocator);
}

fn ffi_create_var(req: *const abi.StateReq, size: u32) callconv(.c) abi.View {
    g_mutex.lock();
    defer g_mutex.unlock();

    const key = StateKey{ 
        .namespace_id = req.namespace_id, 
        .state_alias = req.state_alias 
    };

    if (g_registry.contains(key)) return .{ .data = null, .size = 0 };

    const buffer = g_allocator.alloc(u8, size) catch return .{ .data = null, .size = 0 };

    const entry = StateEntry{
        .data = buffer,
        .owner_id = req.requestor_id,
    };

    g_registry.put(key, entry) catch {
        g_allocator.free(buffer);
        return .{ .data = null, .size = 0 };
    };

    return .{ .data = buffer.ptr, .size = size };
}

fn ffi_update_var(req: *const abi.StateReq) callconv(.c) abi.View {
    g_mutex.lock();
    defer g_mutex.unlock();

    const key = StateKey{ 
        .namespace_id = req.namespace_id, 
        .state_alias = req.state_alias 
    };
    
    if (g_registry.get(key)) |entry| {
        if (entry.owner_id == req.requestor_id) {
            return .{ .data = entry.data.ptr, .size = @intCast(entry.data.len) };
        }
    }

    return .{ .data = null, .size = 0 };
}

fn ffi_read_var(req: *const abi.StateReq) callconv(.c) abi.ConstView {
    g_mutex.lock();
    defer g_mutex.unlock();

    const key = StateKey{ 
        .namespace_id = req.namespace_id, 
        .state_alias = req.state_alias 
    };

    if (g_registry.get(key)) |entry| {
        return .{ .data = entry.data.ptr, .size = @intCast(entry.data.len) };
    }

    return .{ .data = null, .size = 0 };
}

fn ffi_destroy_var(req: *const abi.StateReq) callconv(.c) abi.Status {
    g_mutex.lock();
    defer g_mutex.unlock();

    const key = StateKey{ 
        .namespace_id = req.namespace_id, 
        .state_alias = req.state_alias 
    };

    if (g_registry.get(key)) |entry| {
        if (entry.owner_id != req.requestor_id) return .access_denied;

        g_allocator.free(entry.data);
        _ = g_registry.remove(key);
        return .ok;
    }

    return .not_found;
}

pub const api_instance = abi.StateManager{
    .create_var = ffi_create_var,
    .update_var = ffi_update_var,
    .read_var = ffi_read_var,
    .destroy_var = ffi_destroy_var,
};