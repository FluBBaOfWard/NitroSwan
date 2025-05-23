// Bandai WonderSwan Internal EEPROM

#ifndef INT_EEPROM_HEADER
#define INT_EEPROM_HEADER

#ifdef __cplusplus
extern "C" {
#endif

// Font order = " 0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZhn+-?." h=heart, n=note.
// Values are 0x00-0x2A
// Starts at 0x60, size 0x20.
typedef struct {
	u8 name[16];
	u8 birthYear[2];	// BCD encoded BIG endian
	u8 birthMonth;		// BCD encoded
	u8 birthDay;		// BCD encoded
	u8 sex;				// 0 = ?, 1 = male, 2 = female
	u8 bloodType;		// 0 = ?, 1 = A, 2 = B, 3 = O, 4 = AB
	u8 publisher;		// Copy of ROM header field Publisher ID from the previous boot
	u8 color;			// Copy of ROM header field Color from the previous boot
	u8 gameId;			// Copy of ROM header field Game ID from the previous boot
	u8 unknown[3];		// (Unknown)
	u8 gameChgCount;	// Number of times the cartridge has been changed
	u8 nameChgCount;	// Number of times the owner name has been changed
	u16 bootCount;		// Number of times the system has booted
}  WSUserData;

// Starts at 0x80
typedef struct {
	u8 padding[3];
	u8 consoleFlags;	// Bit 0 & 1 = Volume, bit 6 = High Contrast (WSC), bit 7 = Custom Boot.
	u8 consoleNameColor;
	u8 padding2;		// Must be 0
	u8 size;
	u8 startFrame;
	u8 endFrame;
	u8 spriteCount;
	u8 paletteFlags;
	u8 tilesCount;
	u16 paletteOffset;
	u16 tilesetOffset;
	// 0x90
	u16 tilemapOffset;
	u16 horizontalTilemapDestOffset;
	u16 verticalTilemapDestOffset;
	u8 tilemapWidth;
	u8 tilemapHeight;
	u32 splashCodePointer;
	u8 consoleNameHorizontalPosX;
	u8 consoleNameHorizontalPosY;
	u8 consoleNameVerticalPosX;
	u8 consoleNameVerticalPosY;
	// 0xA0
	u8 padding3[2];
	u16 soundSampleOffset;
	u16 soundChannelDataOffset[5];
	u8 crystalLCD70;	// 0xD0
	u8 crystalLCD71;	// 0x77
	// 0xB0
	u8 crystalLCD72;	// 0xF7
	u8 crystalLCD73;	// 0x06
	u8 crystalLCD74;	// 0xE2
	u8 crystalLCD75;	// 0x0A
	u8 crystalLCD76;	// 0xEA
	u8 crystalLCD77;	// 0xEE
} WSBootSplash;

typedef struct {
	u8 programData[0x60];
	WSUserData userData;
	WSBootSplash splashData;
	u8 memBank1[];
} IntEEPROM;

#ifdef __cplusplus
} // extern "C"
#endif

#endif // INT_EEPROM_HEADER
