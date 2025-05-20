/*
 * SERVO4.c
 *
 * Created: 29/04/2025 14:57:28
 *  Author: Javie
 */ 
#include "SERVO4.h"

void PWM4_init() {
	DDRD |= (1 << PD3); // OC2B como salida

	TCCR2A |= (1 << COM2B1) | (1 << WGM20) | (1 << WGM21); // Fast PWM
	TCCR2B |= (1 << CS22) | (1 << CS21) | (1 << CS20);     // Prescaler 1024
}

void PWM4_setAngle(uint8_t angle) {
	uint8_t ticks = 16 + (angle * 16UL / 180);
	OCR2B = ticks;
}
