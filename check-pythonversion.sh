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

# Store command line
CMD=""
while [[ $# -gt 0 ]] ; do
    CMD="${CMD} $1"
    shift
done

# Check for help
for C in ${CMD}; do
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
INTERPRETER="false"
PYTHONEXE=""
TESTVERSION=""

# Overwrite default options with user options:
for C in ${CMD}; do
  if [[ ${C} == *-get-int* ]]; then
    PYTHONEXE=""
    CHECK="false"
    GET="false"
    GOOD="false"
    INTERPRETER="true"
  elif [[ ${C} == *-c*=* ]]; then
    PYTHONEXE=`echo ${C} | awk -F"=" '{ print $2 }'`
    CHECK="true"
    GET="false"
    GOOD="false"
  elif [[ ${C} == *-get-ma* ]]; then
    PYTHONEXE=""
    CHECK="false"
    GET="true"
    MAX="true"
    GOOD="false"
  elif [[ ${C} == *-get-mi* ]]; then
    PYTHONEXE=""
    CHECK="false"
    GET="true"
    MAX="false"
    GOOD="false"
  elif [[ ${C} == *-go* ]]; then
    PYTHONEXE=""
    CHECK="false"
    GET="false"
    MAX="false"
    GOOD="true"
    TESTVERSION=`echo ${C} | awk -F"=" '{ print $2 }'`
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

PythonVersionMin=$(cat ${SETUPPATH}/allowed-versions.txt | grep "Python-Min" | awk -F":" '{ print $2 }')
PythonVersionMax=$(cat ${SETUPPATH}/allowed-versions.txt | grep "Python-Max" | awk -F":" '{ print $2 }')
PythonBlackList=$(cat ${SETUPPATH}/allowed-versions.txt | grep "Python-Blacklist")

PythonVersionMinString=${PythonVersionMin}
PythonVersionMaxString=${PythonVersionMax}

PythonVersionMin=$(echo ${PythonVersionMinString} | awk -F. '{ print 100*$1 + $2 }')
PythonVersionMax=$(echo ${PythonVersionMaxString} | awk -F. '{ print 100*$1 + $2 }')

if [ "${GET}" == "true" ]; then
  if [ "${MAX}" == "true" ]; then
    echo "${PythonVersionMaxString}"
  else
    echo "${PythonVersionMinString}"
  fi
  exit 0;
fi

if [ "${GOOD}" == "true" ]; then
  # Reject development versions, e.g., 3.15.0rc1
  if [[ ! ${TESTVERSION} =~ ^[0-9]+(\.[0-9]+)*$ ]]; then
    echo ""
    echo "ERROR: python version (${TESTVERSION}) is not acceptable"
    echo "       It is a development version."
    exit 1
  fi

  version=`echo ${TESTVERSION} | awk -F. '{ print $1 }'`;
  release=`echo ${TESTVERSION} | awk -F. '{ print $2 }' | sed 's/0*//'`;
  patch=`echo ${TESTVERSION} | awk -F. '{ print $3 }'`;

  PythonVersion=$((100*${version} + ${release}))

  if ([ ${PythonVersion} -ge ${PythonVersionMin} ] && [ ${PythonVersion} -le ${PythonVersionMax} ]); then
    if [[ ${PythonBlackList} == *${PythonVersion}.${patch}* ]]; then
      echo ""
      echo "ERROR: python version (${TESTVERSION}) is not acceptable"
      echo "       It has been black listed as not working."
      exit 1
    else
      echo "Found a good python version: ${TESTVERSION}"
      exit 0
    fi
  else
    echo ""
    echo "ERROR: python version (${TESTVERSION}) is not acceptable"
    echo "       You require a version between ${PythonVersionMinString} and ${PythonVersionMaxString}"
    exit 1
  fi
fi

if [ "${INTERPRETER}" == "true" ]; then
  # Choose the python version
  PY="python3"

  # In case of OpenSUSE, choose the latest installed python version
  if [[ $(uname -s) != *arwin* ]]; then
    OSNAME=$(cat /etc/os-release | grep "^ID=" | awk -F= '{ print $2 }' | tr -d '"')
    if [[ ${OSNAME} == opensuse-leap ]]; then
      PYVERNEW=$(zypper search -i python3*-base | tail -1 | awk -F"|" '{ print $2 }' | xargs | sed 's/-base$//')
      PYVERNEW=${PYVERNEW:0:7}.${PYVERNEW:7}
      if [[ ${PYVERNEW} != "" ]]; then
        PY=${PYVERNEW}
      fi
    fi
  fi

  # Everything but the name of the interpreter goes to stderr
  ${SETUPPATH}/check-pythonversion.sh --check=${PY} >&2
  if [[ "$?" != "0" ]]; then
    exit 1
  fi

  echo ${PY}
  exit 0
fi

if [ "${CHECK}" == "true" ]; then
  if ! type ${PYTHONEXE} >/dev/null 2>&1; then
    echo " "
    echo "ERROR: The given python interpreter \"${PYTHONEXE}\" does not exist"
    exit 1;
  fi

  pv=`${PYTHONEXE} --version 2>&1 | awk '{ print $2 }'`

  # Reject development versions, e.g., 3.15.0rc1
  if [[ ! ${pv} =~ ^[0-9]+(\.[0-9]+)*$ ]]; then
    echo ""
    echo "ERROR: python version (${pv}) is not acceptable"
    echo "       It is a development version."
    exit 1
  fi

  version=`echo ${pv} | awk -F. '{ print $1 }'`;
  release=`echo ${pv} | awk -F. '{ print $2 }' | sed 's/0*//'`;
  patch=`echo ${pv} | awk -F. '{ print $3 }'`;
  PythonVersion=$((100*${version} + ${release}))

  if ([ ${PythonVersion} -ge ${PythonVersionMin} ] && [ ${PythonVersion} -le ${PythonVersionMax} ]); then
    if [[ ${PythonBlackList} == *${PythonVersion}.${patch}* ]]; then
      echo ""
      echo "ERROR: python version (${pv}) is not acceptable"
      echo "       It has been black listed as not working."
      exit 1
    else
      echo "Found a good python version: ${pv}"
      exit 0
    fi
  else
    echo ""
    echo "ERROR: python version (${pv}) is not acceptable"
    echo "       You require a version between ${PythonVersionMinString} and ${PythonVersionMaxString}"
    exit 1
  fi
fi

exit 1
