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
# Source all HEASoft-related environment variables



# Make this script work with zsh
if [ -n "$ZSH_VERSION" ]; then emulate -L ksh; fi

confhelp() {
  echo ""
  echo "This script sources all HEASoft-related environment variables"
  echo " "
  echo "Usage: ./source-heasoft.sh --path=[full path to the HEASoft installation]";
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
  echo "ERROR: The HEASoft path must be an absolute path: ${__TMP_PATH}"
  echo ""
  return
fi

if [[ ! -d ${__TMP_PATH} ]]; then
  echo ""
  echo "ERROR: HEASoft directory not found: ${__TMP_PATH}"
  echo ""
  return
fi


# Source the HEASoft environment 

__TMP_HEADASFOUND=false
__TMP_CFITSIOFOUND=false
for i in `ls -d ${__TMP_PATH}/*`; do
  if [[ "${i}" == *BUILD_DIR* ]]; then
    continue
  fi
  if [[ -f ${i}/headas-init.sh ]]; then 
    export HEADAS=${i}
    alias heainit=". ${HEADAS}/headas-init.sh"
    source ${HEADAS}/headas-init.sh
    __TMP_HEADASFOUND=true
  fi
  if [[ `uname -a` == *Linux* ]]; then
    if [[ -f ${i}/lib/libcfitsio.so ]]; then 
      __TMP_CFITSIOFOUND=true
    fi
  else
    # Too many installation options here - don't do the check...
    __TMP_CFITSIOFOUND=true
  fi
done

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
