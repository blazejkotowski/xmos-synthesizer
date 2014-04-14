/*
 * adsr.xc
 *
 *  Created on: 10-04-2014
 *      Author: blazi
 */

#include "adsr.h"
#include <stdio.h>

void adsr_duration_ratio(struct adsr_params &params, int duration_base, int attack, int decay, int release) {
    params.duration_ratio[ATTACK] = attack;
    params.duration_ratio[DECAY] = decay;
    params.duration_ratio[RELEASE] = release;
    params.duration_ratio_base = duration_base;
}

void adsr_volume_ratio(struct adsr_params &params, int volume_base, int attack, int sustain) {
    params.volume_ratio[ATTACK] = attack;
    params.volume_ratio[SUSTAIN] = sustain;
    params.volume_ratio_base = volume_base;
}

void adsr_time(struct adsr_params &params, unsigned start_time, int duration) {
    params.state = ATTACK;
    params.start_time = start_time;
    params.finish_time = start_time + duration;

    for(int i = 0; i < STATES_COUNT; ++i)
        params.state_finish[i] = _adsr_count_state_finish_abs(params, i);

//    printf("NOTE START: %u\n", params.start_time);
//    printf("NOTE FINISH: %u\n", params.finish_time);
//    printf("\n\n");
}

int adsr_sample(struct adsr_params &params, unsigned time, int sample) {
    int last_state = params.state;
    params.state = _adsr_state(params, time);
    if(last_state != params.state) {
//        printf("State change (%d -> %d)\ntime: %u\n", last_state, params.state, time);
    }
    long long moment = time - params.start_time;
    long long state_finish = _adsr_state_finish(params, params.state);
    long long state_start = _adsr_state_start(params, params.state);
    switch(params.state) {
    case ATTACK:
        return sample * params.volume_ratio[ATTACK] / params.volume_ratio_base * (moment - state_start) / (state_finish - state_start);
        break;
    case DECAY:
        int max_sample = sample *  params.volume_ratio[SUSTAIN] / params.volume_ratio_base;
        return sample - ((sample - max_sample) * (moment - state_start) / (state_finish - state_start));
        break;
    case SUSTAIN:
        return sample * params.volume_ratio[SUSTAIN] / params.volume_ratio_base;
        break;
    case RELEASE:
        long long max_sample = sample * params.volume_ratio[SUSTAIN] / params.volume_ratio_base;
        return max_sample - max_sample*(moment - state_start - 100) / (state_finish - state_start);
        break;
    }
    return 0;
}

int _adsr_state(struct adsr_params params, unsigned time) {
    if(time < params.state_finish[ATTACK])
        return ATTACK;
    else if(time >= params.state_finish[ATTACK] && time < params.state_finish[DECAY])
        return DECAY;
    else if(time >= params.state_finish[DECAY] && time < params.state_finish[SUSTAIN])
        return SUSTAIN;
    else if(time >= params.state_finish[SUSTAIN] && time < params.state_finish[RELEASE])
        return RELEASE;
    return SUSPEND;
}

unsigned _adsr_count_state_finish_abs(struct adsr_params params, int state) {
    if(state == RELEASE)
        return params.finish_time;

    long long duration = params.finish_time - params.start_time;
    if(state == SUSTAIN)
        return params.finish_time - (duration * params.duration_ratio[RELEASE] / params.duration_ratio_base);

    long long res = 0;
    for(int i = 0; i <= state; ++ i)
        res += (duration * params.duration_ratio[state] / params.duration_ratio_base);
    return params.start_time + res;
}

unsigned _adsr_state_finish(struct adsr_params params, int state) {
    return params.state_finish[state] - params.start_time;
}

unsigned _adsr_state_start(struct adsr_params params, int state) {
    return (state > 0 ? params.state_finish[state-1] : params.start_time) - params.start_time;
}

