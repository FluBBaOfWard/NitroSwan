#ifndef WSHEADER
#define WSHEADER

/// WsHeader
typedef struct
{
	/// 0x00 - 0x04
	const u8  resetCode[5];
	/// 0x05, bit 7 skip custom boot.
	const u8  maintenace;
	/// 0x06 Publisher ID
	const u8  publisher;
	/// 0x07, 0x00 = B&W, 0x01 = Color.
	const u8  color;
	/// 0x08
	const u8  gameId;
	/// 0x09, bit 0-6 rev, bit 7 = don't set the internal EEPROM into write-protected mode.
	const u8  gameRev;
	/// 0x0A
	const u8  romSize;
	/// 0x0B
	const u8  nvramSize;
	/// 0x0C, bit 0=orientation, bit 1=8bit bus, bit 2= cyc Rom access.
	const u8  flags;
	/// 0x0D, 0x01 = Luxsor2003 (RTC).
	const u8  mapper;
	/// 0x0E - 0x0F
	const u16 checksum;
} WsHeader;

typedef enum {
	ROM_SIZE_1MBIT = 0,
	ROM_SIZE_2MBIT,
	ROM_SIZE_4MBIT,
	ROM_SIZE_8MBIT,
	ROM_SIZE_16MBIT,
	ROM_SIZE_24MBIT,
	ROM_SIZE_32MBIT,
	ROM_SIZE_48MBIT,
	ROM_SIZE_64MBIT,
	ROM_SIZE_128MBIT,
	ROM_SIZE_256MBIT,
} WsRomSize;

typedef enum {
	NO_SAVE = 0,
	SRAM_64KBIT,
	SRAM_256KBIT,
	SRAM_1MBIT,
	SRAM_2MBIT,
	SRAM_4MBIT,
	EEPROM_1KBIT = 0x10,
	EEPROM_16BIT = 0x20,
	EEPROM_8BIT = 0x50,
} SaveType;

#endif	// WSHEADER
