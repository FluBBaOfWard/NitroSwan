#ifndef MEMORY_HEADER
#define MEMORY_HEADER

#ifdef __cplusplus
extern "C" {
#endif

#include <nds.h>

u8 cpuReadMem20(u32 addr);
u16 cpuReadMem20W(u32 addr);
u16 dmaReadMem20W(u32 addr);
void cpuWriteMem20(u32 addr, u8 value);
void cpuWriteMem20W(u32 addr, u16 value);
void dmaWriteMem20W(u32 addr, u16 value);

#ifdef __cplusplus
} // extern "C"
#endif

#endif	// MEMORY_HEADER
