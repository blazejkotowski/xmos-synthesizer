/*
 * midi.xc
 *
 *  Created on: 13-04-2014
 *      Author: blazi
 */

#include "midi.h"
#include <xs1.h>
#include <stdio.h>

void midi_receive(in port p_MIDI_IN, client interface i_midi_listener listener) {
    timer t;
    unsigned time, byte, res;

    struct s_midi_message message;
    message.state = 0;
    message.length = -1;

    while(1) {
        p_MIDI_IN when pinsneq(1) :> void;
        t :> time;

        time += MIDI_BITTIME/2;

        for(int i=0; i<8; ++i) {
            time += MIDI_BITTIME;
            t when timerafter(time) :> void;
            p_MIDI_IN :> >> byte;
        }

        time += MIDI_BITTIME;
        t when timerafter(time) :> void;
        p_MIDI_IN :> res;
        byte >>= 24;

        midi_parse(message, byte);
        if(message.state == message.length-1)
            listener.command(message);
    }
}

void midi_parse(struct s_midi_message &message, unsigned byte) {
    // Command byte
    if(byte >> 7 == 1) {
        switch(byte >> 4) {
        case NOTE_ON:
            message.length = 2;
            message.channel = (byte << 28) >> 28;
            message.state = 0;
            message.command = NOTE_ON;
            break;
        case NOTE_OFF:
            message.length = 2;
            message.state = 0;
            message.command = NOTE_OFF;
            printf("NOTE OFF\n");
            break;
        }
    }
    // Data byte
    else if(message.state < message.length) {
        message.data[message.state] = byte;
        message.state++;
    }
}

