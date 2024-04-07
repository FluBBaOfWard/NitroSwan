#include <nds.h>

#include "Gui.h"
#include "Shared/EmuMenu.h"
#include "Shared/EmuSettings.h"
#include "Main.h"
#include "FileHandling.h"
#include "WonderSwan.h"
#include "Cart.h"
#include "Gfx.h"
#include "io.h"
#include "cpu.h"
#include "ARMV30MZ/Version.h"
#include "Sphinx/Version.h"

#define EMUVERSION "V0.6.5 2024-04-07"

#define ALLOW_SPEED_HACKS	(1<<17)
#define ENABLE_HEADPHONES	(1<<18)
#define ALLOW_REFRESH_CHG	(1<<19)

void hacksInit(void);

static void paletteChange(void);
static void machineSet(void);
static void headphonesSet(void);
static void speedHackSet(void);
static void refreshChgSet(void);
static void borderSet(void);
static void languageSet(void);
static void joyMappingSet(void);
static void stepFrame(void);

static void uiMachine(void);
static void uiDebug(void);
static void updateGameId(char *buffer);
static void updateCartInfo(char *buffer);
static void updateMapperInfo(char *buffer);

const fptr fnMain[] = {nullUI, subUI, subUI, subUI, subUI, subUI, subUI, subUI, subUI, subUI};

const fptr fnList0[] = {uiDummy};
const fptr fnList1[] = {selectGame, loadState, saveState, loadNVRAM, saveNVRAM, selectIPS, saveSettings, ejectGame, resetGame, ui9};
const fptr fnList2[] = {ui4, ui5, ui6, ui7, ui8};
const fptr fnList3[] = {uiDummy};
const fptr fnList4[] = {autoBSet, autoASet, controllerSet, swapABSet, joyMappingSet};
const fptr fnList5[] = {gammaSet, contrastSet, paletteChange, borderSet};
const fptr fnList6[] = {machineSet, selectBnWBios, selectColorBios, selectCrystalBios, selectEEPROM, clearIntEeproms, headphonesSet, speedHackSet /*languageSet*/};
const fptr fnList7[] = {speedSet, refreshChgSet, autoStateSet, autoNVRAMSet, autoSettingsSet, autoPauseGameSet, powerSaveSet, screenSwapSet, sleepSet};
const fptr fnList8[] = {debugTextSet, fgrLayerSet, bgrLayerSet, sprLayerSet, winLayerSet, stepFrame};
const fptr fnList9[] = {exitEmulator, backOutOfMenu};
const fptr fnList10[] = {uiDummy};
const fptr *const fnListX[] = {fnList0, fnList1, fnList2, fnList3, fnList4, fnList5, fnList6, fnList7, fnList8, fnList9, fnList10};
u8 menuXItems[] = {ARRSIZE(fnList0), ARRSIZE(fnList1), ARRSIZE(fnList2), ARRSIZE(fnList3), ARRSIZE(fnList4), ARRSIZE(fnList5), ARRSIZE(fnList6), ARRSIZE(fnList7), ARRSIZE(fnList8), ARRSIZE(fnList9), ARRSIZE(fnList10)};
const fptr drawUIX[] = {uiNullNormal, uiFile, uiOptions, uiAbout, uiController, uiDisplay, uiMachine, uiSettings, uiDebug, uiYesNo, uiDummy};

u8 gGammaValue = 0;
u8 gContrastValue = 3;
u8 gBorderEnable = 1;
u8 serialPos = 0;
char serialOut[32];

const char *const autoTxt[]  = {"Off", "On", "With R"};
const char *const speedTxt[] = {"Normal", "200%", "Max", "50%"};
const char *const brighTxt[] = {"I", "II", "III", "IIII", "IIIII"};
const char *const sleepTxt[] = {"5min", "10min", "30min", "Off"};
const char *const ctrlTxt[]  = {"1P", "2P"};

