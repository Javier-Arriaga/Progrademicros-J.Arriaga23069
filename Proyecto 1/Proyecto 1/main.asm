;
; Proyecto 1.asm
;
; Created: 25/02/2025 13:14:25
; Author : Javier Arriaga
;
.include "m328pdef.inc"

; Definición de constantes
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

; Variables en SRAM
.dseg
.org SRAM_START
USEC:    .byte 1
DSEC:    .byte 1
UMIN:    .byte 1
DMIN:    .byte 1
UHORA:   .byte 1
DHORA:   .byte 1
UDIA:    .byte 1
DDIA:    .byte 1
UMES:    .byte 1
DMES:    .byte 1

; Código
.cseg
.org 0x0000
    rjmp START
.org PCI1addr
    jmp PCINT1_ISR
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
    SBIC PINC, PC0        ; Si se presiona PC0 (incrementar)
    RCALL INCREMENTAR_CONFIG
    SBIC PINC, PC1        ; Si se presiona PC1 (decrementar)
    RCALL DECREMENTAR_CONFIG

    ; Restaurar el estado de los registros
    POP R16
    OUT SREG, R16
    POP R16

    RETI                 

;--------------------------------------------------------------------------------------------------------------------------------------

START:
    ; Configuración de pila (Stack)
    LDI R16, LOW(RAMEND)
    OUT SPL, R16
    LDI R16, HIGH(RAMEND)
    OUT SPH, R16

SETUP:
    CLI		; Deshabilita las interrupciones

    ; Configurar Prescaler "Principal"
    LDI R16, (1 << CLKPCE)
    STS CLKPR, R16    ; Habilitar cambio de PRESCALER
    LDI R16, 0b00000100
    STS CLKPR, R16    ; Configurar Prescaler a 16 (1MHz)

    ; Configuración de los puertos
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

    ; Configuración de interrupciones
    LDI R16, (1 << PCIE1)
    STS PCICR, R16        ; Habilita interrupciones en el puerto C
    LDI R16, (1 << PCINT10) ; Habilita interrupción en PC2 (PCINT10)
    STS PCMSK1, R16       ; Habilita interrupciones en PC2

    ; Inicialización de contadores
    CLR MODO              ; Inicializar MODO a 0
    CLR OVERFLOW_COUNT
    LDI R16, 0x00
    STS USEC, R16
    STS DSEC, R16
    STS UMIN, R16
    STS DMIN, R16
    STS UHORA, R16
    STS DHORA, R16
    STS UDIA, R16
    STS DDIA, R16
    STS UMES, R16
    STS DMES, R16
    LDI OVERFLOW_COUNT, 0x00
    LDI DISPLAY_FLAG, 0x00

    ; Configuración del Timer0
    CALL INIT_TMR0

    SEI		; Habilita interrupciones globales

;--------------------------------------------------------------------------------------------------------------------------------------

MAIN_LOOP:
    ; Verificar si ha pasado 10 ms (1 overflow)
    SBIS TIFR0, TOV0
    RJMP MAIN_LOOP

    ; Limpiar la bandera de overflow
    LDI R16, (1 << TOV0)
    OUT TIFR0, R16

    ; Revisar en qué modo nos ubicamos
    CPI MODO, 0
    BREQ HORA
    CPI MODO, 1
    BREQ CONFIG_HORA
    CPI MODO, 2
    BREQ CONFIG_MIN
    CPI MODO, 3
    BREQ FECHA
    CPI MODO, 4
    BREQ CONFIG_DIA
    CPI MODO, 5
    BREQ CONFIG_MES
    CPI MODO, 6
    BREQ ALARMA
    CPI MODO, 7
    BREQ CONFIG_ALARMA
    RJMP MAIN_LOOP

;--------------------------------------------------------------------------------------------------------------------------------------

HORA:
    SBI PORTC, PC3
    CBI PORTC, PC4
    CBI PORTC, PC5
    RCALL MOSTRAR_UHORA
    RCALL MOSTRAR_DHORA
    RCALL MOSTRAR_UMIN
    RCALL MOSTRAR_DMIN
    RJMP MAIN_LOOP

CONFIG_HORA:
    SBI PORTC, PC3
    SBI PORTC, PC4
    CBI PORTC, PC5
    RCALL MOSTRAR_UHORA
    RCALL MOSTRAR_DHORA
    RJMP MAIN_LOOP

