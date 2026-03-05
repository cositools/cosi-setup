#!/bin/bash

# This bash script is part of the MEGAlib & COSItools setup procedure.
# As such it is dual licenced under Apache 2.0 for COSItools and LGPL 3.0 for MEGAlib
#
# Development lead: Andreas Zoglauer
#
# Description:
# This script checks for allowed Healpix versions


confhelp() {
  echo ""
  echo "Check for a correct version of Healpix"
  echo " " 
  echo "Usage: ./check-Healpix.sh [options]";
  echo " "
  echo " "
  echo "Options:"
  echo "--get-max"
  echo "    Return the allowed maximum Healpix version" 
  echo "--get-min"
  echo "    Return the allowed minimum Healpix version" 
  echo " "
  echo "--check=[path to Healpix]"
  echo "    Check the given path if it contains a good Healpix version." 
  echo " "
  echo "--good-version=[version string]"
  echo "    Check the given version string contains a good Healpix version."   
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
HEALPIXPATH=""
TESTVERSION=""

# Overwrite default options with user options:
for C in ${CMD}; do
  if [[ ${C} == *-c*=* ]]; then
    HEALPIXPATH=`echo ${C} | awk -F"=" '{ print $2 }'`
    CHECK="true"
    GET="false"
    GOOD="false"
  elif [[ ${C} == *-get-ma* ]]; then
    HEALPIXPATH=""
    CHECK="false"
    GET="true"
    MAX="true"
    GOOD="false"
  elif [[ ${C} == *-get-mi* ]]; then
    HEALPIXPATH=""
    CHECK="false"
    GET="true"
    MAX="false"
    GOOD="false"
  elif [[ ${C} == *-go* ]]; then
    HEALPIXPATH=""
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


HealpixVersionMin=$(cat ${SETUPPATH}/allowed-versions.txt | grep "Healpix-Min" | awk -F":" '{ print $2 }')
HealpixVersionMax=$(cat ${SETUPPATH}/allowed-versions.txt | grep "Healpix-Max" | awk -F":" '{ print $2 }')



VERSIONS=`cat ${MEGALIB}/config/AllowedHealpixVersions.txt` 
HealpixVersionMin=`echo ${VERSIONS} | awk -F" " '{ print $1 }'`
HealpixVersionMax=`echo ${VERSIONS} | awk -F" " '{ print $NF }'`

HealpixVersionMinString="${HealpixVersionMin:(-3):1}.${HealpixVersionMin:(-2):2}"
HealpixVersionMaxString="${HealpixVersionMax:(-3):1}.${HealpixVersionMax:(-2):2}"

if [ "${GET}" == "true" ]; then
  if [ "${MAX}" == "true" ]; then
    echo "${HealpixVersionMaxString}"
  else 
    echo "${HealpixVersionMinString}"
  fi
  exit 0;
fi


if [ "${GOOD}" == "true" ]; then
  version=`echo ${TESTVERSION} | awk -F. '{ print $1 }'`;
  release=`echo ${TESTVERSION} | awk -F. '{ print $2 }'`;
  HealpixVersion=$((100*${version} + ${release}))
  
  if ([ ${HealpixVersion} -ge ${HealpixVersionMin} ] && [ ${HealpixVersion} -le ${HealpixVersionMax} ]); then
    echo "Found a good Healpix version: ${TESTVERSION}"
    exit 0
  else
    echo ""
    echo "ERROR: Healpix version (${TESTVERSION}) is not acceptable"
    echo "       You require a version between ${HealpixVersionMinString} and ${HealpixVersionMaxString}"
    exit 1
  fi
fi  

if [ "${CHECK}" == "true" ]; then
  if (`test -f ${HEALPIXPATH}/bin/ftversion`); then
    rv=$(${HEALPIXPATH}/bin/ftversion | awk -F"V" '{ print $2 }'  | sed 's/[^0-9.]*//g'); 
    version=`echo ${rv} | awk -F. '{ print $1 }'`;
    release=`echo ${rv} | awk -F. '{ print $2 }'`;
    HealpixVersion=$((100*${version} + ${release}))
  else
    echo " "
    echo "ERROR: The given directory ${HEALPIXPATH} does no contain a correct Healpix installation"
    exit 1;
  fi

  if ([ ${HealpixVersion} -ge ${HealpixVersionMin} ] && [ ${HealpixVersion} -le ${HealpixVersionMax} ]); then
    echo "The given Healpix version ${rv} is acceptable"
    exit 0;
  else
    echo ""
    echo "ERROR: No acceptable Healpix version found: ${HealpixVersion} (min: ${HealpixVersionMinString}, max: ${HealpixVersionMaxString})"
    exit 1
  fi
fi

exit 1
