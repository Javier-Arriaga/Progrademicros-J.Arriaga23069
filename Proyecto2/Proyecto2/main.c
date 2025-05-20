/*
 * Proyecto2.c
 *
 * Created: 29/04/2025 11:03:33
 * Author : Javie
 */ 
#define F_CPU 16000000UL
#include <avr/io.h>
#include <util/delay.h>
#include <avr/interrupt.h>
#include <stdlib.h>
#include <string.h>
#include "TEXTO.h"
#include "SERVO1.h"
#include "SERVO2.h"
#include "SERVO3.h"
#include "SERVO4.h"
#include "EEPROM.h"

#define MODO PB0
#define LED_MANUAL PD2
#define LED_UART PB4
#define POSESMAX 4
#define SERVOSPORPOSE 4
#define GUARDADO1 PD4
#define GUARDADO2 PD5
#define GUARDADO3 PD6
#define GUARDADO4 PD7

enum Mode {
	MANUAL = 0,
	EEPROM_MODE,
	UART_MODE,
	TOTAL_MODES
};

volatile enum Mode current_mode = MANUAL;
volatile uint8_t valor = 0;
volatile char caracter;

void ADC_init() {
	ADMUX = (1 << REFS0);
	ADCSRA = (1 << ADEN) | (1 << ADPS1) | (1 << ADPS0);
}

uint16_t ADC_read(uint8_t channel) {
	ADMUX = (ADMUX & 0xF0) | (channel & 0x0F);
	_delay_us(10);
	ADCSRA |= (1 << ADSC);
	while (ADCSRA & (1 << ADSC));
	return ADCW;
}

void button_init() {
	DDRB &= ~(1 << MODO);
	PORTB |= (1 << MODO);
	DDRD &= ~((1 << GUARDADO1) | (1 << GUARDADO2) | (1 << GUARDADO3) | (1 << GUARDADO4));
	PORTD |= (1 << GUARDADO1) | (1 << GUARDADO2) | (1 << GUARDADO3) | (1 << GUARDADO4);
}

void led_init() {
	DDRD |= (1 << LED_MANUAL);
	DDRB |= (1 << LED_UART);
}

void Revisarboton() {
	static uint8_t button_pressed = 0;
	if (!(PINB & (1 << MODO))) {
		if (!button_pressed) {
			_delay_ms(20);
			if (!(PINB & (1 << MODO))) {
				current_mode = (current_mode + 1) % TOTAL_MODES;
				button_pressed = 1;
			}
		}
	} else {
		button_pressed = 0;
	}
}

void display_menu() {
	UART_writeString("\r\n--- MENÚ ---\r\n");
	UART_writeString("1. Modo Manual (control con potenciómetros)\r\n");
	UART_writeString("2. Modo EEPROM (cargar poses guardadas)\r\n");
	UART_writeString("3. Modo UART\r\n");
	UART_writeString("Seleccione una opción (o use botón físico): ");
}

void Guardarpose(uint8_t numpose, uint8_t angles[SERVOSPORPOSE]) {
	uint16_t base_addr = numpose * SERVOSPORPOSE;
	for (uint8_t i = 0; i < SERVOSPORPOSE; i++) {
		ESCRITURA(angles[i], base_addr + i);
		_delay_ms(10);
	}
	UART_writeString("Pose guardada en EEPROM.\r\n");
}

void Cargarpose(uint8_t pose_index) {
	uint16_t base_addr = pose_index * SERVOSPORPOSE;
	uint8_t angles[SERVOSPORPOSE];
	for (uint8_t i = 0; i < SERVOSPORPOSE; i++) {
		angles[i] = LECTURA(base_addr + i);
	}
	PWM_setAngle(angles[0]);
	PWM2_setAngle(angles[1]);
	PWM3_setAngle(angles[2]);
	PWM4_setAngle(angles[3]);
}

void MenuUART() {
	UART_writeString("\r\n--- MENU DIRECCIONES :) ---\r\n");
	UART_writeString("1:Ceja IZQ\r\n");
	UART_writeString("2:Ceja DER\r\n");
	UART_writeString("3:Ojo IZQ\r\n");
	UART_writeString("4:Ojo DER\r\n");
	UART_writeString("-----------------------\r\n");
	UART_writeString("Ingrese Direccion: ");
}

