#!/bin/bash

# This bash script file is part of the COSItools.
#
# The original file is part of MEGAlib.
# Port to COSItools and license change approved by original author, Andreas Zoglauer  
#
# Development lead: Andreas Zoglauer
# License: Apache 2.0
#
# Description:
# Source all Nuclearizer-related environment variables



# Make this script work with zsh
if [ -n "$ZSH_VERSION" ]; then emulate -L ksh; fi

confhelp() {
  echo ""
  echo "This script sources all Nuclearizer-related environment variables"
  echo " "
  echo "Usage: ./source-nuclearizer.sh --path=[full path to the Nuclearizer installation]";
  echo " "
}


# The command line
CMD=( "$@" )

__TMP_PATH=""
__TMP_HERE=$(pwd)

for C in "${CMD[@]}"; do
  if [[ ${C} == *-p*=* ]]; then
    __TMP_PATH=`echo ${C} | awk -F"=" '{ print $2 }'`
  elif [[ ${C} == *-h ]] || [[ ${C} == *-hel* ]]; then
    echo ""
    confhelp
    exit 0
  fi
done


# Sanity checks

if [[ ${__TMP_PATH} != /* ]]; then
  echo ""
  echo "ERROR: The Nuclearizer path must be an absolute path: ${__TMP_PATH}"
  echo ""
  return
fi

if [[ ! -d ${__TMP_PATH} ]]; then
  echo ""
  echo "ERROR: Nuclearizer directory not found: ${__TMP_PATH}"
  echo ""
  return
fi


# Source the Nuclearizer environment 
export NUCLEARIZER=${__TMP_PATH}   
export PATH=${NUCLEARIZER}/bin:${PATH}    
alias nuc='cd ${NUCLEARIZER}'

return