const char *const machTxt[]  = {"Auto", "WonderSwan", "WonderSwan Color", "SwanCrystal", "Pocket Challenge V2"};
const char *const bordTxt[]  = {"Black", "Border Color", "None"};
const char *const palTxt[]   = {"Classic", "Black & White", "Red", "Green", "Blue", "Green-Blue", "Blue-Green", "Puyo Puyo Tsu"};
const char *const langTxt[]  = {"Japanese", "English"};


void setupGUI() {
	emuSettings = AUTOPAUSE_EMULATION | AUTOLOAD_NVRAM | AUTOSLEEP_OFF | ENABLE_HEADPHONES;
	keysSetRepeat(25, 4);	// Delay, repeat.
	menuXItems[1] = ARRSIZE(fnList1) - (enableExit?0:1);
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
	uiNullDefault();
}

void uiFile() {
	setupMenu();
	drawMenuItem("Load Game");
	drawMenuItem("Load State");
	drawMenuItem("Save State");
	drawMenuItem("Load NVRAM");
	drawMenuItem("Save NVRAM");
	drawMenuItem("Load Patch");
	drawMenuItem("Save Settings");
	drawMenuItem("Eject Game");
	drawMenuItem("Reset Console");
	if (enableExit) {
		drawMenuItem("Quit Emulator");
		drawMenuItem("");			// Cheating to remove last row.
	}
}

