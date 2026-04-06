#ifndef WEON_CORE_API_H
#define WEON_CORE_API_H

// Подключаем весь наш великолепный арсенал:
#include "weon/core/types.h"

#include "weon/tools/hash.h"
#include "weon/tools/log.h"

#include "weon/tools/serializer.h"
#include "weon/tools/deserializer.h"

#include "weon/core/sharedState.h"
#include "weon/core/sharedRequest.h"

#ifdef __cplusplus
extern "C" {
#endif

/**
 * @brief Главный интерфейс Ядра WeOn (The Core API).
 * Эта структура передается каждому плагину при вызове on_init.
 * Через нее плагин получает доступ ко всем подсистемам движка.
 */
struct weon_api_t {
    // ------------------------------------------------------------------------
    // 1. БАЗОВЫЕ УТИЛИТЫ (Утилитарный слой)
    // ------------------------------------------------------------------------
    const weon_hash_api_t* hash;  // Быстрое хэширование строк (FNV-1a)
    const weon_log_api_t* log;   // Безопасный вывод логов с уровнями и тегами

    // ------------------------------------------------------------------------
    // 2. МЕНЕДЖЕРЫ ПАМЯТИ И ДАННЫХ (Слой управления ресурсами)
    // ------------------------------------------------------------------------
    const weon_state_manager_t* state;   // Разделяемые переменные (Shared State)
    const weon_request_manager_t* request; // Высокоскоростные шины команд (Command Buffers)

    // ------------------------------------------------------------------------
    // 3. ИНСТРУМЕНТЫ (Слой трансформации данных)
    // ------------------------------------------------------------------------
    const weon_serializer_api_t* serializer;   // Упаковщик данных (Писатель)
    const weon_deserializer_api_t* deserializer; // Распаковщик данных (Читатель)
};

#ifdef __cplusplus
}
#endif

#endif /* WEON_CORE_API_H */