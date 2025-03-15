;
; Proyecto 1.asm
;
; Created: 25/02/2025 13:14:25
; Author : Javier Arriaga
;
.include "m328pdef.inc"
.equ MODOS = 8
.equ MAX_USEC = 10
.equ MAX_DSEC = 6
.equ MAX_UMIN = 10
.equ MAX_DMIN = 6
.equ MAX_UHORA = 10
.equ MAX_DHORA = 2
.equ MAX_UDIA = 10
.equ MAX_DDIA = 3
.equ MAX_UMES = 10
.equ MAX_DMES = 1

.dseg
.org	SRAM_START
USEC:	.byte 1
DSEC:	.byte 1
UMIN:	.byte 1
DMIN:	.byte 1
UHORA:	.byte 1
DHORA:	.byte 1
UDIA:	.byte 1
DDIA:	.byte 1
UMES:	.byte 1
DMES:	.byte 1

.cseg
.org 0x0000
    rjmp START
.org OVF0addr
    rjmp TIMER0_OVERFLOW  ; Interrupción por overflow del Timer0

; Definición de registros para contadores
.def MODO = R19
.def OVERFLOW_COUNT = R18     ; Contador de overflows (para segundos)
.def DISPLAY_FLAG = R17       ; Flag para alternar entre displays

;--------------------------------------------------------------------------------------------------------------------------------------

ISR_PCINT0:
    PUSH R16
    IN R16, SREG
    PUSH R16

    ; Leer el estado de los pines PC0-PC2
    IN R16, PINC
    ANDI R16, 0x07       ; Aplicar máscara para obtener solo los bits de PC0-PC2

    ; Llamar a las funciones de configuración según el botón presionado
    SBIS PINC, PC0        ; Si se presiona PC0 (incrementar)
    RCALL INCREMENTAR_CONFIG
    SBIS PINC, PC1        ; Si se presiona PC1 (decrementar)
    RCALL DECREMENTAR_CONFIG

    ; Restaurar el estado de los registros
    POP R16
    OUT SREG, R16
    POP R16

    RETI                 

;--------------------------------------------------------------------------------------------------------------------------------------

START:
// Configuración de pila (Stack)
    LDI R16, LOW(RAMEND)
    OUT SPL, R16
    LDI R16, HIGH(RAMEND)
    OUT SPH, R16



SETUP:
    CLI		; Deshabilita las interrupciones

    // Configurar Prescaler "Principal"
    LDI R16, (1 << CLKPCE)
    STS CLKPR, R16    ; Habilitar cambio de PRESCALER
    LDI R16, 0b00000100
    STS CLKPR, R16    ; Configurar Prescaler a 16 (1MHz)

    // Configuración de los puertos
    LDI R16, 0x0F
    OUT DDRB, R16         ; Configura PB0-PB3 como salidas (transistores)
    LDI R16, 0x00
    OUT PORTB, R16        ; Apaga todos los transistores

    LDI R16, 0b0011_1000
    OUT DDRC, R16         ; Configura PC0-PC2 como entradas (botones) / PC3-PC5 como salidas para los LEDs
    LDI R16, 0b0000_0111
    OUT PORTC, R16        ; Habilita pull-ups internos en PC0-PC2

    LDI R16, 0xFF
    OUT DDRD, R16         ; Configura PORTD como salida del display de 7 segmentos
    LDI R16, 0x00
    OUT PORTD, R16        ; Apagar display

    // Configuración de interrupciones
    LDI R16, (1 << PCIE1)
    STS PCICR, R16        ; Habilita interrupciones en el puerto C
    LDI R16, (1 << PCINT8) | (1 << PCINT9) | (1 << PCINT10)
    STS PCMSK1, R16       ; Habilita interrupciones en PC0, PC1 y PC2

    // Inicialización de contadores
    LDI USEC, 0x00
    LDI DSEC, 0x00
    LDI UMIN, 0x00
    LDI DMIN, 0x00
    LDI UHORA, 0x00
    LDI DHORA, 0x00
    LDI UDIA, 0x00
    LDI DDIA, 0x00
    LDI UMES, 0x00
    LDI DMES, 0x00
    LDI OVERFLOW_COUNT, 0x00
    LDI DISPLAY_FLAG, 0x00

    // Configuración del Timer0
    CALL INIT_TMR0

	// Configuración de interrupciones
    LDI R16, (1 << PCIE1)
    STS PCICR, R16        ; Habilita interrupciones en el puerto C
    LDI R16, (1 << PCINT8) | (1 << PCINT9) | (1 << PCINT10)
    STS PCMSK1, R16       ; Habilita interrupciones en PC0, PC1 y PC2

	CLR MODOS
	CLR MAX_USEC
	CLR MAX_DSEC
	CLR MAX_UMIN
	CLR MAX_DMIN
	CLR MAX_UHORA
	CLR MAX_DHORA
	CLR MAX_UDIA
	CLR MAX_DDIA
	CLR MAX_UMES
	CLR MAX_DMES

    SEI		; Habilita interrupciones globales