void uiOptions() {
	setupMenu();
	drawMenuItem("Controller");
	drawMenuItem("Display");
	drawMenuItem("Machine");
	drawMenuItem("Settings");
	drawMenuItem("Debug");
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

void uiController() {
	setupSubMenu("Controller Settings");
	drawSubItem("B Autofire:", autoTxt[autoB]);
	drawSubItem("A Autofire:", autoTxt[autoA]);
	drawSubItem("Controller:", ctrlTxt[(joyCfg>>29)&1]);
	drawSubItem("Swap A-B:  ", autoTxt[(joyCfg>>10)&1]);
	drawSubItem("Alternate map: ", autoTxt[joyMapping&1]);
}

void uiDisplay() {
	setupSubMenu("Display Settings");
	drawSubItem("Gamma:", brighTxt[gGammaValue]);
	drawSubItem("Contrast:", brighTxt[gContrastValue]);
	drawSubItem("B&W Palette:", palTxt[gPaletteBank]);
	drawSubItem("Border:", autoTxt[gBorderEnable]);
}

static void uiMachine() {
	setupSubMenu("Machine Settings");
	drawSubItem("Machine:", machTxt[gMachineSet]);
	drawSubItem("Select WS Bios", NULL);
	drawSubItem("Select WS Color Bios", NULL);
	drawSubItem("Select WS Crystal Bios", NULL);
	drawSubItem("Import Internal EEPROM", NULL);
	drawSubItem("Clear Internal EEPROM", NULL);
	drawSubItem("Headphones:", autoTxt[(emuSettings&ENABLE_HEADPHONES)>>18]);
	drawSubItem("Cpu Speed Hacks:", autoTxt[(emuSettings&ALLOW_SPEED_HACKS)>>17]);
//	drawSubItem("Language: ", langTxt[gLang]);
}

void uiSettings() {
	setupSubMenu("Settings");
	drawSubItem("Speed:", speedTxt[(emuSettings>>6)&3]);
	drawSubItem("Allow Refresh Change:", autoTxt[(emuSettings&ALLOW_REFRESH_CHG)>>19]);
	drawSubItem("Autoload State:", autoTxt[(emuSettings>>2)&1]);
	drawSubItem("Autoload NVRAM:", autoTxt[(emuSettings>>10)&1]);
	drawSubItem("Autosave Settings:", autoTxt[(emuSettings>>9)&1]);
	drawSubItem("Autopause Game:", autoTxt[emuSettings&1]);
	drawSubItem("Powersave 2nd Screen:",autoTxt[(emuSettings>>1)&1]);
	drawSubItem("Emulator on Bottom:", autoTxt[(emuSettings>>8)&1]);
	drawSubItem("Autosleep:", sleepTxt[(emuSettings>>4)&3]);
}

void uiDebug() {
	setupSubMenu("Debug");
	drawSubItem("Debug Output:", autoTxt[gDebugSet&1]);
	drawSubItem("Disable Foreground:", autoTxt[(gGfxMask>>1)&1]);
	drawSubItem("Disable Background:", autoTxt[gGfxMask&1]);
	drawSubItem("Disable Sprites:", autoTxt[(gGfxMask>>4)&1]);
	drawSubItem("Disable Windows:", autoTxt[(gGfxMask>>5)&1]);
	drawSubItem("Step Frame", NULL);
}

void nullUINormal(int key) {
	if (key & KEY_TOUCH) {
		openMenu();
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
	powerIsOn = true;
	loadCart();
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

	debugString[0] = 0;
	strlcat(debugString, message, sizeof(debugString));
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
void debugSerialOutW(u8 val) {
	if (val < 0x80) {
		serialOut[serialPos++] = val;
		if (serialPos >= 32 || val == 0) {
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

void stepFrame() {
	runFrame();
}
//---------------------------------------------------------------------------------
/// Switch between Player 1 & Player 2 controls
void controllerSet() {				// See io.s: refreshEMUjoypads
	joyCfg ^= 0x20000000;
}

/// Swap A & B buttons
void swapABSet() {
	joyCfg ^= 0x400;
}

/// Change gamma (brightness)
void gammaSet() {
	gGammaValue++;
	if (gGammaValue > 4) gGammaValue = 0;
	paletteInit(gGammaValue, gContrastValue);
	monoPalInit(gGammaValue, gContrastValue);
	paletteTxAll();					// Make new palette visible
	setupEmuBorderPalette();
	setupMenuPalette();
	settingsChanged = true;
}

/// Change contrast
void contrastSet() {
	gContrastValue++;
	if (gContrastValue > 4) gContrastValue = 0;
	paletteInit(gGammaValue, gContrastValue);
	monoPalInit(gGammaValue, gContrastValue);
	paletteTxAll();					// Make new palette visible
	setupEmuBorderPalette();
	settingsChanged = true;
}

/// Turn on/off rendering of foreground
void fgrLayerSet() {
	gGfxMask ^= 0x02;
}
/// Turn on/off rendering of background
void bgrLayerSet() {
	gGfxMask ^= 0x01;
}
/// Turn on/off rendering of sprites
void sprLayerSet() {
	gGfxMask ^= 0x10;
}
/// Turn on/off windows
void winLayerSet() {
	gGfxMask ^= 0x20;
}

void paletteChange() {
	gPaletteBank++;
	if (gPaletteBank > 7) {
		gPaletteBank = 0;
	}
	monoPalInit(gGammaValue, gContrastValue);
	paletteTxAll();
	setupEmuBorderPalette();
	settingsChanged = true;
}

void borderSet() {
	gBorderEnable ^= 0x01;
	setupEmuBorderPalette();
}

void languageSet() {
	gLang ^= 0x01;
}

void machineSet() {
	gMachineSet++;
	if (gMachineSet >= HW_SELECT_END) {
		gMachineSet = 0;
	}
}

void speedHackSet() {
	emuSettings ^= ALLOW_SPEED_HACKS;
	hacksInit();
}

void joyMappingSet() {
	joyMapping ^= 0x01;
	setJoyMapping(joyMapping);
}

void headphonesSet() {
	emuSettings ^= ENABLE_HEADPHONES;
	setHeadphones(emuSettings & ENABLE_HEADPHONES);
}

void refreshChgSet() {
	emuSettings ^= ALLOW_REFRESH_CHG;
	updateLCDRefresh();
}
