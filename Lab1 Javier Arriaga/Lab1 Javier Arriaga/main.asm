;***********************************************************
;Universidad del Valle de Guatemala
;IE023: Programacion de microcontroladores
;
; Created: 4/02/2025 12:21:02
; Author : Javier Arriaga
;Proyecto: Lab1 Javier Arriaga.asm
;***********************************

.cseg
.org    0x0000

// Configuracion de oscilador de 1MHz
LDI R16, 0x00
OUT CLKPR, R16

// Configuración de la pila
LDI     R16, LOW(RAMEND)
OUT     SPL, R16        // Cargar 0xff a SPL
LDI     R16, HIGH(RAMEND)
OUT     SPH, R16        // Cargar 0x08 a SPH

// Configuración de los contadores
SETUP:
    // Configuración puerto D como entrada con pull-ups habilitados (Botones en PD2, PD3, PD4, PD5)
    LDI     R16, 0x00
    OUT     DDRD, R16   
    LDI     R16, 0xFF
    OUT     PORTD, R16  

    // Configuración del puerto C como salida para LEDs (Contador en PC0-PC3)
    LDI     R16, 0x0F
    OUT     DDRC, R16   
    LDI     R16, 0x00   // Inicialmente apagados
    OUT     PORTC, R16  
    
    LDI     R17, 0xFF   // Estado previo de botones
    CLR     R18         // Registro para almacenar el valor del contador

	// Configuración del puerto B como salida para LEDs (Contador 2 en PB1-PB4)
    LDI     R16, 0x0F   // Configurar PB1-PB4 como salida
	OUT     DDRB, R16   
    LDI     R16, 0x00   // Inicialmente apagados
    OUT     PORTB, R16  
    
    LDI     R17, 0xFF   // Estado previo de botones
    CLR     R18         // Registro para almacenar el valor del contador 1
    CLR     R19         // Registro para almacenar el valor del contador 2

	//Configuracion del puerto B
	LDI		R16, 0x1F
	OUT		DDRB, R10
	LDI		R16, 0x00
	OUT		PORTB, R16

	LDI R17, 0xFF
	CLR R18
	CLR R19

// Loop principal
LOOP:
    IN      R16, PIND   // Leer puerto D a 0ms
    CP      R17, R16
    BREQ    LOOP
    CALL    DELAY       // Antirrebote
    IN      R16, PIND   
    CP      R17, R16
    BREQ    LOOP
    CALL    DELAY       // Antirrebote
    MOV     R17, R16    

    SBRC    R16, 2      // Si el botón de incremento del contador 1 está presionado, salta
    RJMP    CHECK_DEC1
    CALL    INCREMENTO1  // Suma al contador 1

CHECK_DEC1:
    SBRC    R16, 3      // Si el botón de decremento del contador 1 está presionado, salta
    RJMP    CHECK_INC2
    CALL    DECREMENTO1  // Resta al contador 1

CHECK_INC2:
    SBRC    R16, 4      // Si el botón de incremento del contador 2 está presionado, salta
    RJMP    CHECK_DEC2
    CALL    INCREMENTO2  // Suma al contador 2

CHECK_DEC2:
    SBRC    R16, 5      // Si el botón de decremento del contador 2 está presionado, salta
    RJMP    LOOP
    CALL    DECREMENTO2  // Resta al contador 2
    RJMP    LOOP  

// Subrutinas
INCREMENTO1:
    LDI     R17, 0x0F   // Máscara para limitar a 4 bits
    INC     R18         // Incrementar contador 1
    AND     R18, R17    // Limitar a 4 bits
    OUT     PORTC, R18  // Mostrar valor en los LEDs del contador 1
    RET

DECREMENTO1:
    LDI     R17, 0x0F   // Máscara para limitar a 4 bits
    DEC     R18         // Decrementar contador 1
    AND     R18, R17    // Limitar a 4 bits
    OUT     PORTC, R18  // Mostrar valor en los LEDs del contador 1
    RET

INCREMENTO2:
    LDI     R17, 0x0F   // Máscara para limitar a 4 bits
    INC     R19         // Incrementar contador 2
    AND     R19, R17    // Limitar a 4 bits
    OUT     PORTB, R19  // Mostrar valor en los LEDs del contador 2
    RET

DECREMENTO2:
    LDI     R17, 0x0F   // Máscara para limitar a 4 bits
    DEC     R19         // Decrementar contador 2
    AND     R19, R17    // Limitar a 4 bits
    OUT     PORTB, R19  // Mostrar valor en los LEDs del contador 2
    RET

SUM_CONTADORES:			
	ADD R20, R18		//Se carga el valor del contador 1 al registro 20
	ADD R20, R19		//Se carga el valor del contador 2 al registro 20
	LDI R17, 0x0F
	AND R20, R17
	OUT PORTB, R20
	BRCC SIN_CARRY		//Se realiza la suma si no hay carry
	SBI PORTB , 4		//Se carga alos LEDs
	RJMP SALIR_SUM		//Saltamos al proceso de salir de la suma

SIN_CARRY:
	CBI PORTB, 4

SALIR_SUM:
	RET

DELAY:		//Se implemntan los delay al codigo para evitar el antirrebote
    LDI     R20, 0
SUBDELAY1:
    INC     R20
    CPI     R20, 0
    BRNE    SUBDELAY1
    LDI     R20, 0
SUBDELAY2:
    INC     R20
    CPI     R20, 0
    BRNE    SUBDELAY2
    RET
