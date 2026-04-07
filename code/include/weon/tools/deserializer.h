/**
 * @file deserializer.h
 * @brief Zero-Copy Binary Deserializer
 * * Provides a lightweight cursor-based reader for unpacking binary data.
 * Designed for high-speed data extraction directly from Shared State or 
 * Command Bus buffers without intermediate allocations.
 * * @copyright Copyright (c) 2026 WeOn SDK
 */

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
 * @brief Lightweight Read-Only Cursor (Reader).
 * * The data pointer is strictly 'const', ensuring that memory cannot be 
 * modified during the deserialization process.
 */
typedef struct {
    const uint8_t* data; /** Pointer to the source buffer (Read-Only) */
    uint32_t size;       /** Total size of available data */
    uint32_t pos;        /** Current reading offset */
    bool has_error;      /** Set to true if an out-of-bounds read is attempted */
} weon_reader_t;

/**
 * @brief Binary Unpacking API.
 */
typedef struct {
    /** * @brief Initializes a reader cursor from a constant memory view.
     */
    weon_reader_t (WEON_CALL *init)(weon_const_view_t view);

    // --- Basic Type Extraction (Moves the cursor forward) ---
    
    uint8_t  (WEON_CALL *u8) (weon_reader_t* r);
    uint32_t (WEON_CALL *u32)(weon_reader_t* r);
    uint64_t (WEON_CALL *u64)(weon_reader_t* r);
    float    (WEON_CALL *f32)(weon_reader_t* r);
    
    /** * @brief ZERO-COPY String Extraction.
     * Returns a direct pointer to the string within the source buffer.
     * @param out_len Pointer to store the extracted string length.
     */
    const char* (WEON_CALL *str)(weon_reader_t* r, uint32_t* out_len);
    
    /** * @brief ZERO-COPY Raw Data Extraction.
     * Returns a direct pointer to a memory segment within the source buffer.
     * @param out_len Pointer to store the segment length.
     */
    const void* (WEON_CALL *raw)(weon_reader_t* r, uint32_t* out_len);

} weon_deserializer_api_t;

#ifdef __cplusplus
}
#endif

#endif /* WEON_CORE_DESERIALIZER_H */