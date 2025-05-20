/*
 * TEXTO.h
 *
 * Created: 29/04/2025 15:03:46
 *  Author: Javie
 */ 


#ifndef TEXTO_H_
#define TEXTO_H_

void UART_init(void);
void UART_writeChar(char caracter);
void UART_writeString(char* texto);

#endif /* TEXTO_H_ */