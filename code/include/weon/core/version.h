#ifndef WEON_CORE_VERSION_H
#define WEON_CORE_VERSION_H

#include <stdint.h>
#include "types.h"

// Константы текущей версии SDK
#define WEON_SDK_VERSION_MAJOR 2
#define WEON_SDK_VERSION_MINOR 0
#define WEON_SDK_VERSION_PATCH 0
#define WEON_SDK_VERSION_STR   "2.0.0-alpha"

// Макрос для упаковки версии в одно 32-битное число для быстрой проверки ядром.
// Формат: 0xMMmmPP00 (Major, Minor, Patch, Резерв)
#define WEON_MAKE_VERSION(major, minor, patch) \
    ((((uint32_t)(major) & 0xFF) << 24) |      \
     (((uint32_t)(minor) & 0xFF) << 16) |      \
     (((uint32_t)(patch) & 0xFF) << 8))

// Готовый ID текущей версии, который плагин вшивает в себя при компиляции
#define WEON_SDK_VERSION_ID WEON_MAKE_VERSION(WEON_SDK_VERSION_MAJOR, \
                                              WEON_SDK_VERSION_MINOR, \
                                              WEON_SDK_VERSION_PATCH)

#ifdef __cplusplus
extern "C" {
#endif

// Структура метаданных версии (передается через API для рантайм-проверок)
typedef struct {
    uint32_t major;         // Мажорная версия (ломающие изменения API)
    uint32_t minor;         // Минорная версия (новые функции, обратная совместимость)
    uint32_t patch;         // Патч (исправление багов)
    const char* full_str;   // Строковое представление (например, "2.0.0-alpha")
    
    // Возвращает упакованный ID для быстрого сравнения (Core ID == Plugin ID)
    uint32_t (*get_id)(void);
} weon_version_api_t;

// Прямые вызовы (если плагину нужно спросить версию напрямую у DLL ядра)
WEON_EXPORT uint32_t WEON_CALL weon_get_version_id(void);
WEON_EXPORT const char* WEON_CALL weon_get_version_string(void);

#ifdef __cplusplus
}
#endif

#endif /* WEON_CORE_VERSION_H */