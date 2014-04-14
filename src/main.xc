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

#define NOTE_FREQ(note)     ((note-34)*100)
#define NOTE_DURATION       50000000

on stdcore[AUDIO_IO_TILE]: in port p_MIDI_IN = PORT_MIDI_IN;

void xscope_user_init(void) {
//    xscope_register( 2
//        ,XSCOPE_CONTINUOUS ,"DAC Signal" ,XSCOPE_INT ,"value",
//        XSCOPE_CONTINUOUS, "Timer", XSCOPE_INT, "ms");
    xscope_config_io(XSCOPE_IO_BASIC);
}

void align_left(int &byte) {
    while(!((1 << 31) & byte))
        byte << 1;
}

void send_audio(streaming chanend audio_chan, int signal) {
    #pragma loop unroll
    for(int i=0; i<4; ++i) {
        audio_chan :> int _;
        audio_chan <: signal;
    }
}

[[combinable]]
void handle_midi_command(server interface i_midi_listener midi_listener, chanend notes_chan) {
    while(1) {
        select {
            case midi_listener.command(struct s_midi_message message):
                if(message.command == NOTE_ON)
                    notes_chan :> message.data[0];
                break;
        }
    }
}

void play_note(streaming chanend audio_chan, int frequency, int delay) {
    timer t;
    int phase = 0;
    unsigned current_time, time, stop = 0;

    struct adsr_params adsr;
    adsr_duration_ratio(adsr, 1000, 200, 200, 200);
    adsr_volume_ratio(adsr, 1000, 2000, 1500);

    t :> time;
    adsr_time(adsr, time, delay);
    time += delay;

    while(1) {
        select {
            case t when timerafter(time) :> void:
                stop = 1;
                break;
            default:
                t :> current_time;
                int signal = getSineSample(phase, frequency);
                signal = adsr_sample(adsr, current_time, signal);
//                xscope_int(0, signal);
                align_left(signal);
                send_audio(audio_chan, signal);
                break;
        }
        if(stop)
            break;
    }
}

void player(chanend notes_chan, streaming chanend audio_chan) {
    while(1) {
        int note;
        notes_chan :> note;
        play_note(audio_chan, NOTE_FREQ(note), NOTE_DURATION);
    }
}

int main(void) {
    interface i_midi_listener midi_listener;
    streaming chan audio_chan;
    chan notes_chan;

    par {
        on stdcore[AUDIO_IO_TILE] : midi_receive(p_MIDI_IN, midi_listener);
        on stdcore[AUDIO_IO_TILE] : handle_midi_command(midi_listener, notes_chan);
        on stdcore[AUDIO_IO_TILE] : audio_io(audio_chan);
        on stdcore[DSP_TILE] : player(notes_chan, audio_chan);
    }
    return 0;
}
