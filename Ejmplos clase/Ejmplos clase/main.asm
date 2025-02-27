;
; Ejmplos clase.asm
;
; Created: 13/02/2025 14:00:56
; Author : Javie
;


.include "M328PDEF.inc" 
.cseg
.org 0x0000
	JMP START
.org 

//timer0 Normal
	SETUP:
		CLI // Desabilitar inturrupciones globales (borra I bit en SREG)
		// COnfiguracion Prescaler "Principal"
		LDI R16, (1<<CLKPCE)
		STS CLKPR, R16
		LDI R16, 0b00000100
		STS CLKPR

		//Inicializar temporizador
		LDI R16, (1 << CS01) |  (1 << CS00)
		OUT TCCR0B, R16
		LDI R16, 100
		OUT TCNT0, R16

		//Habilitar interrupciones TOV0
		LDI R16,  (1 << TOIE0)
		STS TIMSK0, R16

		//Configurar PBT COMO SALIDA
		SBI DDRB, PB5
		SBI DDRB, PB0
		CBI PORTB, PB5
		CBI PORTB, PB0

MAIN_LOOP:
	CPI		R20, 50
	BRNE	MAIN_LOOP
	CLR		R20
	SBI		PINB, PB5
	SBI		PINB, PB0
	RJMP	MAIN_LOOP

TMR0_ISR:
	LDI		R16, 100
	OUT		TCNT0, R16
	INC		R20

//EJEMPLOS 20/2
	//Timer1
	.equ T1VALUE= 0x0BDC
	.org 
		
	.cseg
	
	INIT_TMR1:
		LDI R16, HIGH(T1VALUE)
		STS 

		










