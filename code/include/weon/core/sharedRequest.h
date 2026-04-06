#ifndef WEON_CORE_SHARED_REQUEST_H
#define WEON_CORE_SHARED_REQUEST_H

#include <stddef.h>
#include <stdint.h>
#include "types.h"

#ifdef __cplusplus
extern "C" {
#endif

// Координаты буфера (для защиты и маршрутизации)
typedef struct {
    weon_hash_t requestor_id; // ID плагина
    weon_hash_t buffer_alias; // Имя буфера (например, HASH("render_queue"))
    weon_hash_t namespace_id; // Пространство имен
} weon_buffer_req_t;

// Структура-ответ для Пункта 3 (Чтение)
typedef struct {
    const void* data;       // Прямой указатель на начало команд (CONST - только чтение!)
    uint32_t command_count; // Количество актуальных команд за этот кадр
    uint32_t total_bytes;     // Сколько байт они занимают
} weon_buffer_view_t;

// "Билет" на доступ к буферу. Плагин не видит "внутренностей" трубы.
typedef void* weon_buffer_handle_t;

/**
 * @brief Высокоскоростная шина (Data Bus) для потоковой передачи команд.
 * Архитектура: Много писателей (Клиенты) -> Один читатель (Хост).
 */
typedef struct {
    // ------------------------------------------------------------------------
    // ПУНКТ 1: Создание (Хост)
    // ------------------------------------------------------------------------
    // Хост создает трубу, но не получает указатель на память, только билет (handle).
    weon_buffer_handle_t (WEON_CALL *create_buffer)(const weon_buffer_req_t* req, uint32_t capacity);
    
    // (Дополнение): Клиент по координатам находит трубу и тоже получает билет.
    weon_buffer_handle_t (WEON_CALL *get_buffer)(const weon_buffer_req_t* req);


    // ------------------------------------------------------------------------
    // ПУНКТ 2: Запись команд (Клиент)
    // ------------------------------------------------------------------------
    // Скрипт или плагин запрашивает память под 1 команду. Ядро сдвигает курсор.
    // Возвращаем void*, чтобы плагин сразу скастовал это в struct своей команды.
    weon_view_t (WEON_CALL *reserve_space)(weon_buffer_handle_t handle, weon_hash_t cmd_hash, uint32_t data_size);
    // ------------------------------------------------------------------------
    // ПУНКТ 3: Чтение команд (Хост)
    // ------------------------------------------------------------------------
    // Рендерер берет все команды разом. Ядро возвращает указатель и счетчик.
    weon_buffer_view_t (WEON_CALL *read_buffer)(weon_buffer_handle_t handle);
    
    // (Дополнение): Рендерер всё отрисовал -> сбрасывает курсор в 0 для следующего кадра.
    void (WEON_CALL *clear_buffer)(weon_buffer_handle_t handle);


    // ------------------------------------------------------------------------
    // ПУНКТ 4: Уничтожение (Хост)
    // ------------------------------------------------------------------------
    // Полное затирание буфера и освобождение памяти.
    weon_status_t (WEON_CALL *destroy_buffer)(const weon_buffer_req_t* req);

} weon_request_manager_t;

#ifdef __cplusplus
}
#endif

#endif /* WEON_CORE_SHARED_REQUEST_H */