CONFIG_MIN:
    SBI PORTC, PC3
    SBI PORTC, PC4
    SBI PORTC, PC5
    RCALL MOSTRAR_UMIN
    RCALL MOSTRAR_DMIN
    RJMP MAIN_LOOP

FECHA:
    SBI PORTC, PC4
    CBI PORTC, PC3
    CBI PORTC, PC5
    RCALL MOSTRAR_UDIA
    RCALL MOSTRAR_DDIA
    RCALL MOSTRAR_UMES
    RCALL MOSTRAR_DMES
    RJMP MAIN_LOOP

CONFIG_DIA:
    SBI PORTC, PC3
    SBI PORTC, PC4
    CBI PORTC, PC5
    RCALL MOSTRAR_UDIA
    RCALL MOSTRAR_DDIA
    RJMP MAIN_LOOP

CONFIG_MES:
    SBI PORTC, PC3
    SBI PORTC, PC4
    SBI PORTC, PC5
    RCALL MOSTRAR_UMES
    RCALL MOSTRAR_DMES
    RJMP MAIN_LOOP

ALARMA:
    CBI PORTC, PC3
    CBI PORTC, PC4
    CBI PORTC, PC5
    RJMP MAIN_LOOP

CONFIG_ALARMA:
    CBI PORTC, PC3
    CBI PORTC, PC4
    CBI PORTC, PC5
    RJMP MAIN_LOOP

INIT_TMR0:
    LDI R16, (1 << CS01) | (1 << CS00) 
    OUT TCCR0B, R16
    LDI R16, 100         ; Precargar TCNT0 para overflows de 10 ms
    OUT TCNT0, R16
    LDI R16, (1 << TOIE0) ; Habilitar interrupción por overflow del Timer0
    STS TIMSK0, R16
    RET

;--------------------------------------------------------------------------------------------------------------------------------------

TIMER0_OVERFLOW:
    PUSH R16
    IN R16, SREG
    PUSH R16

    ; Recargar TCNT0 para el overflow en 10 ms
    LDI R16, 100
    OUT TCNT0, R16

    ; Incrementar el contador de overflow
    INC OVERFLOW_COUNT

    ; Verificar si se alcanzó 1 segundo (100 overflows)
    CPI OVERFLOW_COUNT, 100
    BRNE TIMER0_OVERFLOW_FIN_INTERMEDIO
    RJMP TIMER0_OVERFLOW_FIN

    ; Reiniciar contador de overflows
    LDI OVERFLOW_COUNT, 0x00

    ; Incrementar contador de segundos
    LDS R16, USEC
    INC R16
    STS USEC, R16
    CPI R16, MAX_USEC
    BRNE TIMER0_OVERFLOW_FIN_INTERMEDIO
    RJMP TIMER0_OVERFLOW_FIN

    ; Reiniciar contador de segundos e incrementar decenas de segundos
    LDI R16, 0x00
    STS USEC, R16
    LDS R16, DSEC
    INC R16
    STS DSEC, R16
    CPI R16, MAX_DSEC
    BRNE TIMER0_OVERFLOW_FIN_INTERMEDIO
    RJMP TIMER0_OVERFLOW_FIN

    ; Reiniciar contador de decenas de segundos e incrementar minutos
    LDI R16, 0x00
    STS DSEC, R16
    LDS R16, UMIN
    INC R16
    STS UMIN, R16
    CPI R16, MAX_UMIN
    BRNE TIMER0_OVERFLOW_FIN_INTERMEDIO
    RJMP TIMER0_OVERFLOW_FIN

