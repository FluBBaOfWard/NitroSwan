#include <nds.h>

#include "WonderSwan.h"
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
	size += wsVideoSaveState(statePtr+size, &wsv_0);
//	size += v30MZSaveState(statePtr+size, &armV30MZState);
	return size;
}

void unpackState(const void *statePtr) {
	int size = 0;
	memcpy(wsRAM, statePtr+size, sizeof(wsRAM));
	size += sizeof(wsRAM);
	size += ioLoadState(statePtr+size);
//	size += sn76496LoadState(&k2Audio_0, statePtr+size);
	size += wsVideoLoadState(&wsv_0, statePtr+size);
//	size += v30MZLoadState(&armV30MZState, statePtr+size);
}

int getStateSize() {
	int size = 0;
	size += sizeof(wsRAM);
	size += ioGetStateSize();
//	size += sn76496GetStateSize();
	size += wsVideoGetStateSize();
//	size += v30MZGetStateSize();
	return size;
}
