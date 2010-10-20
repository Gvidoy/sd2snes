/* ___DISCLAIMER___ */

#include <arm/NXP/LPC17xx/LPC17xx.h>
#include "bits.h"
#include "timer.h"
#include "led.h"

int led_rdyledstate = 0;
int led_readledstate = 0;
int led_writeledstate = 0;

void rdyled(unsigned int state) {
  BITBAND(LPC_GPIO2->FIODIR, 0) = state;
  led_rdyledstate = state;
}

void readled(unsigned int state) {
  BITBAND(LPC_GPIO2->FIODIR, 1) = state;
  led_readledstate = state;
}

void writeled(unsigned int state) {
  BITBAND(LPC_GPIO2->FIODIR, 2) = state;
  led_writeledstate = state;
}

void led_clkout32(uint32_t val) {
  while(1) {
    rdyled(1);
    delay_ms(400);
    readled((val & BV(31))>>31);
    rdyled(0);
    val<<=1;
    delay_ms(400);
  }
}

void toggle_rdy_led() {
  rdyled(~led_rdyledstate);
}

void toggle_read_led() {
  readled(~led_readledstate);
}

void toggle_write_led() {
  writeled(~led_writeledstate);
}

void led_panic() {
  while(1) {
    LPC_GPIO2->FIODIR |= BV(0) | BV(1) | BV(2);
    delay_ms(350);
    LPC_GPIO2->FIODIR &= ~(BV(0) | BV(1) | BV(2));
    delay_ms(350);
  }
}