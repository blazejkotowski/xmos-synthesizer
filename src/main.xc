/*
 * synthesizer.xc
 *
 *  Created on: 13-04-2014
 *      Author: blazi
 */

#include <xs1.h>
#include <xscope.h>
#include <platform.h>
#include "audio_io.h"
#include "sine.h"
#include "midi.h"
#include "adsr.h"

on stdcore[AUDIO_IO_TILE]: in port p_MIDI_IN = PORT_MIDI_IN;

void xscope_user_init(void) {
//    xscope_register( 2
//        ,XSCOPE_CONTINUOUS ,"DAC Signal" ,XSCOPE_INT ,"value",
//        XSCOPE_CONTINUOUS, "Timer", XSCOPE_INT, "ms");
    xscope_config_io(XSCOPE_IO_BASIC);
}

[[combinable]]
void handle_midi_command(server interface i_midi_listener midi_listener, streaming chanend audio_chan) {
    while(1) {
        select {
            case midi_listener.command(struct s_midi_message message):
                break;
        }
    }
}

int main(void) {
    interface i_midi_listener midi_listener;
    streaming chan audio_chan;

    par {
        on stdcore[AUDIO_IO_TILE] : midi_receive(p_MIDI_IN, midi_listener);
        on stdcore[AUDIO_IO_TILE] : handle_midi_command(midi_listener, audio_chan);
        on stdcore[AUDIO_IO_TILE] : audio_io(audio_chan);
    }
    return 0;
}
