#include <nds.h>

#include "Gui.h"
#include "Shared/EmuMenu.h"
#include "Shared/EmuSettings.h"
#include "Main.h"
#include "FileHandling.h"
#include "WonderSwan.h"
#include "WonderWitch.h"
#include "Cart.h"
#include "Gfx.h"
#include "io.h"
#include "cpu.h"
#include "ARMV30MZ/Version.h"
#include "Sphinx/Version.h"
#include "WSBottom.h"
#include "WSCBottom.h"
#include "SCBottom.h"

#define EMUVERSION "V0.6.8 2025-03-09"

void hacksInit(void);

static void nullUIWS(int key);
static void nullUIWSC(int key);

static void gammaChange(void);
static void paletteChange(void);
static const char *getPaletteText(void);
static void machineSet(void);
static const char *getMachineText(void);
static void headphonesSet(void);
static const char *getHeadphonesText(void);
static void speedHackSet(void);
static const char *getSpeedHackText(void);
static void refreshChgSet(void);
static const char *getRefreshChgText(void);
static void borderSet(void);
static const char *getBorderText(void);
static void joyMappingSet(void);
static const char *getJoyMappingText(void);
static void swapABSet(void);
static const char *getSwapABText(void);
static void contrastSet(void);
static const char *getContrastText(void);
static void fgrLayerSet(void);
static const char *getFgrLayerText(void);
static void bgrLayerSet(void);
static const char *getBgrLayerText(void);
static void sprLayerSet(void);
static const char *getSprLayerText(void);
static void winLayerSet(void);
static const char *getWinLayerText(void);
static void languageSet(void);

static void ui11(void);
static void ui12(void);
static void updateGameId(char *buffer);
static void updateCartInfo(char *buffer);
static void updateMapperInfo(char *buffer);

const MItem dummyItems[] = {
	{"", uiDummy}
};
const MItem fileItems[] = {
	{"Load Game", selectGame},
	{"Load State", loadState},
	{"Save State", saveState},
	{"Load NVRAM", loadNVRAM},
	{"Save NVRAM", saveNVRAM},
	{"Load Patch", selectIPS},
	{"Save Settings", saveSettings},
	{"Eject Game", ejectGame},
	{"Reset Console", resetGame},
	{"Quit Emulator", ui9},
};
const MItem optionItems[] = {
	{"Controller", ui4},
	{"Display", ui5},
	{"Machine", ui6},
	{"Settings", ui7},
	{"WonderWitch", ui11},
	{"Debug", ui8},
};
const MItem ctrlItems[] = {
	{"B Autofire:", autoBSet, getAutoBText},
	{"A Autofire:", autoASet, getAutoAText},
	{"Swap A-B:  ", swapABSet, getSwapABText},
	{"Alternate map:", joyMappingSet, getJoyMappingText},
};
const MItem displayItems[] = {
	{"Gamma:", gammaChange, getGammaText},
	{"Contrast:", contrastSet, getContrastText},
	{"B&W Palette:", paletteChange, getPaletteText},
	{"Border:", borderSet, getBorderText},
};
const MItem machineItems[] = {
	{"Machine:", machineSet, getMachineText},
	{"Select WS Bios", selectBnWBios},
	{"Select WS Color Bios", selectColorBios},
	{"Select WS Crystal Bios", selectCrystalBios},
	{"Import Internal EEPROM", selectEEPROM},
	{"Clear Internal EEPROM", clearIntEeproms},
	{"Headphones:", headphonesSet, getHeadphonesText},
	{"Cpu Speed Hacks:", speedHackSet, getSpeedHackText},
	//{"Language:", languageSet},
};
const MItem setItems[] = {
	{"Speed:", speedSet, getSpeedText},
	{"Allow Refresh Change:", refreshChgSet, getRefreshChgText},
	{"Autoload State:", autoStateSet, getAutoStateText},
	{"Autoload NVRAM:", autoNVRAMSet, getAutoNVRAMText},
	{"Autosave Settings:", autoSettingsSet, getAutoSettingsText},
	{"Autopause Game:", autoPauseGameSet, getAutoPauseGameText},
	{"Powersave 2nd Screen:", powerSaveSet, getPowerSaveText},
	{"Emulator on Bottom:", screenSwapSet, getScreenSwapText},
	{"Autosleep:", sleepSet, getSleepText},
};
const MItem debugItems[] = {
	{"Debug Output:", debugTextSet, getDebugText},
	{"Disable Foreground:", fgrLayerSet, getFgrLayerText},
	{"Disable Background:", bgrLayerSet, getBgrLayerText},
	{"Disable Sprites:", sprLayerSet, getSprLayerText},
	{"Disable Windows:", winLayerSet, getWinLayerText},
	{"Step Frame", stepFrame},
};
const MItem quitItems[] = {
	{"Yes ", exitEmulator},
	{"No ", backOutOfMenu},
};
const MItem wonderWitchItems[] = {
	{"Storage:", wwChangeStorage, wwGetStorageText},
	{"Upload File", wwStartPut},
	{"Dir", wwStartDir},
	{"Execute", wwStartExec},
	{"Delete", wwStartDelete},
	{"Defrag", wwStartDefrag},
	{"Download File", wwStartGet},
	{"NewFS (Formatt)", ui12},
	{"XMODEM Transmit", startXModemTransmit},
	{"XMODEM Receive", startXModemReceive},
	{"Reboot WW", wwStartReboot},
	{"CD", wwStartCD},
	{"Interact", wwStartInteract},
	{"Stty", wwStartStty},
	{"Hello", wwStartHello},
	{"Speed", wwStartSpeed},
};
const MItem formattItems[] = {
	{"Yes ", wwStartNewFS},
	{"No ", backOutOfMenu},
};

