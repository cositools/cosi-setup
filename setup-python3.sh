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

# The operating system identifiers
OSTYPE=$(uname -s)
if [[ ${OSTYPE} == *arwin* ]]; then
  OSNAME="MACOS"
  OSVERSION=$(sw_vers | grep "ProductVersion" | awk -F" " '{ print $2 }')
else 
  OSNAME=$(cat /etc/os-release | grep "^ID\=" | awk -F= '{ print $2 }' | tr -d '"')
  OSVERSION=$(cat /etc/os-release | grep "^VERSION_ID\=" | awk -F= '{ print $2 }')
  OSVERSION=${OSVERSION//\"/}
  OSVERSION=${OSVERSION/./}
fi

# We do not want any site packages, thus clear PYTHONENV
export PYTHONPATH=""

# Choose the python version
PY=$($(dirname $0)/check-pythonversion.sh --get-interpreter)
if [[ "$?" != "0" ]]; then
  # The error message is part of the above script
  exit 1
fi


############################################################################################################
# Step 2: Call the operating system specific program

PENV=../python-env

# If we have an existing environment, check if we can reuse it
if [[ -d ${PENV} ]]; then
  # Currently the only requirement for re-use is the same python version
  REUSEOK="TRUE"
  PYVERS=$(${PY} -VV)
  . ${PENV}/bin/activate
  if [[ "${PYVERS}" != "$(python3 -VV)" ]]; then
    echo "INFO: Existing python environment uses different python version (${PYVERS} != $(python3 -VV)) or has been compiled differently - rebuilding it"
    REUSEOK="FALSE"
  fi
  deactivate

  if [[ ${REUSEOK} == "TRUE" ]]; then
    echo ""
    echo "Re-using existing python environment"
    echo "If something goes wrong with the python setup, try first to remove the existing local python environment, and start the setup stript again:"
    echo "rm -r ${PENV}"
    echo ""
  else
    echo "Removing existing python environment"
    rm -r ${PENV}
  fi
fi

# Create the python environment
if [ ! -d ${PENV} ]; then
  ${PY} -m venv ${PENV}
  if [[ "$?" != "0" ]]; then
    echo ""
    echo "ERROR: Unable to create the python environment!"
    exit 1;
  fi
fi

# Activate the environment
. ${PENV}/bin/activate
if [[ "$?" != "0" ]]; then
  echo ""
  echo "ERROR: Unable to activate the python environment!"
  exit 1; 
fi

# Upgrade pip
python3 -m ensurepip
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
    echo "       But not bailing out since not everybody uses it."
    echo "" 
  fi
  pip3 install torch 
  if [[ "$?" != "0" ]]; then
    echo ""
    echo "ERROR: Unable to install torch!"
    echo "       But not bailing out since not everybody uses it."
    echo ""
  fi
fi


# Install some generally helpful packages
pip3 install jupyter


# Install cosipy from its git checkout.
# It is installed in editable mode since the repository is updated by the setup script
# on each run, and a regular install would go stale after the next update.
COSIPY=../cosipy
if [[ ! -d ${COSIPY} ]]; then
  echo ""
  echo "ERROR: Unable to find the cosipy directory at ${COSIPY}!"
  exit 1
fi

echo ""
echo ""
echo "Installing cosipy"
pip3 install -e ${COSIPY}
if [[ "$?" != "0" ]]; then
  echo ""
  echo "ERROR: Unable to install cosipy!"
  exit 1;
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
    if [[ ${OSNAME} == ubuntu ]]; then
      if [ ${OSVERSION} -ge 2204 ]; then
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


  pip3 install --quiet -r ${REQTEMP}
  if [[ "$?" != "0" ]]; then
    echo ""
    echo "ERROR: Unable to install requirements file ${REQFILE}"
    exit 1;
  fi
done

exit 0






 
