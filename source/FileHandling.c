#include <nds.h>
#include <fat.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/dir.h>

#include "FileHandling.h"
#include "Shared/EmuMenu.h"
#include "Shared/EmuSettings.h"
#include "Shared/FileHelper.h"
#include "Shared/unzip/unzipnds.h"
#include "Main.h"
#include "Gui.h"
#include "Cart.h"
#include "cpu.h"
#include "Gfx.h"
#include "io.h"
#include "Memory.h"
#include "NitroSwan.h"

static const char *const folderName = "nitroswan";
static const char *const settingName = "settings.cfg";

ConfigData cfg;

//---------------------------------------------------------------------------------
int initSettings() {
	cfg.gammaValue = 0;
	cfg.emuSettings = AUTOPAUSE_EMULATION | AUTOLOAD_NVRAM;
	cfg.sleepTime = 60*60*5;
	cfg.controller = 0;					// Don't swap A/B
	cfg.alarmHour = PersonalData->alarmHour;
	cfg.alarmMinute = PersonalData->alarmMinute;
	cfg.birthDay = PersonalData->birthDay;
	cfg.birthMonth = PersonalData->birthMonth;
	cfg.birthYear = 99;
	cfg.language = (PersonalData->language == 0) ? 0 : 1;
	int col = 0;
	switch (PersonalData->theme & 0xF) {
		case 1:
		case 4:
			col = 4;	// Brown
			break;
		case 2:
		case 3:
		case 15:
			col = 1;	// Red
			break;
		case 6:
		case 7:
		case 8:
			col = 2;	// Green
			break;
		case 10:
		case 11:
		case 12:
			col = 3;	// Blue
			break;
		default:
			break;
	}
	cfg.palette = col;
	g_paletteBank = col;
	return 0;
}

bool updateSettingsFromNGP() {
	int val;
	bool changed = false;

	val = t9LoadB(0x6F8B);
	if (cfg.birthYear != val) {
		cfg.birthYear = val;
		changed = true;
	}
	val = t9LoadB(0x6F8C);
	if (cfg.birthMonth != val) {
		cfg.birthMonth = val;
		changed = true;
	}
	val = t9LoadB(0x6F8D);
	if (cfg.birthDay != val) {
		cfg.birthDay = val;
		changed = true;
	}

	val = t9LoadB(0x6C34);
	if (cfg.alarmHour != val) {
		cfg.alarmHour = val;
		changed = true;
	}
	val = t9LoadB(0x6C35);
	if (cfg.alarmMinute != val) {
		cfg.alarmMinute = val;
		changed = true;
	}

	val = t9LoadB(0x6F87) & 1;
	if (cfg.language != val) {
		cfg.language = val;
		g_lang = val;
		changed = true;
	}
	val = t9LoadB(0x6F94) & 7;
	if (cfg.palette != val) {
		cfg.palette = val;
		g_paletteBank = val;
		changed = true;
	}
	settingsChanged |= changed;

	return changed;
}

int loadSettings() {
	FILE *file;

	if (findFolder(folderName)) {
		return 1;
	}
	if ( (file = fopen(settingName, "r")) ) {
		fread(&cfg, 1, sizeof(ConfigData), file);
		fclose(file);
		if (!strstr(cfg.magic,"cfg")) {
			infoOutput("Error in settings file.");
			return 1;
		}
	}
	else {
		infoOutput("Couldn't open file:");
		infoOutput(settingName);
		return 1;
	}

	g_gammaValue = cfg.gammaValue;
	emuSettings  = cfg.emuSettings & ~EMUSPEED_MASK;	// Clear speed setting.
	sleepTime    = cfg.sleepTime;
	joyCfg       = (joyCfg & ~0x400)|((cfg.controller & 1)<<10);
	strlcpy(currentDir, cfg.currentPath, sizeof(currentDir));

	infoOutput("Settings loaded.");
	return 0;
}

