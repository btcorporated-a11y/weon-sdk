/**
 * @file hash.h
 * @brief Fast Hashing Utilities
 * * Provides deterministic string-to-hash conversion using the FNV-1a (64-bit) 
 * algorithm. Essential for generating unique identifiers for namespaces, 
 * aliases, and command hashes with minimal collision risk.
 * * @copyright Copyright (c) 2026 WeOn SDK
 */

#ifndef WEON_CORE_HASH_H
#define WEON_CORE_HASH_H

#include <stdint.h>

#include "../core/types.h"

#ifdef __cplusplus
extern "C" {
#endif

/**
 * @brief Hashing Toolkit Interface.
 * * Used throughout the SDK to map human-readable strings to 64-bit integers 
 * for rapid lookup in internal registries.
 */
typedef struct {
    /**
     * @brief Generates a 64-bit FNV-1a hash from a null-terminated string.
     * * @param str The input string to be hashed.
     * @return weon_hash_t A deterministic 64-bit identifier.
     */
    weon_hash_t (WEON_CALL *fnv1a_64)(const char* str);
    
} weon_hash_api_t;

#ifdef __cplusplus
}
#endif

#endif /* WEON_CORE_HASH_H */