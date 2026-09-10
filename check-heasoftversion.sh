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

CHECK="false"
GET="false"
GOOD="false"
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
    check)        HEASoftPATH=$(optionvalue "${C}"); CHECK="true";  GET="false"; GOOD="false" ;;
    get-max)      HEASoftPATH="";                                        CHECK="false"; GET="true";  MAX="true";  GOOD="false" ;;
    get-min)      HEASoftPATH="";                                        CHECK="false"; GET="true";  MAX="false"; GOOD="false" ;;
    good-version) HEASoftPATH="";                                        CHECK="false"; GET="false"; MAX="false"; GOOD="true"
                  TESTVERSION=$(optionvalue "${C}") ;;
    help)         echo ""; confhelp; exit 0 ;;
  esac
done


HEASoftVersionMin=$(cat "${SETUPPATH}/allowed-versions.txt" | grep "HEASoft-Min" | awk -F":" '{ print $2 }')
HEASoftVersionMax=$(cat "${SETUPPATH}/allowed-versions.txt" | grep "HEASoft-Max" | awk -F":" '{ print $2 }')
HEASoftBlackList=$(cat "${SETUPPATH}/allowed-versions.txt" | grep "HEASoft-Blacklist" | awk -F":" '{ print $2 }')

HEASoftVersionMinString=${HEASoftVersionMin}
HEASoftVersionMaxString=${HEASoftVersionMax}

if [[ ! ${HEASoftVersionMinString} =~ ^[0-9]+\.[0-9]+$ ]] || [[ ! ${HEASoftVersionMaxString} =~ ^[0-9]+\.[0-9]+$ ]]; then
  echo ""
  echo "ERROR: Unable to read a valid HEASoft version range from ${SETUPPATH}/allowed-versions.txt"
  exit 1
fi

HEASoftVersionMin=$(echo ${HEASoftVersionMinString} | awk -F. '{ print 100*$1 + $2 }')
HEASoftVersionMax=$(echo ${HEASoftVersionMaxString} | awk -F. '{ print 100*$1 + $2 }')

if [ "${GET}" == "true" ]; then
  if [ "${MAX}" == "true" ]; then
    echo "${HEASoftVersionMaxString}"
  else 
    echo "${HEASoftVersionMinString}"
  fi
  exit 0;
fi


if [ "${GOOD}" == "true" ]; then
  # Reject anything which is not a version, e.g. v11.2.2 or master
  if [[ ! ${TESTVERSION} =~ ^[0-9]+\.[0-9]+([./]p?[0-9]+)?$ ]]; then
    echo ""
    echo "ERROR: HEASoft version (${TESTVERSION}) is not acceptable"
    echo "       It is not a valid version string."
    exit 1
  fi

  version=`echo ${TESTVERSION} | awk -F. '{ print $1 }'`;
  release=`echo ${TESTVERSION} | awk -F. '{ print $2 }'`;
  HEASoftVersion=$((100*10#${version} + 10#${release}))
  
  if ([ ${HEASoftVersion} -ge ${HEASoftVersionMin} ] && [ ${HEASoftVersion} -le ${HEASoftVersionMax} ]); then
    if [[ " ${HEASoftBlackList} " == *" ${TESTVERSION} "* ]] || [[ " ${HEASoftBlackList} " == *" ${TESTVERSION%.*} "* ]]; then
      echo ""
      echo "ERROR: HEASoft version (${TESTVERSION}) is not acceptable"
      echo "       It has been black listed as not working."
      exit 1
    else
      echo "Found a good HEASoft version: ${TESTVERSION}"
      exit 0
    fi
  else
    echo ""
    echo "ERROR: HEASoft version (${TESTVERSION}) is not acceptable"
    echo "       You require a version between ${HEASoftVersionMinString} and ${HEASoftVersionMaxString}"
    exit 1
  fi
fi  

if [ "${CHECK}" == "true" ]; then
  # HEASoft installs its binaries into a platform specific sub-directory, e.g.
  # x86_64-pc-linux-gnu-libc2.44, and its tools only run after headas-init.sh has been
  # sourced. Thus accept the platform directory as well as the one above it, and require
  # both files so that the build directory is not mistaken for the installation.
  HEADASDIR=""
  for DIR in "${HEASoftPATH}" "${HEASoftPATH}"/*; do
    if [[ -f "${DIR}/headas-init.sh" ]] && [[ -x "${DIR}/bin/ftversion" ]]; then
      HEADASDIR="${DIR}"
      break
    fi
  done

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

  version=`echo ${rv} | awk -F. '{ print $1 }'`;
  release=`echo ${rv} | awk -F. '{ print $2 }'`;
  HEASoftVersion=$((100*10#${version} + 10#${release}))

  if ([ ${HEASoftVersion} -ge ${HEASoftVersionMin} ] && [ ${HEASoftVersion} -le ${HEASoftVersionMax} ]); then
    if [[ " ${HEASoftBlackList} " == *" ${rv} "* ]] || [[ " ${HEASoftBlackList} " == *" ${rv%.*} "* ]]; then
      echo ""
      echo "ERROR: HEASoft version (${rv}) is not acceptable"
      echo "       It has been black listed as not working."
      exit 1
    else
      echo "The given HEASoft version ${rv} is acceptable"
      exit 0;
    fi
  else
    echo ""
    echo "ERROR: No acceptable HEASoft version found: ${HEASoftVersion} (min: ${HEASoftVersionMinString}, max: ${HEASoftVersionMaxString})"
    exit 1
  fi
fi

exit 1
