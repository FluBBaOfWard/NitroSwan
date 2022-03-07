#include <nds.h>

#include "WonderSwan.h"
#include "WSBorder.h"
#include "WSCBorder.h"
#include "Cart.h"
#include "Gfx.h"
#include "Sound.h"
#include "io.h"
#include "ARMV30MZ/ARMV30MZ.h"


int packState(void *statePtr) {
	int size = 0;
	memcpy(statePtr+size, wsRAM, sizeof(wsRAM));
	size += sizeof(wsRAM);
	size += ioSaveState(statePtr+size);
//	size += sn76496SaveState(statePtr+size, &k2Audio_0);
	size += sphinxSaveState(statePtr+size, &sphinx0);
//	size += v30MZSaveState(statePtr+size, &armV30MZState);
	return size;
}

void unpackState(const void *statePtr) {
	int size = 0;
	memcpy(wsRAM, statePtr+size, sizeof(wsRAM));
	size += sizeof(wsRAM);
	size += ioLoadState(statePtr+size);
//	size += sn76496LoadState(&k2Audio_0, statePtr+size);
	size += sphinxLoadState(&sphinx0, statePtr+size);
//	size += v30MZLoadState(&armV30MZState, statePtr+size);
}

int getStateSize() {
	int size = 0;
	size += sizeof(wsRAM);
	size += ioGetStateSize();
//	size += sn76496GetStateSize();
	size += sphinxGetStateSize();
//	size += v30MZGetStateSize();
	return size;
}

void setupWSBackground() {
	vramSetBankF(VRAM_F_LCD);
	decompress(WSBorderTiles, BG_TILE_RAM(1), LZ77Vram);
	decompress(WSBorderMap, BG_MAP_RAM(2), LZ77Vram);
	memcpy(VRAM_F, WSBorderPal, WSBorderPalLen);
	vramSetBankF(VRAM_F_BG_EXT_PALETTE_SLOT23);
}

void setupWSCBackground() {
	vramSetBankF(VRAM_F_LCD);
	decompress(WSCBorderTiles, BG_TILE_RAM(1), LZ77Vram);
	decompress(WSCBorderMap, BG_MAP_RAM(2), LZ77Vram);
	memcpy(VRAM_F, WSCBorderPal, WSCBorderPalLen);
	vramSetBankF(VRAM_F_BG_EXT_PALETTE_SLOT23);
}

void setupEmuBackground() {
	if (gMachine == HW_WONDERSWANCOLOR) {
		setupWSCBackground();
	}
	else {
		setupWSBackground();
	}
}
