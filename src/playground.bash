#!/bin/bash

source $(dirname "${BASH_SOURCE[0]}")/bash-annotations.sh
import interfaces/interface.sh 
#import interfaces/inject.sh 
# import util/utility.sh interfaces/inject.sh annotations/functions/ignore.sh annotations/functions/debug.sh
# import util/types.sh
import annotations/variables/element_type.sh
#import annotations/functions/timer.sh

#export PS4='\nDEBUG level:$SHLVL subshell-level: $BASH_SUBSHELL \nsource-file:${BASH_SOURCE} line#:${LINENO} function:${FUNCNAME[0]:+${FUNCNAME[0]}(): }\nstatement: '


declare -a arrr=('one' 'two')

@element_type ARRAY
declare arrays
arrays=arrr

echo "${arrays}"
pwd