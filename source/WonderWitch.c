//
//  WonderWitch.c
//  WonderWitch utility functions.
//
//  Created by Fredrik Ahlström on 2024-09-01.
//  This is public domain, no copyright no warranty.
//  Write it, cut it, paste it, save it
//  Load it, check it, quick – rewrite it
//  Name it, read it, tune it, print it
//  Scan it, send it, fax – rename it
//

#include <nds.h>
#include <stdio.h>
#include <time.h>
#include <sys/stat.h>

#include "Shared/EmuMenu.h"
#include "WonderWitch.h"
#include "Gui.h"
#include "Gfx.h"

FILE *file = NULL;

int counter = 0;
int prevPage = 0;
int fileSize = 0;
int pageCount = 0;
Mode mode = standby;
WWCmd wwCmd = wwCmdNone;
Storage storage = rom0;
bool serialInEmpty = false;
u8 checksum = 0;
u8 outIdx = 0;
u8 inIdx = 0;
//static const char lineFeed[3] = {CR, NL, 0x0};
static const char lineFeed[2] = {CR, 0x0};
static const char *const storText[]  = {"/rom0", "/ram0", "/kern"};
const char *currentFileName;
const char *selectedFile;
char outBuf[PAGE_SIZE];
u8 buffer[PAGE_SIZE];
char txtBuf[0x400];
char wwDir[FILEPATH_MAX_LENGTH];

void wwChangeStorage() {
	storage += 1;
	if (storage > kern) {
		storage = rom0;
	}
}

const char *wwGetStorageText() {
	return storText[storage];
}

static bool sendByte(u8 value) {
	if (serialInEmpty) {
		serialInEmpty = false;
		setSerialByteIn(value);
		return true;
	}
	return false;
}

/// Sends a NACK to the WS serial port.
static void sendNack(void) {
	sendByte(NAK);
}

/// Sends an ACK to the WS serial port.
static void sendAck(void) {
	sendByte(ACK);
}

static void sendCommand() {
	u8 val = outBuf[outIdx];
	if (val == 0) {
		mode = wwReceiveCommand;
		outIdx = 0;
		outBuf[outIdx] = 0;
		return;
	}
	if (sendByte(val)) {
		outIdx += 1;
	}
}

static void doXModemTransmit(void) {
	mode = xmodemTransmitHold;
	counter = 0;
	prevPage = 0;
}

static void receiveBuffer(u8 val) {
	buffer[inIdx] = val;
	inIdx += 1;
	if (val == NL) {
		buffer[inIdx] = 0;
		if (strstr((char *)buffer, "125 STARTING")) {
			if (wwCmd == wwCmdGet) {
				startXModemReceive();
			}
			else {
				// Receive data
				mode = wwReceiveText;
				inIdx = 0;
			}
		}
		else if (strstr((char *)buffer, "350 FURTHER INFO")) {
			if (wwCmd == wwCmdPut) {
				doXModemTransmit();
			}
		}
		else if (strstr((char *)buffer, "200 OK")) {
			if (wwCmd == wwCmdDir) {
				selectedFile = browseDirectory();
				cls(0);
			}
			inIdx = 0;
			buffer[inIdx] = 0;
			wwCmd = wwCmdNone;
		}
		else if (strstr((char *)buffer, "426 TRANSFER ABORTED")
				 || strstr((char *)buffer, "450 NOT AVAILABLE")
				 || strstr((char *)buffer, "451 LOCAL ERR")
				 || strstr((char *)buffer, "452 FS FULL")
				 || strstr((char *)buffer, "501 SYNTAX ERR")
				 || strstr((char *)buffer, "502 NOT IMPLEMENTED")
				 || strstr((char *)buffer, "504 NOT IMPLEMENTED")
				 || strstr((char *)buffer, "550 NOT AVAILABLE")
				 || strstr((char *)buffer, "553 NOT AVAILABLE")) {
			inIdx = 0;
			buffer[inIdx] = 0;
			wwCmd = wwCmdNone;
		}
	}
}

static void receiveText(u8 val) {
	txtBuf[inIdx] = val;
	inIdx += 1;
	if (val == NL) {
		txtBuf[inIdx-1] = 0;
		if (txtBuf[inIdx-2] == CR) {
			txtBuf[inIdx-2] = 0;
		}
		if (!strcmp(txtBuf, ".")) {
			mode = wwReceiveCommand;
		}
		else {
			if (wwCmd == wwCmdDir) {
				if (!strnstr(txtBuf, "total ", 6)){
					inIdx = 16;
					while (txtBuf[inIdx] == 0x20) {
						inIdx -= 1;
					}
					txtBuf[inIdx+1] = 0;
					browseAddFilename(txtBuf);
				}
			}
		}
		inIdx = 0;
	}
}

static void endRxTx(void) {
	mode = standby;
	fclose(file);
	file = NULL;
}

