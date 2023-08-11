#ifndef MAIN_HEADER
#define MAIN_HEADER

#ifdef __cplusplus
extern "C" {
#endif

extern bool powerIsOn;
extern bool gameInserted;
extern uint16 *map0sub;

void waitVBlank(void);

/**
 * Waits the specified number of frames before returning.
 * @param  count: Number of frames to wait.
 * @deprecated Don't use, solve it some other way.
 */
void pausVBlank(int count);

void setEmuSpeed(int speed);
void setupMenuPalette(void);

#ifdef __cplusplus
} // extern "C"
#endif

#endif // MAIN_HEADER
