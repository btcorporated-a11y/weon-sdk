/**
 * @file shared_state.h
 * @brief Persistent Shared Memory Manager
 * * Allows plugins to allocate and manage named memory blocks (variables) 
 * accessible across different modules. Features ownership protection 
 * and boundary checks via Fat Pointers (Views).
 * * @copyright Copyright (c) 2026 WeOn SDK
 */

#ifndef WEON_CORE_SHARED_STATE_H
#define WEON_CORE_SHARED_STATE_H

#include <stddef.h>
#include <stdint.h>

#include "types.h"

#ifdef __cplusplus
extern "C" {
#endif

// ============================================================================
// DATA STRUCTURES
// ============================================================================

/**
 * @brief State Request Coordinates (Variable Address).
 * Used to identify a specific memory block within the global registry.
 */
typedef struct {
    weon_hash_t requestor_id; /** ID of the calling plugin (for ownership check) */
    weon_hash_t state_alias;  /** Unique name/hash of the variable */
    weon_hash_t namespace_id; /** Target namespace for isolation */
} weon_state_req_t;

// ============================================================================
// MANAGER INTERFACE
// ============================================================================

/**
 * @brief Shared State Manager Interface.
 * * Manages cross-module memory allocation. Uses Zero-Copy principles by 
 * providing direct pointers to allocated RAM.
 */
typedef struct {
    /** * @brief Allocates a new persistent memory block.
     * @return Mutable View for writing. Returns null data if alias is taken.
     */
    weon_view_t (WEON_CALL *create_var)(const weon_state_req_t* req, uint32_t size);
    
    /** * @brief Requests write access to an existing block.
     * @note Only the original owner (requestor_id) can obtain a mutable View.
     */
    weon_view_t (WEON_CALL *update_var)(const weon_state_req_t* req);
    
    /** * @brief Retrieves data for reading.
     * @return Read-Only (Const) View. Accessible by any plugin knowing the coordinates.
     */
    weon_const_view_t (WEON_CALL *read_var)(const weon_state_req_t* req);
    
    /** * @brief Deallocates the variable and frees system memory.
     * @return WEON_STATUS_OK on success, or ACCESS_DENIED if caller is not the owner.
     */
    weon_status_t (WEON_CALL *destroy_var)(const weon_state_req_t* req);

} weon_state_manager_t;

#ifdef __cplusplus
}
#endif

#endif /* WEON_CORE_SHARED_STATE_H */