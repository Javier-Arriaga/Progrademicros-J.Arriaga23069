/*
 * PRE.h
 *
 * Created: 22/04/2025 13:43:14
 *  Author: Javie
 */ 
#ifndef PRE_H_
#define PRE_H_

void UART_init(void);
void UART_writeChar(char caracter);
void UART_writeString(char* texto);
void UART_mostrarValor(uint8_t valor);

#endif /* PRE_H_ */