TIMER0_OVERFLOW_FIN_INTERMEDIO:
    RJMP TIMER0_OVERFLOW_FIN

    ; Reiniciar contador de minutos e incrementar decenas de minutos
    LDI R16, 0x00
    STS UMIN, R16
    LDS R16, DMIN
    INC R16
    STS DMIN, R16
    CPI R16, MAX_DMIN
    BRNE TIMER0_OVERFLOW_FIN

    ; Reiniciar contador de decenas de minutos e incrementar horas
    LDI R16, 0x00
    STS DMIN, R16
    LDS R16, UHORA
    INC R16
    STS UHORA, R16
    CPI R16, MAX_UHORA
    BRNE TIMER0_OVERFLOW_FIN

    ; Reiniciar contador de horas e incrementar decenas de horas
    LDI R16, 0x00
    STS UHORA, R16
    LDS R16, DHORA
    INC R16
    STS DHORA, R16
    CPI R16, MAX_DHORA
    BRNE TIMER0_OVERFLOW_FIN

    ; Reiniciar contador de decenas de horas e incrementar días
    LDI R16, 0x00
    STS DHORA, R16
    LDS R16, UDIA
    INC R16
    STS UDIA, R16
    CPI R16, MAX_UDIA
    BRNE TIMER0_OVERFLOW_FIN

    ; Reiniciar contador de días e incrementar decenas de días
    LDI R16, 0x00
    STS UDIA, R16
    LDS R16, DDIA
    INC R16
    STS DDIA, R16
    CPI R16, MAX_DDIA
    BRNE TIMER0_OVERFLOW_FIN

    ; Reiniciar contador de decenas de días e incrementar meses
    LDI R16, 0x00
    STS DDIA, R16
    LDS R16, UMES
    INC R16
    STS UMES, R16
    CPI R16, MAX_UMES
    BRNE TIMER0_OVERFLOW_FIN

    ; Reiniciar contador de meses e incrementar decenas de meses
    LDI R16, 0x00
    STS UMES, R16
    LDS R16, DMES
    INC R16
    STS DMES, R16
    CPI R16, MAX_DMES
    BRNE TIMER0_OVERFLOW_FIN

TIMER0_OVERFLOW_FIN:
    POP R16
    OUT SREG, R16
    POP R16
    RETI

    ; Reiniciar todos los contadores si se alcanza el límite máximo
    LDI R16, 0x00
    STS USEC, R16
    STS DSEC, R16
    STS UMIN, R16
    STS DMIN, R16
    STS UHORA, R16
    STS DHORA, R16
    STS UDIA, R16
    STS DDIA, R16
    STS UMES, R16
    STS DMES, R16

;--------------------------------------------------------------------------------------------------------------------------------------
; Rutina de interrupción para PCINT1 (botón en PC2)
PCINT1_ISR:
    PUSH R16
    IN R16, SREG
    PUSH R16

    ; Debounce: Esperar un poco para evitar rebotes
    RCALL DELAY_DEBOUNCE

    ; Verificar si el botón en PC2 fue presionado
    SBIC PINC, PC2        ; Si se presiona PC2 (cambio de modo)
    RCALL CAMBIAR_MODO    ; Llamar a la función para cambiar el modo

    ; Restaurar el estado de los registros
    POP R16
    OUT SREG, R16
    POP R16

    RETI                  ; Retornar de la interrupción

;--------------------------------------------------------------------------------------------------------------------------------------
; Función para cambiar el modo
CAMBIAR_MODO:
    INC MODO             ; Incrementar el modo en 1
    CPI MODO, MODOS      ; Verificar si el modo supera el límite
    BRLO CAMBIAR_MODO_FIN ; Si no, continuar
    LDI MODO, 0          ; Si supera el límite, reiniciar a 0
CAMBIAR_MODO_FIN:
    RET                  ; Retornar

;--------------------------------------------------------------------------------------------------------------------------------------
INCREMENTAR_CONFIG:
    CPI MODO, 1
    BREQ INCREMENTAR_HORA
    CPI MODO, 2
    BREQ INCREMENTAR_MIN
    CPI MODO, 4
    BREQ INCREMENTAR_DIA
    CPI MODO, 5
    BREQ INCREMENTAR_MES
    RET

INCREMENTAR_MIN:
    LDS R16, UMIN
    INC R16
    CPI R16, MAX_UMIN
    BRNE INCREMENTAR_MIN_FIN
    LDI R16, 0x00
    LDS R17, DMIN
    INC R17
    STS DMIN, R17
    CPI R17, MAX_DMIN
    BRNE INCREMENTAR_MIN_FIN
    LDI R17, 0x00
    STS DMIN, R17
INCREMENTAR_MIN_FIN:
    STS UMIN, R16
    RET

INCREMENTAR_HORA:
    LDS R16, UHORA
    INC R16
    CPI R16, MAX_UHORA
    BRNE INCREMENTAR_HORA_FIN
    LDI R16, 0x00
    LDS R17, DHORA
    INC R17
    STS DHORA, R17
    CPI R17, MAX_DHORA
    BRNE INCREMENTAR_HORA_FIN
    LDI R17, 0x00
    STS DHORA, R17
