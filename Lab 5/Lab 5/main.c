/*
 * Lab 5.c
 *
 * Created: 8/04/2025 12:54:17
 * Author : Javie
 */ 
#include <avr/io.h>
#include <util/delay.h>
#include "Servo.h"

void ADC_init() {
	ADMUX = (1 << REFS0) | 0x07; // AVcc como referencia y usar ADC7 (A7)
	ADCSRA = (1 << ADEN) | (1 << ADPS1) | (1 << ADPS0); // Prescaler de 8
}

uint16_t ADC_read() {
	ADCSRA |= (1 << ADSC); // Iniciar conversión
	while (ADCSRA & (1 << ADSC)); // Esperar a que termine
	return ADC; // Leer el resultado
}

int main(void) {
	ADC_init();
	PWM_init();

	while (1) {
		uint16_t adc = ADC_read(); // 0 - 1023
		uint8_t angle = adc * 180UL / 1023; // Mapear a 0-180 grados
		PWM_setAngle(angle);
		_delay_ms(100);
	}
}