const Menu menu0 = MENU_M("", uiNullNormal, dummyItems);
Menu menu1 = MENU_M("", uiAuto, fileItems);
const Menu menu2 = MENU_M("", uiAuto, optionItems);
const Menu menu3 = MENU_M("", uiAbout, dummyItems);
const Menu menu4 = MENU_M("Controller Settings", uiAuto, ctrlItems);
const Menu menu5 = MENU_M("Display Settings", uiAuto, displayItems);
const Menu menu6 = MENU_M("Machine Settings", uiAuto, machineItems);
const Menu menu7 = MENU_M("Settings", uiAuto, setItems);
const Menu menu8 = MENU_M("Debug", uiAuto, debugItems);
const Menu menu9 = MENU_M("Quit Emulator?", uiAuto, quitItems);
const Menu menu10 = MENU_M("", uiDummy, dummyItems);
const Menu menu11 = MENU_M("WonderWitch", uiAuto, wonderWitchItems);
const Menu menu12 = MENU_M("Formatt Storage?", uiAuto, formattItems);

const Menu *const menus[] = {&menu0, &menu1, &menu2, &menu3, &menu4, &menu5, &menu6, &menu7, &menu8, &menu9, &menu10, &menu11, &menu12};

u8 gContrastValue = 3;
u8 gBorderEnable = 1;
u8 serialPos = 0;
char serialOut[32];

static const char *const machTxt[]  = {"Auto", "WonderSwan", "WonderSwan Color", "SwanCrystal", "Pocket Challenge V2"};
static const char *const palTxt[]   = {"Classic", "Black & White", "Red", "Green", "Blue", "Green-Blue", "Blue-Green", "Puyo Puyo Tsu"};
static const char *const bordTxt[]  = {"Black", "Frame", "BG Color", "None"};
//static const char *const langTxt[]  = {"Japanese", "English"};


void setupGUI() {
	keysSetRepeat(25, 4);	// Delay, repeat.
	menu1.itemCount = ARRSIZE(fileItems) - (enableExit?0:1);
	openMenu();
}

