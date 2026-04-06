const std = @import("std");
const abi = @import("abi");

// ============================================================================
// ВНУТРЕННИЕ СТРУКТУРЫ ЯДРА
// ============================================================================

/// Внутренняя запись о переменной в памяти
const StateEntry = struct {
    data: []u8,           // Срез выделенной памяти
    owner_id: abi.Hash,   // Кто создал (только он может удалять/обновлять)
};

/// Координаты для поиска (ключ в нашей хэш-таблице)
const StateKey = struct {
    namespace_id: abi.Hash,
    state_alias: abi.Hash,
};

// ============================================================================
// ГЛОБАЛЬНОЕ СОСТОЯНИЕ МЕНЕДЖЕРА
// ============================================================================

// Хранилище всех переменных. 
// Используем аллокатор, который нам передаст Core при инициализации SDK.
var g_allocator: std.mem.Allocator = undefined;
var g_registry: std.AutoHashMap(StateKey, StateEntry) = undefined;
var g_mutex: std.Thread.Mutex = .{}; // Защита для многопоточности

/// Инициализация менеджера (вызывается внутри SDK при загрузке)
pub fn init(allocator: std.mem.Allocator) void {
    g_allocator = allocator;
    g_registry = std.AutoHashMap(StateKey, StateEntry).init(allocator);
}

// ============================================================================
// FFI РЕАЛИЗАЦИЯ (Интерфейс для C/C++)
// ============================================================================

fn ffi_create_var(req: *const abi.StateReq, size: u32) callconv(.c) abi.View {
    g_mutex.lock();
    defer g_mutex.unlock();

    const key = StateKey{ .namespace_id = req.namespace_id, .state_alias = req.state_alias };

    // Проверяем, не занято ли имя
    if (g_registry.contains(key)) return .{ .data = null, .size = 0 };

    // Выделяем память через Zig аллокатор
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

    const key = StateKey{ .namespace_id = req.namespace_id, .state_alias = req.state_alias };
    
    if (g_registry.get(key)) |entry| {
        // Безопасность: только владелец может получить указатель на запись
        if (entry.owner_id == req.requestor_id) {
            return .{ .data = entry.data.ptr, .size = @intCast(entry.data.len) };
        }
    }

    return .{ .data = null, .size = 0 };
}

fn ffi_read_var(req: *const abi.StateReq) callconv(.c) abi.ConstView {
    g_mutex.lock();
    defer g_mutex.unlock();

    const key = StateKey{ .namespace_id = req.namespace_id, .state_alias = req.state_alias };

    if (g_registry.get(key)) |entry| {
        // Читать может кто угодно (публичные данные), 
        // но возвращаем строго ConstView
        return .{ .data = entry.data.ptr, .size = @intCast(entry.data.len) };
    }

    return .{ .data = null, .size = 0 };
}

fn ffi_destroy_var(req: *const abi.StateReq) callconv(.c) abi.Status {
    g_mutex.lock();
    defer g_mutex.unlock();

    const key = StateKey{ .namespace_id = req.namespace_id, .state_alias = req.state_alias };

    if (g_registry.get(key)) |entry| {
        // Безопасность: только создатель может удалить
        if (entry.owner_id != req.requestor_id) return .access_denied;

        g_allocator.free(entry.data);
        _ = g_registry.remove(key);
        return .ok;
    }

    return .not_found;
}

// ============================================================================
// ЭКЗЕМПЛЯР МОДУЛЯ
// ============================================================================

pub const api_instance = abi.StateManager{
    .create_var = ffi_create_var,
    .update_var = ffi_update_var,
    .read_var = ffi_read_var,
    .destroy_var = ffi_destroy_var,
};