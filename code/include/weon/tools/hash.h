#ifndef WEON_CORE_HASH_H
#define WEON_CORE_HASH_H

#include <stdint.h>
#include "../core/types.h"

#ifdef __cplusplus
extern "C" {
#endif

/**
 * @brief Инструменты для хэширования.
 * Используется алгоритм FNV-1a (64-bit) для мгновенного перевода строк в числа.
 */
typedef struct {
    /**
     * @brief Генерирует 64-битный хэш из строки.
     * Используется для генерации namespace_id, alias_id и cmd_hash.
     */
    weon_hash_t (WEON_CALL *fnv1a_64)(const char* str);
    
} weon_hash_api_t;

#ifdef __cplusplus
}
#endif

#endif /* WEON_CORE_HASH_H */