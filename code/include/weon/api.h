/**
 * @file api.h
 * @brief WeOn SDK Master Interface (The Core API)
 * * This header aggregates all SDK subsystems into a single entry point.
 * A pointer to the weon_api_t structure is passed to every plugin 
 * during the 'on_init' lifecycle stage, granting access to the entire engine.
 * * @copyright Copyright (c) 2026 WeOn SDK
 */

#ifndef WEON_CORE_API_H
#define WEON_CORE_API_H

// --- Standard definitions and base types ---
#include "weon/core/types.h"

// --- Utility Layer ---
#include "weon/tools/hash.h"
#include "weon/tools/log.h"

// --- Data Transformation Layer ---
#include "weon/tools/serializer.h"
#include "weon/tools/deserializer.h"

// --- Resource & Memory Management Layer ---
#include "weon/core/sharedState.h"
#include "weon/core/sharedRequest.h"

#ifdef __cplusplus
extern "C" {
#endif

/**
 * @brief The Central API Table.
 * * Organizes the SDK into logical modules. Each field is a pointer to a 
 * specialized manager interface, ensuring a clean and stable ABI.
 */
struct weon_api_t {
    // ------------------------------------------------------------------------
    // 1. CORE UTILITIES (The Infrastructure Layer)
    // ------------------------------------------------------------------------
    
    /** High-performance string hashing (FNV-1a 64-bit) */
    const weon_hash_api_t* hash;  
    
    /** Thread-safe logging with severity levels and module tagging */
    const weon_log_api_t* log;   

    // ------------------------------------------------------------------------
    // 2. RESOURCE MANAGERS (The Memory & State Layer)
    // ------------------------------------------------------------------------
    
    /** Persistent named memory blocks and cross-module state sharing */
    const weon_state_manager_t* state;   
    
    /** High-speed command buses for streaming data between plugins and host */
    const weon_request_manager_t* request; 

    // ------------------------------------------------------------------------
    // 3. TOOLING (The Data Serialization Layer)
    // ------------------------------------------------------------------------
    
    /** Binary data packer (Writer) with overflow protection */
    const weon_serializer_api_t* serializer;   
    
    /** Zero-copy binary unpacker (Reader) for rapid data extraction */
    const weon_deserializer_api_t* deserializer; 
};

#ifdef __cplusplus
}
#endif

#endif /* WEON_CORE_API_H */