#!/bin/bash

# This bash script is part of the MEGAlib & COSItools setup procedure.
# As such it is dual licenced under Apache 2.0 for COSItools and LGPL 3.0 for MEGAlib
#
# Development lead: Andreas Zoglauer
#
# Description:
# This script checks if all required macports packages are installed 

PVER="312"

TOOLS_GENERAL="hdf5 curl"
TOOLS_PYTHON="python${PVER} py${PVER}-gnureadline py${PVER}-jupyter py${PVER}-metakernel py${PVER}-numpy"
TOOLS_ROOT="cmake git git-lfs OpenBLAS davix expat giflib git gl2ps gmp graphviz gsl jpeg libpng libxml2 lz4 lzma openssl pcre tbb tiff vdt xrootd xxhashlib xz"
TOOLS_GEANT4="cmake pkgconfig zlib xercesc3"
TOOLS_MEGALIB="git doxygen imagemagick cfitsio healpix"
TOOLS_GCC="gcc12" # must be single gcc version, don't add anything

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

TODO=""

if [[ ${TOBEINSTALLED} != "" ]]; then
  TODO+="port -N install ${TOBEINSTALLED}; "
fi

if [[ $(port select --show python 2> /dev/null) != *python${PVER}* ]]; then
  TODO+="port select --set python python${PVER}; "
fi

if [[ $(port select --show python3 2> /dev/null) != *python${PVER}* ]]; then
  TODO+="port select --set python3 python${PVER}; "
fi

if [[ $(port select --show gcc 2> /dev/null) != *${TOOLS_GCC}* ]]; then
  GCC=$(port select --list gcc | grep -v version | grep -v none | grep ${TOOLS_GCC} | sort | head -n 1 | xargs)
  if [[ ${GCC} != "" ]]; then
    TODO+="port select --set gcc ${GCC}; "
  fi
fi  

if [[ ${TODO} != "" ]]; then
  TODO="sudo -- sh -c '${TODO}'"
  echo ""
  echo "Not all required packages are present or correctly selected."
  echo "Please do the following:"
  echo ""
  echo -e "${TODO}"
  echo ""
  exit 255
fi
  
echo " "
echo "All required macports packages seem to be already installed!"
exit 0
