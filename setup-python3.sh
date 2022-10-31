#!/bin/bash

# This bash script is part of the MEGAlib & COSItools setup procedure.
# As such it is dual licenced under Apache 2.0 for COSItools and LGPL 3.0 for MEGAlib
#
# Development lead: Andreas Zoglauer
#
# Description:
# This script installs a python3 environment for the python3-based analysis tools.
#


############################################################################################################
# Step 1: Define default parameters

# The operating system
OSTYPE=$(uname -s)

# We do not want any site packages, thus clear PYTHONENV
export PYTHONPATH=""


############################################################################################################
# Step 2: Call the operating system specific program

PENV=../python-env

# Create the python environment
if [[ -d ${PENV} ]]; then
  rm -r ${PENV}
fi
python3 -m venv ${PENV}
if [[ "$?" != "0" ]]; then
  echo ""
  echo "ERROR: Unable to create the python environment!"
  exit 1; 
fi

# Activate the environment
. ${PENV}/bin/activate
if [[ "$?" != "0" ]]; then
  echo ""
  echo "ERROR: Unable to activate the python environment!"
  exit 1; 
fi

# Upgrade pip
python3 -m pip install --upgrade pip
if [[ "$?" != "0" ]]; then
  echo ""
  echo "ERROR: Unable to upgrade pip!"
  exit 1; 
fi

# Install tensorflow & torch the special way to take care of issues on Apple M1 machines
if [[ $(uname -s) == *arwin ]] && [[ $(uname -m) == arm64 ]]; then
  # HDF5 is troublesome, thus do this first
  P=$(which port); P=${P%/bin/port}
  if [[ -f ${P}/lib/libhdf5.dylib ]]; then
    export HDF5_DIR=/opt/local/
    pip3 install h5py 
    if [[ "$?" != "0" ]]; then
      echo ""
      echo "ERROR: Unable to install h5py!"
      exit 1; 
    fi
  else
    P=$(which brew)
    if [[ -f ${P} ]]; then
      export HDF5_DIR=$(brew --prefix hdf5)
      pip install h5py
      if [[ "$?" != "0" ]]; then
        echo ""
        echo "ERROR: Unable to install h5py!"
        exit 1; 
      fi
    else
      echo ""
      echo "ERROR: hdf5 must be installed either via macports or brew"
      exit 1
    fi
  fi

  pip3 install tensorflow-macos
  if [[ "$?" != "0" ]]; then
    echo ""
    echo "ERROR: Unable to install tensorflow-macos!"
    exit 1; 
  fi
      
else
  pip3 install tensorflow
  if [[ "$?" != "0" ]]; then
    echo ""
    echo "ERROR: Unable to install tensorflow!"
    exit 1; 
  fi
  pip3 install torch 
  if [[ "$?" != "0" ]]; then
    echo ""
    echo "ERROR: Unable to install torch!"
    exit 1; 
  fi
fi


# All the default installations
ALLREQUIREMENTSFILES=$(find .. -maxdepth 2 -iname "Requirements.txt")

for REQFILE in ${ALLREQUIREMENTSFILES}; do
  echo ""
  echo ""
  echo "Installing requirements file ${REQFILE}"
  
  # Filter everything into a temporary file:
  REQTEMP=$(mktemp /tmp/cositoolsrequirementsfile.XXXXXXXXX)
  cat ${REQFILE} > ${REQTEMP}
  if [[ ${OSTYPE} == *inux ]]; then
    # On Ubuntu 22.04 or higher, filter pystan
    OS=$(cat /etc/os-release | grep "^ID\=" | awk -F= '{ print $2 }')
    VERSIONID=$(cat /etc/os-release | grep "^VERSION_ID\=" | awk -F= '{ print $2 }')
    VERSIONID=${VERSIONID//\"/}
    VERSIONID=${VERSIONID/./}
    if [[ ${OS} == ubuntu ]]; then
      if [ ${VERSIONID} -ge 2204 ]; then
        echo "Filtering pystan since we are on Ubuntu (=${OS}) and release is >= 22.04 (=${VERSIONID})"
        REQTEMP2=$(mktemp /tmp/cositoolsrequirementsfile.XXXXXXXXX)
        cat ${REQTEMP} | grep -v "pystan" > ${REQTEMP2}
        REQTEMP=${REQTEMP2}
      fi
    fi
  elif [[ ${OSTYPE} == *arwin ]]; then
    REQTEMP2=$(mktemp /tmp/cositoolsrequirementsfile.XXXXXXXXX)
    cat ${REQTEMP} | grep -v "pystan" > ${REQTEMP2}
    REQTEMP=${REQTEMP2}
  fi


  pip3 install -r ${REQTEMP}
  if [[ "$?" != "0" ]]; then
    echo ""
    echo "ERROR: Unable to install requirements file ${REQFILE}"
    exit 1; 
  fi
done

exit 0






 
