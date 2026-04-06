const std = @import("std");
const abi = @import("abi");

// ============================================================================
// ВНУТРЕННИЕ СТРУКТУРЫ
// ============================================================================

/// Заголовок, который Ядро записывает перед данными команды.
/// Рендерер будет использовать его, чтобы знать тип команды и размер прыжка.
const CommandHeader = extern struct {
    cmd_hash: abi.Hash,
    data_size: u32,
};

/// Составной ключ для поиска буфера в глобальном реестре.
const BufferKey = struct {
    namespace_id: abi.Hash,
    buffer_alias: abi.Hash,
};

/// Объект буфера в памяти SDK.
const RequestBuffer = struct {
    data: []u8, // Выделенный сырой кусок памяти
    cursor: u32, // Текущее смещение для следующей записи
    cmd_count: u32, // Счетчик записанных команд
    owner_id: abi.Hash, // ID создателя (Хоста)
    mutex: std.Thread.Mutex, // Защита курсора при записи из разных плагинов
};

// ============================================================================
// ГЛОБАЛЬНОЕ СОСТОЯНИЕ МЕНЕДЖЕРА
// ============================================================================

var g_allocator: std.mem.Allocator = undefined;
var g_buffers: std.AutoHashMap(BufferKey, *RequestBuffer) = undefined;
var g_registry_mutex: std.Thread.Mutex = .{};

/// Инициализация менеджера при загрузке SDK.
pub fn init(allocator: std.mem.Allocator) void {
    g_allocator = allocator;
    g_buffers = std.AutoHashMap(BufferKey, *RequestBuffer).init(allocator);
}

// ============================================================================
// FFI РЕАЛИЗАЦИЯ (Интерфейс для C/C++)
// ============================================================================

fn ffi_create_buffer(req: *const abi.BufferReq, capacity: u32) callconv(.c) abi.BufferHandle {
    g_registry_mutex.lock();
    defer g_registry_mutex.unlock();

    const key = BufferKey{ .namespace_id = req.namespace_id, .buffer_alias = req.buffer_alias };

    if (g_buffers.contains(key)) return null;

    // Выделяем память под данные и под саму структуру управления
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
    // Кастуем handle обратно в нашу структуру
    const buf: *RequestBuffer = @ptrCast(@alignCast(handle orelse return .{ .data = null, .size = 0 }));

    const header_size = @sizeOf(CommandHeader);
    const total_needed = header_size + data_size;

    buf.mutex.lock();
    defer buf.mutex.unlock();

    // Защита от переполнения буфера
    if (buf.cursor + total_needed > buf.data.len) {
        return .{ .data = null, .size = 0 };
    }

    // 1. Записываем скрытый заголовок
    const header_ptr: *CommandHeader = @ptrCast(@alignCast(buf.data.ptr + buf.cursor));
    header_ptr.* = .{
        .cmd_hash = cmd_hash,
        .data_size = data_size,
    };

    // 2. Получаем указатель на сегмент данных для плагина (сразу после заголовка)
    const data_ptr = buf.data.ptr + buf.cursor + header_size;

    // Обновляем состояние буфера
    buf.cursor += @intCast(total_needed);
    buf.cmd_count += 1;

    return .{ .data = data_ptr, .size = data_size };
}

fn ffi_read_buffer(handle: abi.BufferHandle) callconv(.c) abi.BufferView {
    const buf: *RequestBuffer = @ptrCast(@alignCast(handle orelse return .{ .data = null, .command_count = 0, .total_bytes = 0 }));

    // Возвращаем "снимок" текущего состояния буфера для Читателя (Хоста)
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

    // Сбрасываем курсор в начало (память не очищаем, просто перезаписываем в следующем кадре)
    buf.cursor = 0;
    buf.cmd_count = 0;
}

fn ffi_destroy_buffer(req: *const abi.BufferReq) callconv(.c) abi.Status {
    g_registry_mutex.lock();
    defer g_registry_mutex.unlock();

    const key = BufferKey{ .namespace_id = req.namespace_id, .buffer_alias = req.buffer_alias };

    if (g_buffers.get(key)) |buf| {
        // Проверка прав: только владелец (requestor_id при создании) может удалить буфер
        if (buf.owner_id != req.requestor_id) return .access_denied;

        g_allocator.free(buf.data);
        g_allocator.destroy(buf);
        _ = g_buffers.remove(key);
        return .ok;
    }

    return .not_found;
}

// ============================================================================
// ЭКЗЕМПЛЯР МОДУЛЯ
// ============================================================================

pub const api_instance = abi.RequestManager{
    .create_buffer = ffi_create_buffer,
    .get_buffer = ffi_get_buffer,
    .reserve_space = ffi_reserve_space,
    .read_buffer = ffi_read_buffer,
    .clear_buffer = ffi_clear_buffer,
    .destroy_buffer = ffi_destroy_buffer,
};
