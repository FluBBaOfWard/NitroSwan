#include <nds.h>

#include "Gui.h"
#include "Shared/EmuMenu.h"
#include "Shared/EmuSettings.h"
#include "Main.h"
#include "FileHandling.h"
#include "Cart.h"
#include "Gfx.h"
#include "io.h"
#include "cpu.h"
#include "bios.h"
#include "ARMV30MZ/Version.h"

#define EMUVERSION "V0.1.1 2021-10-17"

#define ALLOW_SPEED_HACKS	(1<<17)

void hacksInit(void);

static void paletteChange(void);
static void languageSet(void);
static void machineSet(void);
static void batteryChange(void);
static void subBatteryChange(void);
static void speedHackSet(void);

static void uiMachine(void);
static void updateGameInfo(void);

const fptr fnMain[] = {nullUI, subUI, subUI, subUI, subUI, subUI, subUI, subUI, subUI, subUI};

const fptr fnList0[] = {uiDummy};
const fptr fnList1[] = {selectGame, loadState, saveState, loadNVRAM, saveNVRAM, saveSettings, ejectGame, resetGame};
const fptr fnList2[] = {ui4, ui5, ui6, ui7};
const fptr fnList3[] = {uiDummy};
const fptr fnList4[] = {autoBSet, autoASet, controllerSet, swapABSet};
const fptr fnList5[] = {/*scalingSet, flickSet,*/ gammaSet, paletteChange, fgrLayerSet, bgrLayerSet, sprLayerSet};
const fptr fnList6[] = {languageSet, machineSet, batteryChange, subBatteryChange, speedHackSet, selectColorBios};
const fptr fnList7[] = {speedSet, autoStateSet, autoNVRAMSet, autoSettingsSet, autoPauseGameSet, powerSaveSet, screenSwapSet, debugTextSet, sleepSet};
const fptr fnList8[] = {quickSelectGame};
const fptr fnList9[] = {uiDummy};
const fptr *const fnListX[] = {fnList0, fnList1, fnList2, fnList3, fnList4, fnList5, fnList6, fnList7, fnList8, fnList9};
const u8 menuXItems[] = {ARRSIZE(fnList0), ARRSIZE(fnList1), ARRSIZE(fnList2), ARRSIZE(fnList3), ARRSIZE(fnList4), ARRSIZE(fnList5), ARRSIZE(fnList6), ARRSIZE(fnList7), ARRSIZE(fnList8), ARRSIZE(fnList9)};
const fptr drawUIX[] = {uiNullNormal, uiFile, uiOptions, uiAbout, uiController, uiDisplay, uiMachine, uiSettings, uiDummy, uiDummy};
const u8 menuXBack[] = {0,0,0,0,2,2,2,2,1,1};

u8 g_gammaValue = 0;

const char *const autoTxt[]  = {"Off", "On", "With R"};
const char *const speedTxt[] = {"Normal", "200%", "Max", "50%"};
const char *const sleepTxt[] = {"5min", "10min", "30min", "Off"};
const char *const brighTxt[] = {"I", "II", "III", "IIII", "IIIII"};
const char *const ctrlTxt[]  = {"1P", "2P"};
const char *const dispTxt[]  = {"Unscaled", "Scaled"};
const char *const flickTxt[] = {"No Flicker", "Flicker"};
const char *const bordTxt[]  = {"Black", "Border Color", "None"};
const char *const palTxt[]   = {"Black & White", "Red", "Green", "Blue", "Classic"};
const char *const langTxt[]  = {"Japanese", "English"};
const char *const machTxt[]  = {"WonderSwan Color", "WonderSwan"};


void setupGUI() {
	emuSettings = AUTOPAUSE_EMULATION | AUTOLOAD_NVRAM | ALLOW_SPEED_HACKS | AUTOSLEEP_OFF;
	keysSetRepeat(25, 4);	// delay, repeat.
	openMenu();
}

