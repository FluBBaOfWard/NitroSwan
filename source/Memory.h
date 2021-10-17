#ifndef MEMORY_HEADER
#define MEMORY_HEADER

#ifdef __cplusplus
extern "C" {
#endif

uint8  t9LoadB(uint32 address);
uint16 t9LoadW(uint32 address);
uint32 t9LoadL(uint32 address);

void t9StoreB(uint8 data, uint32 address);
void t9StoreW(uint16 data, uint32 address);
void t9StoreL(uint32 data, uint32 address);

#ifdef __cplusplus
} // extern "C"
#endif

#endif	// MEMORY_HEADER
