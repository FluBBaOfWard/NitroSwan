#ifndef WSHEADER
#define WSHEADER

/// WsHeader
typedef struct
{
	char licence[28];		// 0x00 - 0x1B
	u32  startPC;			// 0x1C - 0x1F
	u16  catalog;			// 0x20 - 0x21
	u8   subCatalog;		// 0x22
	u8   mode;				// 0x23, 0x00 = B&W, 0x10 = Color.
	char name[12];			// 0x24 - 0x2F

	u32  reserved1;			// 0x30 - 0x33
	u32  reserved2;			// 0x34 - 0x37
	u32  reserved3;			// 0x38 - 0x3B
	u32  reserved4;			// 0x3C - 0x3F
} WsHeader;

#endif	// WSHEADER