static bool selectFileToTransmit(void) {
	bool result = false;
	char oldDir[FILEPATH_MAX_LENGTH];
	strlcpy(oldDir, currentDir, sizeof(oldDir));
	strlcpy(currentDir, wwDir, sizeof(currentDir));
	// Was ".fx.fr.il.bin"
	const char *fileName = browseForFileType("*");
	if (fileName != NULL) {
		strlcpy(wwDir, currentDir, sizeof(wwDir));
		if (file != NULL) {
			fclose(file);
		}
		if ( (file = fopen(fileName, "r")) ) {
			currentFileName = fileName;
			fseek(file, 0, SEEK_END);
			fileSize = ftell(file);
			if (fileSize <= 0x60000) {
				pageCount = (fileSize + (PAGE_SIZE-1)) / PAGE_SIZE;
				fseek(file, 0, SEEK_SET);
				result = true;
			}
			else {
				endRxTx();
				infoOutput("File too large!");
			}
		}
		else {
			infoOutput("Couldn't open file:");
			infoOutput(fileName);
		}
	}
	strlcpy(currentDir, oldDir, sizeof(oldDir));
	cls(0);
	return result;
}

static void startCommand(const char *str, WWCmd cmd) {
	mode = wwSendCommand;
	wwCmd = cmd;
	outIdx = 0;
	strlMerge(outBuf, " ", str, PAGE_SIZE);
	strlcat(outBuf, lineFeed, PAGE_SIZE);
	sendCommand();
	debugOutput(outBuf);
}

static void startCmdStor(const char *str, WWCmd cmd) {
	char comStr[32];
	strlMerge(comStr, str, " ", sizeof(comStr));
	strlcat(comStr, &wwGetStorageText()[1], sizeof(comStr));
	startCommand(comStr, cmd);
}

static void startCmdPath(const char *str, WWCmd cmd) {
	char comStr[32];
	strlMerge(comStr, str, " ", sizeof(comStr));
	strlcat(comStr, wwGetStorageText(), sizeof(comStr));
	startCommand(comStr, cmd);
}

static void startCmdFile(const char *str, const char *filename, WWCmd cmd) {
	char comStr[32];
	strlMerge(comStr, str, " ", sizeof(comStr));
	strlcat(comStr, filename, sizeof(comStr));
	startCommand(comStr, cmd);
}

static void handleXModemTransmit() {
	u8 value = 0;
	if (counter == 0) {
		checksum = 0;
		// End of Transfer?
		if (prevPage == pageCount) {
			value = EOT;
			endRxTx();
		}
		else {
			// Start of Heading
			value = SOH;
			fread(outBuf, 1, PAGE_SIZE, file);
			if (prevPage == 0) {
				FxFile *fxFile = (FxFile *)outBuf;
				// "#!ws"
				if (fxFile->magic != 0x73772123) {
					memset(fxFile, 0x00, sizeof(FxFile));
					fxFile->magic = 0x73772123;
					memset(fxFile->ffFill, 0xFF, sizeof(fxFile->ffFill));
					fxFile->binarySize = fileSize;
					fxFile->blockCount = pageCount+1;
					fxFile->flags = 4; //Read flag.
					struct stat attrib;
					struct tm ts;
					stat(currentFileName, &attrib);
					gmtime_r( &attrib.st_mtime, &ts);
					fxFile->modificationTime = ((ts.tm_year - 100)<<25) + ((ts.tm_mon + 1)<<21) + (ts.tm_mday<<16) + (ts.tm_hour<<11) + (ts.tm_min<<5) + (ts.tm_sec>>1);
					truncateFileName(fxFile->fileName, currentFileName, sizeof(fxFile->fileName));
					strlcpy(fxFile->description, currentFileName, sizeof(fxFile->description));
					fseek(file, 0, SEEK_SET);
				}
			}
		}
	}
	else if (counter == 1) {
		prevPage += 1;
		value = prevPage;
	}
	else if (counter == 2) {
		value = ~prevPage;
	}
	else if (counter < 131) {
		value = outBuf[counter-3];
		checksum += value;
	}
	else if (counter == 131) {
		value = checksum;
		counter = -1;
	}
	sendByte( value );
	counter += 1;
}

