#!/bin/bash

# This bash script is part of the MEGAlib & COSItools setup procedure.
# As such it is dual licenced under Apache 2.0 for COSItools and LGPL 3.0 for MEGAlib
#
# Development lead: Andreas Zoglauer
#
# Description:
# Source all Geant4-related environment variables



# Make this script work with zsh
if [ -n "$ZSH_VERSION" ]; then emulate -L ksh; fi


# Print some help 
confhelp() {
  echo ""
  echo "This script sources all Geant4-related environment variables"
  echo " "
  echo "Usage: ./source-geant4.sh --path=[full path to the Geant4 installation]";
  echo " "
}


# Parse the command line
CMD=( "$@" )

__TMP_PATH=""
__TMP_HERE=$(pwd)

for C in "${CMD[@]}"; do
  if [[ ${C} == *-p*=* ]]; then
    __TMP_PATH=`echo ${C} | awk -F"=" '{ print $2 }'`
  elif [[ ${C} == *-h ]] || [[ ${C} == *-hel* ]]; then
    echo ""
    confhelp
    exit 0
  fi
done


# Perform sanity checks

# We require an absolute path
if [[ ${__TMP_PATH} != /* ]]; then
  echo ""
  echo "ERROR: The Geant4 path must be an absolute path: ${__TMP_PATH}"
  echo ""
  return
fi

# The directory must exist
if [[ ! -d ${__TMP_PATH} ]]; then
  echo ""
  echo "ERROR: GEANT4 directory not found: ${__TMP_PATH}"
  echo ""
  return
fi

# Source the Geant4 environment depending on which version we have

if [[ -f ${__TMP_PATH}/bin/geant4.sh ]]; then
  source ${__TMP_PATH}/bin/geant4.sh > /dev/null
  __TMP_PATHTOGEANT4MAKE=${__TMP_PATH}/share/Geant4-`${__TMP_PATH}/bin/geant4-config --version`/geant4make

  cd ${__TMP_PATHTOGEANT4MAKE}
  source geant4make.sh
  cd ${__TMP_HERE}

  if [[ `uname -a` == *Darwin* ]]; then
    export LD_LIBRARY_PATH=${G4LIB}/..:${LD_LIBRARY_PATH}
    #export DYLD_LIBRARY_PATH=${G4INSTALL}/lib/${G4SYSTEM}/lib:${DYLD_LIBRARY_PATH}
  fi

  export G4NEUTRONHP_USE_ONLY_PHOTONEVAPORATION=1
  
elif (test -f ${__TMP_PATH}/env.sh); then
  source ${__TMP_PATH}/env.sh > /dev/null  

  export LD_LIBRARY_PATH=${G4INSTALL}/lib/${G4SYSTEM}:${LD_LIBRARY_PATH}
  if [[ `uname -a` == *Darwin* ]]; then
    export DYLD_LIBRARY_PATH=${G4INSTALL}/lib/${G4SYSTEM}/lib:${LD_LIBRARY_PATH}
  fi

  export G4NEUTRONHP_USE_ONLY_PHOTONEVAPORATION=1
  
else
  echo " " 
  echo "WARNING: geant4.sh or env.sh not found in Geant4 directory: ${__TMP_PATH}/bin"
  echo "         Assuming we are currently installing Geant4 otherwise make sure to run \"./Configure\" (Geant4 < 9.5) or \"cmake install\" (Geant4 >= 9.5)!"
  echo ""
  G4INSTALL=${__TMP_PATH}
fi 


return
