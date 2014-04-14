/*
 * adsr.h
 *
 *  Created on: 10-04-2014
 *      Author: blazi
 */

#ifndef ADSR_H_
#define ADSR_H_

#define STATES_COUNT 4

enum adsr {
    ATTACK = 0,
    DECAY = 1,
    SUSTAIN = 2,
    RELEASE = 3,
    SUSPEND = 4
};

struct adsr_params {
    short unsigned state;
    long long duration_ratio[STATES_COUNT];
    unsigned state_finish[STATES_COUNT];
    long long duration_ratio_base;
    long long volume_ratio[STATES_COUNT];
    long long volume_ratio_base;
    long long duration;
    unsigned start_time, finish_time;
};

void adsr_duration_ratio(struct adsr_params &params, int duration_base, int attack, int decay, int release);

void adsr_volume_ratio(struct adsr_params &params, int volume_base, int attack, int sustain);

void adsr_time(struct adsr_params &params, unsigned start_time, int duration);

int adsr_sample(struct adsr_params &params, unsigned ime, int sample);

int _adsr_state(struct adsr_params params, unsigned time);

unsigned _adsr_count_state_finish_abs(struct adsr_params params, int state);

unsigned _adsr_state_finish(struct adsr_params params, int state);

unsigned _adsr_state_start(struct adsr_params params, int state);

#endif /* ADSR_H_ */
