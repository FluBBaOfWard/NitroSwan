#ifndef WSHEADER
#define WSHEADER

/// WsHeader
typedef struct
{
	const u8  resetCode[6];		// 0x00 - 0x05
	const u8  developer;		// 0x06
	const u8  system;			// 0x07, 0x00 = B&W, 0x01 = Color.
	const u8  cartId;			// 0x08
	const u8  cartRev;			// 0x09
	const u8  romSize;			// 0x0A
	const u8  nvramSize;		// 0x0B
	const u8  orientation;		// 0x0C, bit 0-1 = orientation, bit 2=1.
	const u8  rtc;				// 0x0D, 0x01 = RTC.
	const u16 checksum;			// 0x0E - 0x0F
} WsHeader;

#endif	// WSHEADER
