#include <nds.h>

#include "WonderSwan.h"
#include "PCV2Border.h"
#include "WSBorder.h"
#include "WSCBorder.h"
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
	vramSetBankF(VRAM_F_LCD);
	decompress(PCV2BorderTiles, BG_TILE_RAM(1), LZ77Vram);
	decompress(PCV2BorderMap, BG_MAP_RAM(11), LZ77Vram);
	memcpy(VRAM_F, PCV2BorderPal, PCV2BorderPalLen);
	vramSetBankF(VRAM_F_BG_EXT_PALETTE_SLOT23);
}

void setupWSBackground() {
	vramSetBankF(VRAM_F_LCD);
	decompress(WSBorderTiles, BG_TILE_RAM(1), LZ77Vram);
	decompress(WSBorderMap, BG_MAP_RAM(11), LZ77Vram);
	memcpy(VRAM_F, WSBorderPal, WSBorderPalLen);
	vramSetBankF(VRAM_F_BG_EXT_PALETTE_SLOT23);
}

void setupWSCBackground() {
	vramSetBankF(VRAM_F_LCD);
	decompress(WSCBorderTiles, BG_TILE_RAM(1), LZ77Vram);
	decompress(WSCBorderMap, BG_MAP_RAM(11), LZ77Vram);
	memcpy(VRAM_F, WSCBorderPal, WSCBorderPalLen);
	vramSetBankF(VRAM_F_BG_EXT_PALETTE_SLOT23);
}

void setupEmuBackground() {
	if (gMachine == HW_WONDERSWANCOLOR) {
		setupWSCBackground();
	}
	else if (gMachine == HW_WONDERSWAN) {
		setupWSBackground();
	}
	else {
		setupPCV2Background();
	}
}