/// This is called when going from emu to ui.
void enterGUI() {
	if ((emuSettings & AUTOSAVE_SETTINGS) && updateSettingsFromWS()) {
		saveSettings();
		settingsChanged = false;
	}
}

/// This is called going from ui to emu.
void exitGUI() {
}

void quickSelectGame(void) {
	openMenu();
	selectGame();
	closeMenu();
}

void uiNullNormal() {
	if (gMachine == HW_WONDERSWAN) {
		setupCompressedBackground(WSBottomTiles, WSBottomMap, 0);
		memcpy(BG_PALETTE_SUB+0x80, WSBottomPal, WSBottomPalLen);
	}
	else if (gMachine == HW_WONDERSWANCOLOR) {
		setupCompressedBackground(WSCBottomTiles, WSCBottomMap, 0);
		memcpy(BG_PALETTE_SUB+0x80, WSCBottomPal, WSCBottomPalLen);
	}
	else if (gMachine == HW_SWANCRYSTAL) {
		setupCompressedBackground(SCBottomTiles, SCBottomMap, 0);
		memcpy(BG_PALETTE_SUB+0x80, SCBottomPal, SCBottomPalLen);
	}
	uiNullDefault();
}

void uiAbout() {
	char gameInfoString[32];
	cls(1);
	drawTabs();
	drawMenuText("B:        WS B button", 4, 0);
	drawMenuText("A:        WS A button", 5, 0);
	drawMenuText("Start:    WS Start button", 6, 0);
	drawMenuText("Select:   WS Sound button", 7, 0);
	drawMenuText("DPad:     WS X1-X4", 8, 0);

	updateGameId(gameInfoString);
	drawMenuText(gameInfoString, 10, 0);

	updateCartInfo(gameInfoString);
	drawMenuText(gameInfoString, 11, 0);

	updateMapperInfo(gameInfoString);
	drawMenuText(gameInfoString, 12, 0);

	drawMenuText("NitroSwan    " EMUVERSION, 21, 0);
	drawMenuText("Sphinx       " SPHINXVERSION, 22, 0);
	drawMenuText("ARMV30MZ     " ARMV30MZVERSION, 23, 0);
}

void ui11() {
	enterMenu(11);
}
void ui12() {
	enterMenu(12);
}

void nullUINormal(int key) {
	switch (gMachine) {
		case HW_WONDERSWAN:
			nullUIWS(key);
			break;
		case HW_WONDERSWANCOLOR:
			nullUIWSC(key);
			break;
		case HW_SWANCRYSTAL:
			nullUIWSC(key);
			break;
		case HW_POCKETCHALLENGEV2:
			nullUIWSC(key);
			break;
		default:
			if (key & KEY_TOUCH) {
				openMenu();
			}
			break;
	}
}

void nullUIDebug(int key) {
	if (key & KEY_TOUCH) {
		openMenu();
	}
}

void ejectGame() {
	ejectCart();
}

void resetGame() {
	checkMachine();
	loadCart();
	setupEmuBackground();
	powerIsOn = true;
}

void updateGameId(char *buffer) {
	char catalog[8];
	char2HexStr(catalog, gGameHeader->gameId);
	strlMerge(buffer, "Game Id, Revision #: 0x", catalog, 32);
	strlMerge(buffer, buffer, " 0x", 32);
	char2HexStr(catalog, gGameHeader->gameRev);
	strlMerge(buffer, buffer, catalog, 32);
}

void updateCartInfo(char *buffer) {
	char catalog[8];
	char2HexStr(catalog, gGameHeader->romSize);
	strlMerge(buffer, "ROM Size, Save    #: 0x", catalog, 32);
	strlMerge(buffer, buffer, " 0x", 32);
	char2HexStr(catalog, gGameHeader->nvramSize);
	strlMerge(buffer, buffer, catalog, 32);
}

