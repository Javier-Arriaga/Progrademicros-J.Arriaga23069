/*
 * Servo2.h
 *
 * Created: 8/04/2025 15:13:12
 *  Author: Javie
 */ 


#ifndef PWMSERVO2_H
#define PWMSERVO2_H

#include <avr/io.h>

void PWM2_init();
void PWM2_setAngle(uint8_t angle);

#endif
