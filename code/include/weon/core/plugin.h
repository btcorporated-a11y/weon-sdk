/**
 * @file plugin.h
 * @brief WeOn SDK Plugin Interface (ABI Contract)
 * * This file defines the standard interface for creating external plugins.
 * Plugins must export a symbol named WEON_PLUGIN of type weon_plugin_interface_t.
 * * @copyright Copyright (c) 2026 WeOn SDK
 */

#ifndef WEON_PLUGIN_H
#define WEON_PLUGIN_H

#include <stdint.h>
#include <stddef.h>

#include "types.h"

#ifdef __cplusplus
extern "C" {
#endif

/**
 * @brief Plugin Initialization Parameters
 * * During startup, the Core fills the "Input" fields. 
 * The Plugin must read the API pointers and fill the "Output" fields.
 */
typedef struct {
    // --- INPUT (Core to Plugin) ---
    
    /** System-wide tools (Log, RequestManager, etc.) */
    const weon_api_t* api;    
    
    /** Pointer to the Core's array where the plugin registers its commands */
    weon_hash_t* cmd_buffer;  
    
    /** Maximum number of commands the cmd_buffer can hold */
    uint32_t max_cmds;          
    
    // --- OUTPUT (Plugin to Core) ---
    
    /** Plugin must set this to the actual number of commands added to cmd_buffer */
    uint32_t written_cmds;      
} weon_plugin_init_t;

/**
 * @brief Main Plugin ABI Contract
 * * This structure defines the lifecycle of a WeOn plugin.
 */
typedef struct {
    /** Target SDK version for compatibility checks */
    uint32_t sdk_version;

    /** * 1. Initialization 
     * Exchange API pointers and register supported commands.
     */
    weon_status_t (WEON_CALL *on_init)(weon_plugin_init_t* params);

    /** * 2. Instance Creation 
     * Spawns a plugin instance within a specific namespace.
     * @return Opaque pointer to the plugin's internal context.
     */
    void* (WEON_CALL *on_create)(weon_hash_t alias_id, weon_hash_t namespace_id);

    /** * 3. Command Handling 
     * Process incoming events or data requests.
     * @param ctx The context returned by on_create.
     */
    void (WEON_CALL *on_command)(void* ctx, weon_hash_t cmd_hash, weon_hash_t data_handle);

    /** * 4. Shutdown 
     * Cleanup resources and destroy the instance context.
     */
    void (WEON_CALL *on_destroy)(void* ctx);

} weon_plugin_interface_t;

/** The exported symbol name the Core searches for in the DLL/SO */
#define WEON_PLUGIN_EXPORT "WEON_PLUGIN"

#ifdef __cplusplus
}
#endif

#endif /* WEON_PLUGIN_H */