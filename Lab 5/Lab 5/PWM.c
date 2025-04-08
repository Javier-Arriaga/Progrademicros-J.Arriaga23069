/*
 * PWM.c
 *
 * Created: 8/04/2025 12:56:09
 *  Author: Javie
 */ 
#include "Servo.h"

void PWM_init() {
	// Fast PWM, modo 14: TOP = ICR1
	TCCR1A = (1 << COM1A1) | (1 << WGM11);
	TCCR1B = (1 << WGM13) | (1 << WGM12) | (1 << CS11); // prescaler 8

	ICR1 = 40000; // TOP = 20 ms con reloj de 16MHz y prescaler 8
	DDRB |= (1 << PB1); // OC1A (D9) como salida
}

void PWM_setAngle(uint8_t angle) {
	// Mapear 0-180° a 1-2 ms ? 2000 a 4000 ticks (0.5 us cada tick)
	uint16_t ticks = 2000 + (angle * 11); // 11 = (2000/180)
	OCR1A = ticks;
}