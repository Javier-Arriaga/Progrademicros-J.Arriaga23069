/*
 * Servo.h
 *
 * Created: 8/04/2025 12:57:11
 *  Author: Javie
 */ 
#ifndef PWMSERVO_H
#define PWMSERVO_H

#include <avr/io.h>

void PWM_init();
void PWM_setAngle(uint8_t angle);

#endif