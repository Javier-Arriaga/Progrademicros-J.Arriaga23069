/*
 * EEPROM.h
 *
 * Created: 6/05/2025 14:50:27
 *  Author: Javie
 */ 


#ifndef EEPROM_H_
#define EEPROM_H_


void EEPROM_init();
void ESCRITURA(uint8_t ANGULO, uint16_t PosicionEEPROM);
uint16_t LECTURA(uint8_t ANGULO);


#endif /* EEPROM_H_ */