void saveSettings() {
	FILE *file;

	strcpy(cfg.magic,"cfg");
	cfg.gammaValue  = g_gammaValue;
	cfg.emuSettings = emuSettings & ~EMUSPEED_MASK;		// Clear speed setting.
	cfg.sleepTime   = sleepTime;
	cfg.controller  = (joyCfg>>10)&1;
	strlcpy(cfg.currentPath, currentDir, sizeof(cfg.currentPath));

	if (findFolder(folderName)) {
		return;
	}
	if ( (file = fopen(settingName, "w")) ) {
		fwrite(&cfg, 1, sizeof(ConfigData), file);
		fclose(file);
		infoOutput("Settings saved.");
	}
	else {
		infoOutput("Couldn't open file:");
		infoOutput(settingName);
	}
}

void loadNVRAM_() {
	void *space;
	FILE *file;
	char flashName[FILENAMEMAXLENGTH];
	NgpFlashFile flashHdr;

	if (findFolder(folderName)) {
		return;
	}
	strlcpy(flashName, currentFilename, sizeof(flashName));
	strlcat(flashName, ".fla", sizeof(flashName));
	if ( (file = fopen(flashName, "r")) ) {
		fread(&flashHdr, 1, sizeof(flashHdr), file);
		if (flashHdr.magic == NGPF_MAGIC) {
			memcpy(getFlashLOBlocksAddress(), &flashHdr.blocksLOInfo, 35);
			memcpy(getFlashHIBlocksAddress(), &flashHdr.blocksHIInfo, 35);
			space = romSpacePtr + flashHdr.addressLO;
			fread(space, 1, flashHdr.sizeLO, file);
			if ( flashHdr.sizeHI != 0) {
				fread(space, 1, flashHdr.sizeHI, file);
			}
			infoOutput("Loaded flash.");
		}
		fclose(file);
	}
	return;
}

//void loadSaveGameFile()
void loadNVRAM() {
	// Find the .fla file and read it in
	FILE *ngfFile;
	int i;
	NgfHeader header;
	NgfBlock block;
	char flashName[FILENAMEMAXLENGTH];
	bool canCopy;

	if (findFolder(folderName)) {
		return;
	}
	strlcpy(flashName, currentFilename, sizeof(flashName));
	strlcat(flashName, ".fla", sizeof(flashName));
	if ( !(ngfFile = fopen(flashName, "r")) ) {
		infoOutput("Couldn't open flash file:");
		infoOutput(flashName);
		return;
	}

	if (fread(&header, 1, sizeof(NgfHeader), ngfFile) != sizeof(NgfHeader)) {
		infoOutput("Bad flash file:");
		infoOutput(flashName);
		fclose(ngfFile);
		return;
	}

	if (header.version != 0x53) {
		infoOutput("Bad flash file version:");
		infoOutput(flashName);
		fclose(ngfFile);
		return;
	}

    if (header.blockCount > MAX_BLOCKS) {
		infoOutput("Too many blocks in flash file:");
		infoOutput(flashName);
		fclose(ngfFile);
		return;
    }

	// Loop through the blocks and insert them into mainrom
	for (i=0; i < header.blockCount; i++) {
		if (fread(&block, 1, sizeof(NgfBlock), ngfFile) != sizeof(NgfBlock)) {
			infoOutput("Couldn't read correct number of header bytes.");
			fclose(ngfFile);
			return;
		}

		canCopy = false;
		if ((block.ngpAddr >= 0x800000 && block.ngpAddr < 0xA00000)) {
			block.ngpAddr -= 0x600000;
			canCopy = markBlockDirty(1, getBlockFromAddress(block.ngpAddr));
		}
		else if ((block.ngpAddr >= 0x200000 && block.ngpAddr < 0x400000)) {
			block.ngpAddr -= 0x200000;
			canCopy = markBlockDirty(0, getBlockFromAddress(block.ngpAddr));
		}
		if (!canCopy) {
			fseek(ngfFile, block.len, SEEK_CUR);
			infoOutput("Invalid block header in flash.");
            continue;
        }
		if (fread(&romSpacePtr[block.ngpAddr], 1, block.len, ngfFile) != block.len) {
			infoOutput("Couldn't read correct number of block bytes.");
			fclose(ngfFile);
			return;
		}
	}

	infoOutput("Loaded flash.");
	fclose(ngfFile);
}

