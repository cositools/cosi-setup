#!/bin/bash

# This bash script is part of the COSItools.
#
# The original file is part of MEGAlib.
# Port to COSItools and license change approved by original author, Andreas Zoglauer  
#
# Development lead: Andreas Zoglauer
# License: Apache 2.0

# Description:
# This script check is all required macports packages are installed 

TOOLS_GENERAL="hdf5"
TOOLS_PYTHON="py38-gnureadline py38-jupyter py38-metakernel py38-numpy python38"
TOOLS_ROOT="cmake OpenBLAS davix expat giflib git gl2ps gmp graphviz gsl jpeg libgcc-devel libpng libxml2 lz4 lzma openssl pcre tbb tiff vdt xrootd xxhashlib xz"
TOOLS_GEANT4="cmake pkgconfig zlib"
TOOLS_MEGALIB="doxygen imagemagick cfitsio openmpi"

# Not working tools:
TOOLS_NOTWORKING="valgrind-macos-devel gcc11"

# Special for Apple M1:
if [[ $(uname) == *arwin ]] && [[ $(uname -m) == arm64 ]]; then
  TOOLS_GENERAL+=" cfitsio"
fi

TOOLS_ALL=""

INSTALLED=$(port installed | grep \(active\) | awk '{print tolower($1) }')

TOBEINSTALLED=""

for TOOL in ${TOOLS_GENERAL} ${TOOLS_ROOT} ${TOOLS_GEANT4} ${TOOLS_MEGALIB} ${TOOLS_PYTHON}; do
  TOOLTOLOWER=$(echo ${TOOL} | awk '{print tolower($0)}')
  if [[ $(echo "${INSTALLED}" | grep -x ${TOOLTOLOWER}) != ${TOOLTOLOWER} ]]; then
    TOBEINSTALLED+="${TOOL} "
  fi
done

TODO=""

if [[ ${TOBEINSTALLED} != "" ]]; then
  TODO="sudo port -N install ${TOBEINSTALLED}\n"
fi

if [[ $(port select --show python) != *python38* ]]; then
  TODO+="sudo port select --set python python38\n"
fi

if [[ $(port select --show python3) != *python38* ]]; then
  TODO+="sudo port select --set python3 python38\n"
fi

if [[ ${TODO} != "" ]]; then
  echo ""
  echo "Not all packages required for COSItools are present or correctly selected."
  echo "Please do the following:"
  echo ""
  echo -e "${TODO}"
  echo ""
  exit 1
fi
  
echo " "
echo "All required packages seem to be already installed!"
exit 0
