#ifndef WEON_CORE_LOG_H
#define WEON_CORE_LOG_H

#include <stdint.h>
#include "../core/types.h"

#ifdef __cplusplus
extern "C" {
#endif

// ============================================================================
// ТИПЫ ДАННЫХ
// ============================================================================

// Уровни логирования
typedef enum {
    WEON_LOG_DEBUG = 0, // Детальная информация для отладки
    WEON_LOG_INFO,      // Обычные сообщения о работе
    WEON_LOG_WARN,      // Предупреждения (что-то пошло не так, но работаем)
    WEON_LOG_ERROR,     // Критические ошибки
    WEON_LOG_OFF        // Полное отключение логов
} weon_log_level_t;


// ============================================================================
// ИНТЕРФЕЙС ЛОГЕРА (WEON_API -> log)
// ============================================================================

/**
 * @brief Безопасный интерфейс для вывода диагностических сообщений.
 */
typedef struct {
    /**
     * @brief Выводит готовую строку в консоль/файл.
     * @param level Уровень важности.
     * @param tag Короткое имя модуля (например, "RENDER", "NET").
     * @param msg Готовое текстовое сообщение (строго null-terminated).
     */
    void (WEON_CALL *print)(weon_log_level_t level, const char* tag, const char* msg);

    /**
     * @brief Устанавливает глобальный порог вывода сообщений.
     * Все сообщения с уровнем ниже указанного будут проигнорированы Ядром.
     */
    void (WEON_CALL *set_level)(weon_log_level_t level);

} weon_log_api_t;

#ifdef __cplusplus
}
#endif

#endif /* WEON_CORE_LOG_H */