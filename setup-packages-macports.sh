#!/bin/bash

# This bash script is part of the MEGAlib & COSItools setup procedure.
# As such it is dual licenced under Apache 2.0 for COSItools and LGPL 3.0 for MEGAlib
#
# Development lead: Andreas Zoglauer
#
# Description:
# This script checks if all required macports packages are installed 

PVER="312"

# Path to where this file is located
SETUPPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

# The shared helper functions, e.g. resolveoption
. "${SETUPPATH}/setup-helpers.sh"

# Every option this script accepts. Abbreviations are resolved against this list.
SETUPOPTIONS="autoinstall help"

# Automatically install additional packages
AUTOPACKAGEINSTALL=false

confhelp() {
  echo ""
  echo "This script checks whether all packages required by the COSItools via macports are installed."
  echo " "
  echo "Usage: ./setup-packages-macports.sh [options]";
  echo " "
  echo " "
  echo "Options:"
  echo " "
  echo "--autoinstall[=false/off/no, true/on/yes - default: false]"
  echo "    Install the missing packages instead of only listing them."
  echo "    This is only intended for automatic build tests."
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
    echo "       See \"./setup-packages-macports.sh --help\" for a list of options"
    exit 1
  elif [[ ${RESULT} != 0 ]]; then
    echo ""
    echo "ERROR: Unknown command line option: ${C}"
    echo "       See \"./setup-packages-macports.sh --help\" for a list of options"
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
TOOLS_PYTHON="python${PVER} py${PVER}-gnureadline py${PVER}-jupyter py${PVER}-metakernel py${PVER}-numpy"
TOOLS_ROOT="cmake git git-lfs OpenBLAS davix expat giflib git gl2ps gmp graphviz gsl jpeg libpng libxml2 lz4 lzma openssl pcre tbb tiff vdt xrootd xxhashlib xz"
TOOLS_GEANT4="cmake pkgconfig zlib xercesc3 qt5"
TOOLS_MEGALIB="git doxygen imagemagick cfitsio healpix"
TOOLS_GCC="gcc14" # must be single gcc version, don't add anything

# Not working tools:
TOOLS_NOTWORKING="valgrind-macos-devel gcc11"

TOOLS_ALL=""

INSTALLED=$(port installed | grep \(active\) | awk '{print tolower($1) }')

TOBEINSTALLED=""

# Check which tools need to be installed
for TOOL in ${TOOLS_GENERAL} ${TOOLS_PYTHON} ${TOOLS_ROOT} ${TOOLS_GEANT4} ${TOOLS_MEGALIB} ${TOOLS_GCC}; do
  TOOLTOLOWER=$(echo ${TOOL} | awk '{print tolower($0)}')
  if [[ $(echo "${INSTALLED}" | grep -x ${TOOLTOLOWER}) != ${TOOLTOLOWER} ]]; then
    TOBEINSTALLED+="${TOOL} "
  fi
done

STATEMENTS=()

if [[ ${TOBEINSTALLED} != "" ]]; then
  STATEMENTS+=("port -N install ${TOBEINSTALLED}")
fi

if [[ $(port select --show python 2> /dev/null) != *python${PVER}* ]]; then
  STATEMENTS+=("port select --set python python${PVER}")
fi

if [[ $(port select --show python3 2> /dev/null) != *python${PVER}* ]]; then
  STATEMENTS+=("port select --set python3 python${PVER}")
fi

if [[ $(port select --show gcc 2> /dev/null) != *${TOOLS_GCC}* ]]; then
  GCC=$(port select --list gcc | grep -v version | grep -v none | grep ${TOOLS_GCC} | sort | head -n 1 | xargs)
  if [[ ${GCC} != "" ]]; then
    STATEMENTS+=("port select --set gcc ${GCC}")
  fi
fi

if [[ ${#STATEMENTS[@]} -gt 0 ]]; then
  if [[ ${AUTOPACKAGEINSTALL} == true ]]; then
    echo " "
    echo "Performing an automatic installation of the packages. I will do the following:"
    for S in "${STATEMENTS[@]}"; do
      echo "sudo -- sh -c '${S}'"
    done
    echo " "
    for S in "${STATEMENTS[@]}"; do
      if ! sudo -- sh -c "${S}"; then
        echo " "
        echo "ERROR: Something went wrong with the automatic package installation."
        exit 255
      fi
    done
    echo " "
    echo "All required packages seem to be installed now!"
    exit 0
  else
    echo ""
    echo "Not all required packages are present or correctly selected."
    echo "Please do the following:"
    echo ""
    for S in "${STATEMENTS[@]}"; do
      echo "sudo -- sh -c '${S}'"
    done
    echo ""
    exit 255
  fi
fi
  
echo " "
echo "All required macports packages seem to be already installed!"
exit 0
