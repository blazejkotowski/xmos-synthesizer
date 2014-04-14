/*
 * midi.h
 *
 *  Created on: 13-04-2014
 *      Author: blazi
 */

#ifndef MIDI_H_
#define MIDI_H_

#include "midi_commands.h"

#define MIDI_RATE               (31250)
#define MIDI_BITTIME            (XS1_TIMER_MHZ * 1000000 / MIDI_RATE)
#define MIDI_BITTIME_2          (MIDI_BITTIME>>1)

/**
 * Midi message
 * \attr command        MIDI command type
 * \attr length         number of data bytes
 * \attr channel        channel command is sent to
 * \attr data           data bytes
 * \attr state          number of data bytes received
 */
struct s_midi_message {
    unsigned command;
    unsigned short length, channel;
    unsigned data[2];
    unsigned state;
};

/**
 * Interface to handle midi messages
 */
interface i_midi_listener {
    void command(struct s_midi_message message);
};

/**
 * Handles communication between MIDI controller and synthesizer thread
 *
 * \param p_MIDI_IN         1-bit in MIDI port
 * \param listener          interface to handle MIDI messages
 */
void midi_receive(in port p_MIDI_IN, client interface i_midi_listener listener);

/**
 * Parses raw message from MIDI controller and upgrades message state
 *
 * \param message           reference to message structure instance to be changed
 * \param byte              byte to be parsed
 */
void midi_parse(struct s_midi_message &message, unsigned byte);

#endif /* MIDI_H_ */