INCREMENTAR_HORA_FIN:
    STS UHORA, R16
    RET

INCREMENTAR_DIA:
    LDS R16, UDIA
    INC R16
    CPI R16, MAX_UDIA
    BRNE INCREMENTAR_DIA_FIN
    LDI R16, 0x00
    LDS R17, DDIA
    INC R17
    STS DDIA, R17
    CPI R17, MAX_DDIA
    BRNE INCREMENTAR_DIA_FIN
    LDI R17, 0x00
    STS DDIA, R17
INCREMENTAR_DIA_FIN:
    STS UDIA, R16
    RET

INCREMENTAR_MES:
    LDS R16, UMES
    INC R16
    CPI R16, MAX_UMES
    BRNE INCREMENTAR_MES_FIN
    LDI R16, 0x00
    LDS R17, DMES
    INC R17
    STS DMES, R17
    CPI R17, MAX_DMES
    BRNE INCREMENTAR_MES_FIN
    LDI R17, 0x00
    STS DMES, R17
INCREMENTAR_MES_FIN:
    STS UMES, R16
    RET

DECREMENTAR_CONFIG:
    CPI MODO, 1
    BREQ DECREMENTAR_HORA
    CPI MODO, 2
    BREQ DECREMENTAR_MIN
    CPI MODO, 4
    BREQ DECREMENTAR_DIA
    CPI MODO, 5
    BREQ DECREMENTAR_MES
    RET

DECREMENTAR_MIN:
    LDS R16, UMIN
    DEC R16
    CPI R16, 0xFF
    BRNE DECREMENTAR_MIN_FIN
    LDI R16, 0x09
    LDS R17, DMIN
    DEC R17
    CPI R17, 0xFF
    BRNE DECREMENTAR_MIN_FIN
    LDI R17, 0x05
    STS DMIN, R17
DECREMENTAR_MIN_FIN:
    STS UMIN, R16
    RET

DECREMENTAR_HORA:
    LDS R16, UHORA
    DEC R16
    CPI R16, 0xFF
    BRNE DECREMENTAR_HORA_FIN
    LDI R16, 0x09
    LDS R17, DHORA
    DEC R17
    CPI R17, 0xFF
    BRNE DECREMENTAR_HORA_FIN
    LDI R17, 0x01
    STS DHORA, R17
DECREMENTAR_HORA_FIN:
    STS UHORA, R16
    RET

DECREMENTAR_DIA:
    LDS R16, UDIA
    DEC R16
    CPI R16, 0xFF
    BRNE DECREMENTAR_DIA_FIN
    LDI R16, 0x09
    LDS R17, DDIA
    DEC R17
    CPI R17, 0xFF
    BRNE DECREMENTAR_DIA_FIN
    LDI R17, 0x02
    STS DDIA, R17
DECREMENTAR_DIA_FIN:
    STS UDIA, R16
    RET

DECREMENTAR_MES:
    LDS R16, UMES
    DEC R16
    CPI R16, 0xFF
    BRNE DECREMENTAR_MES_FIN
    LDI R16, 0x09
    LDS R17, DMES
    DEC R17
    CPI R17, 0xFF
    BRNE DECREMENTAR_MES_FIN
    LDI R17, 0x00
    STS DMES, R17
DECREMENTAR_MES_FIN:
    STS UMES, R16
    RET

;---------------------------------------------------------------------------------------------------------------------

MOSTRAR_UHORA:
    CBI     PORTB, PB2    ; Apagar display de decenas de horas
    CBI     PORTB, PB3    ; Apagar display de unidades de horas
    LDS     R16, UHORA    ; Cargar valor de unidades de horas
    RCALL   MOSTRAR_DIGITO ; Mostrar dígito en el display
    SBI     PORTB, PB2    ; Encender display de unidades de horas
    RCALL   DELAY         ; Pequeño retardo
    RET

MOSTRAR_DHORA:
    CBI     PORTB, PB2    ; Apagar display de unidades de horas
    CBI     PORTB, PB3    ; Apagar display de decenas de horas
    LDS     R16, DHORA    ; Cargar valor de decenas de horas
    RCALL   MOSTRAR_DIGITO ; Mostrar dígito en el display
    SBI     PORTB, PB3    ; Encender display de decenas de horas
    RCALL   DELAY         ; Pequeño retardo
    RET