;--------------------------------------------------------------------------------------------------------------------------------------

MAIN_LOOP:

    // Verificar si ha pasado 10 ms (1 overflow)
    SBIS TIFR0, TOV0
    RJMP MAIN_LOOP

    // Limpiar la bandera de overflow
    LDI R16, (1 << TOV0)
    OUT TIFR0, R16

	
	//Revisar en que modo nos ubicamos
	CPI		MODOS, 0
	BREQ	HORA
	CPI		MODOS, 1
	BREQ	CONFIG_HORA
	CPI		MODOS, 2
	BREQ	CONFIG_MIN
	CPI		MODOS, 3
	BREQ	FECHA
	CPI		MODOS, 4
	BREQ	CONFIG_DIA
	CPI		MODOS, 5
	BREQ	CONFIG_MES
	CPI		MODOS, 6
	BREQ	ALARMA
	CPI		MODOS, 7
	BREQ	CONFIG_ALARMA
	RJMP	MAIN_LOOP

;--------------------------------------------------------------------------------------------------------------------------------------

// Inicializar el Timer0
INIT_TMR0:
    LDI R16, (1 << CS01) | (1 << CS00) 
    OUT TCCR0B, R16
    LDI R16, 100         ; Precargar TCNT0 para overflows de 10 ms
    OUT TCNT0, R16
    LDI R16, (1 << TOIE0) ; Habilitar interrupción por overflow del Timer0
    STS TIMSK0, R16
    RET

;--------------------------------------------------------------------------------------------------------------------------------------

// Overflows
TIMER0_OVERFLOW:
    PUSH R16
    IN R16, SREG
    PUSH R16

    // Recargar TCNT0 para el overflow en 10 ms
    LDI R16, 100
    OUT TCNT0, R16

    // Incrementar el contador de overflow
    INC OVERFLOW_COUNT

    // Verificar si se alcanzó 1 segundo (100 overflows)
    CPI OVERFLOW_COUNT, 100
    BRNE TIMER0_OVERFLOW_FIN

    // Reiniciar contador de overflows
    LDI OVERFLOW_COUNT, 0x00

    // Incrementar contador de segundos
    INC USEC
    CPI USEC, 10
    BRNE TIMER0_OVERFLOW_FIN

    // Reiniciar contador de segundos e incrementar decenas de segundos
    LDI USEC, 0x00
    INC DSEC
    CPI DSEC, 6
    BRNE TIMER0_OVERFLOW_FIN

    // Reiniciar contador de decenas de segundos e incrementar minutos
    LDI DSEC, 0x00
    INC UMIN
    CPI UMIN, 10
    BRNE TIMER0_OVERFLOW_FIN

    // Reiniciar contador de minutos e incrementar decenas de minutos
    LDI UMIN, 0x00
    INC DMIN
    CPI DMIN, 6
    BRNE TIMER0_OVERFLOW_FIN

    // Reiniciar contador de decenas de minutos e incrementar horas
    LDI DMIN, 0x00
    INC UHORA
    CPI UHORA, 10
    BRNE TIMER0_OVERFLOW_FIN

    // Reiniciar contador de horas e incrementar decenas de horas
    LDI UHORA, 0x00
    INC DHORA
    CPI DHORA, 2
    BRNE TIMER0_OVERFLOW_FIN

    // Reiniciar contador de decenas de horas e incrementar días
    LDI DHORA, 0x00
    INC UDIA
    CPI UDIA, 10
    BRNE TIMER0_OVERFLOW_FIN

    // Reiniciar contador de días e incrementar decenas de días
    LDI UDIA, 0x00
    INC DDIA
    CPI DDIA, 3
    BRNE TIMER0_OVERFLOW_FIN

    // Reiniciar contador de decenas de días e incrementar meses
    LDI DDIA, 0x00
    INC UMES
    CPI UMES, 10
    BRNE TIMER0_OVERFLOW_FIN

    // Reiniciar contador de meses e incrementar decenas de meses
    LDI UMES, 0x00
    INC DMES
    CPI DMES, 1
    BRNE TIMER0_OVERFLOW_FIN

    // Reiniciar todos los contadores si se alcanza el límite máximo
    LDI USEC, 0x00
    LDI DSEC, 0x00
    LDI UMIN, 0x00
    LDI DMIN, 0x00
    LDI UHORA, 0x00
    LDI DHORA, 0x00
    LDI UDIA, 0x00
    LDI DDIA, 0x00
    LDI UMES, 0x00
    LDI DMES, 0x00

