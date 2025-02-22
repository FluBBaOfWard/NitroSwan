#include <nds.h>

#include "WonderSwan.h"
#include "Shared/EmuMenu.h"
#include "WSBorder.h"
#include "WSCBorder.h"
#include "SCBorder.h"
#include "PCV2Border.h"
#include "Gui.h"
#include "Cart.h"
#include "Gfx.h"
#include "ARMV30MZ/ARMV30MZ.h"


int packState(void *statePtr) {
	int size = 0;
	memcpy(statePtr+size, wsRAM, sizeof(wsRAM));
	size += sizeof(wsRAM);
	size += sphinxSaveState(statePtr+size, &sphinx0);
	size += V30SaveState(statePtr+size, &V30OpTable);
	memcpy(statePtr+size, wsSRAM, sizeof(wsSRAM));
	size += sizeof(wsSRAM);
	size += wsEepromSaveState(statePtr+size, &extEeprom);
	return size;
}

void unpackState(const void *statePtr) {
	int size = 0;
	memcpy(wsRAM, statePtr+size, sizeof(wsRAM));
	size += sizeof(wsRAM);
	size += sphinxLoadState(&sphinx0, statePtr+size);
	size += V30LoadState(&V30OpTable, statePtr+size);
	memcpy(wsSRAM, statePtr+size, sizeof(wsSRAM));
	size += sizeof(wsSRAM);
	size += wsEepromLoadState(&extEeprom, statePtr+size);
}

int getStateSize() {
	int size = 0;
	size += sizeof(wsRAM);
	size += sphinxGetStateSize();
	size += V30GetStateSize();
	size += sizeof(wsSRAM);
	size += wsEepromGetStateSize();
	return size;
}

static void setupBorderPalette(const unsigned short *palette, int len) {
	vramSetBankF(VRAM_F_LCD);
	if (gBorderEnable == 0) {
		memset(VRAM_F, 0, len);
	}
	else {
		memcpy(VRAM_F, palette, len);
	}
	// Copy Icon colors.
	memcpy(VRAM_F + 0xF0, MAPPED_BNW, sizeof(MAPPED_BNW));
	vramSetBankF(VRAM_F_BG_EXT_PALETTE_SLOT23);
	paletteTxAll();					// Make new palette visible
}

void setupWSBackground() {
	decompress(WSBorderTiles, BG_TILE_RAM(1), LZ77Vram);
	decompress(WSBorderMap, BG_MAP_RAM(15), LZ77Vram);
}

void setupWSBorderPalette() {
	setupBorderPalette(WSBorderPal, WSBorderPalLen);
}

void setupWSCBackground() {
	decompress(WSCBorderTiles, BG_TILE_RAM(1), LZ77Vram);
	decompress(WSCBorderMap, BG_MAP_RAM(15), LZ77Vram);
}

void setupWSCBorderPalette() {
	setupBorderPalette(WSCBorderPal, WSCBorderPalLen);
}

void setupSCBackground() {
	decompress(SCBorderTiles, BG_TILE_RAM(1), LZ77Vram);
	decompress(SCBorderMap, BG_MAP_RAM(15), LZ77Vram);
}

void setupSCBorderPalette() {
	setupBorderPalette(SCBorderPal, SCBorderPalLen);
}

void setupPCV2Background() {
	decompress(PCV2BorderTiles, BG_TILE_RAM(1), LZ77Vram);
	decompress(PCV2BorderMap, BG_MAP_RAM(15), LZ77Vram);
}

void setupPCV2BorderPalette() {
	setupBorderPalette(PCV2BorderPal, PCV2BorderPalLen);
}

void setupEmuBackground() {
	if (gMachine == HW_WONDERSWANCOLOR) {
		setupWSCBackground();
		setupWSCBorderPalette();
	}
	else if (gMachine == HW_SWANCRYSTAL) {
		setupSCBackground();
		setupSCBorderPalette();
	}
	else if (gMachine == HW_WONDERSWAN) {
		setupWSBackground();
		setupWSBorderPalette();
	}
	else {
		setupPCV2Background();
		setupPCV2BorderPalette();
	}
}

void setupEmuBorderPalette() {
	if (gMachine == HW_WONDERSWANCOLOR) {
		setupWSCBorderPalette();
	}
	else if (gMachine == HW_SWANCRYSTAL) {
		setupSCBorderPalette();
	}
	else if (gMachine == HW_WONDERSWAN) {
		setupWSBorderPalette();
	}
	else {
		setupPCV2BorderPalette();
	}
}
