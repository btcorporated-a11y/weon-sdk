/**
 * @file log.h
 * @brief Thread-Safe Diagnostic Logging Interface
 * * Provides a standardized way for plugins to output debug and operational 
 * messages. Supports runtime severity filtering and module-based tagging.
 * * @copyright Copyright (c) 2026 WeOn SDK
 */

#ifndef WEON_CORE_LOG_H
#define WEON_CORE_LOG_H

#include <stdint.h>
#include "../core/types.h"

#ifdef __cplusplus
extern "C" {
#endif

// ============================================================================
// DATA TYPES
// ============================================================================

/**
 * @brief Logging Severity Levels
 */
typedef enum {
    WEON_LOG_DEBUG = 0, /** Verbose information for development and debugging */
    WEON_LOG_INFO,      /** Standard operational messages */
    WEON_LOG_WARN,      /** Non-critical issues that allow the system to continue */
    WEON_LOG_ERROR,     /** Critical failures requiring immediate attention */
    WEON_LOG_OFF        /** Completely disables all log output */
} weon_log_level_t;


// ============================================================================
// LOGGER INTERFACE (WEON_API -> log)
// ============================================================================

/**
 * @brief Thread-safe Logger Interface.
 */
typedef struct {
    /**
     * @brief Outputs a formatted message to the system console or log file.
     * * @param level Severity level of the message.
     * @param tag   Short module identifier (e.g., "RENDER", "NET", "PHYS").
     * @param msg   Null-terminated string containing the log message.
     */
    void (WEON_CALL *print)(weon_log_level_t level, const char* tag, const char* msg);

    /**
     * @brief Sets the global visibility threshold.
     * * Messages with a severity lower than the specified level will be 
     * discarded by the Core to save performance.
     */
    void (WEON_CALL *set_level)(weon_log_level_t level);

} weon_log_api_t;

#ifdef __cplusplus
}
#endif

#endif /* WEON_CORE_LOG_H */