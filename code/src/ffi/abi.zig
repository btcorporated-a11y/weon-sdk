const std = @import("std");

// ============================================================================
// 1. БАЗОВЫЕ ТИПЫ (из types.h)
// ============================================================================

/// Универсальный хэш
pub const Hash = u64;

/// Статусы выполнения (C enum обычно занимает 4 байта, поэтому u32)
pub const Status = enum(u32) {
    ok = 0,
    err = 1,
    not_supported = 2,
    invalid_arguments = 3,
    pending = 4,
    not_found = 5,
    access_denied = 6,
    version_mismatch = 7,
    _, // Разрешаем другие значения (безопасность для C ABI)
};

/// Уровни логирования
pub const LogLevel = enum(u32) {
    debug = 0,
    info = 1,
    warn = 2,
    err = 3,
    off = 4,
    _,
};

/// Универсальный срез памяти для записи
pub const View = extern struct {
    data: ?[*]u8, // Указатель на массив байтов (может быть null)
    size: u32,
};

/// Универсальный срез памяти для чтения (Строгий CONST)
pub const ConstView = extern struct {
    data: ?[*]const u8,
    size: u32,
};


// ============================================================================
// 2. МЕНЕДЖЕРЫ И СТРУКТУРЫ (Shared State & Requests)
// ============================================================================

pub const StateReq = extern struct {
    requestor_id: Hash,
    state_alias: Hash,
    namespace_id: Hash,
};

pub const BufferReq = extern struct {
    requestor_id: Hash,
    buffer_alias: Hash,
    namespace_id: Hash,
};

pub const BufferView = extern struct {
    data: ?*const anyopaque, // const void*
    command_count: u32,
    total_bytes: u32,        // Заменили size_t на u32, как договаривались!
};

/// Билет на доступ к буферу (Opaque Pointer -> void*)
pub const BufferHandle = ?*anyopaque;


// ============================================================================
// 3. СЕРИАЛИЗАЦИЯ (Курсоры)
// ============================================================================

pub const Writer = extern struct {
    data: ?[*]u8,
    capacity: u32,
    pos: u32,
    has_error: bool,
};

pub const Reader = extern struct {
    data: ?[*]const u8,
    size: u32,
    pos: u32,
    has_error: bool,
};


// ============================================================================
// 4. ИНТЕРФЕЙСЫ МОДУЛЕЙ (Таблицы виртуальных функций - VTables)
// Обрати внимание: все функции используют callconv(.c)
// ============================================================================

pub const HashApi = extern struct {
    fnv1a_64: *const fn (str: [*:0]const u8) callconv(.c) Hash,
};

pub const LogApi = extern struct {
    print: *const fn (level: LogLevel, tag: [*:0]const u8, msg: [*:0]const u8) callconv(.c) void,
    set_level: *const fn (level: LogLevel) callconv(.c) void,
};

pub const StateManager = extern struct {
    create_var: *const fn (req: *const StateReq, size: u32) callconv(.c) View,
    update_var: *const fn (req: *const StateReq) callconv(.c) View,
    read_var: *const fn (req: *const StateReq) callconv(.c) ConstView,
    destroy_var: *const fn (req: *const StateReq) callconv(.c) Status,
};

pub const RequestManager = extern struct {
    create_buffer: *const fn (req: *const BufferReq, capacity: u32) callconv(.c) BufferHandle,
    get_buffer: *const fn (req: *const BufferReq) callconv(.c) BufferHandle,
    reserve_space: *const fn (handle: BufferHandle, cmd_hash: Hash, data_size: u32) callconv(.c) View,
    read_buffer: *const fn (handle: BufferHandle) callconv(.c) BufferView,
    clear_buffer: *const fn (handle: BufferHandle) callconv(.c) void,
    destroy_buffer: *const fn (req: *const BufferReq) callconv(.c) Status,
};

pub const SerializerApi = extern struct {
    init: *const fn (view: View) callconv(.c) Writer,
    u8:   *const fn (w: *Writer, v: u8) callconv(.c) void,
    u32:  *const fn (w: *Writer, v: u32) callconv(.c) void,
    u64:  *const fn (w: *Writer, v: u64) callconv(.c) void,
    f32:  *const fn (w: *Writer, v: f32) callconv(.c) void,
    str:  *const fn (w: *Writer, str: [*]const u8, len: u32) callconv(.c) void,
    raw:  *const fn (w: *Writer, data: ?*const anyopaque, len: u32) callconv(.c) void,
};

pub const DeserializerApi = extern struct {
    init: *const fn (view: ConstView) callconv(.c) Reader,
    u8:   *const fn (r: *Reader) callconv(.c) u8,
    u32:  *const fn (r: *Reader) callconv(.c) u32,
    u64:  *const fn (r: *Reader) callconv(.c) u64,
    f32:  *const fn (r: *Reader) callconv(.c) f32,
    str:  *const fn (r: *Reader, out_len: *u32) callconv(.c) ?[*]const u8,
    raw:  *const fn (r: *Reader, out_len: *u32) callconv(.c) ?*const anyopaque,
};


// ============================================================================
// 5. ГЛАВНЫЙ ЧЕМОДАН (The Core API)
// ============================================================================

/// Это та самая структура, адрес которой мы передадим плагину в on_init
pub const CoreApi = extern struct {
    hash: *const HashApi,
    log: *const LogApi,
    state: *const StateManager,
    request: *const RequestManager,
    serializer: *const SerializerApi,
    deserializer: *const DeserializerApi,
};


// ============================================================================
// 6. ИНТЕРФЕЙС ПЛАГИНА (То, что Ядро ожидает от DLL плагина)
// ============================================================================

pub const PluginInitParams = extern struct {
    api: *const CoreApi,
    cmd_buffer: ?[*]Hash,
    max_cmds: u32,
    written_cmds: u32,
};

pub const PluginInterface = extern struct {
    sdk_version: u32,
    on_init: *const fn (params: *PluginInitParams) callconv(.c) Status,
    on_create: *const fn (alias_id: Hash, namespace_id: Hash) callconv(.c) ?*anyopaque,
    on_command: *const fn (ctx: ?*anyopaque, cmd_hash: Hash, data_handle: Hash) callconv(.c) void,
    on_destroy: *const fn (ctx: ?*anyopaque) callconv(.c) void,
};