#include <nds.h>

#include "WonderSwan.h"
#include "PCV2Border.h"
#include "WSBorder.h"
#include "WSCBorder.h"
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

void setupPCV2Background() {
	decompress(PCV2BorderTiles, BG_TILE_RAM(1), LZ77Vram);
	decompress(PCV2BorderMap, BG_MAP_RAM(15), LZ77Vram);
	vramSetBankF(VRAM_F_LCD);
	memcpy(VRAM_F, PCV2BorderPal, PCV2BorderPalLen);
	vramSetBankF(VRAM_F_BG_EXT_PALETTE_SLOT23);
}

void setupWSBackground() {
	decompress(WSBorderTiles, BG_TILE_RAM(1), LZ77Vram);
	decompress(WSBorderMap, BG_MAP_RAM(15), LZ77Vram);
}

void setupWSBorderPalette() {
	vramSetBankF(VRAM_F_LCD);
	memcpy(VRAM_F, WSBorderPal, WSBorderPalLen);
	memcpy(VRAM_F + 0xF0, MAPPED_BNW, sizeof(MAPPED_BNW));
	vramSetBankF(VRAM_F_BG_EXT_PALETTE_SLOT23);
}

void setupWSCBackground() {
	decompress(WSCBorderTiles, BG_TILE_RAM(1), LZ77Vram);
	decompress(WSCBorderMap, BG_MAP_RAM(15), LZ77Vram);
}

void setupWSCBorderPalette() {
	vramSetBankF(VRAM_F_LCD);
	memcpy(VRAM_F, WSCBorderPal, WSCBorderPalLen);
	memcpy(VRAM_F + 0xF0, MAPPED_BNW, sizeof(MAPPED_BNW));
	vramSetBankF(VRAM_F_BG_EXT_PALETTE_SLOT23);
}

void setupEmuBackground() {
	monoPalInit(gGammaValue, gContrastValue);
	if (gMachine == HW_WONDERSWANCOLOR || gMachine == HW_SWANCRYSTAL) {
		setupWSCBackground();
		setupWSCBorderPalette();
	}
	else if (gMachine == HW_WONDERSWAN) {
		setupWSBackground();
		setupWSBorderPalette();
	}
	else {
		setupPCV2Background();
	}
}

void setupEmuBorderPalette() {
	if (gMachine == HW_WONDERSWANCOLOR || gMachine == HW_SWANCRYSTAL) {
		setupWSCBorderPalette();
	}
	else if (gMachine == HW_WONDERSWAN) {
		setupWSBorderPalette();
	}
}
