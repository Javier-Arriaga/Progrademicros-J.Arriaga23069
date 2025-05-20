/*
 * SERVO2.h
 *
 * Created: 29/04/2025 13:50:09
 *  Author: Javie
 */ 


#ifndef SERVO2_H_
#define SERVO2_H_

#include <avr/io.h>

void PWM2_init();
void PWM2_setAngle(uint8_t angle);


#endif /* SERVO2_H_ */