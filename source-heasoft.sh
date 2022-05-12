#!/bin/bash

# This bash script is part of the MEGAlib & COSItools setup procedure.
# As such it is dual licenced under Apache 2.0 for COSItools and LGPL 3.0 for MEGAlib
#
# Development lead: Andreas Zoglauer
#
# Description:
# Source all HEASoft-related environment variables



# Make this script work with zsh
if [ -n "$ZSH_VERSION" ]; then emulate -L ksh; fi


# Print some help 
confhelp() {
  echo ""
  echo "This script sources all HEASoft-related environment variables"
  echo " "
  echo "Usage: ./source-heasoft.sh --path=[full path to the HEASoft installation]";
  echo " "
}


# Parse the command line
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


# Perform sanity checks

# We require an absolute path
if [[ ${__TMP_PATH} != /* ]]; then
  echo ""
  echo "ERROR: The HEASoft path must be an absolute path: ${__TMP_PATH}"
  echo ""
  return
fi

# The directory must exist
if [[ ! -d ${__TMP_PATH} ]]; then
  echo ""
  echo "ERROR: HEASoft directory not found: ${__TMP_PATH}"
  echo ""
  return
fi


# Source the HEASoft environment 

__TMP_HEADASFOUND=false
__TMP_CFITSIOFOUND=false
if [[ -f ${__TMP_PATH}/headas-init.sh ]]; then 
  export HEADAS=${__TMP_PATH}
  alias heainit=". ${HEADAS}/headas-init.sh"
  source ${HEADAS}/headas-init.sh
  __TMP_HEADASFOUND=true
fi
if [[ `uname -a` == *Linux* ]]; then
  if [[ -f ${__TMP_PATH}/lib/libcfitsio.so ]]; then 
    __TMP_CFITSIOFOUND=true
  fi
else
  # Too many installation options here - don't do the check...
  __TMP_CFITSIOFOUND=true
fi

if [[ ${__TMP_HEADASFOUND} == false ]]; then
  echo ""
  echo "ERROR: HEADAS software not found in HEADAS directory"
  echo ""
  return
fi
if [[ ${__TMP_CFITSIOFOUND} == false ]]; then
  echo ""
  echo "ERROR: libcfitsio not found in the HEADAS library directory"
  echo "       You should make a link such as libcfitsio_3.XY.so -> libcfitsio.so"
  return
fi


return
