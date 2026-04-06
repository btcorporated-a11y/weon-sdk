#ifndef WEON_CORE_TYPES_H
#define WEON_CORE_TYPES_H

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

// --- ABI макросы (для правильной работы DLL/SO на разных ОС) ---
#if defined(_WIN32) || defined(__CYGWIN__)
    #define WEON_CALL   __cdecl
    #define WEON_EXPORT __declspec(dllexport)
    #define WEON_IMPORT __declspec(dllimport)
#elif defined(__GNUC__) || defined(__clang__)
    #define WEON_CALL   
    #define WEON_EXPORT __attribute__((visibility("default")))
    #define WEON_IMPORT 
#else
    #define WEON_CALL
    #define WEON_EXPORT
    #define WEON_IMPORT
#endif

#ifdef __cplusplus
extern "C" {
#endif

// --- МАГИЯ: Forward Declaration ---
// Говорим компилятору: "Такая структура существует, подробности будут позже"
typedef struct weon_api_t weon_api_t;

// Универсальный тип для хэшей (namespace_id, alias_id, cmd_hash)
typedef uint64_t weon_hash_t;

// --- Статусы выполнения ---
typedef enum {
    WEON_STATUS_OK                = 0,  // Успех
    WEON_STATUS_ERROR             = 1,  // Общая внутренняя ошибка
    WEON_STATUS_NOT_SUPPORTED     = 2,  // Операция не поддерживается
    WEON_STATUS_INVALID_ARGUMENTS = 3,  // Переданы неверные данные или NULL
    WEON_STATUS_PENDING           = 4,  // В процессе (асинхронно)
    WEON_STATUS_NOT_FOUND         = 5,  // Объект или буфер не найден
    WEON_STATUS_ACCESS_DENIED     = 6,  // Отказ в доступе (например, чужой Namespace)
    WEON_STATUS_VERSION_MISMATCH  = 7   // Несовпадение версий ABI
} weon_status_t;

/**
 * @brief Универсальное представление памяти для ЗАПИСИ (Mutable View).
 * Если данных нет (ошибка доступа или нехватки памяти), data = NULL, size = 0.
 */
typedef struct {
    uint8_t* data;
    uint32_t size;
} weon_view_t;

/**
 * @brief Универсальное представление памяти только для ЧТЕНИЯ (Const View).
 */
typedef struct {
    const uint8_t* data; // CONST: компилятор не даст изменить эти байты!
    uint32_t size;
} weon_const_view_t;

#ifdef __cplusplus
}
#endif

#endif /* WEON_CORE_TYPES_H */