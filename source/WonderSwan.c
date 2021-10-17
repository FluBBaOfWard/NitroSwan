#include <nds.h>

#include "WonderSwan.h"
#include "Cart.h"
#include "Gfx.h"
#include "Sound.h"
#include "io.h"
#include "TLCS900H/TLCS900H.h"
#include "ARMV30MZ/ARMV30MZ.h"


int packState(void *statePtr) {
	int size = 0;
	memcpy(statePtr+size, ngpRAM, sizeof(ngpRAM));
	size += sizeof(ngpRAM);
	size += ioSaveState(statePtr+size);
	size += sn76496SaveState(statePtr+size, &k2Audio_0);
	size += k2GESaveState(statePtr+size, &k2GE_0);
	size += Z80SaveState(statePtr+size, &Z80OpTable);
	size += tlcs900HSaveState(statePtr+size, &tlcs900HState);
	return size;
}

void unpackState(const void *statePtr) {
	int size = 0;
	memcpy(ngpRAM, statePtr+size, sizeof(ngpRAM));
	size += sizeof(ngpRAM);
	size += ioLoadState(statePtr+size);
	size += sn76496LoadState(&k2Audio_0, statePtr+size);
	size += k2GELoadState(&k2GE_0, statePtr+size);
	size += Z80LoadState(&Z80OpTable, statePtr+size);
	tlcs900HLoadState(&tlcs900HState, statePtr+size);
}

int getStateSize() {
	int size = 0;
	size += sizeof(ngpRAM);
	size += ioGetStateSize();
	size += sn76496GetStateSize();
	size += k2GEGetStateSize();
	size += Z80GetStateSize();
	size += tlcs900HGetStateSize();
	return size;
}
