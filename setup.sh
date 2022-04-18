#!/bin/bash

# This bash file is part of the COSItools.
#
# The original file is part of MEGAlib.
# Port to COSItools and license change approved by original author, Andreas Zoglauer  
#
# Development lead: Andreas Zoglauer
# License: Apache 2.0

# Description:
# This is the stage 1 script to setup the COSI tools
# It sets up up the main directory if it not exists and 
# then either updates or clones the cosi-setup repository,
# and finally hands off the setup to the newly downloaded stage 2 script


############################################################################################################
# Step 1: Define default parameters

# The command line
CMD=( "$@" )

# The path to the COSItools install
COSIPATH=""
GITBASEDIR="https://github.com/cositools"
GITBRANCH="feature/initialsetup"



############################################################################################################
# Step 2: helper functions

confhelp() {
  echo ""
  echo "Setup script for COSItools"
  echo " "
  echo "This script downloads COSItools along with all required software"
  echo " "
  echo "Usage: ./setup.sh [options - all are optional!]";
  echo " "
  echo " "
  echo "Options:"
  echo " "
  #echo "Remark: This script stores the last used options and will read it the next time it is started."
  #echo "        Thus if you restart it, make sure to overwrite any options you want to change!"
  #echo " "
  echo "--cositoolspath=[path to CSOItools - first launch default: \"COSItools\"]"
  echo "    This is the path to where the COSItools will be installed. If the path exists, we will try to update them."
  echo " "
  echo "--branch=[name of a git branch]"
  echo "    Choose a specific branch of the COSItools git repositories."
  echo "    If the option is not given the latest release will be used."
  echo "    If the branch does not exist for all repositories use the main/master branch."
  echo " "
  echo "--ignore-missing-packages"
  echo "    Do not check for missing packages."
  echo " "
  echo "--keep-environment=[off/no, on/yes - first launch default: off]"
  echo "    By default all relevant environment paths (such as LD_LIBRRAY_PATH, CPATH) are reset to empty"
  echo "    to avoid most libray conflicts. This flag toggles this behaviour and lets you decide to keep your environment or not."
  echo "    If you use this flag make sure the COSItools source script has not been called in the terminal you are using."
  echo " "
  echo "--root=[options: empty (default), path to existing ROOT installation]"
  echo "    If empty (or the option has not been given at all), download and install the latest compatible version"
  echo "    If a path to an existing ROOT installation is given, then use this one. If it is not compatible with MEGAlib, the script will stop with an error."
  echo " "
  echo "--geant=[options: empty (default), path to existing GEANT4 installation]"
  echo "    If empty (or the option has not been given at all), download and install the latest compatible version"
  echo "    If a path to an existing GEANT4 installation is given, then use this one. If it is not compatible with MEGAlib, the script will stop with an error."
  echo " "
  echo "--heasoft=[options: off (default), empty, path to existing HEASoft installation]"
  echo "    If empty (or the option has not been given at all), download and install the latest compatible version"
  echo "    If the string \"off\" is given, do not install HEASoft. This will affect some tertiary tools of MEGAlib, such as storing the data in fits files."
  echo "    If a path to an existing HEASoft installation is given, then use this one. If it is not compatible with MEGAlib, the script will stop with an error."
  echo " "
  echo "--maxthreads=[integer >=1]"
  echo "    The maximum number of threads to be used for compilation. Default is the number of cores in your system."
  echo " "
  echo "--debug=[off/no, on/yes - first launch default: off]"
  echo "    Debugging options for C++ programs (MEGAlib, Nuclearizer), ROOT, Geant4."
  echo " "
  echo "--optimization=[off/no, normal/on/yes, strong/hard (requires gcc 4.2 or higher) - first launch default: on]"
  echo "    Compilation optimization for MEGAlib ONLY (Default is normal)"
  echo " "
  echo "--help or -h"
  echo "    Show this help."
  echo " "
  echo " "
}

absolutefilename() {
  echo "$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
}



############################################################################################################
# Step 3: extract the main parameters for the stage 1 script

