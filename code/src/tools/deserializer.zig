const std = @import("std");
const abi = @import("abi");

// Читаем в том же формате, в котором писали (Little Endian)
const ENDIAN = std.builtin.Endian.little;

// ============================================================================
// 1. ВНУТРЕННИЕ ПОМОЩНИКИ
// ============================================================================

/// Безопасное чтение. Проверяет границы и возвращает Zig-срез данных.
/// Если данных не хватает — ставит ошибку и возвращает null.
inline fn readBytes(r: *abi.Reader, len: u32) ?[]const u8 {
    if (r.has_error or r.data == null) return null;
    
    const start = r.pos;
    const end = start + len;
    
    // Защита от переполнения (чтения за пределами выделенной памяти)
    if (end > r.size) {
        r.has_error = true;
        return null;
    }
    
    r.pos = end;
    // Возвращаем константный срез оригинального буфера
    return r.data.?[start..end];
}

// ============================================================================
// 2. FFI-ФУНКЦИИ (Распаковщик)
// ============================================================================

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
    return 0; // Безопасный fallback при ошибке
}

fn ffi_u32(r: *abi.Reader) callconv(.c) u32 {
    if (readBytes(r, @sizeOf(u32))) |slice| {
        return std.mem.readInt(u32, slice[0..4], ENDIAN);
    }
    return 0;
}

fn ffi_u64(r: *abi.Reader) callconv(.c) u64 {
    if (readBytes(r, @sizeOf(u64))) |slice| {
        return std.mem.readInt(u64, slice[0..8], ENDIAN);
    }
    return 0;
}

fn ffi_f32(r: *abi.Reader) callconv(.c) f32 {
    if (readBytes(r, @sizeOf(f32))) |slice| {
        // Читаем как целое число, затем бинарно кастуем во float
        const int_val = std.mem.readInt(u32, slice[0..4], ENDIAN);
        return @bitCast(int_val);
    }
    return 0.0;
}

// ZERO-COPY МАГИЯ ДЛЯ СТРОК
fn ffi_str(r: *abi.Reader, out_len: *u32) callconv(.c) ?[*]const u8 {
    // Сначала читаем 4 байта длины
    if (readBytes(r, 4)) |len_bytes| {
        const len = std.mem.readInt(u32, len_bytes[0..4], ENDIAN);
        
        // Теперь запрашиваем саму строку
        if (readBytes(r, len)) |str_bytes| {
            out_len.* = len;
            return str_bytes.ptr; // Отдаем прямой указатель в буфер!
        }
    }
    
    out_len.* = 0;
    return null;
}

// ZERO-COPY ДЛЯ СЫРЫХ ДАННЫХ (Читаем всё, что осталось)
fn ffi_raw(r: *abi.Reader, out_len: *u32) callconv(.c) ?*const anyopaque {
    if (r.has_error or r.data == null) {
        out_len.* = 0;
        return null;
    }
    
    // Вычисляем, сколько байт осталось до конца буфера
    const remaining = r.size - r.pos;
    if (remaining > 0) {
        if (readBytes(r, remaining)) |raw_bytes| {
            out_len.* = remaining;
            return @ptrCast(raw_bytes.ptr); // Кастуем обратно в void*
        }
    }
    
    out_len.* = 0;
    return null;
}

// ============================================================================
// 3. ЭКЗЕМПЛЯР МОДУЛЯ
// ============================================================================

pub const api_instance = abi.DeserializerApi{
    .init = ffi_init,
    .u8 = ffi_u8,
    .u32 = ffi_u32,
    .u64 = ffi_u64,
    .f32 = ffi_f32,
    .str = ffi_str,
    .raw = ffi_raw,
};