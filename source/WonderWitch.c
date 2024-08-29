#include <nds.h>
#include <stdio.h>

#include "Shared/EmuMenu.h"
#include "Shared/FileHelper.h"
#include "WonderWitch.h"
#include "Gui.h"
#include "Gfx.h"

FILE *file = NULL;

int counter = 0;
int prevPage = 0;
int fileSize = 0;
int pageCount = 0;
Mode mode = standby;
bool serialInEmpty = false;
u8 checksum = 0;
u8 buffer[PAGE_SIZE];

static bool sendByte(u8 value) {
	if (serialInEmpty) {
		serialInEmpty = false;
		setSerialByteIn(value);
		return true;
	}
	return false;
}

static void sendBuffer() {
	u8 val = buffer[counter];
	if (val == 0) {
		mode = wwReceiveCommand;
		counter = 0;
		return;
	}
	if (sendByte(val)) {
		counter += 1;
	}
}

static void receiveBuffer(u8 val) {
	if (val == 0) {
		mode = standby;
		return;
	}
	buffer[counter] = val;
	counter += 1;
}

void sendNack() {
	sendByte(NAK);
}

void sendAck() {
	sendByte(ACK);
}

static void endRxTx(void) {
	mode = standby;
	fclose(file);
	file = NULL;
}

void startWWCommand(const char *str) {
	mode = wwSendCommand;
	counter = 0;
	char lineFeed[2] = {CR, 0x0};
	strlcpy((char *)buffer, " ", PAGE_SIZE);
	strlcat((char *)buffer, str, PAGE_SIZE);
	strlcat((char *)buffer, lineFeed, PAGE_SIZE);
	sendBuffer();
	debugOutput(str);
}

void startWWPut() {
	startWWCommand("put");
}

void startWWInteract() {
	startWWCommand("");
}

void startWWStty() {
	startWWCommand("stty");
}

void startWWHello() {
	startWWCommand("HELO");
}

void startWWReboot() {
	startWWCommand("reboot");
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
	const char *fileName = browseForFileType(".fx.fr.il.bin");
	if (fileName != NULL) {
		if (file != NULL) {
			fclose(file);
		}
		if ( (file = fopen(fileName, "r")) ) {
			fseek(file, 0, SEEK_END);
			fileSize = ftell(file);
			if (fileSize <= 0x60000) {
				pageCount = (fileSize + 0x7F) / PAGE_SIZE;
				fseek(file, 0, SEEK_SET);
				mode = xmodemTransmitHold;
				counter = 0;
				prevPage = 0;
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
	cls(0);
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
			fseek(file, prevPage*PAGE_SIZE, SEEK_SET);
		}
	}
	else if (counter == 1) {
		prevPage += 1;
		value = prevPage;
	}
	else if (counter == 2) {
		value = 0xFF-prevPage;
	}
	else if (counter < 131) {
		fread(&value, 1, 1, file);
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
		// Start of Heading?
		else if (value != SOH) {
			return;
		}
	}
	else if (counter == 1) {
		if (value != ((prevPage+1) & 0xFF)) {
			infoOutput("Receive resend.");
			ok = false;
		}
		else {
			prevPage += 1;
		}
	}
	else if (counter == 2) {
		if (value != ((0xFF-prevPage) & 0xFF)) {
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
					strlcpy(fileName, fxFile->fileName, 0x20);
					// Executeable?
					if (fxFile->flags & 0x01) {
						strlcat(fileName, ".fx", 0x20);
					}
					// Library?
					else if (fxFile->flags & 0x20) {
						strlcat(fileName, ".il", 0x20);
					}
					else if (strrchr(fileName, '.') == NULL) {
						strlcat(fileName, ".fr", 0x20);
					}
				}
				else {
					fileSize = 0x60000;
					strlcpy(fileName, "ReceiveData.bin", 0x20);
				}
				file = fopen(fileName, "w");
			}
			int chunk = (fileSize < PAGE_SIZE) ? fileSize : PAGE_SIZE;
			fileSize -= chunk;
			fwrite(buffer, 1, chunk, file);
			sendAck();
		}
		counter = -1;
	}
	counter += 1;
	if (!ok) {
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
		sendBuffer();
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
		}
		else if (value == CAN) {
			infoOutput("Transmit canceled.");
			sendAck();
			endRxTx();
		}
	}
	else if (mode == wwReceiveCommand) {
		receiveBuffer(value);
	}
//	else if (mode == debugSerial) {
		debugSerialOutW(value);
//	}
}
