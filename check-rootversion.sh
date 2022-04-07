#!/bin/bash

# This bash file is part of the COSItools.
#
# The original file is part of MEGAlib.
# Port to COSItools and license change approved by original author, Andreas Zoglauer  
#
# Development lead: Andreas Zoglauer
# License: Apache 2.0

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
ROOTPATH=""
TESTVERSION=""

# Overwrite default options with user options:
for C in ${CMD}; do
  if [[ ${C} == *-c*=* ]]; then
    ROOTPATH=`echo ${C} | awk -F"=" '{ print $2 }'`
    CHECK="true"
    GET="false"
    GOOD="false"
  elif [[ ${C} == *-get-ma* ]]; then
    ROOTPATH=""
    CHECK="false"
    GET="true"
    MAX="true"
    GOOD="false"
  elif [[ ${C} == *-get-mi* ]]; then
    ROOTPATH=""
    CHECK="false"
    GET="true"
    MAX="false"
    GOOD="false"
  elif [[ ${C} == *-go* ]]; then
    ROOTPATH=""
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

RootVersionMin=$(cat ${SETUPPATH}/allowed-versions.txt | grep "ROOT-Min" | awk -F":" '{ print $2 }')
RootVersionMax=$(cat ${SETUPPATH}/allowed-versions.txt | grep "ROOT-Max" | awk -F":" '{ print $2 }')

RootVersionMinString="${RootVersionMin:(-3):1}.${RootVersionMin:(-2):2}"
RootVersionMaxString="${RootVersionMax:(-3):1}.${RootVersionMax:(-2):2}"

if [ "${GET}" == "true" ]; then
  if [ "${MAX}" == "true" ]; then
    echo "${RootVersionMaxString}"
  else 
    echo "${RootVersionMinString}"
  fi
  exit 0;
fi

if [ "${GOOD}" == "true" ]; then
  version=`echo ${TESTVERSION} | awk -F. '{ print $1 }'`;
  release=`echo ${TESTVERSION} | awk -F/ '{ print $1 }' | awk -F. '{ print $2 }'| sed 's/0*//'`;
  RootVersion=$((100*${version} + ${release}))
  
  if ([ ${RootVersion} -ge ${RootVersionMin} ] && [ ${RootVersion} -le ${RootVersionMax} ]); then
    echo "Found a good ROOT version: ${TESTVERSION}"
    exit 0
  else
    echo ""
    echo "ERROR: ROOT version (${TESTVERSION}) is not acceptable"
    echo "       You require a version between ${RootVersionMinString} and ${RootVersionMaxString}"
    exit 1
  fi
fi  

if [ "${CHECK}" == "true" ]; then
  if [ ! -f ${ROOTPATH}/bin/root-config ]; then
    echo " "
    echo "ERROR: The given directory ${ROOTPATH} does no contain a correct ROOT installation"
    exit 1;
  fi

  rv=`${ROOTPATH}/bin/root-config --version`
  version=`echo $rv | awk -F. '{ print $1 }'`;
  release=`echo $rv | awk -F/ '{ print $1 }' | awk -F. '{ print $2 }'| sed 's/0*//'`;
  patch=`echo $rv | awk -F/ '{ print $2 }'| sed 's/0*//'`;
  RootVersion=$((100*${version} + ${release}))

  if ([ ${RootVersion} -ge ${RootVersionMin} ] && [ ${RootVersion} -le ${RootVersionMax} ]); then
    echo "The given ROOT version is acceptable."
    exit 0
  else
    echo ""
    echo "ERROR: No acceptable ROOT version found: ${RootVersion}"
    exit 1
  fi
fi

exit 1
