////////////////////////////////////////////////////////////////////////////////
// Copyright (C) 2013-2026 Efinix Inc. All rights reserved.
// Full license header bsp/efinix/EfxSapphireSocRV64/include/LICENSE.MD
////////////////////////////////////////////////////////////////////////////////

#ifndef SRC_USERDEF_H_
#define SRC_USERDEF_H_

#ifdef __cplusplus
extern "C" {
#endif

/* -----------------------------------------------------------------------------*/
/* User Configuration                         	        	
/* -----------------------------------------------------------------------------**/

/* -----------------------------------------------------------------------------*/
/*  USER DEBUG CONFIGURATION
/* -----------------------------------------------------------------------------*/
// --- DEBUG_MODE --- 
    // 0 = Asserts OFF, Logs removed
    // 1 = Asserts ON, Logs filtered
#define DEBUG_MODE 1
// --- ACTIVE_DEBUG_MOD --- This is the list of available module to debug
#define ACTIVE_DEBUG_MOD   DBG_MOD_ALL

// --- ACTIVE_MIN_LVL ---
    // DBG_LVL_ALL     0   // Show Info, Warn, Error
    // DBG_LVL_WARN    1   // Show Warn, Error
    // DBG_LVL_ERR     2   // Show Error only
    // DBG_LVL_NONE    3   // Silence
#define ACTIVE_MIN_LVL   DBG_LVL_WARN


#ifdef __cplusplus
}
#endif // C_plusplus

#endif /* SRC_USERDEF_H_ */