# Check for help
for C in "${CMD[@]}"; do
  if [[ ${C} == *-h ]] || [[ ${C} == *-hel* ]]; then
    echo ""
    confhelp
    exit 0
  fi
done

# Overwrite default options with user options:
for C in "${CMD[@]}"; do
  if [[ ${C} == *-co*=* ]]; then
    COSIPATH=`echo ${C} | awk -F"=" '{ print $2 }'`
  elif [[ ${C} == *-b* ]]; then
    GITBRANCH=`echo ${C} | awk -F"=" '{ print $2 }'`
  elif [[ ${C} == *-h ]] || [[ ${C} == *-hel* ]]; then
    echo ""
    confhelp
    exit 0
  fi
done



############################################################################################################
# Step 4: Check if all the software for this script is installed

BASETOOLS="git"
INSTALLTOOLS=""

for N in ${BASETOOLS}; do
  type ${N} >/dev/null 2>&1
  if [ $? -ne 0 ]; then
    INSTALLTOOLS+="${N} "
  fi
done

if [[ ${INSTALLTOOLS} != "" ]]; then
  echo ""
  echo "Please install the following tools to run this script correctly: ${INSTALLTOOLS}" 
  exit 1
fi



############################################################################################################
# Step 5: Sanity checks

# Setup the path to the COSI installation

echo "" 
echo "Starting stage 1 setup"

# Check 


echo ""
echo "Setting up the COSItools directory"
# If we don't have a path check if we are in the setup repository, and then set the 
if [[ "${COSIPATH}" == "" ]]; then
  # Check if we are in the COSI tools directory
  if [[ -d ../cosi-setup ]]; then # later more: && [[ -d ../MEGAlib ]]; then
    COSIPATH="$(cd ..; pwd)"
    echo " * Found COSItools directory at ${COSIPATH}"
  else 
    COSIPATH="$(pwd)/COSItools"
    echo " * Creating new COSItools directory at ${COSIPATH}"
  fi
else 
  COSIPATH=$(absolutefilename ${COSIPATH}})
fi

if [[ "${COSIPATH}" != "${COSIPATH% *}" ]]; then
  echo ""
  echo "ERROR: COSItools should to be installed in a path without spaces,"
  echo "       but you chose: \"${COSIPATH}\""
  exit 1
fi
if [[ ! -d "${COSIPATH}" ]]; then
  mkdir -p "${COSIPATH}"
  if [ "$?" != "0" ]; then
    echo ""
    echo "ERROR: Something went wrong creating the COSItools path!"
    exit 1
  fi
fi
echo " * Using this path to install the COSItools: ${COSIPATH}"
cd ${COSIPATH}
echo " * Switched to the COSItools path"



############################################################################################################
# Step 6: Update/clone the cosi-setup repository

echo ""
echo "Updating/cloning the cosi-setup repository"

# If the cosi-setup diretcory exists update it if not clone it
if [[ -d cosi-setup ]]; then
  cd cosi-setup
  git pull
  if [ "$?" != "0" ]; then
    echo ""
    echo "ERROR: Unable to pull cosi-setup!"
    exit 1
  fi
else 
  git clone ${GITBASEDIR}/cosi-setup cosi-setup
  if [ "$?" != "0" ]; then
    echo ""
    echo "ERROR: Unable to clone cosi-setup!"
    exit 1
  fi
  cd cosi-setup
fi
# At this stage we need to be in the cosi-setup directory

git checkout ${GITBRANCH}
if [ "$?" != "0" ]; then
  echo ""
  echo "ERROR: Unable to checkout branch ${GITBRANCH} from cosi-setup!"
  exit 1
fi



############################################################################################################
# Step 7: Switch to the newly downloaded stage 2 file

pwd
if [[ ! -f setup-stage2.sh ]]; then
  echo ""
  echo "ERROR: Unable to find the stage 2 setup script!"
  exit 1
fi

./setup-stage2.sh "$@" --br=${GITBRANCH}
if [ "$?" != "0" ]; then
  exit 1
fi

exit 0






 
