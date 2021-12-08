#ifndef IO_HEADER
#define IO_HEADER

#ifdef __cplusplus
extern "C" {
#endif

extern u32 joyCfg;
extern u32 EMUinput;
extern u32 batteryLevel;
extern u8 wsEepromMem[0x80];
extern u8 wscEepromMem[0x800];

/**
 * Saves the state of io to the destination.
 * @param  *destination: Where to save the state.
 * @return The size of the state.
 */
int ioSaveState(void *destination);

/**
 * Loads the state of io from the source.
 * @param  *source: Where to load the state from.
 * @return The size of the state.
 */
int ioLoadState(const void *source);

/**
 * Gets the state size of an io state.
 * @return The size of the state.
 */
int ioGetStateSize(void);

/// Copies the time from the NDS RTC to the WS RTC.
void transferTime(void);


#ifdef __cplusplus
} // extern "C"
#endif

#endif	// IO_HEADER
