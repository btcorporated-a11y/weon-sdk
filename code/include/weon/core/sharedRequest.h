/**
 * @file shared_request.h
 * @brief High-Speed Command Bus (Data Bus)
 * * Architecture: Many Writers (Plugins) -> One Reader (Host).
 * Optimized for streaming commands between modules with zero-copy overhead.
 * * @copyright Copyright (c) 2026 WeOn SDK
 */

#ifndef WEON_CORE_SHARED_REQUEST_H
#define WEON_CORE_SHARED_REQUEST_H

#include <stddef.h>
#include <stdint.h>

#include "types.h"

#ifdef __cplusplus
extern "C" {
#endif

/**
 * @brief Buffer Coordinates for routing and security.
 */
typedef struct {
    weon_hash_t requestor_id; /** Plugin unique identifier */
    weon_hash_t buffer_alias; /** Buffer name (e.g., HASH("render_queue")) */
    weon_hash_t namespace_id; /** Target namespace */
} weon_buffer_req_t;

/**
 * @brief Buffer Read Result.
 * Contains a pointer to the command stream and metadata for processing.
 */
typedef struct {
    const void* data;       /** Direct pointer to the start of the command stream (Read-Only) */
    uint32_t command_count; /** Number of active commands in the current frame */
    uint32_t total_bytes;   /** Total memory footprint of the commands */
} weon_buffer_view_t;

/** * @brief Opaque handle to a buffer "pipe". 
 * Plugins interact with this "ticket" without seeing internal implementation.
 */
typedef void* weon_buffer_handle_t;

/**
 * @brief High-Speed Command Bus Manager.
 */
typedef struct {
    // ------------------------------------------------------------------------
    // STAGE 1: Lifecycle & Access
    // ------------------------------------------------------------------------

    /** Host creates a pipe and receives an opaque handle. */
    weon_buffer_handle_t (WEON_CALL *create_buffer)(const weon_buffer_req_t* req, uint32_t capacity);
    
    /** Clients find an existing pipe by coordinates to receive their access handle. */
    weon_buffer_handle_t (WEON_CALL *get_buffer)(const weon_buffer_req_t* req);

    // ------------------------------------------------------------------------
    // STAGE 2: Writing Commands (Client/Plugin)
    // ------------------------------------------------------------------------

    /** * Allocates space for a single command. The core shifts the internal cursor.
     * @param cmd_hash Identifier for the specific command type.
     * @return A View that should be cast to the plugin's specific command struct.
     */
    weon_view_t (WEON_CALL *reserve_space)(weon_buffer_handle_t handle, weon_hash_t cmd_hash, uint32_t data_size);

    // ------------------------------------------------------------------------
    // STAGE 3: Reading & Consumption (Host/Renderer)
    // ------------------------------------------------------------------------

    /** Retrieves all commands at once for batch processing. */
    weon_buffer_view_t (WEON_CALL *read_buffer)(weon_buffer_handle_t handle);
    
    /** Resets the buffer cursor to zero. Called after processing all commands for the frame. */
    void (WEON_CALL *clear_buffer)(weon_buffer_handle_t handle);

    // ------------------------------------------------------------------------
    // STAGE 4: Finalization
    // ------------------------------------------------------------------------

    /** Completely wipes the buffer and releases system memory. */
    weon_status_t (WEON_CALL *destroy_buffer)(const weon_buffer_req_t* req);

} weon_request_manager_t;

#ifdef __cplusplus
}
#endif

#endif /* WEON_CORE_SHARED_REQUEST_H */