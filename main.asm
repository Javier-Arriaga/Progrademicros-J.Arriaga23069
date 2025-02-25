;
; Laboratorio 3.asm
;
; Created: 18/02/2025 11:01:45
; Author : Javier Arriaga
;

.include "m328pdef.inc"

.dseg
.org SRAM_START
counter: .byte 1          ; Contador binario de 4 bits

.cseg
.org 0x0000
    rjmp SETUP
.org PCI1addr
    rjmp INTERRUPCION
.org OVF0addr
    rjmp TIMER0_OVERFLOW  ; Interrupción por overflow del Timer0

.def SEG_COUNTER = R20   ; Contador de display de segundos
.def OVERFLOW_COUNT = R21 ; Contador de overflows
.def DECENA_COUNTER = R22 ; Contador display de decenas
.def DISPLAY_FLAG = R23  ; Flag para alternar entre displays

;--------------------------------------------------------------------------------------------------------------------------------------


SETUP:
    CLI		; Deshabilita las interrupciones

    // Configuración de pila (Stack)
    LDI R16, LOW(RAMEND)
    OUT SPL, R16
    LDI R16, HIGH(RAMEND)
    OUT SPH, R16

    // Configurar Prescaler "Principal"
    LDI R16, (1 << CLKPCE)
    STS CLKPR, R16    ; Habilitar cambio de PRESCALER
    LDI R16, 0b00000100
    STS CLKPR, R16    ; Configurar Prescaler a 16 (1MHz)

    // Configuración de los puertos
    LDI R16, 0x0F
    OUT DDRB, R16         ; Configura PB0-PB3 como salidas (LEDs)
    LDI R16, 0x00
    OUT PORTB, R16        ; Apaga todos los LEDs

    LDI R16, 0b0011_0000
    OUT DDRC, R16         ; Configura PC0 y PC1 como entradas (botones) / PC4 y PC5 como salidas para los tranistores
    LDI R16, 0b0000_0011
    OUT PORTC, R16        ; Habilita pull-ups internos en PC0 y PC1

    LDI R16, 0xFF
    OUT DDRD, R16         ; Configura PORTD como salida del display de 7 segmentos
    LDI R16, 0x00
    OUT PORTD, R16        ; Apagar display

    // Configuración de interrupciones
    LDI R16, (1 << PCIE1)
    STS PCICR, R16        ; Habilita interrupciones en el puerto C
    LDI R16, (1 << PCINT8) | (1 << PCINT9)
    STS PCMSK1, R16       ; Habilita interrupciones en PC0 y PC1

    // Inicialización de contadores
    LDI SEG_COUNTER, 0x00
    LDI OVERFLOW_COUNT, 0x00
    LDI DECENA_COUNTER, 0x00
    LDI DISPLAY_FLAG, 0x00
    LDI R16, 0x00
    STS counter, R16     

    CBI PORTC, PC4
    CBI PORTC, PC5

    // Configuración del Timer0
    CALL INIT_TMR0
    
    SEI		; Habilita interrupciones globales

 
MAIN_LOOP:
    // Verificar si ha pasado 10 ms (1 overflow)
    SBIS TIFR0, TOV0
    RJMP MAIN_LOOP

    // Limpiar la bandera de overflow
    LDI R16, (1 << TOV0)
    OUT TIFR0, R16

    // Alternar entre displays
    SBRS DISPLAY_FLAG, 0
    RCALL DISPLAY_SEG
    SBRC DISPLAY_FLAG, 0
    RCALL DISPLAY_DEC

    // Cambiar la bandera para alternar displays
    LDI R16, 0x01
    EOR DISPLAY_FLAG, R16

    RJMP MAIN_LOOP

// Inicializar el Timer0
INIT_TMR0:
    LDI R16, (1 << CS01) | (1 << CS00) 
    OUT TCCR0B, R16
    LDI R16, 100         ; Precargar TCNT0 para overflows de 10 ms
    OUT TCNT0, R16
    LDI R16, (1 << TOIE0) ; Habilitar interrupción por overflow del Timer0
    STS TIMSK0, R16
    RET


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

    // Verificar si se alcanzó 1 segudos
    CPI OVERFLOW_COUNT, 100
    BRNE TIMER0_OVERFLOW_FIN

    // Reiniciar contador
    LDI OVERFLOW_COUNT, 0x00

    // Incrementar contador de segundos
    INC SEG_COUNTER
    CPI SEG_COUNTER, 10
    BRNE TIMER0_OVERFLOW_FIN

    // Reiniciar contador de segundos e incrementar contador de decenas
    LDI SEG_COUNTER, 0x00
    INC DECENA_COUNTER
    CPI DECENA_COUNTER, 6
    BRNE TIMER0_OVERFLOW_FIN

    // Reiniciar ambos contadores
    LDI SEG_COUNTER, 0x00
    LDI DECENA_COUNTER, 0x00

TIMER0_OVERFLOW_FIN:
    POP R16
    OUT SREG, R16
    POP R16
    RETI

// Tabla de conversión para display de 7 segmentos
TABLA:
    .DB 0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x47, 0x7F, 0x6F

// Función para el Display de segundos
DISPLAY_SEG: 
    LDI ZL, LOW(mitabla << 1)
    LDI ZH, HIGH(mitabla << 1)
    ADD ZL, SEG_COUNTER  ; Sumar el valor del contador de segundos
    LPM R18, Z           ; Cargar el valor de la tabla
    OUT PORTD, R18       ; Mostrar en el display
    SBI PORTC, PC4       ; Encender display de segundos
    CBI PORTC, PC5       ; Apagar display de decenas
    RET

// Función para el Display de decenas
DISPLAY_DEC:
    LDI ZL, LOW(TABLA << 1)
    LDI ZH, HIGH(TABLA << 1)
    ADD ZL, DECENA_COUNTER  ; Sumar el valor del contador de decenas
    LPM R19, Z              ; Cargar el valor de la tabla
    OUT PORTD, R19          ; Mostrar en el display
    SBI PORTC, PC5          ; Encender display de decenas
    CBI PORTC, PC4          ; Apagar display de segundos
    RET

// Interrupción por cambio en los botones
INTERRUPCION:
    PUSH R16
    IN R16, SREG
    PUSH R16

    ; Leer el estado de los botones
    IN R16, PINC

    ; Verificar si el botón de incremento fue presionado
    SBRS R16, PC0
    RCALL INCREMENT_COUNTER

    ; Verificar si el botón de decremento fue presionado
    SBRS R16, PC1
    RCALL DECREMENT_COUNTER

    ; Restaurar el estado de los registros
    POP R16
    OUT SREG, R16
    POP R16
    RETI

// Incrementar el contador binario
INCREMENT_COUNTER:
    LDS R17, counter
    INC R17
    ANDI R17, 0x0F        ; Limitar a 4 bits
    STS counter, R17
    OUT PORTB, R17        ; Actualizar LEDs
    RET

// Decrementar el contador binario
DECREMENT_COUNTER:
    LDS R17, counter
    DEC R17
    ANDI R17, 0x0F        ; Limitar a 4 bits
    STS counter, R17
    OUT PORTB, R17        ; Actualizar LEDs
    RET

