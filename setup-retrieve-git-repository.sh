#!/bin/bash

# This bash script is part of the MEGAlib & COSItools setup procedure.
# As such it is dual licenced under Apache 2.0 for COSItools and LGPL 3.0 for MEGAlib
#
# Development lead: Andreas Zoglauer
#
# Description:
# This script retrieves a specified branch from a specified git repository .
#


############################################################################################################
# Step 1: Define default parameters

# The command line
CMD=( "$@" )

# The path to the COSItools install
COSIPATH=""
NAME=""
GITPATH=""
GITBRANCH=""
STASHNAME=""


############################################################################################################
# Step 2: helper functions

confhelp() {
  echo ""
  echo "This script retrieves a software tool from github"
  echo " "
  echo "Usage: ./setup-retrieve-git-repository.sh [options - all are mandatory]";
  echo " "
  echo " "
  echo "Options:"
  echo " "
  echo "--name=[name of the repository in the COSItools directory]"
  echo "    The name the repository should be given in the COSItools folder."
  echo " "
  echo "--branch=[name of a git branch]"
  echo "    Choose a specific branch of the COSItools git repositories."
  echo "    If the option is not given or the branch does not exist then the main/master is chosen."
  echo " "
  echo "--repositorypath=[name of the git path]"
  echo "    The path to the git repository"
  echo " "
  echo "--cositoolspath=[absolute path to COSItools]"
  echo "    This is the path to where the COSItools will be installed. If the path exists, we will try to update them."
  echo " "
  echo "--stashname=[name under which to stash chnages in the repository]"
  echo "    This is the name under which existing chnages to the repository are stashed."
  echo " "
  echo "--help or -h"
  echo "    Show this help."
  echo " "
  echo " "
}



############################################################################################################
# Step 3: Extract the command line parameters

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
  if [[ ${C} == *-c*=* ]]; then
    COSIPATH=`echo ${C} | awk -F"=" '{ print $2 }'`
  elif [[ ${C} == *-b* ]]; then
    GITBRANCH=`echo ${C} | awk -F"=" '{ print $2 }'`
  elif [[ ${C} == *-r* ]]; then
    GITPATH=`echo ${C} | awk -F"=" '{ print $2 }'`
  elif [[ ${C} == *-n* ]]; then
    NAME=`echo ${C} | awk -F"=" '{ print $2 }'`
  elif [[ ${C} == *-s* ]]; then
    STASHNAME=`echo ${C} | awk -F"=" '{ print $2 }'`
  elif [[ ${C} == *-h ]] || [[ ${C} == *-hel* ]]; then
    echo ""
    confhelp
    exit 0
  fi
done



############################################################################################################
# Step 4: Checking the command line parameters

if [[ ${COSIPATH} == "" ]]; then
  echo ""
  echo "ERROR: No COSItools path provided..."
  exit 1
fi
if [[ ! -d ${COSIPATH} ]]; then
  echo ""
  echo "ERROR: The path to the COSItools does not exist: \"${COSIPATH}\""
  exit 1
fi

if [[ ${NAME} == "" ]]; then
  echo ""
  echo "ERROR: No repository name provided..."
  exit 1
fi
if ! [[ "${NAME}" =~ ^[a-zA-Z0-9\-]+$ ]]; then
  echo ""
  echo "ERROR: The name is only allowed to contain characters, numbers, and dashes: \"${NAME}\""
  exit 1
fi

if [[ ${STASHNAME} == "" ]]; then
  echo ""
  echo "ERROR: No stash name provided..."
  exit 1
fi
if ! [[ "${STASHNAME}" =~ ^[a-zA-Z0-9\.:]+$ ]]; then
  echo ""
  echo "ERROR: The stash name is only allowed to contain characters, numbers, dots, and double colons: \"${STASHNAME}\""
  exit 1
fi

if [[ ${GITPATH} == "" ]]; then
  echo ""
  echo "ERROR: No git path provided..."
  exit 1
fi

if [[ ${GITBRANCH} == "" ]]; then
  echo ""
  echo "ERROR: No git branch provided..."
  exit 1
fi



############################################################################################################
# Step 5: Setup the repository

cd ${COSIPATH}

# The repository does not exist - clone it
if [[ ! -d ${NAME} ]]; then
  echo "Using git to clone the repository ${GITPATH} into the local directory ${NAME}..."
  git clone ${GITPATH} ${NAME}
  if [ "$?" != "0" ]; then
    echo " "
    echo "ERROR: Unable to checkout the latest development version from git"
    exit 1
  fi
  cd ${NAME}
    
# The repository does exist - stash potential changes
else   
  echo "The repository ${NAME} already exists"
  echo "Stashing any potential modifications if there are any"
  cd ${NAME}
  git stash push -m ${STASHNAME}
  if [ "$?" != "0" ]; then
    echo " "
    echo "Warning: Unable to stash with \"push -m\" -- your git version might be too old. Trying just git stash"
    git stash
    if [ "$?" != "0" ]; then
      echo " "
      echo "ERROR: Unable to stash any changes in your code"
      exit 1
    fi
  fi   
fi


# Fetch all branches
echo "Getting all the latest changes from the repository..."
git fetch origin
if [ "$?" != "0" ]; then
  echo " "
  echo "ERROR: Unable to fetch the latest data from the repository"
  exit 1
fi

# Getting the current brnach
CURRENTBRANCH=`git rev-parse --abbrev-ref HEAD`
echo "Current branch: ${CURRENTBRANCH}"

if [ "${GITBRANCH}" == "" ]; then
  GITBRANCH="main"
fi
 
FOUNDBRANCH=$(git ls-remote --heads ${GITPATH} | awk -F"refs/heads/" '{ print $2 }' | grep -x "${GITBRANCH}")
if [[ ${FOUNDBRANCH} != ${GITBRANCH} ]]; then
  echo " "
  echo "WARNING: The desired branch \"${GITBRANCH}\" does not exit in the repository"
  FOUNDBRANCH=$(git ls-remote --heads ${GITPATH} | awk -F"refs/heads/" '{ print $2 }' | grep -x "main")
  if [[ ${FOUNDBRANCH} == main ]]; then    
    echo "         Switching to the main branch..."
    GITBRANCH="main"
  else
    FOUNDBRANCH=$(git ls-remote --heads ${GITPATH} | awk -F"refs/heads/" '{ print $2 }' | grep -x "master")
    if [[ ${FOUNDBRANCH} == master ]]; then    
      echo "         Switching to the master branch..."
      GITBRANCH="master"
    else
      echo " "
      echo "ERROR: Unable to find the desired or the main/master branch"
      exit 1
    fi
  fi
fi
 

# Switch to the desired branch if we are not yet there
if [ "${CURRENTBRANCH}" != "${GITBRANCH}" ]; then
  echo "Switching to branch ${GITBRANCH}"
  git checkout ${GITBRANCH}
  if [ "$?" != "0" ]; then
    echo " "
    echo "ERROR: Unable to update the git repository to branch ${GITBRANCH}"
    exit 1
  fi
fi


# Do a final pull
git pull
if [ "$?" != "0" ]; then
  echo " "
  echo "ERROR: Unable to perform a final pull."
  exit 1
fi 

cd ${COSIPATH}

exit 0






 
