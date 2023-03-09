#ifndef GUI_HEADER
#define GUI_HEADER

#ifdef __cplusplus
extern "C" {
#endif

extern u8 gGammaValue;
extern u8 gContrastValue;
extern u8 gBorderEnable;

void setupGUI(void);
void enterGUI(void);
void exitGUI(void);
void quickSelectGame(void);
void nullUINormal(int key);
void nullUIDebug(int key);
void resetGame(void);
void ejectGame(void);

void uiNullNormal(void);
void uiFile(void);
void uiSettings(void);
void uiAbout(void);
void uiOptions(void);
void uiController(void);
void uiDisplay(void);

void debugIOUnmappedR(u16 port, u8 val);
void debugIOUnmappedW(u16 port, u8 val);
void debugIOUnimplR(u16 port, u8 val);
void debugIOUnimplW(u16 port, u8 val);
void debugDivideError(void);
void debugUndefinedInstruction(void);
void debugCrashInstruction(void);

void controllerSet(void);
void swapABSet(void);

void gammaSet(void);
void contrastSet(void);
void fgrLayerSet(void);
void bgrLayerSet(void);
void sprLayerSet(void);

#ifdef __cplusplus
} // extern "C"
#endif

#endif // GUI_HEADER