TIMER0_OVERFLOW_FIN:
    POP R16
    OUT SREG, R16
    POP R16
    RETI

;--------------------------------------------------------------------------------------------------------------------------------------

// Funciones de incremento y decremento con overflow y underflow
INCREMENTAR_CONFIG:
    RCALL INCREMENTAR_MIN
    RCALL INCREMENTAR_HORA
    RCALL INCREMENTAR_DIA
    RCALL INCREMENTAR_MES
    RET

DECREMENTAR_CONFIG:
    RCALL DECREMENTAR_MIN
    RCALL DECREMENTAR_HORA
    RCALL DECREMENTAR_DIA
    RCALL DECREMENTAR_MES
    RET
//---------------------------------------------------------------------------------
INCREMENTAR_MIN:
    INC UMIN
    CPI UMIN, 10
    BRNE INCREMENTAR_MIN_FIN
    LDI UMIN, 0x00
    INC DMIN
    CPI DMIN, 6
    BRNE INCREMENTAR_MIN_FIN
    LDI DMIN, 0x00
INCREMENTAR_MIN_FIN:
    RET

DECREMENTAR_MIN:
    DEC UMIN
    CPI UMIN, 0xFF
    BRNE DECREMENTAR_MIN_FIN
    LDI UMIN, 0x09
    DEC DMIN
    CPI DMIN, 0xFF
    BRNE DECREMENTAR_MIN_FIN
    LDI DMIN, 0x05
DECREMENTAR_MIN_FIN:
    RET

INCREMENTAR_HORA:
    INC UHORA
    CPI UHORA, 10
    BRNE INCREMENTAR_HORA_FIN
    LDI UHORA, 0x00
    INC DHORA
    CPI DHORA, 2
    BRNE INCREMENTAR_HORA_FIN
    LDI DHORA, 0x00
INCREMENTAR_HORA_FIN:
    RET

DECREMENTAR_HORA:
    DEC UHORA
    CPI UHORA, 0xFF
    BRNE DECREMENTAR_HORA_FIN
    LDI UHORA, 0x09
    DEC DHORA
    CPI DHORA, 0xFF
    BRNE DECREMENTAR_HORA_FIN
    LDI DHORA, 0x01
DECREMENTAR_HORA_FIN:
    RET

INCREMENTAR_DIA:
    INC UDIA
    CPI UDIA, 10
    BRNE INCREMENTAR_DIA_FIN
    LDI UDIA, 0x00
    INC DDIA
    CPI DDIA, 3
    BRNE INCREMENTAR_DIA_FIN
    LDI DDIA, 0x00
INCREMENTAR_DIA_FIN:
    RET

DECREMENTAR_DIA:
    DEC UDIA
    CPI UDIA, 0xFF
    BRNE DECREMENTAR_DIA_FIN
    LDI UDIA, 0x09
    DEC DDIA
    CPI DDIA, 0xFF
    BRNE DECREMENTAR_DIA_FIN
    LDI DDIA, 0x02
DECREMENTAR_DIA_FIN:
    RET

INCREMENTAR_MES:
    INC UMES
    CPI UMES, 10
    BRNE INCREMENTAR_MES_FIN
    LDI UMES, 0x00
    INC DMES
    CPI DMES, 1
    BRNE INCREMENTAR_MES_FIN
    LDI DMES, 0x00
INCREMENTAR_MES_FIN:
    RET

