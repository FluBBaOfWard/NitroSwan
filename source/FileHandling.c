#include <nds.h>
#include <stdio.h>
#include <string.h>

#include "FileHandling.h"
#include "Shared/EmuMenu.h"
#include "Shared/EmuSettings.h"
#include "Shared/FileHelper.h"
#include "Shared/IPSPatch.h"
#include "Shared/AsmExtra.h"
#include "Shared/CartridgeRAM.h"
#include "Main.h"
#include "Gui.h"
#include "Cart.h"
#include "cpu.h"
#include "Gfx.h"
#include "io.h"
#include "Memory.h"
#include "InternalEEPROM.h"

static const char *const folderName = "nitroswan";
static const char *const settingName = "settings.cfg";
static const char *const wsEepromName = "wsinternal.eeprom";
static const char *const wscEepromName = "wscinternal.eeprom";
static const char *const scEepromName = "scinternal.eeprom";
static const char *const nitroSwanName = "@ NitroSwan @";

char translateDSChar(u16 char16);

ConfigData cfg;

//---------------------------------------------------------------------------------
int initSettings() {
	cfg.config = 0;
	cfg.palette = 0;
	cfg.gammaValue = 0x30;
	cfg.emuSettings = AUTOPAUSE_EMULATION | AUTOLOAD_NVRAM;
	cfg.sleepTime = 60*60*5;
	cfg.controller = 0;					// Don't swap A/B
	cfg.birthYear[0] = 0x19;
	cfg.birthYear[1] = 0x99;
	cfg.birthMonth = bin2BCD(PersonalData->birthMonth);
	cfg.birthDay = bin2BCD(PersonalData->birthDay);
	cfg.sex = 0;
	cfg.bloodType = 0;
	cfg.language = (PersonalData->language == 0) ? 0 : 1;

	int i;
	for (i = 0; i < 13; i++) {
		s16 char16 = nitroSwanName[i];
		cfg.name[i] = translateDSChar(char16);
	}
//	for (i = 0; i < PersonalData->nameLen; i++) {
//		s16 char16 = PersonalData->name[i];
//		debugIO(char16, 0, "C");
//		cfg.name[i] = translateDSChar(char16);
//	}
	cfg.name[i] = 0;
	return 0;
}

char translateDSChar(u16 char16) {
	// Translate numbers.
	if (char16 > 0x2F && char16 < 0x3A) {
		return char16 - 0x2F;
	}
	// Translate normal chars.
	if ((char16 > 0x40 && char16 < 0x5B) || (char16 > 0x60 && char16 < 0x7B)) {
		return (char16 & 0x1F) + 10;
	}
	// Check for heart (♥︎).
	if (char16 == 0xE017 || char16 == 0x0040) {
		return 0x25;
	}
	// Check for note (♪).
	if (char16 == 0x266A) {
		return 0x26;
	}
	// Check for plus (+).
	if (char16 == 0x002B) {
		return 0x27;
	}
	// Check for minus/dash (-).
	if (char16 == 0x002D || char16 == 0x30FC) {
		return 0x28;
	}
	// Check for different question marks (?).
	if (char16 == 0x003F || char16 == 0xFF1F || char16 == 0xE011) {
		return 0x29;
	}
	// Check for different dots/full stop (.).
	if (char16 == 0x002E || char16 == 0x3002) {
		return 0x2A;
	}
	return 0; // Space
}

