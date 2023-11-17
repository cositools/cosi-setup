#!/bin/bash

# This bash script is part of the MEGAlib & COSItools setup procedure.
# As such it is dual licenced under Apache 2.0 for COSItools and LGPL 3.0 for MEGAlib
#
# Development lead: Andreas Zoglauer
#
# Description:
# This is the stage 1 script to setup the COSI tools
# It sets up up the main directory if it not exists and 
# then either updates or clones the cosi-setup repository,
# and finally hands off the setup to the newly downloaded stage 2 script
#


############################################################################################################
# Step 1: Define default parameters

# The command line
CMD=( "$@" )

# The path to the COSItools install
OUTPUT=""

# Operating system type
OSTYPE=$(uname -s)


############################################################################################################
# Step 2: helper functions

confhelp() {
  echo ""
  echo "Setup script for COSItools"
  echo " "
  echo "This script created a summary of the system to help debugging"
  echo " "
  echo "Usage: ./setup-system-summary.sh";
  echo " "
  echo " "
  echo "Options:"
  echo " "
  echo "--output=[output file name]"
  echo "    This is the file where we store the information"
  echo " "
  echo "--help or -h"
  echo "    Show this help."
  echo " "
  echo " "
}



############################################################################################################
# Step 3: extract the main parameters for the stage 1 script

# Check for help
for C in "${CMD[@]}"; do
  if [[ ${C} == *-h ]] || [[ ${C} == *-hel* ]]; then
    echo ""
    confhelp
    exit 0
  fi
done

# Overwrite default options with user options:
for C in "${CMD[@]}"; do
  if [[ ${C} == *-o*=* ]]; then
    OUTPUT=`echo ${C} | awk -F"=" '{ print $2 }'`
  elif [[ ${C} == *-h ]] || [[ ${C} == *-hel* ]]; then
    echo ""
    confhelp
    exit 0
  fi
done



############################################################################################################
# Step 4: Create the summary 

SEPARATOR="\n*****************************\n"

echo ""
echo ""
echo -e "${SEPARATOR}"
echo "System summary"

if [[ ${OSTYPE} == *inux* ]]; then
  echo -e "${SEPARATOR}"
  echo -e "CPU:\n"
  lscpu | grep "Model name" | awk -F: '{print $2 }' | xargs

  echo -e "${SEPARATOR}"
  echo -e "Memory:\n"
  lsmem | grep "Total online" | awk -F: '{ print $2 }' | xargs
elif [[ ${OSTYPE} == *arwin* ]]; then
  echo -e "${SEPARATOR}"
  echo -e "CPU:\n"
  sysctl -a | grep "cpu.brand_string" | awk -F: '{ print $2 }' | xargs

  echo -e "${SEPARATOR}"
  echo -e "Memory:\n"
  MEM=$(sysctl -a | grep "mem" | grep "hw.memsize:" | awk -F: '{ print $2 }' | xargs)
  MEM=$(echo "${MEM}/1024/1024/1024" | bc)
  echo "${MEM} GB"

fi


echo -e "${SEPARATOR}"
echo -e "uname -a\n"
uname -a 

echo -e "${SEPARATOR}"
if [[ ${OSTYPE} == *inux* ]]; then
  echo -e "cat /etc/os-release:\n"
  cat /etc/os-release
elif [[ ${OSTYPE} == *arwin* ]]; then
  echo -e "sw_vers:\n"
  sw_vers
fi

echo -e "${SEPARATOR}"
echo -e "PATH variable:\n"
if [[ ${PATH} != "" ]]; then
  echo "${PATH}"
else
  echo "PATH not set"
fi

echo -e "${SEPARATOR}"
echo -e "LD_LIBRARY_PATH variable:\n"
if [[ ${LD_LIBRARY_PATH} != "" ]]; then
  echo "${LD_LIBRARY_PATH}"
else 
  echo "LD_LIBRARY_PATH not set"
fi

echo -e "${SEPARATOR}"
echo -e "DYLD_LIBRARY_PATH variable:\n"
if [[ ${DYLD_LIBRARY_PATH} != "" ]]; then
  echo "${DYLD_LIBRARY_PATH}"
else 
  echo "DYLD_LIBRARY_PATH not set"
fi

echo -e "${SEPARATOR}"
echo -e "gcc --version:\n"
type gcc >/dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "gcc not found"
else
  gcc --version
fi

echo -e "${SEPARATOR}"
echo -e "clang --version:\n"
type clang >/dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "clang not found"
else
  clang --version
fi

if [[ ${OSTYPE} == *arwin* ]]; then
  echo -e "${SEPARATOR}"
  echo -e "brew, port, conda:\n"
  type brew >/dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo "brew not found"
  else
    echo "brew found"
  fi

  type port >/dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo "port not found"
  else
    echo "port found"
  fi

  type conda >/dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo "conda not found"
  else
    echo "conda found"
  fi
fi




echo -e "${SEPARATOR}"
exit 0

