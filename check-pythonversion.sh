#!/bin/bash

# This bash script is part of the MEGAlib & COSItools setup procedure.
# As such it is dual licenced under Apache 2.0 for COSItools and LGPL 3.0 for MEGAlib
#
# Development lead: Andreas Zoglauer
#
# Description:
# This script checks for allowed python versions


# Allowed versions

confhelp() {
  echo ""
  echo "Check for a correct version of python"
  echo " "
  echo "Usage: ./check-pythonversion.sh [options]";
  echo " "
  echo " "
  echo "Options:"
  echo "--get-max"
  echo "    Return the allowed maximal python version"
  echo "--get-min"
  echo "    Return the allowed minimum python version"
  echo " "
  echo "--get-interpreter"
  echo "    Return the python interpreter to be used, and verify that its version is allowed."
  echo "    The name of the interpreter is written to stdout, everything else to stderr."
  echo " "
  echo "--check=[python interpreter]"
  echo "    Check if the given python interpreter has a good version."
  echo " "
  echo "--good-version=[version string]"
  echo "    Check the given version string contains a good python version."
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
SETUPOPTIONS="check get-interpreter get-max get-min good-version help"

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


# What the script was asked to do: check, get-max, get-min, good-version or
# get-interpreter. One variable rather than a flag each, so that a mode can never be
# half set and no mode can stay on when a later option names another one.
MODE=""
PYTHONEXE=""
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
    get-interpreter) MODE="get-interpreter" ;;
    check)           MODE="check";        PYTHONEXE=$(optionvalue "${C}") ;;
    get-max)         MODE="get-max" ;;
    get-min)         MODE="get-min" ;;
    good-version)    MODE="good-version"; TESTVERSION=$(optionvalue "${C}") ;;
    help)            echo ""; confhelp; exit 0 ;;
  esac
done

# The allowed version range and the black list live in allowed-versions.txt
if ! readversionrange "${SETUPPATH}/allowed-versions.txt" "Python" "python"; then
  exit 1
fi

case ${MODE} in

  get-max) echo "${VERSIONMAXSTRING}"; exit 0 ;;
  get-min) echo "${VERSIONMINSTRING}"; exit 0 ;;

  good-version)
    # Reject development versions, e.g., 3.15.0rc1
    if [[ ! ${TESTVERSION} =~ ^[0-9]+(\.[0-9]+)*$ ]]; then
      echo ""
      echo "ERROR: python version (${TESTVERSION}) is not acceptable"
      echo "       It is a development version."
      exit 1
    fi

    # Reject anything which is not a version, e.g. v11.2.2 or master
    if [[ ! ${TESTVERSION} =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ ]]; then
      echo ""
      echo "ERROR: python version (${TESTVERSION}) is not acceptable"
      echo "       It is not a valid version string."
      exit 1
    fi

    if ! checkversionrange "${TESTVERSION}" "python"; then
      exit 1
    fi
    exit 0
    ;;

  get-interpreter)
    # Choose the python version
    PY="python3"

    # Everything but the name of the interpreter goes to stderr
    "${SETUPPATH}/check-pythonversion.sh" "--check=${PY}" >&2
    if [[ "$?" != "0" ]]; then
      exit 1
    fi

    echo ${PY}
    exit 0
    ;;

  check)
    if ! type "${PYTHONEXE}" >/dev/null 2>&1; then
      echo " "
      echo "ERROR: The given python interpreter \"${PYTHONEXE}\" does not exist"
      exit 1;
    fi

    pv=`"${PYTHONEXE}" --version 2>&1 | awk '{ print $2 }'`

    # Reject development versions, e.g., 3.15.0rc1
    if [[ ! ${pv} =~ ^[0-9]+(\.[0-9]+)*$ ]]; then
      echo ""
      echo "ERROR: python version (${pv}) is not acceptable"
      echo "       It is a development version."
      exit 1
    fi

    if ! checkversionrange "${pv}" "python"; then
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
