// Bandai WonderSwan EEPROM emulation
//Microchip 93LCx6
//  93LC46 =>  1024 cells =>  128 x 8-bit or   64 x 16-bit
//  93LC56 =>  2048 cells =>  256 x 8-bit or  128 x 16-bit
//  93LC66 =>  4096 cells =>  512 x 8-bit or  256 x 16-bit
//  93LC76 =>  8192 cells => 1024 x 8-bit or  512 x 16-bit
//  93LC86 => 16384 cells => 2048 x 8-bit or 1024 x 16-bit

#ifndef EEPROM_HEADER
#define EEPROM_HEADER

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
	void *eepMemory;
	int eepSize;	// Size in bytes
	int eepMask;	// Address mask (size - 1)
	int eepAddress;	// Current address
	short eepData;	// Current data value
	u8 eepStatus;	// Status value
	u8 eepAdrBits;	// Number of bits in the address
	u8 eepMode;
	u8 eepCommand;
	u8 eepWidth;	// bus width in bits (8 or 16)
	u8 eepPadding1;
} WSEEPROM;

void wsEepromReset(int size, void *mem);
void wsEepromSetSize(int size);
void wsEepromWriteByte(int offset, int value);

/**
 * Saves the state of the chip to the destination.
 * @param  *destination: Where to save the state.
 * @param  *chip: The WSEEPROM chip to save.
 * @return The size of the state.
 */
int wsEepromSaveState(void *destination, const WSEEPROM *chip);

/**
 * Loads the state of the chip from the source.
 * @param  *chip: The WSEEPROM chip to load a state into.
 * @param  *source: Where to load the state from.
 * @return The size of the state.
 */
int wsEepromLoadState(WSEEPROM *chip, const void *source);

/**
 * Gets the state size of a WSEEPROM chip.
 * @return The size of the state.
 */
int wsEepromGetStateSize(void);

#ifdef __cplusplus
} // extern "C"
#endif

#endif // EEPROM_HEADER
