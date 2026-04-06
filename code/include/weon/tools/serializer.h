#ifndef WEON_CORE_SERIALIZER_H
#define WEON_CORE_SERIALIZER_H

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

#include "../core/types.h"

#ifdef __cplusplus
extern "C" {
#endif

/**
 * @brief Легковесный курсор для записи (Писатель).
 */
typedef struct {
    uint8_t* data;       // Указатель для записи
    uint32_t capacity;   // Максимальный размер (защита от переполнения)
    uint32_t pos;        // Текущая позиция курсора
    bool has_error;      // Флаг ошибки (если места не хватило)
} weon_writer_t;

/**
 * @brief Интерфейс упаковки бинарных данных.
 */
typedef struct {
    // Инициализация курсора
    weon_writer_t (WEON_CALL *init)(weon_view_t view);

    // Функции записи (сдвигают pos вперед)
    void (WEON_CALL *u8) (weon_writer_t* w, uint8_t v);
    void (WEON_CALL *u32)(weon_writer_t* w, uint32_t v);
    void (WEON_CALL *u64)(weon_writer_t* w, uint64_t v);
    void (WEON_CALL *f32)(weon_writer_t* w, float v);
    
    // Записывает длину (u32) + символы
    void (WEON_CALL *str)(weon_writer_t* w, const char* str, uint32_t len);
    
    // Запись сырого бинарного куска
    void (WEON_CALL *raw)(weon_writer_t* w, const void* data, uint32_t len);

} weon_serializer_api_t;

#ifdef __cplusplus
}
#endif

#endif /* WEON_CORE_SERIALIZER_H */