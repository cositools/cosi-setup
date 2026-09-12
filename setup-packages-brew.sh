#!/bin/bash

# This bash script is part of the MEGAlib & COSItools setup procedure.
# As such it is dual licenced under Apache 2.0 for COSItools and LGPL 3.0 for MEGAlib
#
# Development lead: Andreas Zoglauer
#
# Description:
# This script checks if all required brew packages are installed

MAIN_PYTHON_VERSION="python@3.12"

# Path to where this file is located
SETUPPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

# The shared helper functions, e.g. resolveoption
. "${SETUPPATH}/setup-helpers.sh"

# Every option this script accepts. Abbreviations are resolved against this list.
SETUPOPTIONS="autoinstall python-path help"

# Automatically install additional packages
AUTOPACKAGEINSTALL=false

confhelp() {
  echo ""
  echo "This script checks whether all packages required by the COSItools via homebrew are installed."
  echo " "
  echo "Usage: ./setup-packages-brew.sh [options]";
  echo " "
  echo " "
  echo "Options:"
  echo " "
  echo "--autoinstall[=false/off/no, true/on/yes - default: false]"
  echo "    Install the missing packages instead of only listing them."
  echo "    This is only intended for automatic build tests."
  echo " "
  echo "--python-path"
  echo "    Only print the path to the python version used by the COSItools and exit."
  echo " "
  echo "--help or -h"
  echo "    Show this help."
  echo " "
  echo " "
}

# The command line
CMD=( "$@" )

for C in "${CMD[@]}"; do
  # "|| RESULT=$?" so that a non-zero return does not trip a "set -e"
  RESULT=0
  OPTION=$(resolveoption "${C}" "${SETUPOPTIONS}") || RESULT=$?
  if [[ ${RESULT} == 2 ]]; then
    echo ""
    echo "ERROR: The command line option \"${C}\" is ambiguous - it matches: ${OPTION}"
    echo "       See \"./setup-packages-brew.sh --help\" for a list of options"
    exit 1
  elif [[ ${RESULT} != 0 ]]; then
    echo ""
    echo "ERROR: Unknown command line option: ${C}"
    echo "       See \"./setup-packages-brew.sh --help\" for a list of options"
    exit 1
  fi

  case ${OPTION} in
    autoinstall)
      if ! AUTOPACKAGEINSTALL=$(booleanvalue "$(optionvalue "${C}")"); then
        echo ""
        echo "ERROR: Unknown value for the --autoinstall option: ${C}"
        echo "       Use true/on/yes or false/off/no, or give the option without a value"
        exit 1
      fi
      ;;
    python-path)
      echo "$(brew --prefix)/opt/${MAIN_PYTHON_VERSION}/libexec/bin"
      exit 0
      ;;
    help)
      echo ""
      confhelp
      exit 0
      ;;
  esac
done

# The automatic package installation is only intended for automatic build tests inside a VM, switch it off anywhere else
if [[ ${AUTOPACKAGEINSTALL} == true ]]; then
  if [[ $(sysctl -n kern.hv_vmm_present 2>/dev/null) != 1 ]]; then
    echo " "
    echo "WARNING: The automatic package installation is only intended for automatic build tests inside a VM."
    echo "         Switching it off - any missing packages along with installation instructions will be listed below."
    echo " "
    AUTOPACKAGEINSTALL="false"
  fi
fi

TOOLS_GENERAL="hdf5 curl"
TOOLS_PYTHON="${MAIN_PYTHON_VERSION} jupyterlab numpy"
TOOLS_ROOT="cmake openblas davix expat giflib git git-lfs gl2ps gmp graphviz gsl jpeg libpng libxml2 lz4 openssl@3 pcre tbb libtiff xrootd xxhash xz"
TOOLS_GEANT4="cmake zlib xerces-c qt@5"
TOOLS_MEGALIB="doxygen imagemagick cfitsio ccfits healpix open-mpi"

# Not working tools:
TOOLS_NOTWORKING="valgrind-macos-devel gcc11"

TOOLS_ALL=""

INSTALLED=$(brew list | awk '{print tolower($1) }')

TOBEINSTALLED=""

# Check which tools need to be installed
for TOOL in ${TOOLS_GENERAL} ${TOOLS_ROOT} ${TOOLS_GEANT4} ${TOOLS_MEGALIB} ${TOOLS_PYTHON}; do
  TOOLTOLOWER=$(echo ${TOOL} | awk '{print tolower($0)}')
  if [[ $(echo "${INSTALLED}" | grep -x ${TOOLTOLOWER}) != ${TOOLTOLOWER} ]]; then
    TOBEINSTALLED+="${TOOL} "
  fi
done

# There is an idiocracy regarding pkg-conf / pkgconf
if [[ "${INSTALLED}" != *pkg-conf* ]] && [[ "${INSTALLED}" != *pkgconf* ]]; then
  TOBEINSTALLED+="pkgconf "
fi 

TODO=""
LINK=""
if [[ ${TOBEINSTALLED} != "" ]]; then
  TODO="brew install ${TOBEINSTALLED}"
  if [[ ${TOBEINSTALLED} == *${MAIN_PYTHON_VERSION}* ]]; then
    LINK="brew link --force ${MAIN_PYTHON_VERSION}"
  fi
fi

if [[ ${TODO} != "" ]]; then
  if [[ ${AUTOPACKAGEINSTALL} == true ]]; then
    echo " "
    echo "Performing an automatic installation of the packages. I will do the following:"
    echo "${TODO}"
    if [[ ${LINK} != "" ]]; then
      echo "${LINK}"
    fi
    echo " "
    if ! bash -e -c "${TODO}"; then
      echo " "
      echo "ERROR: Something went wrong with the automatic package installation."
      exit 255
    fi
    if [[ ${LINK} != "" ]] && ! bash -e -c "${LINK}"; then
      echo " "
      echo "ERROR: Something went wrong with the automatic package installation."
      exit 255
    fi
    echo " "
    echo "All required packages seem to be installed now!"
    exit 0
  else
    echo ""
    echo "Not all required packages are present or correctly selected."
    echo "Please do the following:"
    echo ""
    echo "${TODO}"
    if [[ ${LINK} != "" ]]; then
      echo "${LINK}"
    fi
    echo ""
    exit 255
  fi
fi

echo " "
echo "All required homebrew packages seem to be already installed!"
exit 0