void updateMapperInfo(char *buffer) {
	char catalog[8];
	char2HexStr(catalog, gGameHeader->flags);
	strlMerge(buffer, "Flags, Mapper     #: 0x", catalog, 32);
	strlMerge(buffer, buffer, " 0x", 32);
	char2HexStr(catalog, gGameHeader->mapper);
	strlMerge(buffer, buffer, catalog, 32);
}

//---------------------------------------------------------------------------------
void debugIO(u16 port, u8 val, const char *message) {
	char debugString[32];

	strlcpy(debugString, message, sizeof(debugString));
	short2HexStr(&debugString[strlen(debugString)], port);
	strlcat(debugString, " val:", sizeof(debugString));
	char2HexStr(&debugString[strlen(debugString)], val);
	debugOutput(debugString);
}
//---------------------------------------------------------------------------------
void debugIOUnimplR(u16 port, u8 val) {
	debugIO(port, val, "Unimpl R port:");
}
void debugIOUnimplW(u8 val, u16 port) {
	debugIO(port, val, "Unimpl W port:");
}
void debugIOUnmappedR(u16 port, u8 val) {
	debugIO(port, val, "Unmapped R port:");
}
void debugIOUnmappedW(u8 val, u16 port) {
	debugIO(port, val, "Unmapped W port:");
}
void debugROMW(u8 val, u16 adr) {
	debugIO(adr, val, "Rom W:");
}
void debugSerialOutW(u8 val) {
	if (val < 0x80) {
		serialOut[serialPos++] = val;
		if (serialPos >= 31 || val == 0 || val == 0xA || val == 0xD) {
			serialOut[serialPos] = 0;
			serialPos = 0;
			debugOutput(serialOut);
		}
	}
}
void debugDivideError() {
	debugOutput("Divide Error.");
}
void debugUndefinedInstruction() {
	debugOutput("Undefined Instruction.");
}
void debugCrashInstruction() {
	debugOutput("CPU Crash! (0xF1)");
}

//---------------------------------------------------------------------------------
void nullUIWS(int keyHit) {
	if (EMUinput & KEY_TOUCH) {
		touchPosition myTouch;
		touchRead(&myTouch);
		int xpos = (myTouch.px>>2);
		int ypos = (myTouch.py>>2);
		if ( ypos > 8 ) {
			openMenu();
		}
		else if (xpos > 20 && xpos < 29) { // Start button
			EMUinput |= KEY_START;
		}
		else if (keyHit & KEY_TOUCH) {
			if (xpos > 9 && xpos < 19) { // Sound button
				pushVolumeButton();
			}
		}
	}
}

//---------------------------------------------------------------------------------
void nullUIWSC(int keyHit) {
	if (EMUinput & KEY_TOUCH) {
		touchPosition myTouch;
		touchRead(&myTouch);
		int xpos = (myTouch.px>>2);
		int ypos = (myTouch.py>>2);
		if ( ypos > 8 ) {
			openMenu();
		}
		else if (xpos > 16 && xpos < 24) { // Start button
			EMUinput |= KEY_START;
		}
		else if (keyHit & KEY_TOUCH) {
			if (xpos > 6 && xpos < 14) { // Sound button
				pushVolumeButton();
			}
			else if (xpos > 27 && xpos < 35) { // Power button
				if (powerIsOn) {
					setPowerOff();
					gfxRefresh();
				}
				else {
					resetGame();
				}
			}
		}
	}
}

//---------------------------------------------------------------------------------
void nullUISC(int keyHit) {
	if (EMUinput & KEY_TOUCH) {
		touchPosition myTouch;
		touchRead(&myTouch);
		int xpos = (myTouch.px>>2);
		int ypos = (myTouch.py>>2);
		if ( ypos > 8 ) {
			openMenu();
		}
		else if (xpos > 16 && xpos < 25) { // Start button
			EMUinput |= KEY_START;
		}
		else if (keyHit & KEY_TOUCH) {
			if (xpos > 6 && xpos < 14) { // Sound button
				pushVolumeButton();
			}
			else if (xpos > 30 && xpos < 36) { // Power button
				if (powerIsOn) {
					setPowerOff();
					gfxRefresh();
				}
				else {
					resetGame();
				}
			}
		}
	}
}

