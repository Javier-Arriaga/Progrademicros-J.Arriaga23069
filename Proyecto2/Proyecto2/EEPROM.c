/*
 * EEPROM.c
 *
 * Created: 6/05/2025 14:50:56
 *  Author: Javie
 */ 

#include <avr/eeprom.h>

void ESCRITURA(uint8_t dato, uint16_t direccionEEPROM) {
    while (EECR & (1 << EEPE));       // Esperar si EEPROM está ocupada
    EEAR = direccionEEPROM;           // Establecer dirección de EEPROM
    EEDR = dato;                      // Colocar dato a escribir
    EECR |= (1 << EEMPE);             // Habilitar escritura (master)
    EECR |= (1 << EEPE);              // Iniciar escritura
}

uint16_t LECTURA(uint16_t direccionEEPROM) {
    while (EECR & (1 << EEPE));       // Esperar si EEPROM está ocupada
    EEAR = direccionEEPROM;           // Establecer dirección
    EECR |= (1 << EERE);              // Iniciar lectura
    return EEDR;                      // Devolver dato leído
}
