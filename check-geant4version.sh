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
CMD=""
while [[ $# -gt 0 ]] ; do
    CMD="${CMD} $1"
    shift
done

# Check for help
for C in ${CMD}; do
  if [[ ${C} == *-h* ]]; then
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
for C in ${CMD}; do
  if [[ ${C} == *-c*=* ]]; then
    GEANT4PATH=`echo ${C} | awk -F"=" '{ print $2 }'`
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
    TESTVERSION=`echo ${C} | awk -F"=" '{ print $2 }'`
  elif [[ ${C} == *-h* ]]; then
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


Geant4VersionMin=$(cat ${SETUPPATH}/allowed-versions.txt | grep "Geant4-Min" | awk -F":" '{ print $2 }')
Geant4VersionMax=$(cat ${SETUPPATH}/allowed-versions.txt | grep "Geant4-Max" | awk -F":" '{ print $2 }')

Sep=$((${#Geant4VersionMin}-1))
Geant4VersionMinString="${Geant4VersionMin:0:${Sep}}.${Geant4VersionMin:${Sep}:1}"
Sep=$((${#Geant4VersionMax}-1))
Geant4VersionMaxString="${Geant4VersionMax:0:${Sep}}.${Geant4VersionMax:${Sep}:1}"

if [ "${GET}" == "true" ]; then
  if [ "${MAX}" == "true" ]; then
    echo "${Geant4VersionMaxString}"
  else 
    echo "${Geant4VersionMinString}"
  fi
  exit 0;
fi


if [ "${GOOD}" == "true" ]; then
  version=`echo ${TESTVERSION} | awk -F. '{ print $1 }'`;
  release=`echo ${TESTVERSION} | awk -F. '{ print $2 }'`;
  Geant4Version=$((10*${version} + ${release}))
  
  if ([ ${Geant4Version} -ge ${Geant4VersionMin} ] && [ ${Geant4Version} -le ${Geant4VersionMax} ]); then
    echo "Found a good Geant4 version: ${TESTVERSION}"
    exit 0
  else
    echo ""
    echo "ERROR: Geant4 version (${TESTVERSION}) is not acceptable"
    echo "       You require a version between ${Geant4VersionMinString} and ${Geant4VersionMaxString}"
    exit 1
  fi
fi  


if [ "${CHECK}" == "true" ]; then
  if (`test -f ${GEANT4PATH}/source/global/management/include/G4Version.hh`); then
    rv=`grep -r "\#define G4VERSION_NUMBER" ${GEANT4PATH}/source/global/management/include/G4Version.hh`; 
    version=`echo $rv | awk -F" " '{ print $3 }'`;
    Geant4Version=`echo $((${version} / 10)) | awk -F"." '{ print $1 }'`
  elif [ -f ${GEANT4PATH}/bin/geant4-config ]; then
    version=`${GEANT4PATH}/bin/geant4-config --version | sed 's|\.||g'`
    Geant4Version=`echo $((${version} / 10)) | awk -F"." '{ print $1 }'`
  else
    echo " "
    echo "ERROR: The given directory ${GEANT4PATH} does no contain a correct Geant4 installation"
    exit 1;
  fi

  if ([ ${Geant4Version} -ge ${Geant4VersionMin} ] && [ ${Geant4Version} -le ${Geant4VersionMax} ]); then
    echo "The given Geant4 version is acceptable"
    exit 0;
  else
    echo ""
    echo "ERROR: No acceptable Geant4 version found: ${Geant4Version}"
    exit 1
  fi
fi

exit 1
