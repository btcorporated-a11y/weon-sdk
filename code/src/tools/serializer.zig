const std = @import("std");
const abi = @import("abi");

// Все наши бинарные данные будут строго Little Endian. 
// Это индустриальный стандарт для сетевых пакетов и файлов сохранений.
const ENDIAN = std.builtin.Endian.little;

// ============================================================================
// 1. ВНУТРЕННИЕ ПОМОЩНИКИ (Скрыты от C/C++)
// ============================================================================

/// Проверяет, хватает ли места в буфере. 
/// Если хватает — сдвигает курсор и возвращает Zig-срез (slice) нужной длины.
/// Если не хватает — ставит ошибку и возвращает null.
inline fn reserveBytes(w: *abi.Writer, len: u32) ?[]u8 {
    if (w.has_error or w.data == null) return null;
    
    const start = w.pos;
    const end = start + len;
    
    if (end > w.capacity) {
        w.has_error = true;
        return null;
    }
    
    w.pos = end;
    // Превращаем сырой C-указатель в безопасный Zig-срез!
    return w.data.?[start..end];
}

// ============================================================================
// 2. FFI-ФУНКЦИИ (Те самые, которые мы отдаем плагинам)
// ============================================================================

fn ffi_init(view: abi.View) callconv(.c) abi.Writer {
    // Если нам передали пустой вид (например, не смогли выделить память),
    // мы сразу помечаем курсор как ошибочный.
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
    if (reserveBytes(w, @sizeOf(u32))) |slice| {
        std.mem.writeInt(u32, slice[0..4], v, ENDIAN);
    }
}

fn ffi_u64(w: *abi.Writer, v: u64) callconv(.c) void {
    if (reserveBytes(w, @sizeOf(u64))) |slice| {
        std.mem.writeInt(u64, slice[0..8], v, ENDIAN);
    }
}

fn ffi_f32(w: *abi.Writer, v: f32) callconv(.c) void {
    if (reserveBytes(w, @sizeOf(f32))) |slice| {
        // Числа с плавающей точкой в бинарниках — хитрая штука.
        // Мы используем @bitCast, чтобы перевести биты float в u32,
        // а потом записываем их как обычное число.
        const int_val: u32 = @bitCast(v);
        std.mem.writeInt(u32, slice[0..4], int_val, ENDIAN);
    }
}

fn ffi_str(w: *abi.Writer, str: [*]const u8, len: u32) callconv(.c) void {
    // Строка занимает: 4 байта (длина) + сама длина строки
    if (reserveBytes(w, 4 + len)) |slice| {
        // Сначала пишем длину
        std.mem.writeInt(u32, slice[0..4], len, ENDIAN);
        // Затем быстро копируем байты строки
        const src_slice = str[0..len];
        @memcpy(slice[4..], src_slice);
    }
}

fn ffi_raw(w: *abi.Writer, data: ?*const anyopaque, len: u32) callconv(.c) void {
    if (data == null or len == 0) return;
    
    if (reserveBytes(w, len)) |slice| {
        // Кастуем void* (anyopaque) к [*]const u8 и делаем срез для копирования
        const src_ptr: [*]const u8 = @ptrCast(data.?);
        const src_slice = src_ptr[0..len];
        @memcpy(slice, src_slice);
    }
}

// ============================================================================
// 3. ЭКЗЕМПЛЯР МОДУЛЯ
// ============================================================================

pub const api_instance = abi.SerializerApi{
    .init = ffi_init,
    .u8 = ffi_u8,
    .u32 = ffi_u32,
    .u64 = ffi_u64,
    .f32 = ffi_f32,
    .str = ffi_str,
    .raw = ffi_raw,
};