/**
 * @file version.h
 * @brief SDK Versioning and Compatibility Guard
 * * Provides macros and structures to ensure binary compatibility between 
 * the Core and external Plugins. Uses a packed 32-bit ID for fast checks.
 * * @copyright Copyright (c) 2026 WeOn SDK
 */

#ifndef WEON_CORE_VERSION_H
#define WEON_CORE_VERSION_H

#include <stdint.h>

#include "types.h"

// --- SDK Version Constants ---
#define WEON_SDK_VERSION_MAJOR 2
#define WEON_SDK_VERSION_MINOR 0
#define WEON_SDK_VERSION_PATCH 0
#define WEON_SDK_VERSION_STR   "2.0.0-alpha"

/**
 * @brief Packs version components into a single 32-bit integer.
 * Format: 0xMMmmPP00 (Major, Minor, Patch, Reserved)
 * Allows for lightning-fast compatibility checks at runtime.
 */
#define WEON_MAKE_VERSION(major, minor, patch) \
    ((((uint32_t)(major) & 0xFF) << 24) |      \
     (((uint32_t)(minor) & 0xFF) << 16) |      \
     (((uint32_t)(patch) & 0xFF) << 8))

/** Current SDK Version ID to be embedded into plugins during compilation */
#define WEON_SDK_VERSION_ID WEON_MAKE_VERSION(WEON_SDK_VERSION_MAJOR, \
                                              WEON_SDK_VERSION_MINOR, \
                                              WEON_SDK_VERSION_PATCH)

#ifdef __cplusplus
extern "C" {
#endif

/**
 * @brief Version Metadata API
 * Provided via the main API structure for runtime version introspection.
 */
typedef struct {
    uint32_t major;         /** Major version (breaking API changes) */
    uint32_t minor;         /** Minor version (new features, backward compatible) */
    uint32_t patch;         /** Patch version (bug fixes only) */
    const char* full_str;   /** Full version string (e.g., "2.0.0-alpha") */
    
    /** Returns the packed ID of the running Core for comparison with Plugin ID */
    uint32_t (*get_id)(void);
} weon_version_api_t;

// --- Direct Exported Calls ---

/** Returns the packed version ID directly from the Core DLL/SO */
WEON_EXPORT uint32_t WEON_CALL weon_get_version_id(void);

/** Returns the full version string directly from the Core DLL/SO */
WEON_EXPORT const char* WEON_CALL weon_get_version_string(void);

#ifdef __cplusplus
}
#endif

#endif /* WEON_CORE_VERSION_H */