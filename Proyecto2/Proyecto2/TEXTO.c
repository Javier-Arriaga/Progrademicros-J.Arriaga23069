/*
 * TEXTO.c
 *
 * Created: 29/04/2025 15:04:28
 *  Author: Javie
 */ 
#define F_CPU 16000000UL
#include <avr/io.h>
#include <util/delay.h>
#include <avr/interrupt.h>
#include "TEXTO.h"

void UART_init(void) {
	
	DDRD |= (1 << DDD1); // TX salida
	DDRD &= ~(1 << DDD0); // RX entrada
	sei(); // Habilita interrupciones globales
	UCSR0A = 0;
	UCSR0B = (1 << RXCIE0) | (1 << RXEN0) | (1 << TXEN0);
	UCSR0C = (1 << UCSZ01) | (1 << UCSZ00);
	UBRR0 = 103; // 9600 baudios @16MHz
}

void UART_writeChar(char caracter) {
	while (!(UCSR0A & (1 << UDRE0)));
	UDR0 = caracter;
}

void UART_writeString(char* texto) {
	for (uint8_t i = 0; texto[i] != '\0'; i++) {
		UART_writeChar(texto[i]);
	}
}