#ifndef GUI_HEADER
#define GUI_HEADER

#ifdef __cplusplus
extern "C" {
#endif

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
void uiAbout(void);

void debugIOUnmappedR(u16 port, u8 val);
void debugIOUnmappedW(u8 val, u16 port);
void debugIOUnimplR(u16 port, u8 val);
void debugIOUnimplW(u8 val, u16 port);
void debugSerialOutW(u8 val);
void debugDivideError(void);
void debugUndefinedInstruction(void);
void debugCrashInstruction(void);

#ifdef __cplusplus
} // extern "C"
#endif

#endif // GUI_HEADER
