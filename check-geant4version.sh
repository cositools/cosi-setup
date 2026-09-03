#!/bin/bash

# This bash script is part of the MEGAlib & COSItools setup procedure.
# As such it is dual licenced under Apache 2.0 for COSItools and LGPL 3.0 for MEGAlib
#
# Development lead: Andreas Zoglauer
#
# Description:
# This script checks for allowed Geant4 versions


confhelp() {
  echo ""
  echo "Check for a correct version of Geant4"
  echo " " 
  echo "Usage: ./check-geant4.sh [options]";
  echo " "
  echo " "
  echo "Options:"
  echo "--get-max"
  echo "    Return the allowed maximal Geant4 version" 
  echo "--get-min"
  echo "    Return the allowed minimum Geant4 version" 
  echo " "
  echo "--check=[path to Geant4]"
  echo "    Check the given path if it contains a good Geant4 version." 
  echo " "
  echo "--good-version=[version string]"
  echo "    Check the given version string contains a good Geant4 version."   
  echo " "
  echo "--help or -h"
  echo "    Show this help."
  echo " "
  echo " "
}

# Store command line
CMD=( "$@" )

# Check for help
for C in "${CMD[@]}"; do
  if [[ ${C} == *-h ]] || [[ ${C} == *-hel* ]]; then
    echo ""
    confhelp
    exit 0
  fi
done

# Path to where this file is located
SETUPPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

CHECK="false"
GET="false"
GOOD="false"
GEANT4PATH=""
TESTVERSION=""

# Overwrite default options with user options:
for C in "${CMD[@]}"; do
  if [[ ${C} == *-c*=* ]]; then
    GEANT4PATH=`echo "${C}" | awk -F"=" '{ print $2 }'`
    CHECK="true"
    GET="false"
    GOOD="false"
  elif [[ ${C} == *-get-ma* ]]; then
    GEANT4PATH=""
    CHECK="false"
    GET="true"
    MAX="true"
    GOOD="false"
  elif [[ ${C} == *-get-mi* ]]; then
    GEANT4PATH=""
    CHECK="false"
    GET="true"
    MAX="false"
    GOOD="false"
  elif [[ ${C} == *-go* ]]; then
    GEANT4PATH=""
    CHECK="false"
    GET="false"
    MAX="false"
    GOOD="true"
    TESTVERSION=`echo "${C}" | awk -F"=" '{ print $2 }'`
  elif [[ ${C} == *-h ]] || [[ ${C} == *-hel* ]]; then
    echo ""
    confhelp
    exit 0
  else
    echo ""
    echo "ERROR: Unknown command line option: ${C}"
    echo "       See \"$0 --help\" for a list of options"
    exit 1
  fi
done


Geant4VersionMin=$(cat "${SETUPPATH}/allowed-versions.txt" | grep "Geant4-Min" | awk -F":" '{ print $2 }')
Geant4VersionMax=$(cat "${SETUPPATH}/allowed-versions.txt" | grep "Geant4-Max" | awk -F":" '{ print $2 }')
Geant4BlackList=$(cat "${SETUPPATH}/allowed-versions.txt" | grep "Geant4-Blacklist" | awk -F":" '{ print $2 }')

Geant4VersionMinString=${Geant4VersionMin}
Geant4VersionMaxString=${Geant4VersionMax}

if [[ ! ${Geant4VersionMinString} =~ ^[0-9]+\.[0-9]+$ ]] || [[ ! ${Geant4VersionMaxString} =~ ^[0-9]+\.[0-9]+$ ]]; then
  echo ""
  echo "ERROR: Unable to read a valid Geant4 version range from ${SETUPPATH}/allowed-versions.txt"
  exit 1
fi

Geant4VersionMin=$(echo ${Geant4VersionMinString} | awk -F. '{ print 100*$1 + $2 }')
Geant4VersionMax=$(echo ${Geant4VersionMaxString} | awk -F. '{ print 100*$1 + $2 }')

if [ "${GET}" == "true" ]; then
  if [ "${MAX}" == "true" ]; then
    echo "${Geant4VersionMaxString}"
  else 
    echo "${Geant4VersionMinString}"
  fi
  exit 0;
fi


if [ "${GOOD}" == "true" ]; then
  # Reject anything which is not a version, e.g. v11.2.2 or master
  if [[ ! ${TESTVERSION} =~ ^[0-9]+\.[0-9]+ ]]; then
    echo ""
    echo "ERROR: Geant4 version (${TESTVERSION}) is not acceptable"
    echo "       It is not a valid version string."
    exit 1
  fi

  version=`echo ${TESTVERSION} | awk -F. '{ print $1 }'`;
  release=`echo ${TESTVERSION} | awk -F. '{ print $2 }'`;
  Geant4Version=$((100*10#${version} + 10#${release}))
  
  if ([ ${Geant4Version} -ge ${Geant4VersionMin} ] && [ ${Geant4Version} -le ${Geant4VersionMax} ]); then
    if [[ " ${Geant4BlackList} " == *" ${TESTVERSION} "* ]] || [[ " ${Geant4BlackList} " == *" ${TESTVERSION%.*} "* ]]; then
      echo ""
      echo "ERROR: Geant4 version (${TESTVERSION}) is not acceptable"
      echo "       It has been black listed as not working."
      exit 1
    else
      echo "Found a good Geant4 version: ${TESTVERSION}"
      exit 0
    fi
  else
    echo ""
    echo "ERROR: Geant4 version (${TESTVERSION}) is not acceptable"
    echo "       You require a version between ${Geant4VersionMinString} and ${Geant4VersionMaxString}"
    exit 1
  fi
fi  


if [ "${CHECK}" == "true" ]; then
  if (`test -f "${GEANT4PATH}/source/global/management/include/G4Version.hh"`); then
    rv=`grep "#define G4VERSION_NUMBER" "${GEANT4PATH}/source/global/management/include/G4Version.hh"`; 
    version=`echo $rv | awk -F" " '{ print $3 }'`;
    Geant4VersionString="$((${version} / 100)).$(( (${version} / 10) % 10 )).$((${version} % 10))"
  elif [ -f "${GEANT4PATH}/bin/geant4-config" ]; then
    Geant4VersionString=`"${GEANT4PATH}/bin/geant4-config" --version`
  else
    echo " "
    echo "ERROR: The given directory ${GEANT4PATH} does no contain a correct Geant4 installation"
    exit 1;
  fi

  Geant4Version=$(echo ${Geant4VersionString} | awk -F. '{ print 100*$1 + $2 }')

  if ([ ${Geant4Version} -ge ${Geant4VersionMin} ] && [ ${Geant4Version} -le ${Geant4VersionMax} ]); then
    if [[ " ${Geant4BlackList} " == *" ${Geant4VersionString} "* ]] || [[ " ${Geant4BlackList} " == *" ${Geant4VersionString%.*} "* ]]; then
      echo ""
      echo "ERROR: Geant4 version (${Geant4VersionString}) is not acceptable"
      echo "       It has been black listed as not working."
      exit 1
    else
      echo "The given Geant4 version ${Geant4VersionString} is acceptable"
      exit 0;
    fi
  else
    echo ""
    echo "ERROR: No acceptable Geant4 version found: ${Geant4VersionString} (min: ${Geant4VersionMinString}, max: ${Geant4VersionMaxString})"
    exit 1
  fi
fi

exit 1
