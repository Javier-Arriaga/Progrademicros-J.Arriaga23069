/*
 * PWM2.c
 *
 * Created: 8/04/2025 15:15:29
 *  Author: Javie
 */ 
#include "Servo2.h"

void PWM2_init() {
	// Activar OC1B (PB2), usar modo Fast PWM con TOP en ICR1
	TCCR1A |= (1 << COM1B1); // No invertido
	DDRB |= (1 << PB2); // PB2 como salida (OC1B)
}

void PWM2_setAngle(uint8_t angle) {
	uint16_t ticks = 2000 + (angle * 11); // Mapear 0°–180° a 2000–4000 ticks
	OCR1B = ticks;
}
