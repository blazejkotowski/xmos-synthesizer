/*
 * adsr.h
 * Library handling ADSR envelope generator
 *
 *  Created on: 10-04-2014
 *      Author: blazi
 */

#ifndef ADSR_H_
#define ADSR_H_

#define STATES_COUNT 4

/**
 * ADSR States enum
 */
enum adsr {
    ATTACK = 0,
    DECAY = 1,
    SUSTAIN = 2,
    RELEASE = 3,
    SUSPEND = 4
};

/**
 * Keeps ADSR Envelope parameters
 *
 * \attr state                      current state
 * \attr duration_ratio             duration is counted with use of this ratio
 * \attr state_finish               time in ms when state finishes
 * \attr duration_ratio_base        base ratio to count state duration
 * \attr volume_ratio               volume is counted with use of this ratio
 * \attr volume_ratio_base          base ratio to count state volume
 * \attr duration                   entire note duration in ms
 * \attr start_time                 note start time in ms
 * \attr finish_time                note finish time in ms
 */
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

/**
 * Duration ratios setter
 *
 * \param params                reference to params structure to be upgraded
 * \param duration_base
 * \param attack
 * \param decay
 * \param release
 */
void adsr_duration_ratio(struct adsr_params &params, int duration_base, int attack, int decay, int release);

/**
 * Volume ratios setter
 *
 * \param params                reference to params structure to be upgraded
 * \param volume_base
 * \param attack
 * \param sustain
 */
void adsr_volume_ratio(struct adsr_params &params, int volume_base, int attack, int sustain);

/**
 * Sets start time, finish time and duration
 *
 * \param params                reference to params structure to be upgraded
 * \param start_time            start_time in ms (from timer)
 * \param duration              duration in ms
 */
void adsr_time(struct adsr_params &params, unsigned start_time, int duration);

/**
 * Computes current sample based on time and input sample
 *
 * \param params                reference to adsr parameters structure
 * \param time                  current time in ms (from timer)
 * \param sample                raw input sample
 *
 * \return                      computed ADSR sample
 */
int adsr_sample(struct adsr_params &params, unsigned time, int sample);

/**
 * Returns state basing on current time
 *
 * \param params                ADSR parameters structure
 * \param time                  time in ms (from timer)
 *
 * \return                      current ADSR state
 */
int _adsr_state(struct adsr_params params, unsigned time);

/**
 * Computes absolute time of ADSR state finish. Absolute time is sum of
 * note start time, duration of certain state and all states before
 *
 * \param params                ADSR parameters structure
 * \param state                 state to be computed
 *
 * \return                      absolute state finish time in ms
 */
unsigned _adsr_count_state_finish_abs(struct adsr_params params, int state);

/**
 * Computes ADSR state finish in ms.
 *
 * \param params                ADSR parameters structure
 * \param state                 state to be computed
 *
 * \return                      state finish time computed from 0 in ms
 */
unsigned _adsr_state_finish(struct adsr_params params, int state);

/**
 * Computes ADSR state start time in ms. It bases on _adsr_count_state_finish
 *
 * \param params                ADSR parameters structure
 * \param state                 state to be computed
 *
 * \return                      state start time computed from 0 in ms
 */
unsigned _adsr_state_start(struct adsr_params params, int state);

#endif /* ADSR_H_ */
