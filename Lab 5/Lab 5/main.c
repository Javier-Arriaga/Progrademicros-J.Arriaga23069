/*
 * Lab 5.c
 *
 * Created: 8/04/2025 12:54:17
 * Author : Javie
 */ 
#define F_CPU 16000000
#include <avr/io.h>
#include <util/delay.h>
#include "Servo.h"
#include "Servo2.h"
#include "PWMManual.h"

void ADC_init() {
	ADMUX = (1 << REFS0);
	ADCSRA = (1 << ADEN) | (1 << ADPS1) | (1 << ADPS0); // Prescaler 8
}

uint16_t ADC_read(uint8_t channel) {
	ADMUX = (ADMUX & 0xF0) | (channel & 0x0F);
	ADCSRA |= (1 << ADSC);
	while (ADCSRA & (1 << ADSC));
	return ADC;
}

int main(void) {
	ADC_init();
	PWM_init();
	PWM2_init();
	PWMManual_init();

	// Configurar ICR1 solo una vez
	TCCR1B |= (1 << WGM13);
	ICR1 = 40000;

	while (1) {
		uint8_t angle1 = ADC_read(0) * 180UL / 1023;
		uint8_t angle2 = ADC_read(1) * 180UL / 1023;
		uint8_t brightness = ADC_read(2) / 4; // Escalar a 0–255

		PWM_setAngle(angle1);
		PWM2_setAngle(angle2);
		PWMManual_setLevel(brightness);

		_delay_ms(100);
	}
}
