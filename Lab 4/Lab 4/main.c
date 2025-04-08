
/*
 * Lab 4.c
 *
 * Created: 31/03/2025 00:25:18
 * Author : Javier
 */ 

/****************************************/
// Encabezado (Libraries)
#define  Tabla PORTD
#include <avr/io.h>
#include <avr/interrupt.h>
#include <util/delay.h>
#define F_CPU = 16000000
#define ALARM_LED PC0  // LED de alarma conectado al pin PC0


/****************************************/
// Defines and Constants
#define DEBOUNCE_DELAY 50 // ms
#define INCREMENT_BUTTON PB0
#define DECREMENT_BUTTON PB1
#define  Tabla PORTD

const uint8_t tabla[16]=
{
	0x3F,
	0x06,
	0x5B,
	0x4F,
	0x66,
	0x6D,
	0x7D,
	0x07,
	0x7F,
	0x6F,
	0x77,
	0x7C,
	0x39,
	0x5E,
	0x79,
	0x71
};
/****************************************/
// Global Variables
volatile uint8_t counter = 0;
uint8_t valorADC = 0;

/****************************************/
// Function prototypes
void setup(void);
uint8_t debounce(uint8_t pin);
void initADC(void);

/****************************************/
// Main Function
int main(void) {
	setup();
	
	while(1) {
		// Increment counter if increment button pressed
		if (debounce(INCREMENT_BUTTON)) {
			counter++;
			while (!(PINB & (1 << INCREMENT_BUTTON))); // Wait for button release
		}
		
		// Decrement counter if decrement button pressed
		if (debounce(DECREMENT_BUTTON)) {
			counter--;
			while (!(PINB & (1 << DECREMENT_BUTTON))); // Wait for button release
		}
		
		// Comparación para LED de alarma
		if (valorADC > counter) {
			PORTC |= (1 << ALARM_LED); // Encender LED de alarma
			} else {
			PORTC &= ~(1 << ALARM_LED); // Apagar LED
		}
		
		// Multiplexar CONTADOR (display 1 y 2, 5ms cada uno)
		PORTB &= ~((1 << PORTB2) | (1 << PORTB3));
		PORTD = tabla[counter & 0x0F]; // Parte baja del contador
		PORTB |= (1 << PORTB3);
		_delay_ms(5);
		
		PORTB &= ~(1 << PORTB3);
		PORTD = tabla[counter >> 4]; // Parte alta del contador
		PORTB |= (1 << PORTB2);
		_delay_ms(5);
		
		// Multiplexar ADC (display 1 y 2, 5ms cada uno)
		PORTB &= ~((1 << PORTB2) | (1 << PORTB3));
		PORTD = tabla[valorADC & 0x0F];
		PORTB |= (1 << PORTB3);
		_delay_ms(5);
		
		PORTB &= ~(1 << PORTB3);
		PORTD = tabla[valorADC >> 4];
		PORTB |= (1 << PORTB2);
		_delay_ms(5);
	}
	
	return 0;
}

/****************************************/
// NON-Interrupt subroutines
void setup(void) {
	
	// Configure PORTD as output for LEDs (8 bits)
	DDRD = 0xFF;
	
	// Configure buttons as inputs with pull-ups
	DDRB &= ~((1 << INCREMENT_BUTTON) | (1 << DECREMENT_BUTTON));
	DDRB |= (1 << DDD3) | (1 << DDD2);
	PORTB |= (1 << INCREMENT_BUTTON) | (1 << DECREMENT_BUTTON);
	
	// Initialize counter to 0
	counter = 0;
	PORTD = counter;
	
	cli();
	CLKPR = (1 << CLKPCE);
	CLKPR = (1 << CLKPS2);
		
	UCSR0B = 0x00;
	initADC();
	sei();
	
	DDRC |= (1 << ALARM_LED);  // Configurar LED como salida
	PORTC &= ~(1 << ALARM_LED);  // Asegurarse que inicia apagado
}


void initADC(void) 
{
	ADMUX =0;
	ADMUX |= (1 << REFS0);
	ADMUX |= (1 << ADLAR);
	ADMUX |= (1 << MUX2) | (1 << MUX1) | (1 << MUX0);
	
	ADCSRA = 0;
	ADCSRA |= (1 << ADEN) | (1 << ADIE) | (1 << ADPS1) | (1 << ADPS0);
	
	ADCSRA |= (1 << ADSC);
}

uint8_t debounce(uint8_t pin) {
	if (!(PINB & (1 << pin))) { // If button is pressed (LOW)
		_delay_ms(DEBOUNCE_DELAY);
		if (!(PINB & (1 << pin))) { // Verify after delay
			return 1; // Button truly pressed
		}
	}
	return 0; // Not pressed or bounce
}

/****************************************/
// Interrupt routines
ISR(ADC_vect)
{
		valorADC = ADCH;
		ADCSRA |= (1 << ADSC);
}
