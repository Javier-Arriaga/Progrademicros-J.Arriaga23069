;
; Proyecto 1.asm
;
; Created: 25/02/2025 13:14:25
; Author : Javier Arriaga
;



.include "m328pdef.inc"  


.org PCINT0addr
    RJMP ISR_PCINT0   
.org 0x0000
    RJMP MAIN      


ISR_PCINT0:
    PUSH R16
    IN R16, SREG
    PUSH R16

    ; Leer el estado de los pines PB0-PB4
    IN R16, PINB
    ANDI R16, 0x1F       ; Aplicar máscara para obtener solo los bits de PB0-PB4

    ; Restaurar el estado de los registros
    POP R16
    OUT SREG, R16
    POP R16

    RETI                 


MAIN:
    ; Configuración de los pines como entradas con pull-up
    LDI R16, 0x1F        ; Cargar 0x1F en R16 (00011111 en binario, para PB0-PB4)
    OUT DDRB, R16        ; Configurar PB0-PB4 como entradas (0 en DDRB)
    OUT PORTB, R16       ; Habilitar resistencias pull-up en PB0-PB4 (1 en PORTB)

    ; Habilitar interrupciones en los pines PB0-PB4
    LDI R16, (1 << PCIE0); Habilitar interrupción por cambio de pin en el puerto B (PCIE0)
    STS PCICR, R16       ; Escribir en el registro PCICR
    LDI R16, 0x1F        ; Cargar 0x1F en R16 (00011111 en binario, para PB0-PB4)
    STS PCMSK0, R16      ; Habilitar interrupciones en PB0-PB4
    
    SEI                  


LOOP:
    RJMP LOOP            

TABLA:
    .DB 0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x47, 0x7F, 0x6F

FECHA:


CONFIG_FECHA:


HORA:



CONFIG_HORA:



ALARMA:



CONFIG_ALARMA:
