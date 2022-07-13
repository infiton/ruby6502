#ifndef FAKE6502
#define FAKE6502

void reset6502();
void step6502();
void exec6502(uint32_t tickcount);
void hookexternal(void *funcptr);

uint16_t getPC();
uint8_t getSP();
uint8_t getA();
uint8_t getX();
uint8_t getY();
uint8_t getStatus();
uint32_t getInstructions();

#endif
