#ifndef WEON_PLUGIN_H
#define WEON_PLUGIN_H

#include <stdint.h>
#include <stddef.h>

#include "types.h"

#ifdef __cplusplus
extern "C" {
#endif

/**
 * @brief Параметры инициализации плагина.
 * Ядро заполняет входящие поля, плагин читает их и заполняет исходящие.
 */
typedef struct {
    // --- ВХОД (От Ядра к Плагину) ---
    const weon_api_t* api;    // Системные инструменты (Log, RequestManager и т.д.)
    weon_hash_t* cmd_buffer;  // Указатель на массив ядра, куда плагин запишет свои команды
    uint32_t max_cmds;          // Максимальная вместимость cmd_buffer
    
    // --- ВЫХОД (От Плагина к Ядру) ---
    uint32_t written_cmds;      // Плагин должен записать сюда, сколько команд он реально добавил
} weon_plugin_init_t;

/**
 * @brief Главный контракт (ABI) плагина WeOn.
 */
typedef struct {
    uint32_t sdk_version;

    // 1. Инициализация (Получаем API, отдаем список поддерживаемых команд)
    weon_status_t (WEON_CALL *on_init)(weon_plugin_init_t* params);

    // 2. Создание инстанса в конкретном пространстве имен
    void* (WEON_CALL *on_create)(weon_hash_t alias_id, weon_hash_t namespace_id);

    // 3. Обработка входящих событий/команд
    void (WEON_CALL *on_command)(void* ctx, weon_hash_t cmd_hash, weon_hash_t data_handle);

    // 4. Уничтожение инстанса и очистка памяти
    void (WEON_CALL *on_destroy)(void* ctx);

} weon_plugin_interface_t;

// Имя экспортируемого символа, которое Ядро будет искать в DLL
#define WEON_PLUGIN_EXPORT "WEON_PLUGIN"

#ifdef __cplusplus
}
#endif

#endif /* WEON_PLUGIN_H */