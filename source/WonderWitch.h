//
//  WonderWitch.h
//  WonderWitch utility functions.
//
//  Created by Fredrik Ahlström on 2024-09-01.
//  This is public domain, no copyright no warranty.
//  Write it, cut it, paste it, save it
//  Load it, check it, quick – rewrite it
//  Name it, read it, tune it, print it
//  Scan it, send it, fax – rename it
//

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
/// New Line
#define NL 0x0A
/// Caridge Return
#define CR 0x0D
/// Not Acknowledged
#define NAK 0x15
/// Cancel
#define CAN 0x18
/// Used instead of NAK for CRC-16 instead of byte checksum.
#define C_CHR 0x43

typedef enum {
	rom0 = 0,
	ram0,
	kern,
} Storage;

typedef enum {
	standby = 0,
	wwSendCommand,
	wwReceiveCommand,
	wwReceiveText,
	xmodemTransmitHold,
	xmodemTransmit,
	xmodemReceive,
	debugSerial,
} Mode;

typedef enum {
	wwCmdNone = 0,
	wwCmdStty,
	wwCmdInt,
	wwCmdHello,
	wwCmdPut,
	wwCmdSend,
	wwCmdGet,
	wwCmdDelete,
	wwCmdExec,
	wwCmdReboot,
	wwCmdDir,
	wwCmdDf,
	wwCmdNewFS,
	wwCmdDefrag,
	wwCmdRename,
	wwCmdSpeed,
	wwCmdDate,
	wwCmdCopy,
	wwCmdMove,
	wwCmdSetInfo,
	wwCmdChMod,
	wwCmdCD,
	wwCmdPwd,
} WWCmd;

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

/// Change between rom0 & ram0 storage on the WW.
void wwChangeStorage(void);

/// Get the currant storage as a string.
const char *wwGetStorageText(void);

/// Start Hello command.
void wwStartStty(void);

/// Start Interactive command.
void wwStartInteract(void);

/// Start Hello command.
void wwStartHello(void);

/// Start Put command.
void wwStartPut(void);

/// Start Get command.
void wwStartGet(void);

/// Start Delete command.
void wwStartDelete(void);

/// Start Exec command.
void wwStartExec(void);

/// Start Reboot command.
void wwStartReboot(void);

/// Start Ls command.
void wwStartLs(void);

/// Start Dir command.
void wwStartDir(void);

/// Start DF command.
void wwStartDF(void);

/// Start New File System command.
void wwStartNewFS(void);

/// Start Defrag command.
void wwStartDefrag(void);

/// Start Rename command.
void wwStartRename(void);

/// Start Speed command.
void wwStartSpeed(void);

/// Start Date command.
void wwStartDate(void);

/// Start Copy command.
void wwStartCopy(void);

/// Start Move command.
void wwStartMove(void);

/// Start SetInfo command.
void wwStartSetInfo(void);

/// Start ChMod command.
void wwStartChMod(void);

/// Start CD command.
void wwStartCD(void);

/// Start Pwd command.
void wwStartPwd(void);

/// Start XMODEM transmit.
void startXModemTransmit(void);

/// Start XMODEM receive.
void startXModemReceive(void);

/// Handle serial in empty on WonderSwan.
void handleSerialInEmpty(void);

/// Handle 1 byte from WonderSwan.
void handleSerialReceive(u8 value);

#ifdef __cplusplus
} // extern "C"
#endif

#endif // WONDERWITCH_HEADER
