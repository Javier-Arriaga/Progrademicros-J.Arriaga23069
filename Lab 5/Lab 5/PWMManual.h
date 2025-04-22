/*
 * PWMManual.h
 *
 * Created: 19/04/2025 13:11:04
 *  Author: Javie
 */ 


#ifndef PWMMANUAL_H_
#define PWMMANUAL_H_

#include <avr/io.h>

void PWM_manual_init();
void PWM_manual_set(uint8_t value);

#endif /* PWMMANUAL_H_ */