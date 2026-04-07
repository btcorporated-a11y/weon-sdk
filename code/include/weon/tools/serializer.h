/**
 * @file serializer.h
 * @brief High-Performance Binary Serializer
 * * Provides a lightweight, cursor-based API for packing data into binary buffers.
 * Includes built-in overflow protection and is optimized for zero-copy 
 * data preparation within the WeOn ecosystem.
 * * @copyright Copyright (c) 2026 WeOn SDK
 */

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
 * @brief Lightweight Write-Only Cursor (Writer).
 * * Manages the current position within a memory buffer and tracks 
 * potential overflow errors.
 */
typedef struct {
    uint8_t* data;       /** Pointer to the destination buffer */
    uint32_t capacity;   /** Maximum buffer size (overflow protection) */
    uint32_t pos;        /** Current writing offset */
    bool has_error;      /** Set to true if a write exceeds capacity */
} weon_writer_t;

/**
 * @brief Binary Packing API.
 */
typedef struct {
    /** * @brief Initializes a writer cursor from a mutable memory view.
     */
    weon_writer_t (WEON_CALL *init)(weon_view_t view);

    // --- Primitive Type Injection (Moves the cursor forward) ---

    void (WEON_CALL *u8) (weon_writer_t* w, uint8_t v);
    void (WEON_CALL *u32)(weon_writer_t* w, uint32_t v);
    void (WEON_CALL *u64)(weon_writer_t* w, uint64_t v);
    void (WEON_CALL *f32)(weon_writer_t* w, float v);
    
    /** * @brief Serializes a string as Length-Prefixed (u32 length + characters).
     * @param len Number of bytes to write (excluding null terminator).
     */
    void (WEON_CALL *str)(weon_writer_t* w, const char* str, uint32_t len);
    
    /** * @brief Writes a raw binary block to the buffer.
     */
    void (WEON_CALL *raw)(weon_writer_t* w, const void* data, uint32_t len);

} weon_serializer_api_t;

#ifdef __cplusplus
}
#endif

#endif /* WEON_CORE_SERIALIZER_H */