bool updateSettingsFromWS() {
	bool changed = false;
	IntEEPROM *intProm = (IntEEPROM *)intEeprom.memory;

	WSUserData *userData = &intProm->userData;
	if (cfg.birthYear[0] != userData->birthYear[0]
		|| cfg.birthYear[1] != userData->birthYear[1]) {
		cfg.birthYear[0] = userData->birthYear[0];
		cfg.birthYear[1] = userData->birthYear[1];
		changed = true;
	}
	if (cfg.birthMonth != userData->birthMonth) {
		cfg.birthMonth = userData->birthMonth;
		changed = true;
	}
	if (cfg.birthDay != userData->birthDay) {
		cfg.birthDay = userData->birthDay;
		changed = true;
	}
	if (cfg.sex != userData->sex) {
		cfg.sex = userData->sex;
		changed = true;
	}
	if (cfg.bloodType != userData->bloodType) {
		cfg.bloodType = userData->bloodType;
		changed = true;
	}
	if (memcmp(cfg.name, userData->name, 16) != 0) {
		memcpy(cfg.name, userData->name, 16);
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

	gBorderEnable = (cfg.config & 1) ^ 1;
	gPaletteBank  = cfg.palette;
	gGammaValue   = cfg.gammaValue & 0xF;
	gContrastValue = (cfg.gammaValue>>4) & 0xF;
	emuSettings   = cfg.emuSettings & ~EMUSPEED_MASK;	// Clear speed setting.
	sleepTime     = cfg.sleepTime;
	joyCfg        = (joyCfg & ~0x400)|((cfg.controller & 1)<<10);
	joyMapping    = (joyMapping & ~1)|((cfg.controller & 2)>>1);
	strlcpy(currentDir, cfg.currentPath, sizeof(currentDir));

	infoOutput("Settings loaded.");
	return 0;
}

void saveSettings() {
	FILE *file;

	strcpy(cfg.magic,"cfg");
	cfg.config      = (gBorderEnable & 1) ^ 1;
	cfg.palette     = gPaletteBank;
	cfg.gammaValue  = (gGammaValue & 0xF) | (gContrastValue<<4);
	cfg.emuSettings = emuSettings & ~EMUSPEED_MASK;		// Clear speed setting.
	cfg.sleepTime   = sleepTime;
	cfg.controller  = ((joyCfg>>10)&1) | (joyMapping&1)<<1;
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
	saveIntEeproms();
}

void loadNVRAM() {
	FILE *wssFile;
	char nvRamName[FILENAMEMAXLENGTH];
	int saveSize = 0;
	void *nvMem = NULL;

	if (sramSize > 0) {
		saveSize = sramSize;
		nvMem = wsSRAM;
		setFileExtension(nvRamName, currentFilename, ".ram", sizeof(nvRamName));
	}
	else if (eepromSize > 0) {
		saveSize = eepromSize;
		nvMem = extEepromMem;
		setFileExtension(nvRamName, currentFilename, ".eeprom", sizeof(nvRamName));
	}
	else {
		return;
	}
	if (findFolder(folderName)) {
		return;
	}
	if ( (wssFile = fopen(nvRamName, "r")) ) {
		if (fread(nvMem, 1, saveSize, wssFile) != saveSize) {
			infoOutput("Bad NVRAM file:");
			infoOutput(nvRamName);
		}
		fclose(wssFile);
		infoOutput("Loaded NVRAM.");
	}
	else {
//		memset(nvMem, 0, saveSize);
		infoOutput("Couldn't open NVRAM file:");
		infoOutput(nvRamName);
	}
}

void saveNVRAM() {
	FILE *wssFile;
	char nvRamName[FILENAMEMAXLENGTH];
	int saveSize = 0;
	void *nvMem = NULL;

	if (sramSize > 0) {
		saveSize = sramSize;
		nvMem = wsSRAM;
		setFileExtension(nvRamName, currentFilename, ".ram", sizeof(nvRamName));
	}
	else if (eepromSize > 0) {
		saveSize = eepromSize;
		nvMem = extEepromMem;
		setFileExtension(nvRamName, currentFilename, ".eeprom", sizeof(nvRamName));
	}
	else {
		return;
	}
	if (findFolder(folderName)) {
		return;
	}
	if ( (wssFile = fopen(nvRamName, "w")) ) {
		if (fwrite(nvMem, 1, saveSize, wssFile) != saveSize) {
			infoOutput("Couldn't write correct number of bytes.");
		}
		fclose(wssFile);
		infoOutput("Saved NVRAM.");
	}
	else {
		infoOutput("Couldn't open NVRAM file:");
		infoOutput(nvRamName);
	}
}

void loadState() {
	loadDeviceState(folderName);
}

void saveState() {
	saveDeviceState(folderName);
}

//---------------------------------------------------------------------------------
int loadIntEeprom(const char *name, u8 *dest, int size) {
	FILE *file;
	if ( (file = fopen(name, "r")) ) {
		fread(dest, 1, size, file);
		fclose(file);
	}
	else {
		infoOutput("Couldn't open file:");
		infoOutput(name);
		return 1;
	}
	infoOutput("Internal EEPROM loaded.");
	return 0;
}

int saveIntEeprom(const char *name, u8 *source, int size) {
	FILE *file;
	if ( (file = fopen(name, "w")) ) {
		fwrite(source, 1, size, file);
		fclose(file);
	}
	else {
		infoOutput("Couldn't open file:");
		infoOutput(name);
		return 1;
	}
	infoOutput("Internal EEPROM saved.");
	return 0;
}

static void initIntEepromWS(IntEEPROM *intProm) {
	WSUserData *userData = &intProm->userData;
	memcpy(userData->name, cfg.name, 16);
	userData->birthYear[0] = cfg.birthYear[0];
	userData->birthYear[1] = cfg.birthYear[1];
	userData->birthMonth = cfg.birthMonth;
	userData->birthDay = cfg.birthDay;
	userData->sex = cfg.sex;
	userData->bloodType = cfg.bloodType;
}
static void initIntEepromWSC(IntEEPROM *intProm) {
	initIntEepromWS(intProm);
	intProm->splashData.consoleFlags = 3;
}


static void clearIntEepromWS() {
	memset(wsEepromMem, 0, sizeof(wsEepromMem));
	initIntEepromWS((IntEEPROM *)wsEepromMem);
}
static void clearIntEepromWSC() {
	memset(wscEepromMem, 0, sizeof(wscEepromMem));
	initIntEepromWSC((IntEEPROM *)wscEepromMem);
}
static void clearIntEepromSC() {
	memset(scEepromMem, 0, sizeof(scEepromMem));
	initIntEepromWSC((IntEEPROM *)scEepromMem);
}

int loadIntEeproms() {
	int status = 0;
	clearIntEepromWS();
	clearIntEepromWSC();
	clearIntEepromSC();
	if (!findFolder(folderName)) {
		status = loadIntEeprom(wsEepromName, wsEepromMem, sizeof(wsEepromMem));
		status |= loadIntEeprom(wscEepromName, wscEepromMem, sizeof(wscEepromMem));
		status |= loadIntEeprom(scEepromName, scEepromMem, sizeof(scEepromMem));
	}
	return status;
}

int saveIntEeproms() {
	int status = 1;
	if (!findFolder(folderName)) {
		switch (gSOC) {
			case SOC_ASWAN:
				status = saveIntEeprom(wsEepromName, wsEepromMem, sizeof(wsEepromMem));
				break;
			case SOC_SPHINX:
				status = saveIntEeprom(wscEepromName, wscEepromMem, sizeof(wscEepromMem));
				break;
			case SOC_SPHINX2:
				status = saveIntEeprom(scEepromName, scEepromMem, sizeof(scEepromMem));
				break;
		}
	}
	return status;
}

void selectEEPROM() {
	pauseEmulation = true;
//	setSelectedMenu(9);
	const char *eepromName = browseForFileType(".eeprom");
	if (eepromName) {
		cls(0);
		switch (gSOC) {
			case SOC_SPHINX:
				loadIntEeprom(eepromName, wscEepromMem, sizeof(wscEepromMem));
				break;
			case SOC_SPHINX2:
				loadIntEeprom(eepromName, scEepromMem, sizeof(scEepromMem));
				break;
		}
	}
}

void clearIntEeproms() {
	switch (gSOC) {
		case SOC_ASWAN:
			clearIntEepromWS();
			break;
		case SOC_SPHINX:
			clearIntEepromWSC();
			break;
		case SOC_SPHINX2:
			clearIntEepromSC();
			break;
	}
}

//---------------------------------------------------------------------------------
bool loadGame(const char *gameName) {
	if (gameName) {
		cls(0);
		drawText("     Please wait, loading.", 11, 0);
		u32 maxSize = allocatedRomMemSize;
		u8 *romPtr = allocatedRomMem;
		gRomSize = loadROM(romPtr, gameName, maxSize);
		if (!gRomSize) {
			// Enable Expansion RAM in GBA port
			drawText("        Trying Exp-RAM.", 10, 0);
			if (cartRamInit(DETECT_RAM) != DETECT_RAM) {
				drawText("         Using Exp-RAM.", 10, 0);
				infoOutput("Using Exp-RAM.");
				romPtr = (u8 *)cartRamUnlock();
				maxSize = cartRamSize();
				gRomSize = loadROM(romPtr, gameName, maxSize);
				enableSlot2Cache();
			}
		}
		else {
			cartRamLock();
		}

		if (gRomSize) {
			maxRomSize = maxSize;
			romSpacePtr = romPtr;

			checkMachine();
			setEmuSpeed(0);
			loadCart();
			gameInserted = true;
			if (emuSettings & AUTOLOAD_NVRAM) {
				loadNVRAM();
			}
			if (emuSettings & AUTOLOAD_STATE) {
				loadState();
			}
			powerIsOn = true;
			closeMenu();
			return false;
		}
	}
	return true;
}

void selectGame() {
	pauseEmulation = true;
	ui10();
	const char *gameName = browseForFileType(FILEEXTENSIONS".zip");
	if (loadGame(gameName)) {
		backOutOfMenu();
	}
}

void checkMachine() {
	char fileExt[8];
	if (gMachineSet == HW_AUTO) {
		getFileExtension(fileExt, currentFilename);
		if (romSpacePtr[gRomSize - 9] != 0 || strstr(fileExt, ".wsc")) {
			gMachine = HW_WONDERSWANCOLOR;
		}
		else if (strstr(fileExt, ".pc2")) {
			gMachine = HW_POCKETCHALLENGEV2;
		}
		else {
			gMachine = HW_WONDERSWAN;
		}
	}
	else {
		gMachine = gMachineSet;
	}
	setupEmuBackground();
}

//---------------------------------------------------------------------------------
void ejectCart() {
	gRomSize = 0x200000;
	memset(romSpacePtr, -1, gRomSize);
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

int loadBnWBIOS(void) {
	if (loadBIOS(biosSpace, cfg.monoBiosPath, sizeof(biosSpace))) {
		g_BIOSBASE_BNW = biosSpace;
		return 1;
	}
	g_BIOSBASE_BNW = NULL;
	return 0;
}

int loadColorBIOS(void) {
	if (loadBIOS(biosSpaceColor, cfg.colorBiosPath, sizeof(biosSpaceColor))) {
		g_BIOSBASE_COLOR = biosSpaceColor;
		return 1;
	}
	g_BIOSBASE_COLOR = NULL;
	return 0;
}

int loadCrystalBIOS(void) {
	if (loadBIOS(biosSpaceCrystal, cfg.crystalBiosPath, sizeof(biosSpaceCrystal))) {
		g_BIOSBASE_CRYSTAL = biosSpaceCrystal;
		return 1;
	}
	g_BIOSBASE_CRYSTAL = NULL;
	return 0;
}

static bool selectBios(char *dest, const char *fileTypes) {
	const char *biosName = browseForFileType(fileTypes);

	if (biosName) {
		strlcpy(dest, currentDir, FILEPATHMAXLENGTH);
		strlcat(dest, "/", FILEPATHMAXLENGTH);
		strlcat(dest, biosName, FILEPATHMAXLENGTH);
		return true;
	}
	return false;
}

void selectBnWBios() {
	if (selectBios(cfg.monoBiosPath, ".ws.rom.zip")) {
		loadBnWBIOS();
	}
	cls(0);
}

void selectColorBios() {
	if (selectBios(cfg.colorBiosPath, ".ws.wsc.rom.zip")) {
		loadColorBIOS();
	}
	cls(0);
}

void selectCrystalBios() {
	if (selectBios(cfg.crystalBiosPath, ".ws.wsc.rom.zip")) {
		loadCrystalBIOS();
	}
	cls(0);
}

void selectIPS() {
	pauseEmulation = true;
	ui10();
	const char *fileName = browseForFileType(".ips");
	if (patchRom(romSpacePtr, fileName, gRomSize)) {
		checkMachine();
		loadCart();
		backOutOfMenu();
	}
}