//---------------------------------------------------------------------------------
/// Swap A & B buttons
void swapABSet() {
	joyCfg ^= 0x400;
}
const char *getSwapABText() {
	return autoTxt[(joyCfg>>10)&1];
}

void gammaChange() {
	gammaSet();
	paletteInit(gGammaValue, gContrastValue, 0);
	monoPalInit(gGammaValue, gContrastValue, 0);
	setupEmuBorderPalette();
	setupMenuPalette();
}

/// Change contrast
void contrastSet() {
	gContrastValue++;
	if (gContrastValue > 4) gContrastValue = 0;
	paletteInit(gGammaValue, gContrastValue, 0);
	monoPalInit(gGammaValue, gContrastValue, 0);
	setupEmuBorderPalette();
	settingsChanged = true;
}
const char *getContrastText() {
	return brighTxt[gContrastValue];
}

/// Turn on/off rendering of foreground
void fgrLayerSet() {
	gGfxMask ^= 0x02;
}
const char *getFgrLayerText() {
	return autoTxt[(gGfxMask>>1)&1];
}
/// Turn on/off rendering of background
void bgrLayerSet() {
	gGfxMask ^= 0x01;
}
const char *getBgrLayerText() {
	return autoTxt[gGfxMask&1];
}
/// Turn on/off rendering of sprites
void sprLayerSet() {
	gGfxMask ^= 0x10;
}
const char *getSprLayerText() {
	return autoTxt[(gGfxMask>>4)&1];
}
/// Turn on/off windows
void winLayerSet() {
	gGfxMask ^= 0x20;
}
const char *getWinLayerText() {
	return autoTxt[(gGfxMask>>5)&1];
}

void paletteChange() {
	gPaletteBank++;
	if (gPaletteBank > 7) {
		gPaletteBank = 0;
	}
	monoPalInit(gGammaValue, gContrastValue, 0);
	setupEmuBorderPalette();
	settingsChanged = true;
}
const char *getPaletteText() {
	return palTxt[gPaletteBank];
}

void borderSet() {
	gBorderEnable ^= 0x01;
	setupEmuBorderPalette();
}
const char *getBorderText() {
	return bordTxt[gBorderEnable];
}

void languageSet() {
	gLang ^= 0x01;
}

void machineSet() {
	gMachineSet++;
	if (gMachineSet >= HW_SELECT_END) {
		gMachineSet = 0;
	}
	setupEmuBorderPalette();
}
const char *getMachineText() {
	return machTxt[gMachineSet];
}

void speedHackSet() {
	emuSettings ^= ALLOW_SPEED_HACKS;
	hacksInit();
}
const char *getSpeedHackText() {
	return autoTxt[(emuSettings & ALLOW_SPEED_HACKS)>>17];
}

void joyMappingSet() {
	joyMapping ^= 0x01;
	setJoyMapping(joyMapping);
}
const char *getJoyMappingText() {
	return autoTxt[joyMapping&1];
}

void headphonesSet() {
	emuSettings ^= ENABLE_HEADPHONES;
	setHeadphones(emuSettings & ENABLE_HEADPHONES);
}
const char *getHeadphonesText() {
	return autoTxt[(emuSettings&ENABLE_HEADPHONES)>>18];
}

void refreshChgSet() {
	emuSettings ^= ALLOW_REFRESH_CHG;
	updateLCDRefresh();
}
const char *getRefreshChgText() {
	return autoTxt[(emuSettings&ALLOW_REFRESH_CHG)>>19];
}
