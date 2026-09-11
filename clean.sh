#!/bin/bash

# This bash script is part of the MEGAlib & COSItools setup procedure.
# As such it is dual licenced under Apache 2.0 for COSItools and LGPL 3.0 for MEGAlib
#
# Development lead: Andreas Zoglauer
#
# Description:
# This script resets the environment, i.e. removes all compiled code and downloads.
# It does not touch the cloned repositories themselves.
# It assumes the COSI tools have been setup correctly, i.e., source.sh has been sourced.
#


############################################################################################################
# Step 1: Define default parameters

# Path to where this file is located
SETUPPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

# The shared helper functions, e.g. resolveoption
. "${SETUPPATH}/setup-helpers.sh"

# Every option this script accepts. Abbreviations are resolved against this list.
SETUPOPTIONS="all c++-code external python-env help"

# The command line
CMD=( "$@" )

CLEANCPP=false
CLEANEXTERNAL=false
CLEANPYTHON=false



############################################################################################################
# Step 2: helper functions

confhelp() {
  echo ""
  echo "Cleanup script for the COSItools"
  echo " "
  echo "This script resets the environment, i.e. removes all compiled code and downloads."
  echo "It does not touch the cloned repositories themselves."
  echo "It assumes the COSItools have been setup correctly, i.e., source.sh has been sourced."
  echo " "
  echo "Usage: ./clean.sh [options]"
  echo " "
  echo " "
  echo "Options:"
  echo " "
  echo "--all or -a          Clean all"
  echo "--c++-code or -c     Clean all compiled C/C++ code"
  echo "--external or -e     Remove all external programs (ROOT, Geant4, HEASoft/cfitsio, etc.)"
  echo "--python-env or -p   Remove the python environment"
  echo " "
  echo "--help or -h"
  echo "    Show this help."
  echo " "
  echo " "
}



############################################################################################################
# Step 3: Extract the main parameters frm the command line

# Check for help
for C in "${CMD[@]}"; do
  # "|| RESULT=$?" so that a non-zero return does not trip a "set -e"
  RESULT=0
  OPTION=$(resolveoption "${C}" "${SETUPOPTIONS}") || RESULT=$?
  if [[ ${RESULT} == 2 ]]; then
    echo ""
    echo "ERROR: The command line option \"${C}\" is ambiguous - it matches: ${OPTION}"
    echo "       See \"./clean.sh --help\" for a list of options"
    exit 1
  elif [[ ${RESULT} != 0 ]]; then
    echo ""
    echo "ERROR: Unknown command line option: ${C}"
    echo "       See \"./clean.sh --help\" for a list of options"
    exit 1
  fi

  case ${OPTION} in
    all)
      CLEANCPP=true
      CLEANEXTERNAL=true
      CLEANPYTHON=true
      ;;
    c++-code)
      CLEANCPP=true
      ;;
    external)
      CLEANEXTERNAL=true
      ;;
    python-env)
      CLEANPYTHON=true
      ;;
    help)
      echo ""
      confhelp
      exit 0
      ;;
  esac
done

if [[ ${CLEANCPP} != "true" ]] && [[ ${CLEANEXTERNAL} != "true" ]] && [[ ${CLEANPYTHON} != "true" ]]; then
  echo ""
  echo "Nothing to be done. Please see \"./clean.sh --help\" for a list of options."
  echo ""
  exit 0
fi



############################################################################################################
# Step 4: Do the cleanup


if [[ ${COSITOOLSDIR} == "" ]] || [[ ! -d ${COSITOOLSDIR} ]]; then
  echo ""
  echo "ERROR: The path to the COSI tools has not been found."
  echo "       Make sure the COSI tools are installed and you have sourced the environment script."
  echo ""
  exit 1
fi

if [[ ${CLEANCPP} == "true" ]]; then
  if [[ -d ${COSITOOLSDIR}/nuclearizer ]]; then
    echo "Cleaning nuclearizer"
    cd "${COSITOOLSDIR}/nuclearizer"
    make clean
  fi

  if [[ -d ${COSITOOLSDIR}/megalib ]]; then
    echo "Cleaning MEGAlib"
    cd "${COSITOOLSDIR}/megalib"
    make clean
  fi
fi

if [[ ${CLEANEXTERNAL} == "true" ]]; then
  if [[ -d ${COSITOOLSDIR}/external ]]; then
    echo "Removing external libraries/programs"
    cd "${COSITOOLSDIR}/external"
    rm -rf root*
    rm -rf geant4*
    rm -rf cfitsio*
    rm -rf heasoft*
    rm -rf healpix*
  fi
fi

if [[ ${CLEANPYTHON} == "true" ]]; then
  if [[ -d ${COSITOOLSDIR}/python-env ]]; then
    echo "Removing python environment"
    rm -rf "${COSITOOLSDIR}/python-env"
  fi
fi

echo ""
echo "Done cleaning COSI tools"
echo ""

exit 0






 
