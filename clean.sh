#!/bin/bash

# This bash script is part of the MEGAlib & COSItools setup procedure.
# As such it is dual licenced under Apache 2.0 for COSItools and LGPL 3.0 for MEGAlib
#
# Development lead: Andreas Zoglauer
#
# Description:
# This script resets the environment, i.e. removes all compiled code and downloads.
# It does not touch the cloned repositories themselves.
# It assumes the COSItools have been setup correctly, i.e., source.sh has been sourced.
#


############################################################################################################
# Step 1: Define default parameters

# The command line
CMD=( "$@" )

# The path to the COSItools install
COSIPATH=""
GITBASEDIR="https://github.com/cositools"
GITBRANCH="feature/initialsetup"



############################################################################################################
# Step 2: helper functions

confhelp() {
  echo ""
  echo "Reset script for COSItools"
  echo " "
  echo "his script resets the environment, i.e. removes all compiled code and downloads."
  echo "It does not touch the cloned repositories themselves."
  echo "It assumes the COSItools have been setup correctly, i.e., source.sh has been sourced."
  echo " "
  echo "Usage: ./reset.sh"
  echo " "
  echo " "
  echo "Options:"
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



############################################################################################################
# Step 4: Do the cleanup


if [[ ${COSITOOLSDIR} == "" ]] || [[ ! -d ${COSITOOLSDIR} ]]; then
  echo ""
  echo "ERROR: The path to the COSI tools has not been found."
  echo "       Make sure the COSItools are installed and you have sourced the environment script."
  exit 1
fi

if [[ -d ${COSITOOLSDIR}/nuclearizer ]]; then
  echo "Cleaning nuclearizer"
  cd ${COSITOOLSDIR}/nuclearizer
  make clean
fi

if [[ -d ${COSITOOLSDIR}/megalib ]]; then
  echo "Cleaning MEGAlib"
  cd ${COSITOOLSDIR}/megalib
  make clean
fi

if [[ -d ${COSITOOLSDIR}/external ]]; then
  echo "Removing external libraries/programs"
  cd ${COSITOOLSDIR}/external
  rm -rf root*
  rm -rf geant4*
  rm -rf cfitsio*
  rm -rf heasoft*
fi

if [[ -d ${COSITOOLSDIR}/python-env ]]; then
  echo "Removing python environment"
  rm -rf ${COSITOOLSDIR}/python-env
fi

echo ""
echo "COSItools have been cleaned"

exit 0






 