static void handleXModemReceive(u8 value) {
	bool ok = true;
	if (counter == 0) {
		checksum = 0;
		// End of Transfer?
		if (value == EOT) {
			sendAck();
			endRxTx();
		}
		// Cancel?
		else if (value == CAN) {
			infoOutput("Receive canceled.");
			sendAck();
			endRxTx();
		}
		// Not Start of Heading?
		else if (value != SOH) {
			return;
		}
	}
	else if (counter == 1) {
		prevPage += 1;
		if (value != (prevPage & 0xFF)) {
			ok = false;
		}
	}
	else if (counter == 2) {
		if (value != ((~prevPage) & 0xFF)) {
			ok = false;
		}
	}
	else if (counter < 131) {
		buffer[counter-3] = value;
		checksum += value;
	}
	else if (counter == 131) {
		if (value != checksum) {
			ok = false;
		}
		else {
			if (prevPage == 1) {
				FxFile *fxFile = (FxFile *)buffer;
				char fileName[0x20];
				// "#!ws"
				if (fxFile->magic == 0x73772123) {
					fileSize = fxFile->binarySize + PAGE_SIZE;
					strlcpy(fileName, fxFile->fileName, sizeof(fileName));
					// Executeable?
					if (fxFile->flags & 0x01) {
						strlcat(fileName, ".fx", sizeof(fileName));
					}
					// Library?
					else if (fxFile->flags & 0x20) {
						strlcat(fileName, ".il", sizeof(fileName));
					}
					else if (strrchr(fileName, '.') == NULL) {
						strlcat(fileName, ".fr", sizeof(fileName));
					}
				}
				else {
					fileSize = 0x60000;
					strlcpy(fileName, "ReceiveData.bin", sizeof(fileName));
				}
				file = fopen(fileName, "w");
			}
			int chunkSize = (fileSize < PAGE_SIZE) ? fileSize : PAGE_SIZE;
			fileSize -= chunkSize;
			fwrite(buffer, 1, chunkSize, file);
			sendAck();
		}
		counter = -1;
	}
	counter += 1;
	if (!ok) {
		infoOutput("Receive resend.");
		counter = 0;
		prevPage -= 1;
		sendNack();
	}
}

void handleSerialInEmpty() {
	serialInEmpty = true;
	if (mode == xmodemTransmit) {
		handleXModemTransmit();
	}
	else if (mode == wwSendCommand) {
		sendCommand();
	}
}

void handleSerialReceive(u8 value) {
	if (mode == xmodemReceive) {
		handleXModemReceive(value);
	}
	else if (mode == xmodemTransmitHold) {
		if (value == NAK) {
			mode = xmodemTransmit;
			handleXModemTransmit();
		}
	}
	else if (mode == xmodemTransmit) {
		if (value == NAK) {
			infoOutput("Transmit resend.");
			counter = 0;
			prevPage -= 1;
			fseek(file, prevPage*PAGE_SIZE, SEEK_SET);
		}
		else if (value == CAN) {
			infoOutput("Transmit canceled.");
			sendAck();
			endRxTx();
		}
	}
	else if (mode == wwReceiveCommand || mode == wwSendCommand) {
		receiveBuffer(value);
	}
	else if (mode == wwReceiveText) {
		receiveText(value);
	}
//	else if (mode == debugSerial) {
		debugSerialOutW(value);
//	}
}

void wwStartStty() {
	startCommand("stty", wwCmdStty);
}

void wwStartInteract() {
	startCommand("", wwCmdInt);
}

void wwStartHello() {
	startCommand("HELO", wwCmdHello);
}

void wwStartPut() {
	if (selectFileToTransmit()) {
//		startCmdPath("put", wwCmdPut);
		startCommand("put", wwCmdPut);
	}
}

void wwStartGet() {
	startCmdFile("get", selectedFile, wwCmdGet);
}

void wwStartDelete() {
	startCmdFile("delete", selectedFile, wwCmdDelete);
}

void wwStartExec() {
	startCmdFile("exec", selectedFile, wwCmdExec);
}

void wwStartReboot() {
	startCommand("reboot", wwCmdReboot);
}

void wwStartLs() {
	initBrowse(wwGetStorageText());
	startCmdPath("ls", wwCmdDir);
}

void wwStartDir() {
	initBrowse(wwGetStorageText());
	startCmdPath("dir", wwCmdDir);
}

void wwStartDF() {
	startCmdStor("df", wwCmdDf);
}

void wwStartNewFS() {
	startCmdStor("newfs", wwCmdNewFS);
}

void wwStartDefrag() {
	startCmdStor("defrag", wwCmdDefrag);
}

void wwStartRename() {
	startCommand("rename", wwCmdRename);
}

void wwStartSpeed() {
	startCommand("speed", wwCmdSpeed);
}

void wwStartDate() {
	startCommand("date", wwCmdDate);
}

void wwStartCopy() {
	startCommand("copy", wwCmdCopy);
}

void wwStartMove() {
	startCommand("move", wwCmdMove);
}

void wwStartSetInfo() {
	startCmdFile("setinfo", selectedFile, wwCmdSetInfo);
}

void wwStartChMod() {
	startCmdFile("chmod", selectedFile, wwCmdChMod);
}

void wwStartCD() {
	startCmdPath("cd", wwCmdCD);
}

void wwStartPwd() {
	startCommand("pwd", wwCmdPwd);
}

void startXModemReceive() {
	if (file != NULL) {
		fclose(file);
	}
	mode = xmodemReceive;
	counter = 0;
	prevPage = 0;
	sendNack();
}

void startXModemTransmit() {
	if (selectFileToTransmit()) {
		doXModemTransmit();
	}
}
