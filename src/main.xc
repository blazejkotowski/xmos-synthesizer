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
#define NOTE_DURATION       90000000

interface i_player_listener {
    void note_on(int note, int velocity);
    void note_off(int note);
    void pitch(int value);
};

on stdcore[AUDIO_IO_TILE]: in port p_MIDI_IN = PORT_MIDI_IN;

int midi_frequencies[] = {116, 120,
                          123, 126,
                          130,
                          138, 142,
                          146, 150,
                          155, 160,
                          164};

inline int midi_freq(int n) {
    return midi_frequencies[(n-26)%12] * (1 << (n-26)/12);
}

void xscope_user_init(void) {
    xscope_register( 2
        ,XSCOPE_CONTINUOUS ,"DAC Signal" ,XSCOPE_INT ,"value",
        XSCOPE_CONTINUOUS, "Timer", XSCOPE_INT, "ms");
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
void handle_midi_command(server interface i_midi_listener midi_listener, client interface i_player_listener player_listener) {
    while(1) {
        select {
            case midi_listener.command(struct s_midi_message message):
                /*printf("Command %d (0x%X)\n", message.command, message.command);
                for(int i=0; i<message.length; ++i) {
                    printf("\t%d\n", message.data[i]);
                }*/
                if(message.command == NOTE_ON) {
                    // NOTE ON
                    if(message.data[1] != 0) {
                        player_listener.note_on(message.data[0], message.data[1]);
                    }
                    // NOTE OFF
                    else {
                        player_listener.note_off(message.data[0]);
                    }
                }
                else if(message.command == PITCH) {
                    int pitch_value = (message.data[0] | (message.data[1] << 7));
                    printf("pitch value: %d\n", pitch_value);
                    player_listener.pitch(pitch_value);
                }
                break;
        }
    }
}

void play_note(streaming chanend audio_chan, int frequency, int delay) {
    timer t;
    int phase = 0;
    unsigned current_time, time, stop = 0;

    struct adsr_params adsr;
    adsr_duration_ratio(adsr, 1000, 0, 100, 600);
    adsr_volume_ratio(adsr, 1000, 160000, 160000);

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
//                align_left(signal);
                send_audio(audio_chan, signal);
                break;
        }
        if(stop)
            break;
    }
}

void player(server interface i_player_listener player_listener, streaming chanend audio_chan) {
    unsigned short playing = 0;
    int current_note = 0;
    int phase = 0;
    int pitch = 0;

    //24 - 108
    while(1) {
        select {
            case player_listener.note_on(int new_note, int new_velocity):
                current_note = new_note;
                printf("Playing note %d\n",current_note);
                playing = 1;
                phase = 0;
                break;
            case player_listener.note_off(int note):
                if(current_note == note)
                    playing = 0;
                break;
            case player_listener.pitch(int value):
                pitch = value - 8192;
                break;
            default:
                if(playing) {
                    int signal = getSineSample(phase, MIDI_NOTE_FREQUENCY(current_note));
                    send_audio(audio_chan, signal);
                }
                break;
        }
//        int note;
//        notes_chan :> note;
//        printf("freq: %d\n", midi_freq(note));
//        play_note(audio_chan, midi_freq(note), NOTE_DURATION);
    }
}

/*void play(streaming chanend audio_chan) {
    int phase = 0;
    while(1) {
        int signal = getSineSample(phase, 500);
        xscope_int(0, signal);
        align_left(signal);
        send_audio(audio_chan, signal);
    }
}*/

int main(void) {
    interface i_midi_listener midi_listener;
    interface i_player_listener player_listener;
    streaming chan audio_chan;

    par {
        on stdcore[AUDIO_IO_TILE] : midi_receive(p_MIDI_IN, midi_listener);
        on stdcore[AUDIO_IO_TILE] : handle_midi_command(midi_listener, player_listener);
        on stdcore[AUDIO_IO_TILE] : audio_io(audio_chan);
//        on stdcore[DSP_TILE] : play(audio_chan);
        on stdcore[DSP_TILE] : player(player_listener, audio_chan);
    }
    return 0;
}
