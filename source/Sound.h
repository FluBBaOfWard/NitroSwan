#ifndef SOUND_HEADER
#define SOUND_HEADER

#ifdef __cplusplus
extern "C" {
#endif

#include <maxmod9.h>
#include "K2Audio/SN76496.h"

extern SN76496 k2Audio_0;
void soundInit(void);
void setMuteSoundGUI(void);
mm_word VblSound2(mm_word length, mm_addr dest, mm_stream_formats format);

#ifdef __cplusplus
} // extern "C"
#endif

#endif // SOUND_HEADER