//void writeSaveGameFile() {
void saveNVRAM() {
	// Find the dirty blocks and write them to the .fla file
	int totalBlocks = MAX_BLOCKS;
	int i;
	int chip;
	FILE *ngfFile;
	char flashName[FILENAMEMAXLENGTH];

	int bytes;
	int chipCount = (flashSize != 0x400000) ? 1 : 2;
	NgfHeader header;
	NgfBlock block;

	header.version = 0x53;
	header.blockCount = 0;
	header.fileLen = sizeof(NgfHeader);

	// Add them all up, first
	for (chip=0; chip<chipCount; chip++) {
		for (i=0; i<totalBlocks; i++) {
			if (isBlockDirty(chip,i)) {
				header.blockCount++;
				header.fileLen += getBlockSize(i);
			}
		}
	}

	header.fileLen += header.blockCount * sizeof(NgfBlock);

	if (findFolder(folderName)) {
		return;
	}
	strlcpy(flashName, currentFilename, sizeof(flashName));
	strlcat(flashName, ".fla", sizeof(flashName));
	if ( !(ngfFile = fopen(flashName, "w")) ) {
		infoOutput("Couldn't open file:");
		infoOutput(flashName);
		return;
	}

	if (fwrite(&header, 1, sizeof(NgfHeader), ngfFile) != sizeof(NgfHeader)) {
		infoOutput("Couldn't write correct number of bytes.");
		fclose(ngfFile);
		return;
	}

	for (chip=0; chip<chipCount; chip++) {
		for (i=0; i<totalBlocks; i++) {
			if (isBlockDirty(chip,i)) {
				block.len = getBlockSize(i);
				if (chip == 0) {
					block.ngpAddr = getBlockOffset(i)+0x200000;
				}
				else {
					block.ngpAddr = getBlockOffset(i)+0x800000;
				}

				if (fwrite(&block, 1, sizeof(NgfBlock), ngfFile) != sizeof(NgfBlock)) {
					infoOutput("Couldn't write correct number of bytes.");
					fclose(ngfFile);
					return;
				}

				if (chip == 0) {
					bytes = fwrite(&romSpacePtr[getBlockOffset(i)], 1, block.len, ngfFile);
				}
				else {
					bytes = fwrite(&romSpacePtr[getBlockOffset(i)+0x200000], 1, block.len, ngfFile);
				}
				if (bytes != block.len)
				{
					infoOutput("Couldn't write correct number of bytes.");
					fclose(ngfFile);
					return;
				}
			}
		}
	}

	infoOutput("Saved flash.");
	fclose(ngfFile);
}

void loadState(void) {
	u32 *statePtr;
	FILE *file;
	char stateName[FILENAMEMAXLENGTH];

	if (findFolder(folderName)) {
		return;
	}
	strlcpy(stateName, currentFilename, sizeof(stateName));
	strlcat(stateName, ".sta", sizeof(stateName));
	int stateSize = getStateSize();
	if ( (file = fopen(stateName, "r")) ) {
		if ( (statePtr = malloc(stateSize)) ) {
			cls(0);
			drawText("        Loading state...", 11, 0);
			fread(statePtr, 1, stateSize, file);
			unpackState(statePtr);
			free(statePtr);
			infoOutput("Loaded state.");
		} else {
			infoOutput("Couldn't alloc mem for state.");
		}
		fclose(file);
	}
	return;
}

void saveState(void) {
	u32 *statePtr;
	FILE *file;
	char stateName[FILENAMEMAXLENGTH];

	if (findFolder(folderName)) {
		return;
	}
	strlcpy(stateName, currentFilename, sizeof(stateName));
	strlcat(stateName, ".sta", sizeof(stateName));
	int stateSize = getStateSize();
	if ( (file = fopen(stateName, "w")) ) {
		if ( (statePtr = malloc(stateSize)) ) {
			cls(0);
			drawText("        Saving state...", 11, 0);
			packState(statePtr);
			fwrite(statePtr, 1, stateSize, file);
			free(statePtr);
			infoOutput("Saved state.");
		}
		else {
			infoOutput("Couldn't alloc mem for state.");
		}
		fclose(file);
	}
}

