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
#include "WSCart/WSCart.h"


int packState(void *statePtr) {
	int size = 0;
	memcpy(statePtr+size, wsRAM, sizeof(wsRAM));
	size += sizeof(wsRAM);
	size += sphinxSaveState(statePtr+size, &sphinx0);
	size += V30SaveState(statePtr+size, &V30OpTable);
	memcpy(statePtr+size, cartSRAM, sizeof(cartSRAM));
	size += sizeof(cartSRAM);
	size += wsEepromSaveState(statePtr+size, &cartEeprom);
	return size;
}

void unpackState(const void *statePtr) {
	int size = 0;
	memcpy(wsRAM, statePtr+size, sizeof(wsRAM));
	size += sizeof(wsRAM);
	size += sphinxLoadState(&sphinx0, statePtr+size);
	size += V30LoadState(&V30OpTable, statePtr+size);
	memcpy(cartSRAM, statePtr+size, sizeof(cartSRAM));
	size += sizeof(cartSRAM);
	size += wsEepromLoadState(&cartEeprom, statePtr+size);
}

int getStateSize() {
	int size = 0;
	size += sizeof(wsRAM);
	size += sphinxGetStateSize();
	size += V30GetStateSize();
	size += sizeof(cartSRAM);
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

static void setupBorderTiles(const void *tiles) {
	decompress(tiles, BG_TILE_RAM(1), LZ77Vram);
}

static void setupBorderMap(const void *map) {
	decompress(map, BG_MAP_RAM(15), LZ77Vram);
}

void setupWSBorderPalette() {
	setupBorderPalette(WSBorderPal, WSBorderPalLen);
}

void setupWSCBorderPalette() {
	setupBorderPalette(WSCBorderPal, WSCBorderPalLen);
}

void setupSCBorderPalette() {
	setupBorderPalette(SCBorderPal, SCBorderPalLen);
}

void setupPCV2BorderPalette() {
	setupBorderPalette(PCV2BorderPal, PCV2BorderPalLen);
}

static void fillScreenMap(u16 val) {
	u16 *dest = BG_MAP_RAM(15) + (3 * 32) + 2;
	u16 fill = BG_MAP_RAM(15)[val];
	for (int i=0;i<18;i++) {
		for (int j=0;j<28;j++) {
			dest[i*32+j] = fill;
		}
	}
}

static void fillScreenRow(u16 val, int row) {
	u16 *dest = BG_MAP_RAM(15) + (3 * 32) + 2;
	u16 fill = BG_MAP_RAM(15)[val];
	for (int j=0;j<28;j++) {
		dest[row*32+j] = fill;
	}
}

void setupEmuBackground() {
	if (gMachine == HW_WONDERSWANCOLOR) {
		setupBorderTiles(WSCBorderTiles);
		setupBorderMap(WSCBorderMap);
		setupWSCBorderPalette();
	}
	else if (gMachine == HW_SWANCRYSTAL) {
		setupBorderTiles(SCBorderTiles);
		setupBorderMap(SCBorderMap);
		setupSCBorderPalette();
	}
	else if (gMachine == HW_WONDERSWAN) {
		setupBorderTiles(WSBorderTiles);
		setupBorderMap(WSBorderMap);
		setupWSBorderPalette();
	}
	else {
		setupBorderTiles(PCV2BorderTiles);
		setupBorderMap(PCV2BorderMap);
		setupPCV2BorderPalette();
	}
}

void setupEmuBgrShutDown() {
	if (gMachine == HW_WONDERSWANCOLOR) {
		setupBorderMap(WSCBorderMap);
		fillScreenMap(0x31E);
		fillScreenRow(0x31F, 5);
	}
	else if (gMachine == HW_SWANCRYSTAL) {
		setupBorderMap(SCBorderMap);
		fillScreenMap(0x31F);
	}
	else if (gMachine == HW_WONDERSWAN) {
		setupBorderMap(WSBorderMap);
		fillScreenMap(0x31F);
	}
	else {
		setupBorderMap(PCV2BorderMap);
		fillScreenMap(0x31F);
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
