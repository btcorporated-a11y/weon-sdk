#ifndef WEON_CORE_DESERIALIZER_H
#define WEON_CORE_DESERIALIZER_H

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

#include "../core/types.h"

#ifdef __cplusplus
extern "C" {
#endif

/**
 * @brief Легковесный курсор для чтения (Читатель).
 */
typedef struct {
    const uint8_t* data; // CONST! Физически невозможно перезаписать данные!
    uint32_t size;       // Размер доступных данных
    uint32_t pos;        // Текущая позиция чтения
    bool has_error;      // Флаг ошибки (если попытались прочитать больше, чем есть)
} weon_reader_t;

/**
 * @brief Интерфейс распаковки бинарных данных.
 */
typedef struct {
    // Инициализация курсора (принимает const void*)
    weon_reader_t (WEON_CALL *init)(weon_const_view_t view);

    // Функции чтения
    uint8_t  (WEON_CALL *u8) (weon_reader_t* r);
    uint32_t (WEON_CALL *u32)(weon_reader_t* r);
    uint64_t (WEON_CALL *u64)(weon_reader_t* r);
    float    (WEON_CALL *f32)(weon_reader_t* r);
    
    // ZERO-COPY: Возвращает прямой указатель в буфер
    const char* (WEON_CALL *str)(weon_reader_t* r, uint32_t* out_len);
    const void* (WEON_CALL *raw)(weon_reader_t* r, uint32_t* out_len);

} weon_deserializer_api_t;

#ifdef __cplusplus
}
#endif

#endif /* WEON_CORE_DESERIALIZER_H */