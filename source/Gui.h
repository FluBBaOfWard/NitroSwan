#ifndef GUI_HEADER
#define GUI_HEADER

#ifdef __cplusplus
extern "C" {
#endif

extern u8 g_gammaValue;

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

void debugIOUnimplR(u8 port);
void debugIOUnimplW(u8 port, u8 val);

void controllerSet(void);
void swapABSet(void);

void scalingSet(void);
void gammaSet(void);
void fgrLayerSet(void);
void bgrLayerSet(void);
void sprLayerSet(void);

#ifdef __cplusplus
} // extern "C"
#endif

#endif // GUI_HEADER
