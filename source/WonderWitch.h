#ifndef WONDERWITCH_HEADER
#define WONDERWITCH_HEADER

#ifdef __cplusplus
extern "C" {
#endif
//                SOH, Page,^Page
// XMODEM Start: 0x01, 0x01, 0xFE

#define PAGE_SIZE (0x80)

/// Start of Heading
#define SOH 0x01
/// Start of Text, used instead of SOH for 1k blocks.
#define STX 0x02
// End of Transfer
#define EOT 0x04
/// Acknowledged
#define ACK 0x06
/// Not Acknowledged
#define NAK 0x15
/// Cancel
#define CAN 0x18
/// Used instead of NAK for CRC-16 instead of byte checksum.
#define C_CHR 0x43

typedef enum {
	standby = 0,
	xmodemReceive,
	xmodemTransmitHold,
	xmodemTransmit,
	debugSerial,
} Mode;

typedef struct {
	u8 startOfHeading;
	u8 page;
	u8 invPage;
	u8 payload[PAGE_SIZE];
	u8 checkSum;
} XModemBlock;

typedef struct {
	/// "#!ws"
	//char magic[4];
	u32 magic;
	u8 ffFill[0x3C];
	char fileName[0x10];
	char description[0x18];
	u32 binaryOffset;
	u32 binarySize;
	u16 blockCount;
	u16 flags;
	/// Seconds since January 1st, 2000.
	u32 modificationTime;
	u32 handler;
	u32 resource;
} FxFile;

/// Sends an ACK to the WS serial port.
void sendAck(void);

/// Sends a NACK to the WS serial port.
void sendNack(void);

/// Start XMODEM receive.
void startXModemReceive(void);

/// Start XMODEM transmit.
void startXModemTransmit(void);

/// Handle serial in empty on WonderSwan.
void handleSerialInEmpty(void);

/// Handle 1 byte from WonderSwan.
void handleSerialReceive(u8 value);

#ifdef __cplusplus
} // extern "C"
#endif

#endif // WONDERWITCH_HEADER