/// Hold down the power button for ~40 frames.
static void turnPowerOff(void) {
	int i;
	if ( g_BIOSBASE_COLOR != NULL ) {
		EMUinput &= ~4;
		for (i = 0; i < 100; i++ ) {
			run();
			EMUinput |= 4;
			if (isConsoleSleeping()) {
				break;
			}
		}
	}
}

/// Hold down the power button for ~40 frames.
static void turnPowerOn(void) {
	int i;
	if ( g_BIOSBASE_COLOR != NULL ) {
		EMUinput &= ~4;
		for (i = 0; i < 100; i++ ) {
			run();
			EMUinput |= 4;
			if (isConsoleRunning()) {
				break;
			}
		}
	}
}

//---------------------------------------------------------------------------------
bool loadGame(const char *gameName) {
	if ( gameName ) {
		cls(0);
		if ( isConsoleRunning() ) {
			drawText("     Please wait, power off.", 11, 0);
			turnPowerOff();
		}
		drawText("     Please wait, loading.", 11, 0);
		g_romSize = loadROM(romSpacePtr, gameName, maxRomSize);
		if ( g_romSize ) {
			setEmuSpeed(0);
			loadCart(emuFlags);
			gameInserted = true;
			if ( emuSettings & AUTOLOAD_NVRAM ) {
				loadNVRAM();
			}
			if ( emuSettings & AUTOLOAD_STATE ) {
				loadState();
			}
			drawText("     Please wait, power on.", 11, 0);
			turnPowerOn();
			closeMenu();
			return false;
		}
	}
	return true;
}

void selectGame() {
	pauseEmulation = true;
	setSelectedMenu(9);
	const char *gameName = browseForFileType(FILEEXTENSIONS".zip");
	if ( loadGame(gameName) ) {
		backOutOfMenu();
	}
}

//---------------------------------------------------------------------------------
void ejectCart() {
	g_romSize = 0x200000;
	memset(romSpacePtr, -1, g_romSize);
	gameInserted = false;
}

//---------------------------------------------------------------------------------
static int loadBIOS(void *dest, const char *fPath, const int maxSize) {
	char tempString[FILEPATHMAXLENGTH];
	char *sPtr;

	cls(0);
	strlcpy(tempString, fPath, sizeof(tempString));
	if ( (sPtr = strrchr(tempString, '/')) ) {
		sPtr[0] = 0;
		sPtr += 1;
		chdir("/");
		chdir(tempString);
		return loadROM(dest, sPtr, maxSize);
	}
	return 0;
}

int loadColorBIOS(void) {
	if ( loadBIOS(biosSpace, cfg.biosPath, sizeof(biosSpace)) ) {
		g_BIOSBASE_COLOR = biosSpace;
		return 1;
	}
	g_BIOSBASE_COLOR = NULL;
	return 0;
}

int loadBWBIOS(void) {
	if ( loadBIOS(biosSpace, cfg.biosPath, sizeof(biosSpace)) ) {
		g_BIOSBASE_BW = biosSpace;
		return 1;
	}
	g_BIOSBASE_BW = NULL;
	return 0;
}

static bool selectBios(char *dest, const char *fileTypes) {
	const char *biosName = browseForFileType(fileTypes);

	if ( biosName ) {
		strlcpy(dest, currentDir, FILEPATHMAXLENGTH);
		strlcat(dest, "/", FILEPATHMAXLENGTH);
		strlcat(dest, biosName, FILEPATHMAXLENGTH);
		return true;
	}
	return false;
}

void selectColorBios() {
	pauseEmulation = true;
	if ( selectBios(cfg.biosPath, ".ngp.ngc.zip") ) {
		loadColorBIOS();
		machineInit();
	}
	cls(0);
}

void selectBWBios() {
	if ( selectBios(cfg.biosPath, ".ngp.ngc.zip") ) {
		loadBWBIOS();
		machineInit();
	}
	cls(0);
}
