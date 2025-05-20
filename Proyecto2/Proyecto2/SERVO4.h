/*
 * SERVO4.h
 *
 * Created: 29/04/2025 14:54:41
 *  Author: Javie
 */ 


#ifndef SERVO4_H_
#define SERVO4_H_

#include <avr/io.h>

void PWM4_init();
void PWM4_setAngle(uint8_t angle);

#endif /* SERVO4_H_ */