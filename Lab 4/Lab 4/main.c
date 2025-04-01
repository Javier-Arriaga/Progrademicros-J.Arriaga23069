/*
 * Lab 4.c
 *
 * Created: 31/03/2025 00:25:18
 * Author : Javier
 */ 

/****************************************/
// Encabezado (Libraries)
#include <avr/io.h>
#include <avr/interrupt.h>
#include <util/delay.h>

/****************************************/
// Defines and Constants
#define DEBOUNCE_DELAY 50 // ms
#define INCREMENT_BUTTON PC0
#define DECREMENT_BUTTON PC1

/****************************************/
// Global Variables
volatile uint8_t counter = 0;

/****************************************/
// Function prototypes
void setup(void);
uint8_t debounce(uint8_t pin);

/****************************************/
// Main Function
int main(void) {
	setup();
	
	while(1) {
		// Increment counter if increment button pressed
		if (debounce(INCREMENT_BUTTON)) {
			counter++;
			PORTD = counter;
			while (!(PINC & (1 << INCREMENT_BUTTON))); // Wait for button release
		}
		
		// Decrement counter if decrement button pressed
		if (debounce(DECREMENT_BUTTON)) {
			counter--;
			PORTD = counter;
			while (!(PINC & (1 << DECREMENT_BUTTON))); // Wait for button release
		}
	}
	
	return 0;
}

/****************************************/
// NON-Interrupt subroutines
void setup(void) {
	// Configure PORTD as output for LEDs (8 bits)
	DDRD = 0xFF;
	
	// Configure buttons as inputs with pull-ups
	DDRC &= ~((1 << INCREMENT_BUTTON) | (1 << DECREMENT_BUTTON));
	PORTC |= (1 << INCREMENT_BUTTON) | (1 << DECREMENT_BUTTON);
	
	// Initialize counter to 0
	counter = 0;
	PORTD = counter;
}

uint8_t debounce(uint8_t pin) {
	if (!(PINC & (1 << pin))) { // If button is pressed (LOW)
		_delay_ms(DEBOUNCE_DELAY);
		if (!(PINC & (1 << pin))) { // Verify after delay
			return 1; // Button truly pressed
		}
	}
	return 0; // Not pressed or bounce
}

/****************************************/
// Interrupt routines
// (Not used in this implementation but left as placeholder)
ISR(PCINT0_vect) {
	// Potential interrupt service routine for pin change
	// Not implemented in this version
}