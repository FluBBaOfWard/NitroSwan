//
//  Sound.h
//  NitroSwan
//
//  Created by Fredrik Ahlström on 2006-07-23.
//  Copyright © 2006-2026 Fredrik Ahlström. All rights reserved.
//
#ifndef SOUND_HEADER
#define SOUND_HEADER

#ifdef __cplusplus
extern "C" {
#endif

#include <maxmod9.h>

#define sample_rate 24000
#define buffer_size (640)

void soundInit(void);
void soundSetMuteGUI(void);
void soundSetMuteChip(void);
mm_word soundRender(mm_word length, mm_addr dest, mm_stream_formats format);

#ifdef __cplusplus
} // extern "C"
#endif

#endif // !SOUND_HEADER
