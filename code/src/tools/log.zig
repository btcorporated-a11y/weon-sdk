const std = @import("std");
const abi = @import("abi");

// ============================================================================
// ГЛОБАЛЬНОЕ СОСТОЯНИЕ
// ============================================================================
// По умолчанию ставим уровень INFO, чтобы не спамить DEBUG-сообщениями.
var current_log_level: abi.LogLevel = .info;


// ============================================================================
// 1. ВНУТРЕННИЕ ПОМОЩНИКИ
// ============================================================================

/// Переводим уровень лога в красивую строку с выравниванием по ширине,
/// чтобы в консоли всё читалось как идеальная таблица.
fn getLevelString(level: abi.LogLevel) []const u8 {
    return switch (level) {
        .debug => "DEBUG",
        .info  => "INFO ", // Пробел для красоты
        .warn  => "WARN ",
        .err   => "ERROR",
        .off   => "OFF  ",
        _      => "UNKWN",
    };
}


// ============================================================================
// 2. FFI-ФУНКЦИИ (Интерфейс для C/C++ плагинов)
// ============================================================================

fn ffi_set_level(level: abi.LogLevel) callconv(.c) void {
    // В будущем тут можно добавить атомарную запись (Atomic), 
    // если уровень логов будут менять из разных потоков, но пока хватит и так.
    current_log_level = level;
}

fn ffi_print(level: abi.LogLevel, tag: [*:0]const u8, msg: [*:0]const u8) callconv(.c) void {
    // 1. Проверяем фильтр. Если сообщение ниже нашего порога — игнорируем.
    if (@intFromEnum(level) < @intFromEnum(current_log_level) or current_log_level == .off) {
        return;
    }

    // 2. Превращаем "бесконечные" Си-строки в строгие Zig-срезы (вычисляем длину до нуля)
    const safe_tag = std.mem.span(tag);
    const safe_msg = std.mem.span(msg);
    const level_str = getLevelString(level);

    // 3. Выводим в консоль (std.debug.print пишет в stderr и защищен мьютексом)
    // Формат: [INFO ] [RENDER] Hello world!
    std.debug.print("[{s}] [{s}] {s}\n", .{ level_str, safe_tag, safe_msg });
}


// ============================================================================
// 3. ЭКЗЕМПЛЯР МОДУЛЯ
// ============================================================================

pub const api_instance = abi.LogApi{
    .print = ffi_print,
    .set_level = ffi_set_level,
};