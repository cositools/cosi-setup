#!/bin/bash

# This bash script is part of the MEGAlib & COSItools setup procedure.
# As such it is dual licenced under Apache 2.0 for COSItools and LGPL 3.0 for MEGAlib
#
# Development lead: Andreas Zoglauer
#
# Description:
# This script checks for allowed ROOT versions


# Allowed versions

confhelp() {
  echo ""
  echo "Check for a correct version of ROOT"
  echo " " 
  echo "Usage: ./check-root.sh [options]";
  echo " "
  echo " "
  echo "Options:"
  echo "--get-max"
  echo "    Return the allowed maximal ROOT version" 
  echo "--get-min"
  echo "    Return the allowed minimum ROOT version" 
  echo " "
  echo "--check=[path to ROOT]"
  echo "    Check the given path if it contains a good ROOT version." 
  echo " "
  echo "--good-version=[version string]"
  echo "    Check the given version string contains a good ROOT version."   
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
ROOTPATH=""
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
    check)        MODE="check";        ROOTPATH=$(optionvalue "${C}") ;;
    get-max)      MODE="get-max" ;;
    get-min)      MODE="get-min" ;;
    good-version) MODE="good-version"; TESTVERSION=$(optionvalue "${C}") ;;
    help)         echo ""; confhelp; exit 0 ;;
  esac
done

if ! readversionrange "${SETUPPATH}/allowed-versions.txt" "ROOT" "ROOT"; then
  exit 1
fi

case ${MODE} in

  get-max) echo "${VERSIONMAXSTRING}"; exit 0 ;;
  get-min) echo "${VERSIONMINSTRING}"; exit 0 ;;

  good-version)
    # Reject anything which is not a version, e.g. v11.2.2 or master
    if [[ ! ${TESTVERSION} =~ ^[0-9]+\.[0-9]+([./]p?[0-9]+)?$ ]]; then
      echo ""
      echo "ERROR: ROOT version (${TESTVERSION}) is not acceptable"
      echo "       It is not a valid version string."
      exit 1
    fi

    if ! checkversionrange "${TESTVERSION}" "ROOT"; then
      exit 1
    fi
    exit 0
    ;;

  check)
    if [ ! -f "${ROOTPATH}/bin/root-config" ]; then
      echo " "
      echo "ERROR: The given directory ${ROOTPATH} does no contain a correct ROOT installation"
      exit 1;
    fi

    rv=$("${ROOTPATH}/bin/root-config" --version)

    if ! checkversionrange "${rv}" "ROOT"; then
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
