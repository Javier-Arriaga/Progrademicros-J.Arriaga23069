/*
 * SERVO2.c
 *
 * Created: 29/04/2025 13:49:53
 *  Author: Javie
 */ 
#include "SERVO2.h"

void PWM2_init() {
	TCCR1A |= (1 << COM1B1); // No invertido
	DDRB |= (1 << PB2); 
}

void PWM2_setAngle(uint8_t angle) {
	uint16_t ticks = 2000 + (angle * 11); // Mapear 0°–180° a 2000–4000 ticks
	OCR1B = ticks;
}
