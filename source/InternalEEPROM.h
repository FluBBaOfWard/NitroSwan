// Bandai WonderSwan Internal EEPROM

#ifndef INT_EEPROM_HEADER
#define INT_EEPROM_HEADER

#ifdef __cplusplus
extern "C" {
#endif

// Font order = " 0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZhn+-?." h=heart, n=note.
// Values are 0x00-0x2A
// Starts at 0x60
struct userdata_t
{
	uint8_t name[16];
	uint8_t birthYear[2];	// BCD encoded BIG endian
	uint8_t birthMonth;		// BCD encoded
	uint8_t birthDay;		// BCD encoded
	uint8_t sex;			// 0 = ?, 1 = male, 2 = female
	uint8_t bloodType;		// 0 = ?, 1 = A, 2 = B, 3 = O, 4 = AB
	uint8_t publisher;		// Copy of ROM header field Publisher ID from the previous boot
	uint8_t color;			// Copy of ROM header field Color from the previous boot
	uint8_t gameID;			// Copy of ROM header field Game ID from the previous boot
	uint8_t unknown0[3];	// (Unknown)
	uint8_t gameChgCount;	// Number of times the cartridge has been changed
	uint8_t nameChgCount;	// Number of times the owner name has been changed
	uint16_t bootCount;		// Number of times the system has booted
};

// Starts at 0x80
struct bootsplash_t
{
	uint8_t padding[3];
	uint8_t consoleFlags;		// Bit 0 & 1 = Volume, bit 6 = High Contrast (WSC), bit 7 = Custom Boot.
	uint8_t consoleNameColor;
	uint8_t padding2;
	uint8_t size;
	uint8_t startFrame;
	uint8_t endFrame;
	uint8_t spriteCount;
	uint8_t paletteFlags;
	uint8_t tilesCount;
	uint16_t paletteOffset;
	uint16_t tilesetOffset;
	uint16_t tilemapOffset;
	uint16_t horizontalTilemapDestOffset;
	uint16_t verticalTilemapDestOffset;
	uint8_t tilemapWidth;
	uint8_t tilemapHeight;
	uint32_t splashCodePointer;
	uint8_t consoleNameHorizontalPosX;
	uint8_t consoleNameHorizontalPosY;
	uint8_t consoleNameVerticalPosX;
	uint8_t consoleNameVerticalPosY;
	uint8_t padding3[2];
	uint16_t soundSampleOffset;
	uint16_t soundChannelDataOffset[]
};

typedef struct {
	u8 memBank0[];
	u8 memBank1[];
} INTEEPROM;

#ifdef __cplusplus
} // extern "C"
#endif

#endif // INT_EEPROM_HEADER
