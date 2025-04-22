/*
 * PWMManual.c
 *
 * Created: 19/04/2025 13:10:07
 *  Author: Javie
 */ 
#include "PWMManual.h"
#include <avr/interrupt.h>

volatile uint8_t setpoint = 0;
volatile uint8_t count = 0;

void PWMManual_init() {
	DDRD |= (1 << PD6); // D6 como salida

	TCCR0A = (1 << WGM01); // Modo CTC
	TCCR0B = (1 << CS01) | (1 << CS00); // Prescaler 64
	OCR0A = 25; // 25 ticks = 0.1 ms 100 Hz PWM con count hasta 100

	TIMSK0 |= (1 << OCIE0A); // Habilita interrupción
	sei();
}

void PWMManual_setLevel(uint8_t value) {
	if (value > 100) value = 100;
	setpoint = value;
}

ISR(TIMER0_COMPA_vect) {
	if (count < setpoint) {
		PORTD |= (1 << PD6); // LED ON
		} else {
		PORTD &= ~(1 << PD6); // LED OFF
	}

	count++;
	if (count >= 100) count = 0;
}