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
# Source all ROOT-related environment variables



# Make this script work with zsh
if [ -n "$ZSH_VERSION" ]; then emulate -L ksh; fi

confhelp() {
  echo ""
  echo "This script sources all ROOT-related environment variables"
  echo " "
  echo "Usage: ./source-root.sh --path=[full path to the ROOT installation]";
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
  echo "ERROR: The ROOT path must be an absolute path: ${__TMP_PATH}"
  echo ""
  return
fi

if [[ ! -d ${__TMP_PATH} ]]; then
  echo ""
  echo "ERROR: ROOT directory not found: ${__TMP_PATH}"
  echo ""
  return
fi


# Source the ROOT environment 

if [[ ! -f ${__TMP_PATH}/bin/thisroot.sh ]]; then
  echo ""
  echo "ERROR: Root environment script not found: ${__TMP_PATH}/bin/thisroot.sh"
  echo ""
  return
fi
   
# Has to come before HEADAS since both have a libMinuit.so
source ${__TMP_PATH}/bin/thisroot.sh


return