DECREMENTAR_MES:
    DEC UMES
    CPI UMES, 0xFF
    BRNE DECREMENTAR_MES_FIN
    LDI UMES, 0x09
    DEC DMES
    CPI DMES, 0xFF
    BRNE DECREMENTAR_MES_FIN
    LDI DMES, 0x00
DECREMENTAR_MES_FIN:
    RET

// ESTADOS

HORA:
	RET

CONFIG_UHORA:
	RET


CONFIG_DHORA:
	RET

CONFIG_UMIN:
	RET

CONFIG_DMIN:
	RET

FECHA:
	RET

CONFIG_UMES:
	RET

CONFIG_DMES:
	RET

CONFIG_UDIA:
	RET

CONFIG_DDIA:
	RET

MOSTRAR_UHORA:
	CBI		PORTB, PB2
	CBI		PORTB, PB3
	LDS		R16, UHORA
	LDI		ZL, LOW(TABLA << 1)
	LDI		ZH, HIGH(TABLA << 1)
	ADD		ZL, R16
	ADC		ZH, R1
	LPM		R16, Z
	OUT		PORTD, R16
	SBI		PORTB, PB2	; Encender display correspondiente
	RET

MOSTRAR_DHORA:
	CBI		PORTB, PB2
	CBI		PORTB, PB3
	LDS		R16, DHORA
	LDI		ZL, LOW(TABLA << 1)
	LDI		ZH, HIGH(TABLA << 1)
	ADD		ZL, R16
	ADC		ZH, R1
	LPM		R16, Z
	OUT		PORTD, R16
	SBI		PORTB, PB3	; Encender display correspondiente
	RET

MOSTRAR_UMIN:
	CBI		PORTB, PB0
	CBI		PORTB, PB1
	LDS		R16, UMIN
	LDI		ZL, LOW(TABLA << 1)
	LDI		ZH, HIGH(TABLA << 1)
	ADD		ZL, R16
	ADC		ZH, R1
	LPM		R16, Z
	OUT		PORTD, R16
	SBI		PORTB, PB0	; Encender display correspondiente
	RET

MOSTRAR_DMIN:
	CBI		PORTB, PB0
	CBI		PORTB, PB1
	LDS		R16, DMIN
	LDI		ZL, LOW(TABLA << 1)
	LDI		ZH, HIGH(TABLA << 1)
	ADD		ZL, R16
	ADC		ZH, R1
	LPM		R16, Z
	OUT		PORTD, R16
	SBI		PORTB, PB1	; Encender display correspondiente
	RET

MOSTRAR_UDIA:
	CBI		PORTB, PB2
	CBI		PORTB, PB3
	LDS		R16, UDIA
	LDI		ZL, LOW(TABLA << 1)
	LDI		ZH, HIGH(TABLA << 1)
	ADD		ZL, R16
	ADC		ZH, R1
	LPM		R16, Z
	OUT		PORTD, R16
	SBI		PORTB, PB2	; Encender display correspondiente
	RET

MOSTRAR_DDIA:
	CBI		PORTB, PB2
	CBI		PORTB, PB3
	LDS		R16, DDIA
	LDI		ZL, LOW(TABLA << 1)
	LDI		ZH, HIGH(TABLA << 1)
	ADD		ZL, R16
	ADC		ZH, R1
	LPM		R16, Z
	OUT		PORTD, R16
	SBI		PORTB, PB3	; Encender display correspondiente
	RET

MOSTRAR_UMES:
	CBI		PORTB, PB0
	CBI		PORTB, PB1
	LDS		R16, UMES
	LDI		ZL, LOW(TABLA << 1)
	LDI		ZH, HIGH(TABLA << 1)
	ADD		ZL, R16
	ADC		ZH, R1
	LPM		R16, Z
	OUT		PORTD, R16
	SBI		PORTB, PB0	; Encender display correspondiente
	RET

MOSTRAR_DMES:
	CBI		PORTB, PB0
	CBI		PORTB, PB1
	LDS		R16, DMES
	LDI		ZL, LOW(TABLA << 1)
	LDI		ZH, HIGH(TABLA << 1)
	ADD		ZL, R16
	ADC		ZH, R1
	LPM		R16, Z
	OUT		PORTD, R16
	SBI		PORTB, PB1	; Encender display correspondiente
	RET


TABLA:
    .DB 0x3F,0x06,0x5B,0x4F,0x66,0x6D,0x7D,0x07,0x7F,0x6F