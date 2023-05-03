#!/bin/bash

# This bash script is part of the MEGAlib & COSItools setup procedure.
# As such it is dual licenced under Apache 2.0 for COSItools and LGPL 3.0 for MEGAlib
#
# Development lead: Andreas Zoglauer
#
# Description:
# This is the stage 1 script to setup the COSI tools
# It sets up up the main directory if it not exists and 
# then either updates or clones the cosi-setup repository,
# and finally hands off the setup to the newly downloaded stage 2 script
#


############################################################################################################
# Step 1: Define default parameters

# The start time
TIMESTART=$(date +%s)

# The command line
CMD=( "$@" )

# The path to the COSItools install
COSIPATH=""
GITBASEDIR="https://github.com/cositools"
GITBRANCH="main"



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
  echo "--cositoolspath=[path to COSItools - default: \"COSItools\"]"
  echo "    This is the path to where the COSItools will be installed. If the path exists, we will try to update them."
  echo " "
  echo "--branch=[name of a git branch - default: main]"
  echo "    Choose a specific branch of the COSItools git repositories."
  echo "    If the option is not given the latest release will be used."
  echo "    If the branch does not exist for all repositories use the main/master branch."
  echo " "
  echo "--pull-behavior-git=[stash (default), merge]"
  echo "     Choose how to handle changes in git repositories:"
  echo "     \"stash\": stash the changes and pull the latest version"
  echo "     \"merge\": merge the changes -- the script will stop on error"
  echo "     \"no\": Do not change existing repositories in any way (no pull, no branch switch, etc.)"
  echo " "
  echo "--extras=[list of extra packages not installed by default]"
  echo "     Add a few extra packages not installed by default since, e.g., they are too large"
  echo "     Example: --extras=cosi-data-challenge-1,cosi-data-challenge-2"
  echo " "
  echo "--ignore-missing-packages"
  echo "    Do not check for missing packages."
  echo " "
  echo "--keep-environment=[off/no, on/yes - default: off]"
  echo "    By default all relevant environment paths (such as LD_LIBRRAY_PATH, CPATH) are reset to empty"
  echo "    to avoid most libray conflicts. This flag toggles this behaviour and lets you decide to keep your environment or not."
  echo "    If you use this flag make sure the COSItools source script has not been called in the terminal you are using."
  echo " "
  echo "--root=[options: empty (default), path to existing ROOT installation]"
  echo "    --root=              Download and install the latest compatible version"
  echo "    --root=[version]     Download the given ROOT version. Format must be \"x.yy\""
  echo "    --root=[GitHub tag]  Download the ROOT version with the given tag. Format must be \"vx-yy-zz\", \"vx-yy-zz-patches\", or \"master\""
  echo "    --root=[path]        Use the version of ROOT found in the path. The path cannot be of the format \"x.yy\", \"vx-yy-zz\", \"vx-yy-zz-patches\", or \"master\""
  echo " "
  echo "--geant=[options: empty (default), path to existing GEANT4 installation]"
  echo "    --geant=           Download and install the latest compatible version."
  echo "    --geant=[path]     Use the version of Geant4 found in the path. If it is not compatible, the script will stop with an error."
  echo " "
  echo "--heasoft=[options: empty or heasoft, off, cfitsio (default), path to existing HEASoft installation]"
  echo "    --heasoft=         Download and install the latest compatible version."
  echo "    --heasoft=heasoft  Download and install the latest compatible version."
  echo "    --heasoft=cfitsio  Download and install the latest cfitsio version."
  echo "    --heasoft=off      Do not install HEASoft."
  echo "    --heasoft=[path]   Use the version of HEASoft found in the path. If it is not compatible, the script will stop with an error."
  echo " "
  echo "--maxthreads=[integer >=1]"
  echo "    The maximum number of threads to be used for compilation. Default is the number of cores in your system."
  echo " "
  echo "--debug=[off/no (default), on/yes]"
  echo "    Debugging compiler flags for C++ programs ROOT, Geant4 & MEGAlib."
  echo " "
  echo "--optimization=[off/no, normal/on/yes (default), strong/hard]"
  echo "    Compilation optimization compiler flags for MEGAlib only."
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

if [[ ! -f setup-stage2.sh ]]; then
  echo ""
  echo "ERROR: Unable to find the stage 2 setup script!"
  exit 1
fi


# Create a log directory
if [[ ! -d log ]]; then
  mkdir log
fi

NOW=$(date +"%Y%m%d-%H%M%S")
LOGFILE="log/Build_${NOW}.log"

echo "*********************************************" >> ${LOGFILE}
echo "" >> ${LOGFILE}
echo "COSItools build log file from ${NOW}" >> ${LOGFILE}
echo "" >> ${LOGFILE}
echo "*********************************************" >> ${LOGFILE}
echo "" >> ${LOGFILE}
echo "" >> ${LOGFILE}
./setup-system-info.sh >> ${LOGFILE}
if [ "$?" != "0" ]; then
  echo "" >> ${LOGFILE}
  echo "ERROR: Unable to find the system info setup script!" >> ${LOGFILE}
  exit 1
fi

ADDITIONALOPTIONS=""
# Check if we should set a new git branch
ADDITIONALOPTIONS+=" --br=${GITBRANCH}"
# If the heasoft flag is not given we just install cfitsio
if [[ $@ != *-hea* ]]; then
  ADDITIONALOPTIONS+=" --heasoft=cfitsio"
fi

set -o pipefail # This ensures the $? catches any error in the pipeline
./setup-stage2.sh "$@" ${ADDITIONALOPTIONS} 2>&1 | tee -a log/Build_$(date +"%Y%m%d-%H%M%S").log  
if [ "$?" != "0" ]; then
  echo ""
  echo "ERROR: An error occured, and COSItools was not completely installed."
  echo ""
  exit 1
fi



############################################################################################################
# Step 8: Finalize

TIMEEND=$(date +%s)
TIMEDIFF=$(( ${TIMEEND} - ${TIMESTART} ))

echo ""
if [ $((TIMEDIFF/3600)) -gt 0 ]; then 
  printf 'Setup finished after %d hours, %d minutes, and %d seconds\n' $((TIMEDIFF/3600)) $((TIMEDIFF%3600/60)) $((TIMEDIFF%60)); 
else 
  printf 'Setup finished after %d minutes and %d seconds\n' $((TIMEDIFF/60)) $((TIMEDIFF%60));
fi
echo ""

exit 0






 
