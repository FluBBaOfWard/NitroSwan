#ifndef MEMORY_HEADER
#define MEMORY_HEADER

#ifdef __cplusplus
extern "C" {
#endif

#include <nds.h>

void cpuWriteByte(u32 addr, u8 value);
u8 cpuReadByte(u32 addr);

#ifdef __cplusplus
} // extern "C"
#endif

#endif	// MEMORY_HEADER
