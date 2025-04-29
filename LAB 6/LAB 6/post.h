/*
 * post.h
 *
 * Created: 28/04/2025 12:19:15
 *  Author: Javie
 */ 


#ifndef POST_H_
#define POST_H_

#include <avr/io.h>

void ADC_init(void);
uint8_t ADC_read(uint8_t canal);


#endif /* POST_H_ */