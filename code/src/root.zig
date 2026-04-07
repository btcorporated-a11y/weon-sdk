//
// * @file main.zig
// * @brief SDK Entry Point and Global Initialization
// * @copyright Copyright (c) 2026 WeOn SDK
//

const std = @import("std");
const abi = @import("abi");

// Toolset
const hash_tool = @import("tools/hash.zig");
const log_tool = @import("tools/log.zig");
const ser_tool = @import("tools/serializer.zig");
const deser_tool = @import("tools/deserializer.zig");

// Managers
const state_manager = @import("core/sharedState.zig");
const request_manager = @import("core/sharedRequest.zig");

// --- Global State ---

var initialized: bool = false;

const GLOBAL_API = abi.CoreApi{
    .hash = &hash_tool.api_instance,
    .log = &log_tool.api_instance,
    .state = &state_manager.api_instance,
    .request = &request_manager.api_instance,
    .serializer = &ser_tool.api_instance,
    .deserializer = &deser_tool.api_instance,
};

// --- Exported C Interface ---

export fn weon_sdk_init() callconv(.c) bool {
    if (initialized) return true;

    const allocator = std.heap.c_allocator;

    state_manager.init(allocator);
    request_manager.init(allocator);

    initialized = true;

    log_tool.api_instance.print(.info, "SDK", "WeOn SDK v2.0.0 initialized.");

    return true;
}

export fn weon_sdk_get_api() callconv(.c) *const abi.CoreApi {
    return &GLOBAL_API;
}

export fn weon_sdk_shutdown() callconv(.c) void {
    if (!initialized) return;
    initialized = false;
}
