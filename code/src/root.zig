const std = @import("std");
const abi = @import("abi");

// Инструменты
const hash_tool = @import("tools/hash.zig");
const log_tool = @import("tools/log.zig");
const ser_tool = @import("tools/serializer.zig");
const deser_tool = @import("tools/deserializer.zig");

// Менеджеры
const state_manager = @import("core/sharedState.zig");
const request_manager = @import("core/sharedRequest.zig");

// ============================================================================
// ГЛОБАЛЬНОЕ СОСТОЯНИЕ
// ============================================================================

// Убедись, что здесь нет лишних символов перед var
var initialized: bool = false;

const GLOBAL_API = abi.CoreApi{
    .hash = &hash_tool.api_instance,
    .log = &log_tool.api_instance,
    .state = &state_manager.api_instance,
    .request = &request_manager.api_instance,
    .serializer = &ser_tool.api_instance,
    .deserializer = &deser_tool.api_instance,
};

// ============================================================================
// ЭКСПОРТ
// ============================================================================

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
