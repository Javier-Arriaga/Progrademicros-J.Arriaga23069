/*
 * LAB 6.c
 *
 * Created: 22/04/2025 09:49:49
 * Author : Javie
 */ 
#include <avr/io.h>
#include <avr/interrupt.h>
#include "PRE.h"
#include "post.h"

// Prototipos
void setup(void);
void mostrarMenu(void);

// Variables globales
volatile char received_char;
volatile uint8_t new_data = 0;
volatile uint8_t ascii_mode = 0;

int main(void) {
	setup();
	mostrarMenu();
	
	while (1) {
		if (new_data) {
			new_data = 0;
			
			if (ascii_mode == 0) { // Modo menú
				if (received_char == '1') { // Leer potenciómetro
					uint8_t valor = ADC_read(0); // Canal A0
					
					// Mostrar en LEDs
					PORTB = valor & 0x1F; // bits 0-4 a PORTB
					PORTD = (PORTD & 0x1F) | (valor & 0xE0); // bits 5-7 a PD5-PD7
					
					// Mostrar en terminal
					UART_writeString("\nValor del potenciómetro (0-255): ");
					UART_mostrarValor(valor);
					UART_writeString("\n");
					
					mostrarMenu();
				}
				else if (received_char == '2') { // Enviar ASCII
					UART_writeString("\nIngrese un caracter ASCII: ");
					ascii_mode = 1;
					new_data = 0; // Esperar nuevo caracter
				}
				else { // Opción inválida
					UART_writeString("\nOpcion invalida.\n");
					mostrarMenu();
				}
			}
			else if (ascii_mode == 1) { // Modo ASCII
				// Mostrar en LEDs
				PORTB = received_char & 0x1F;
				PORTD = (PORTD & 0x1F) | ((received_char & 0xE0) >> 3);
				
				UART_writeString("\nCaracter recibido: ");
				UART_writeChar(received_char);
				UART_writeString("\n");
				
				ascii_mode = 0; // Volver al menú
				mostrarMenu();
			}
		}
	}
}

void setup(void) {
	cli(); // Desactivar interrupciones globales

	// Configurar LEDs
	DDRB |= 0x1F; // PB0-PB4 salida
	DDRD |= (1 << DDD5) | (1 << DDD6) | (1 << DDD7); // PD5-PD7 salida
	
	PORTB = 0x00;
	PORTD &= ~((1 << PORTD5) | (1 << PORTD6) | (1 << PORTD7));
	
	UART_init(); // Inicializar UART
	ADC_init();  // Inicializar ADC

	sei(); // Activar interrupciones globales
}

void mostrarMenu(void) {
	UART_writeString("\n----- MENU -----\n");
	UART_writeString("1. Leer Potenciometro\n");
	UART_writeString("2. Enviar Ascii\n");
	UART_writeString("Seleccione una opcion: ");
}

// ISR para recibir datos UART
ISR(USART_RX_vect) {
	received_char = UDR0;
	new_data = 1;
}
