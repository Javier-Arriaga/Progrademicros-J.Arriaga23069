/*
 * EEPROM.c
 *
 * Created: 6/05/2025 14:50:56
 *  Author: Javie
 */ 

#include <avr/eeprom.h>

void EEPROM_init(void){
		EECR |= (1 << EEPE) | (1 << EERE);
	
}

void EEPROM_write( uint8_t Dato, uint16_t Posicion){
	while(EECR & ( 1<<EEPE));
	EEAR0 = Dato;
	EEDR =Posicion;
	EECR |= (1<<EEMPE);
	EECR |= (1<<EEPE);
}

uint16_t EEPROM_read(uint8_t Dato){
	while(EECR & (1<<EEPE));
	EEAR= Dato;
	EECR |= (1<<EERE);
	return EEDR;
}