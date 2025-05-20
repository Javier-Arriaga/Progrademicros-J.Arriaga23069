/*
 * SERVO3.c
 *
 * Created: 29/04/2025 14:21:31
 *  Author: Javie
 */ 
#include "SERVO3.h"

void PWM3_init() {
	DDRB |= (1 << PB3); // OC2A como salida

	// Fast PWM con TOP=OCR2A no es posible, usamos modo normal con prescaler alto
	TCCR2A = (1 << COM2A1) | (1 << WGM20) | (1 << WGM21); // Fast PWM
	TCCR2B = (1 << CS22) | (1 << CS21) | (1 << CS20);     // Prescaler 1024 (~61 Hz)
}

void PWM3_setAngle(uint8_t angle) {
	// Mapeo reducido para 8 bits (0–255) resolución pobre
	// Pulso de 1ms ~ 16, 2ms ~ 32 (con prescaler 1024 y 16MHz)
	uint8_t ticks = 16 + (angle * 16UL / 180); // entre 16 y 32 aprox
	OCR2A = ticks;
}
