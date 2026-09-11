#!/bin/bash

# This bash script is part of the MEGAlib & COSItools setup procedure.
# As such it is dual licenced under Apache 2.0 for COSItools and LGPL 3.0 for MEGAlib
#
# Development lead: Andreas Zoglauer
#
# Description:
# This script checks for allowed HEASoft versions


confhelp() {
  echo ""
  echo "Check for a correct version of HEASoft"
  echo " " 
  echo "Usage: ./check-HEASoft.sh [options]";
  echo " "
  echo " "
  echo "Options:"
  echo "--get-max"
  echo "    Return the allowed maximum HEASoft version" 
  echo "--get-min"
  echo "    Return the allowed minimum HEASoft version" 
  echo " "
  echo "--check=[path to HEASoft]"
  echo "    Check the given path if it contains a good HEASoft version." 
  echo " "
  echo "--good-version=[version string]"
  echo "    Check the given version string contains a good HEASoft version."   
  echo " "
  echo "--help or -h"
  echo "    Show this help."
  echo " "
  echo " "
}

# Path to where this file is located
SETUPPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

# The shared helper functions, e.g. resolveoption
. "${SETUPPATH}/setup-helpers.sh"

# Every option this script accepts. Abbreviations are resolved against this list.
SETUPOPTIONS="check get-max get-min good-version help"

# Store command line
CMD=( "$@" )

# Check for help
for C in "${CMD[@]}"; do
  if [[ ${C} == "-h" ]] || [[ $(resolveoption "${C}" "${SETUPOPTIONS}") == "help" ]]; then
    echo ""
    confhelp
    exit 0
  fi
done

# What the script was asked to do: check, get-max, get-min or good-version
MODE=""
HEASoftPATH=""
TESTVERSION=""

# Overwrite default options with user options:
for C in "${CMD[@]}"; do
  # "|| RESULT=$?" so that a non-zero return does not trip a "set -e"
  RESULT=0
  OPTION=$(resolveoption "${C}" "${SETUPOPTIONS}") || RESULT=$?
  if [[ ${RESULT} == 2 ]]; then
    echo ""
    echo "ERROR: The command line option \"${C}\" is ambiguous - it matches: ${OPTION}"
    echo "       See \"$0 --help\" for a list of options"
    exit 1
  elif [[ ${RESULT} != 0 ]]; then
    echo ""
    echo "ERROR: Unknown command line option: ${C}"
    echo "       See \"$0 --help\" for a list of options"
    exit 1
  fi

  case ${OPTION} in
    check)        MODE="check";        HEASoftPATH=$(optionvalue "${C}") ;;
    get-max)      MODE="get-max" ;;
    get-min)      MODE="get-min" ;;
    good-version) MODE="good-version"; TESTVERSION=$(optionvalue "${C}") ;;
    help)         echo ""; confhelp; exit 0 ;;
  esac
done


# The allowed version range and the black list live in allowed-versions.txt
if ! readversionrange "${SETUPPATH}/allowed-versions.txt" "HEASoft" "HEASoft"; then
  exit 1
fi

case ${MODE} in

  get-max) echo "${VERSIONMAXSTRING}"; exit 0 ;;
  get-min) echo "${VERSIONMINSTRING}"; exit 0 ;;

  good-version)
    # Reject anything which is not a version, e.g. v11.2.2 or master
    if [[ ! ${TESTVERSION} =~ ^[0-9]+\.[0-9]+([./]p?[0-9]+)?$ ]]; then
      echo ""
      echo "ERROR: HEASoft version (${TESTVERSION}) is not acceptable"
      echo "       It is not a valid version string."
      exit 1
    fi

    if ! checkversionrange "${TESTVERSION}" "HEASoft"; then
      exit 1
    fi
    exit 0
    ;;

  check)
    # The given path may be the platform specific directory or the one above it, and the
    # HEASoft tools only run after headas-init.sh has been sourced
    HEADASDIR=$(heasoftdirectory "${HEASoftPATH}") || HEADASDIR=""

    if [[ ${HEADASDIR} == "" ]]; then
      echo " "
      echo "ERROR: The given directory ${HEASoftPATH} does no contain a correct HEASoft installation"
      exit 1;
    fi

    # Initialize HEASoft in a subshell, otherwise ftversion refuses to run
    rv=$(export HEADAS="${HEADASDIR}"; . "${HEADASDIR}/headas-init.sh" > /dev/null 2>&1; "${HEADASDIR}/bin/ftversion" 2>/dev/null | awk -F"V" '{ print $2 }' | sed 's/[^0-9.]*//g')
    if [[ ${rv} == "" ]]; then
      echo " "
      echo "ERROR: Unable to determine the HEASoft version in ${HEADASDIR}"
      exit 1;
    fi


    if ! checkversionrange "${rv}" "HEASoft"; then
      exit 1
    fi
    exit 0
    ;;

  *)
    echo ""
    echo "ERROR: No mode given - say what the script should do"
    confhelp
    exit 1
    ;;

esac

exit 1
