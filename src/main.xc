/*
 * synthesizer.xc
 *
 *  Created on: 13-04-2014
 *      Author: blazi
 */

#include <xs1.h>
#include "sine.h"

void xscope_user_init(void) {
//    xscope_register( 2
//        ,XSCOPE_CONTINUOUS ,"DAC Signal" ,XSCOPE_INT ,"value",
//        XSCOPE_CONTINUOUS, "Timer", XSCOPE_INT, "ms");
    xscope_config_io(XSCOPE_IO_BASIC);
}

int main(void) {
    return 0;
}
