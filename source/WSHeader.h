#ifndef WSHEADER
#define WSHEADER

/// WsHeader
typedef struct
{
	u8   developer;			// 0x00
	u8   system;			// 0x01, 0x00 = B&W, 0x10 = Color.
	u8   cartId;			// 0x02
	u8   cartRev;			// 0x03
	u8   romSize;			// 0x04
	u8   nvramSize;			// 0x05
	u8   orientation;		// 0x06, bit 0-1 = orientation, bit 2=1.
	u8   rtc;				// 0x07, 0x01 = RTC.
	u16  checksum;			// 0x08 - 0x09
} WsHeader;

#endif	// WSHEADER
