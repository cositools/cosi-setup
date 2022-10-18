#!/bin/bash

# This bash script is part of the MEGAlib & COSItools setup procedure.
# As such it is dual licenced under Apache 2.0 for COSItools and LGPL 3.0 for MEGAlib
#
# Development lead: Andreas Zoglauer
#
# Description:
# This script checks if all required macports packages are installed 



TOOLS_GENERAL="hdf5"
TOOLS_PYTHON="python38 py38-gnureadline py38-jupyter py38-metakernel py38-numpy"
TOOLS_ROOT="cmake git git-lfs OpenBLAS davix expat giflib git gl2ps gmp graphviz gsl jpeg libpng libxml2 lz4 lzma openssl pcre tbb tiff vdt xrootd xxhashlib xz"
TOOLS_GEANT4="cmake pkgconfig zlib xercesc3"
TOOLS_MEGALIB="git doxygen imagemagick cfitsio healpix"
TOOLS_GCC="gcc11" # must be single gcc version, don't add anything

# Not working tools:
TOOLS_NOTWORKING="valgrind-macos-devel"

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

TODO=""

if [[ ${TOBEINSTALLED} != "" ]]; then
  TODO="sudo port -N install ${TOBEINSTALLED}\n"
fi

if [[ $(port select --show python 2> /dev/null) != *python38* ]]; then
  TODO+="sudo port select --set python python38\n"
fi

if [[ $(port select --show python3 2> /dev/null) != *python38* ]]; then
  TODO+="sudo port select --set python3 python38\n"
fi

if [[ $(port select --show gcc 2> /dev/null) != *${TOOLS_GCC}* ]]; then
  GCC=$(port select --list gcc | grep -v version | grep -v none | grep ${TOOLS_GCC} | sort | head -n 1 | xargs)
  if [[ ${GCC} != "" ]]; then
    TODO+="sudo port select --set gcc ${GCC}\n"
  fi
fi  

if [[ ${TODO} != "" ]]; then
  echo ""
  echo "Not all required packages are present or correctly selected."
  echo "Please do the following:"
  echo ""
  echo -e "${TODO}"
  echo ""
  exit 1
fi
  
echo " "
echo "All required macports packages seem to be already installed!"
exit 0
