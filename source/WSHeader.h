#ifndef WSHEADER
#define WSHEADER

/// WsHeader
typedef struct
{
	const u8  resetCode[5];		// 0x00 - 0x04
	const u8  maintenace;		// 0x05, bit 7 skip custom boot.
	const u8  publisher;		// 0x06
	const u8  system;			// 0x07, 0x00 = B&W, 0x01 = Color.
	const u8  gameId;			// 0x08
	const u8  gameRev;			// 0x09, bit 0-6 rev, bit 7 = don't set the internal EEPROM into write-protected mode.
	const u8  romSize;			// 0x0A
	const u8  nvramSize;		// 0x0B
	const u8  orientation;		// 0x0C, bit 0=orientation, bit 1=8bit bus, bit 2=3 cyc Rom access.
	const u8  rtc;				// 0x0D, 0x01 = RTC.
	const u16 checksum;			// 0x0E - 0x0F
} WsHeader;

#endif	// WSHEADER
