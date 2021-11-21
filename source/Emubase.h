#ifndef EMUBASE
#define EMUBASE

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {				//(config struct)
	char magic[4];				//="CFG",0
	int emuSettings;
	int sleepTime;				// autoSleepTime
	u8 gammaValue;				// from gfx.s
	u8 config;					// from cart.s
	u8 controller;				// from io.s
	u8 name[16];				// Name on start screen
	u8 birthYear[2];			// BCD encoded BIG endian
	u8 birthMonth;				// BCD encoded
	u8 birthDay;				// BCD encoded
	u8 sex;						// 1 = male, 2 = female
	u8 bloodType;				// 1 = A, 2 = B, 3 = O, 4 = AB
	u8 language;
	u8 palette;
	char currentPath[256];
	char biosPath[256];
	char colorBiosPath[256];
} ConfigData;

#ifdef __cplusplus
} // extern "C"
#endif

#endif // EMUBASE
