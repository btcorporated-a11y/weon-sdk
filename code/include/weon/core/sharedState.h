#ifndef WEON_CORE_SHARED_STATE_H
#define WEON_CORE_SHARED_STATE_H

#include <stddef.h>
#include <stdint.h>
#include "types.h"

#ifdef __cplusplus
extern "C" {
#endif

// ============================================================================
// СТРУКТУРЫ ДАННЫХ
// ============================================================================

/**
 * @brief Структура запроса к менеджеру состояний (Адрес переменной).
 */
typedef struct {
    weon_hash_t requestor_id; // ID плагина
    weon_hash_t state_alias;  // Имя переменной
    weon_hash_t namespace_id; // Пространство имен
} weon_state_req_t;

// ============================================================================
// ИНТЕРФЕЙС МЕНЕДЖЕРА
// ============================================================================

/**
 * @brief Позволяет плагинам выделять "статичную" память, доступную другим.
 * Теперь с защитой от переполнения буфера (Fat Pointers).
 */
typedef struct {
    // Творец резервирует память. Возвращает View для записи.
    weon_view_t (WEON_CALL *create_var)(const weon_state_req_t* req, uint32_t size);
    
    // Творец запрашивает обновление. Возвращает View для записи.
    weon_view_t (WEON_CALL *update_var)(const weon_state_req_t* req);
    
    // Читатель запрашивает данные. Возвращает CONST View для чтения.
    weon_const_view_t (WEON_CALL *read_var)(const weon_state_req_t* req);
    
    // Удаление переменной
    weon_status_t (WEON_CALL *destroy_var)(const weon_state_req_t* req);

} weon_state_manager_t;

#ifdef __cplusplus
}
#endif

#endif /* WEON_CORE_SHARED_STATE_H */