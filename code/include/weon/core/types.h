/**
 * @file types.h
 * @brief Core ABI Definitions and Common Types
 * * Provides platform-independent macros and base structures for 
 * memory management and error handling across the WeOn SDK.
 * * @copyright Copyright (c) 2026 WeOn SDK
 */

#ifndef WEON_CORE_TYPES_H
#define WEON_CORE_TYPES_H

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

// --- ABI Macros (Ensures correct calling conventions across OS) ---
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

// --- Forward Declarations ---
/** Opaque handle to the main API structure, defined in api.h */
typedef struct weon_api_t weon_api_t;

/** Universal 64-bit hash type for IDs, aliases, and commands */
typedef uint64_t weon_hash_t;

/**
 * @brief Operation Status Codes
 */
typedef enum {
    WEON_STATUS_OK                = 0,  /** Operation successful */
    WEON_STATUS_ERROR             = 1,  /** General internal error */
    WEON_STATUS_NOT_SUPPORTED     = 2,  /** Feature not implemented or supported */
    WEON_STATUS_INVALID_ARGUMENTS = 3,  /** Null pointers or out-of-range values */
    WEON_STATUS_PENDING           = 4,  /** Operation in progress (async) */
    WEON_STATUS_NOT_FOUND         = 5,  /** Target object or buffer missing */
    WEON_STATUS_ACCESS_DENIED     = 6,  /** Permission error (e.g., namespace isolation) */
    WEON_STATUS_VERSION_MISMATCH  = 7   /** Incompatible ABI version */
} weon_status_t;

/**
 * @brief Mutable Memory View (Fat Pointer)
 * Used for WRITING data. If an error occurs (access denied or OOM), 
 * data is set to NULL and size to 0.
 */
typedef struct {
    uint8_t* data;    /** Pointer to the raw byte array */
    uint32_t size;    /** Accessible memory size in bytes */
} weon_view_t;

/**
 * @brief Read-Only Memory View (Const Fat Pointer)
 * Used for READING data. The 'const' qualifier prevents accidental 
 * modifications at the compiler level.
 */
typedef struct {
    const uint8_t* data; /** Pointer to the constant byte array */
    uint32_t size;       /** Data size in bytes */
} weon_const_view_t;

#ifdef __cplusplus
}
#endif

#endif /* WEON_CORE_TYPES_H */