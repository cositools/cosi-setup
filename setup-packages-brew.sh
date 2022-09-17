#!/bin/bash

# This bash script is part of the MEGAlib & COSItools setup procedure.
# As such it is dual licenced under Apache 2.0 for COSItools and LGPL 3.0 for MEGAlib
#
# Development lead: Andreas Zoglauer
#
# Description:
# This script checks if all required brew packages are installed 

TOOLS_GENERAL="hdf5"
TOOLS_PYTHON="python@3.8 jupyterlab numpy"
TOOLS_ROOT="cmake openblas davix expat giflib git git-lfs gl2ps gmp graphviz gsl jpeg libpng libxml2 lz4 openssl@3 pcre tbb libtiff xrootd xxhash xz"
TOOLS_GEANT4="cmake pkg-config zlib xerces-c"
TOOLS_MEGALIB="doxygen imagemagick cfitsio open-mpi"

# Not working tools:
TOOLS_NOTWORKING="valgrind-macos-devel gcc11"

TOOLS_ALL=""

INSTALLED=$(brew list | awk '{print tolower($1) }')

TOBEINSTALLED=""

for TOOL in ${TOOLS_GENERAL} ${TOOLS_ROOT} ${TOOLS_GEANT4} ${TOOLS_MEGALIB} ${TOOLS_PYTHON}; do
  TOOLTOLOWER=$(echo ${TOOL} | awk '{print tolower($0)}')
  if [[ $(echo "${INSTALLED}" | grep -x ${TOOLTOLOWER}) != ${TOOLTOLOWER} ]]; then
    TOBEINSTALLED+="${TOOL} "
  fi
done

TODO=""

if [[ ${TOBEINSTALLED} != "" ]]; then
  TODO="brew install ${TOBEINSTALLED}\n"
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
echo "All required packages seem to be already installed!"
exit 0
