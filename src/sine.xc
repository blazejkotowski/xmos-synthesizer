/*
 * sine.xc
 *
 *  Created on: 13-04-2014
 *      Author: blazi
 */

#include "sine.h"

int getSineSample(int &phase, int freq) {
  int res;
  if(phase < SINE_SAMPLES_NUM) {
    res = sine[phase];
  }
  else if (phase >= SINE_SAMPLES_NUM && phase < SINE_SAMPLES_NUM*2) {
    res = sine[(SINE_SAMPLES_NUM-1)-(phase-SINE_SAMPLES_NUM)];
  }
  else if (phase >= SINE_SAMPLES_NUM*2 && phase < SINE_SAMPLES_NUM*3) {
    res = -sine[phase-(SINE_SAMPLES_NUM*2)];
  }
  else if (phase >= SINE_SAMPLES_NUM*3 && phase <= SINE_SAMPLES_NUM*4) {
    res = -sine[(SINE_SAMPLES_NUM-1)-(phase-(SINE_SAMPLES_NUM*3))];
  }
  phase += (4*SINE_SAMPLES_NUM)/(SAMP_FREQ/freq);
  if(phase >= 4*SINE_SAMPLES_NUM)
      phase -= 4*SINE_SAMPLES_NUM;
  return res;
}