uint8_t read_button_pressed() {
	if (!(PIND & (1 << GUARDADO1))) return 0;
	if (!(PIND & (1 << GUARDADO2))) return 1;
	if (!(PIND & (1 << GUARDADO3))) return 2;
	if (!(PIND & (1 << GUARDADO4))) return 3;
	return 0xFF;
}

int main(void) {
	UART_init();
	ADC_init();
	PWM_init();
	PWM2_init();
	PWM3_init();
	PWM4_init();
	button_init();
	led_init();

	enum Mode previous_mode = TOTAL_MODES; // Para forzar la primera impresión del menú
	static uint8_t menu_mostrado = 0; // Para evitar reimprimir el menú UART

	while (1) {
		Revisarboton();

		// Ya no leemos UDR0 aquí porque se hace en la ISR
		// Solo cambiamos de modo si 'valor' se activó y estamos fuera de UART_MODE
		if (valor && current_mode != UART_MODE) {
			switch (caracter) {
				case '1': current_mode = MANUAL; break;
				case '2': current_mode = EEPROM_MODE; break;
				case '3': current_mode = UART_MODE; break;
				default: UART_writeString("\r\nOpción inválida.\r\n"); break;
			}
			valor = 0; // Limpiamos bandera
		}

		// Si cambia el modo, mostrar mensaje y menú
		if (current_mode != previous_mode) {
			menu_mostrado = 0; // Reinicia menú UART si cambia el modo

			switch (current_mode) {
				case MANUAL: UART_writeString("\r\nModo Manual activado\r\n"); break;
				case EEPROM_MODE: UART_writeString("\r\nModo EEPROM activado\r\n"); break;
				case UART_MODE: UART_writeString("\r\nModo UART activado\r\n"); break;
				default:
				current_mode = MANUAL; // Valor seguro
				break;
			}
			display_menu();
			previous_mode = current_mode;
		}

		switch (current_mode) {
			case MANUAL: {
				PORTD |= (1 << LED_MANUAL);
				PORTB &= ~(1 << LED_UART);

				uint16_t adc0 = ADC_read(0);
				uint16_t adc1 = ADC_read(1);
				uint16_t adc2 = ADC_read(2);
				uint16_t adc3 = ADC_read(3);

				uint8_t angle0 = adc0 * 180UL / 1023;
				uint8_t angle1 = adc1 * 180UL / 1023;
				uint8_t angle2 = adc2 * 180UL / 1023;
				uint8_t angle3 = adc3 * 180UL / 1023;

				PWM_setAngle(angle0);
				PWM2_setAngle(angle1);
				PWM3_setAngle(angle2);
				PWM4_setAngle(angle3);

				uint8_t btn = read_button_pressed();
				if (btn != 0xFF) {
					_delay_ms(50);
					if (read_button_pressed() == btn) {
						uint8_t pose[SERVOSPORPOSE] = {angle0, angle1, angle2, angle3};
						Guardarpose(btn, pose);
						while (read_button_pressed() == btn);
					}
				}
				break;
			}

			case EEPROM_MODE: {
				PORTB &= ~(1 << LED_UART);
				PORTD &= ~(1 << LED_MANUAL);

				uint8_t btn = read_button_pressed();
				if (btn != 0xFF) {
					_delay_ms(50);
					if (read_button_pressed() == btn) {
						Cargarpose(btn);
						UART_writeString("Pose cargada desde EEPROM.\r\n");
						while (read_button_pressed() == btn);
					}
				}
				break;
			}

			case UART_MODE: {
				PORTB |= (1 << LED_UART);
				PORTD &= ~(1 << LED_MANUAL);

				if (!menu_mostrado) {
					MenuUART();
					menu_mostrado = 1;
				}

				if (valor) {
					switch (caracter) {
						case '1': OCR2A = 23; UART_writeString("\r\nCeja IZQ\r\n"); break;
						case '2': OCR2B = 9;  UART_writeString("\r\nCeja DER\r\n"); break;
						case '3': OCR1A = 60;  UART_writeString("\r\nOjo IZQ\r\n"); break;
						case '4': OCR1B = 25; UART_writeString("\r\nOjo DER\r\n"); break;
						default: UART_writeString("\r\nComando no válido. Intente de nuevo.\r\n"); break;
					}
					valor = 0;
					MenuUART(); // Muestra de nuevo el prompt para comando
				}
				break;
			}

			default:
			current_mode = MANUAL;
			break;
		}
	}
}

ISR(USART_RX_vect) {
	caracter = UDR0;
	valor = 1;
	UART_writeChar(caracter);
}