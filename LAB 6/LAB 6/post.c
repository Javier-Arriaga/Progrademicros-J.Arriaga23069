/*
 * post.c
 *
 * Created: 28/04/2025 12:20:12
 *  Author: Javie
 */ 
#include "post.h"

void ADC_init(void) {
	ADMUX = (1 << REFS0); // Referencia AVcc
	ADCSRA = (1 << ADEN) | (1 << ADPS2) | (1 << ADPS1) | (1 << ADPS0); // Habilitar ADC y prescaler de 128
}

uint8_t ADC_read(uint8_t canal) {
	ADMUX = (ADMUX & 0xF0) | (canal & 0x0F); // Seleccionar canal
	ADCSRA |= (1 << ADSC); // Iniciar conversión
	while (ADCSRA & (1 << ADSC)); // Esperar a que termine
	return ADC >> 2; // Convertir de 10 bits a 8 bits
}
