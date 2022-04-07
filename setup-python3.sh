#!/bin/bash

# This bash script is part of the COSItools.

# Development lead: Andreas Zoglauer
# License: Apache 2.0

# Description:
# This script check is all required packages are installed 


############################################################################################################
# Step 1: Define default parameters

# Th operating system
OSTYPE=$(uname -s)


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
if [ "$(uname -s)" == "*arwin*" ]; then 
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
ALLREQUIREMENTSFILES=$(find .. -maxdepth 2 -name "Requirements.txt")

for REQFILE in ${ALLREQUIREMENTSFILES}; do
  echo "Installing requirements file ${REQFILE}"
  pip3 install -r ${REQFILE}
  if [[ "$?" != "0" ]]; then
    echo ""
    echo "ERROR: Unable to install a requirements file"
    exit 1; 
  fi
done

exit 0






 