/// This is called when going from emu to ui.
void enterGUI() {
	if (updateSettingsFromNGP() && (emuSettings & AUTOSAVE_SETTINGS)) {
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
	drawMenuItem("Load Flash");
	drawMenuItem("Save Flash");
	drawMenuItem("Save Settings");
	drawMenuItem("Eject Game");
	drawMenuItem("Reset Console");
	if (enableExit) {
		drawMenuItem("Quit Emulator");
	}
}

void uiOptions() {
	setupMenu();
	drawMenuItem("Controller");
	drawMenuItem("Display");
	drawMenuItem("Machine");
	drawMenuItem("Settings");
}

void uiAbout() {
	cls(1);
	drawTabs();
	drawText(" B:        NGP A button", 4, 0);
	drawText(" A:        NGP B button", 5, 0);
	drawText(" Y/Select: Power button", 6, 0);
	drawText(" X/Start:  Start button", 7, 0);

	drawText(" NitroSwan    " EMUVERSION, 22, 0);
	drawText(" ARMV30MZ     " ARMV30MZVERSION, 23, 0);
}

void uiController() {
	setupSubMenu("Controller Settings");
	drawSubItem("B Autofire: ", autoTxt[autoB]);
	drawSubItem("A Autofire: ", autoTxt[autoA]);
	drawSubItem("Controller: ", ctrlTxt[(joyCfg>>29)&1]);
	drawSubItem("Swap A-B:   ", autoTxt[(joyCfg>>10)&1]);
}

void uiDisplay() {
	setupSubMenu("Display Settings");
	drawSubItem("Gamma: ", brighTxt[g_gammaValue]);
	drawSubItem("B&W Palette: ", palTxt[g_paletteBank]);
	drawSubItem("Disable Foreground: ", autoTxt[g_gfxMask&1]);
	drawSubItem("Disable Background: ", autoTxt[(g_gfxMask>>1)&1]);
	drawSubItem("Disable Sprites: ", autoTxt[(g_gfxMask>>4)&1]);
}

static void uiMachine() {
	setupSubMenu("Machine Settings");
	drawSubItem("Language: ",langTxt[g_lang]);
	drawSubItem("Machine: ",machTxt[g_machine]);
	drawMenuItem(" Change Batteries");
	drawMenuItem(" Change Sub Battery");
	drawSubItem("Cpu speed hacks: ",autoTxt[(emuSettings&ALLOW_SPEED_HACKS)>>17]);
	drawMenuItem(" Bios Settings ->");
}

void uiSettings() {
	setupSubMenu("Settings");
	drawSubItem("Speed: ", speedTxt[(emuSettings>>6)&3]);
	drawSubItem("Autoload State: ", autoTxt[(emuSettings>>2)&1]);
	drawSubItem("Autoload Flash RAM: ", autoTxt[(emuSettings>>10)&1]);
	drawSubItem("Autosave Settings: ", autoTxt[(emuSettings>>9)&1]);
	drawSubItem("Autopause Game: ", autoTxt[emuSettings&1]);
	drawSubItem("Powersave 2nd Screen: ",autoTxt[(emuSettings>>1)&1]);
	drawSubItem("Emulator on Bottom: ", autoTxt[(emuSettings>>8)&1]);
	drawSubItem("Debug Output: ", autoTxt[gDebugSet&1]);
	drawSubItem("Autosleep: ", sleepTxt[(emuSettings>>4)&3]);
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
	loadCart(0);
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

/// Turn on/off scaling
void scalingSet(){
	g_scaling ^= 0x01;
	refreshGfx();
}

/// Change gamma (brightness)
void gammaSet() {
	g_gammaValue++;
	if (g_gammaValue > 4) g_gammaValue = 0;
	paletteInit(g_gammaValue);
	paletteTxAll();					// Make new palette visible
	setupMenuPalette();
	settingsChanged = true;
}

/// Turn on/off rendering of foreground
void fgrLayerSet(){
	g_gfxMask ^= 0x01;
}
/// Turn on/off rendering of background
void bgrLayerSet(){
	g_gfxMask ^= 0x02;
}
/// Turn on/off rendering of sprites
void sprLayerSet(){
	g_gfxMask ^= 0x10;
}

void paletteChange() {
	g_paletteBank++;
	if (g_paletteBank > 4) {
		g_paletteBank = 0;
	}
	monoPalInit();
	paletteTxAll();
	fixBiosSettings();
	settingsChanged = true;
}
/*
void borderSet() {
	bcolor++;
	if (bcolor > 2) {
		bcolor = 0;
	}
	makeborder();
}
*/
void languageSet() {
	g_lang ^= 0x01;
	fixBiosSettings();
}

void machineSet() {
	g_machine ^= 0x01;
}

void speedHackSet() {
	emuSettings ^= ALLOW_SPEED_HACKS;
	hacksInit();
}

void batteryChange() {
	batteryLevel = 0xFFFF;				// 0xFFFF for 2 days battery?
}

void subBatteryChange() {
	g_subBatteryLevel = 0x3FFFFFF;		// 0x3FFFFFF for 2 years battery?
}
