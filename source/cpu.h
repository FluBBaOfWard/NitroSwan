//
//  cpu.h
//  NitroSwan
//
//  Created by Fredrik Ahlström on 2006-07-23.
//  Copyright © 2006-2026 Fredrik Ahlström. All rights reserved.
//
#ifndef CPU_HEADER
#define CPU_HEADER

#ifdef __cplusplus
extern "C" {
#endif

extern u8 waitMaskIn;
extern u8 waitMaskOut;

void run(void);
void stepFrame(void);
void stepScanLine(void);
void cpuInit(void);
void cpuReset(int type);

#ifdef __cplusplus
} // extern "C"
#endif

#endif // CPU_HEADER
