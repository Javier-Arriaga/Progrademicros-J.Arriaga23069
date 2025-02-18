; Laboratorio 2.asm
;Implementacion del timero y display de segmentos
;
; Created: 11/02/2025 09:35:22
; Author : JavieR Arriaga

.include "M328PDEF.inc"     // Include definitions specific to ATMega328P
.cseg
.org 0x0000
.def    COUNTER = R20
.def    DISPLAY_VALUE = R21
.def    SECONDS_COUNTER = R22
.def    LED_STATE = R23

/****************************************/
// Configuración de la pila
LDI     R16, LOW(RAMEND)
OUT     SPL, R16
LDI     R16, HIGH(RAMEND)
OUT     SPH, R16

/****************************************/
// Configuración MCU
SETUP:
    // Configurar Prescaler "Principal"
    LDI     R16, (1 << CLKPCE)
    STS     CLKPR, R16          // Habilitar cambio de PRESCALER
    LDI     R16, 0b000000100
    STS     CLKPR, R16          

    // Inicializar timer0
    CALL    INIT_TMR0

    // Configurar PB0-PB3 como salida para el contador
    LDI     R16, 0x0F           // Configurar PB0-PB3 como salidas
    OUT     DDRB, R16
    LDI     R16, 0x00           // Asegurar que los LEDs inicien apagados
    OUT     PORTB, R16

    // Salida PD0-PD7 para el display de 7 segmentos
    LDI     R17, 0xFF
    OUT     DDRD, R17
    LDI     R17, 0x3F
    OUT     PORTD, R17

    // Configurar botones en PC0 y PC1 como entrada con pull-ups activados
    LDI     R17, 0x00
    OUT     DDRC, R17   
    LDI     R18, 0xFF
    OUT     PORTC, R18  

    CLR     DISPLAY_VALUE       // Inicializar DISPLAY_VALUE en 0
    CLR     SECONDS_COUNTER     // Inicializar SECONDS_COUNTER en 0
    CLR     LED_STATE           // Inicializar LED_STATE en 0

/****************************************/
// Loop Infinito
MAIN_LOOP:
    IN      R16, TIFR0          // Leer registro de interrupción de TIMER 0
    SBRS    R16, TOV0           // Salta si el bit 0 está "set" (TOV0 bit)
    RJMP    MAIN_LOOP           // Reiniciar loop
    SBI     TIFR0, TOV0         // Limpiar bandera de "overflow"
    LDI     R16, 100            
    OUT     TCNT0, R16          // Volver a cargar valor inicial en TCNT0
    
    INC     COUNTER             // Incrementar contador binario
    ANDI    COUNTER, 0x0F       // Mantenerlo en el rango de 0-15
    OUT     PORTB, COUNTER      // Mostrar el valor en PB0-PB3

    // Incrementar el contador de segundos cada 10 ciclos (1 segundo)
    INC     SECONDS_COUNTER
    CPI     SECONDS_COUNTER, 10
    BRNE    NO_SECOND
    CLR     SECONDS_COUNTER     // Reiniciar contador de segundos
    CALL    CHECK_LED           // Verificar si se debe cambiar el estado del LED

NO_SECOND:
    IN      R17, PINC          // Leer estado de botones
    SBIC    PINC, 0            // Verificar si el botón de incremento (PC0) está presionado
    CALL    BOTON_INCREMENTO
    SBIC    PINC, 1            // Verificar si el botón de decremento (PC1) está presionado
    CALL    BOTON_DECREMENTO
    RJMP    MAIN_LOOP          // Repetir el ciclo

BOTON_INCREMENTO:
    CALL    DELAY               // Antirrebote
    INC     DISPLAY_VALUE
    ANDI    DISPLAY_VALUE, 0x0F  // Mantenerlo en rango de 0-15
    CALL    ACTUALIZAR_DISPLAY
    RET

BOTON_DECREMENTO:
    CALL    DELAY               // Antirrebote
    DEC     DISPLAY_VALUE
    CALL    ACTUALIZAR_DISPLAY
    RET

ACTUALIZAR_DISPLAY:
    LDI     ZL, LOW(TABLA<<1)
    LDI     ZH, HIGH(TABLA<<1)
    MOV     R16, DISPLAY_VALUE   // Usar DISPLAY_VALUE en lugar de COUNTER
    ADD     ZL, R16             // Ajustar la dirección en la tabla
    LPM     R17, Z              // Leer el valor correspondiente
    OUT     PORTD, R17          // Mostrarlo en el display
    RET

CHECK_LED:
    CP      DISPLAY_VALUE, COUNTER  // Comparar DISPLAY_VALUE con COUNTER
    BRNE    NO_LED_CHANGE           // Si no son iguales, no cambiar el LED
    COM     LED_STATE               // Cambiar el estado del LED
    OUT     PORTB, LED_STATE        // Mostrar el nuevo estado del LED
    CLR     COUNTER                 // Reiniciar el contador de segundos

NO_LED_CHANGE:
    RET

// Tabla de valores del display
TABLA:
    .DB 0x3F,0x06,0x5B,0x4F,0x66,0x6D,0x7D,0x07 
    .DB 0x7F,0x6F,0x77,0x7C,0x39,0x5E,0x79,0x71

/****************************************/
// Subrutinas de no interrupción
INIT_TMR0:
    LDI     R16, (1<<CS01) | (1<<CS00)  // Prescaler de 64
    OUT     TCCR0B, R16         // Setear prescaler del TIMER 0 a 64
    LDI     R16, 100            
    OUT     TCNT0, R16          // Cargar valor inicial en TCNT0
    RET

DELAY:      // Implementación del delay para evitar rebote
    LDI     R22, 250
SUBDELAY1:
    DEC     R22
    BRNE    SUBDELAY1
    LDI     R22, 250  // Aumentar la duración del delay
SUBDELAY2:
    DEC     R22
    BRNE    SUBDELAY2
    RET