MOSTRAR_UMIN:
    CBI     PORTB, PB0    ; Apagar display de decenas de minutos
    CBI     PORTB, PB1    ; Apagar display de unidades de minutos
    LDS     R16, UMIN     ; Cargar valor de unidades de minutos
    RCALL   MOSTRAR_DIGITO ; Mostrar dígito en el display
    SBI     PORTB, PB0    ; Encender display de unidades de minutos
    RCALL   DELAY         ; Pequeño retardo
    RET

MOSTRAR_DMIN:
    CBI     PORTB, PB0    ; Apagar display de unidades de minutos
    CBI     PORTB, PB1    ; Apagar display de decenas de minutos
    LDS     R16, DMIN     ; Cargar valor de decenas de minutos
    RCALL   MOSTRAR_DIGITO ; Mostrar dígito en el display
    SBI     PORTB, PB1    ; Encender display de decenas de minutos
    RCALL   DELAY         ; Pequeño retardo
    RET

MOSTRAR_UDIA:
    CBI     PORTB, PB2    ; Apagar display de decenas de días
    CBI     PORTB, PB3    ; Apagar display de unidades de días
    LDS     R16, UDIA     ; Cargar valor de unidades de días
    RCALL   MOSTRAR_DIGITO ; Mostrar dígito en el display
    SBI     PORTB, PB2    ; Encender display de unidades de días
    RCALL   DELAY         ; Pequeño retardo
    RET

MOSTRAR_DDIA:
    CBI     PORTB, PB2    ; Apagar display de unidades de días
    CBI     PORTB, PB3    ; Apagar display de decenas de días
    LDS     R16, DDIA     ; Cargar valor de decenas de días
    RCALL   MOSTRAR_DIGITO ; Mostrar dígito en el display
    SBI     PORTB, PB3    ; Encender display de decenas de días
    RCALL   DELAY         ; Pequeño retardo
    RET

MOSTRAR_UMES:
    CBI     PORTB, PB0    ; Apagar display de decenas de meses
    CBI     PORTB, PB1    ; Apagar display de unidades de meses
    LDS     R16, UMES     ; Cargar valor de unidades de meses
    RCALL   MOSTRAR_DIGITO ; Mostrar dígito en el display
    SBI     PORTB, PB0    ; Encender display de unidades de meses
    RCALL   DELAY         ; Pequeño retardo
    RET

MOSTRAR_DMES:
    CBI     PORTB, PB0    ; Apagar display de unidades de meses
    CBI     PORTB, PB1    ; Apagar display de decenas de meses
    LDS     R16, DMES     ; Cargar valor de decenas de meses
    RCALL   MOSTRAR_DIGITO ; Mostrar dígito en el display
    SBI     PORTB, PB1    ; Encender display de decenas de meses
    RCALL   DELAY         ; Pequeño retardo
    RET

;---------------------------------------------------------------------------------------------------------------------

MOSTRAR_DIGITO:
    LDI     ZL, LOW(TABLA << 1)  ; Cargar dirección baja de la tabla de segmentos
    LDI     ZH, HIGH(TABLA << 1) ; Cargar dirección alta de la tabla de segmentos
    ADD     ZL, R16              ; Sumar el valor del dígito a la dirección de la tabla
    ADC     ZH, R1               ; Añadir el acarreo si es necesario
    LPM     R16, Z               ; Cargar el patrón de segmentos desde la tabla
    OUT     PORTD, R16           ; Mostrar el patrón en el display
    RET

;---------------------------------------------------------------------------------------------------------------------

DELAY:
    LDI     R20, 50              ; Cargar valor para el retardo
DELAY_LOOP:
    DEC     R20                  ; Decrementar el contador
    BRNE    DELAY_LOOP           ; Repetir hasta que el contador sea cero
    RET

DELAY_DEBOUNCE:
    LDI     R20, 100             ; Cargar valor para el retardo de debounce
DELAY_DEBOUNCE_LOOP:
    DEC     R20
    BRNE    DELAY_DEBOUNCE_LOOP
    RET

;---------------------------------------------------------------------------------------------------------------------

TABLA:
    .DB 0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F  ; Tabla de segmentos para dígitos 0-9