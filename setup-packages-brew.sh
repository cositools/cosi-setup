#!/bin/bash

# This bash script is part of the MEGAlib & COSItools setup procedure.
# As such it is dual licenced under Apache 2.0 for COSItools and LGPL 3.0 for MEGAlib
#
# Development lead: Andreas Zoglauer
#
# Description:
# This script checks if all required brew packages are installed 

MAIN_PYTHON_VERSION="python@3.12"

if [[ $1 == "--python-path" ]]; then
  echo "$(brew --prefix)/opt/${MAIN_PYTHON_VERSION}/libexec/bin"
  exit 0
fi

TOOLS_GENERAL="hdf5 curl"
TOOLS_PYTHON="${MAIN_PYTHON_VERSION} jupyterlab numpy"
TOOLS_ROOT="cmake openblas davix expat giflib git git-lfs gl2ps gmp graphviz gsl jpeg libpng libxml2 lz4 openssl@3 pcre tbb libtiff xrootd xxhash xz"
TOOLS_GEANT4="cmake zlib xerces-c"
TOOLS_MEGALIB="doxygen imagemagick cfitsio healpix open-mpi"

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

if [[ ${TOBEINSTALLED} != "" ]]; then
  TODO="brew install ${TOBEINSTALLED}"
  if [[ ${TOBEINSTALLED} == *python3* ]]; then
    TODO+="; brew link --force ${MAIN_PYTHON_VERSION}\n"
  fi
fi

if [[ ${TODO} != "" ]]; then
  echo ""
  echo "Not all required packages are present or correctly selected."
  echo "Please do the following:"
  echo ""
  echo -e "${TODO}"
  echo ""
  exit 255
fi
  
echo " "
echo "All required homebrew packages seem to be already installed!"
exit 0
