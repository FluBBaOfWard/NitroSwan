#ifndef WSHEADER
#define WSHEADER

/// WsHeader
typedef struct
{
	u8   resetCode[6];		// 0x00 - 0x05
	u8   developer;			// 0x06
	u8   system;			// 0x07, 0x00 = B&W, 0x10 = Color.
	u8   cartId;			// 0x08
	u8   cartRev;			// 0x09
	u8   romSize;			// 0x0A
	u8   nvramSize;			// 0x0B
	u8   orientation;		// 0x0C, bit 0-1 = orientation, bit 2=1.
	u8   rtc;				// 0x0D, 0x01 = RTC.
	u16  checksum;			// 0x0E - 0x0F
} WsHeader;

#endif	// WSHEADER
