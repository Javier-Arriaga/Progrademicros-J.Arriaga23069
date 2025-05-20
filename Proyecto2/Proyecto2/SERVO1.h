/*
 * SERVO1.h
 *
 * Created: 29/04/2025 13:37:01
 *  Author: Javie
 */ 


#ifndef SERVO1_H_
#define SERVO1_H_

#include <avr/io.h>

void PWM_init();
void PWM_setAngle(uint8_t angle);


#endif /* SERVO1_H_ */