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
# Path to where this file is located
SETUPPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

# The shared helper functions, e.g. resolveoption
. "${SETUPPATH}/setup-helpers.sh"

# Every option this script accepts. Abbreviations are resolved against this list.
SETUPOPTIONS="cosi-tools-path branch repository-path pull-behavior-git name stash-name help"

CMD=( "$@" )

# The path to the COSItools install
COSIPATH=""
NAME=""
GITPATH=""
GITBRANCH=""
GITPULLBEHAVIOR="stash"
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
  echo "--repository-path=[name of the git path]"
  echo "    The path to the git repository"
  echo " "
  echo "--pull-behavior-git=[stash (default), merge]"
  echo "     Choose how to handle changes in git repositories:"
  echo "     \"stash\": stash the changes and pull the latest version"
  echo "     \"merge\": merge the changes -- the script will stop on error"
  echo "     \"no\": Do not change existing repositories in any way (no pull, no branch switch, etc.)"
  echo " "
  echo "--cosi-tools-path=[absolute path to COSItools]"
  echo "    This is the path to where the COSItools will be installed. If the path exists, we will try to update them."
  echo " "
  echo "--stash-name=[name under which to stash changes in the repository if --pull-behavior-git=stash]"
  echo "    This is the name under which existing chnages to the repository are stashed."
  echo " "
  echo "--help or -h"
  echo "    Show this help."
  echo " "
  echo " "
  echo "Return codes:"
  echo "0:    Nothing to be done, e.g. local branch is already latest version or you requested this help"
  echo "1:    The local installation was updated"
  echo "Else: An error occured"
  echo " "
  echo " "
}



############################################################################################################
# Step 3: Extract the command line parameters

# Check for help
for C in "${CMD[@]}"; do
  if [[ ${C} == "-h" ]] || [[ $(resolveoption "${C}" "${SETUPOPTIONS}") == "help" ]]; then
    echo ""
    confhelp
    exit 0
  fi
done

# Overwrite default options with user options:
for C in "${CMD[@]}"; do
  # "|| RESULT=$?" so that a non-zero return does not trip a "set -e"
  RESULT=0
  OPTION=$(resolveoption "${C}" "${SETUPOPTIONS}") || RESULT=$?
  # 100 and not 1: this script returns 0 for "unchanged" and 1 for "updated, recompile it",
  # thus a 1 here would tell the caller that everything went fine
  if [[ ${RESULT} == 2 ]]; then
    echo ""
    echo "ERROR: The command line option \"${C}\" is ambiguous - it matches: ${OPTION}"
    echo "       See \"./setup-retrieve-git-repository.sh --help\" for a list of options"
    exit 100
  elif [[ ${RESULT} != 0 ]]; then
    echo ""
    echo "ERROR: Unknown command line option: ${C}"
    echo "       See \"./setup-retrieve-git-repository.sh --help\" for a list of options"
    exit 100
  fi

  case ${OPTION} in
    cosi-tools-path)
      COSIPATH=$(optionvalue "${C}")
      ;;
    branch)
      GITBRANCH=$(optionvalue "${C}")
      ;;
    repository-path)
      GITPATH=$(optionvalue "${C}")
      ;;
    pull-behavior-git)
      GITPULLBEHAVIOR=$(optionvalue "${C}")
      ;;
    name)
      NAME=$(optionvalue "${C}")
      ;;
    stash-name)
      STASHNAME=$(optionvalue "${C}")
      ;;
    help)
      echo ""
      confhelp
      exit 0
      ;;
  esac
done



############################################################################################################
# Step 4: Checking the command line parameters

if [[ ${COSIPATH} == "" ]]; then
  echo ""
  echo "ERROR: No COSItools path provided..."
  exit 100
fi
if [[ ! -d ${COSIPATH} ]]; then
  echo ""
  echo "ERROR: The path to the COSItools does not exist: \"${COSIPATH}\""
  exit 100
fi

if [[ ${NAME} == "" ]]; then
  echo ""
  echo "ERROR: No repository name provided..."
  exit 100
fi
if ! [[ "${NAME}" =~ ^[a-zA-Z0-9\-]+$ ]]; then
  echo ""
  echo "ERROR: The name is only allowed to contain characters, numbers, and dashes: \"${NAME}\""
  exit 100
fi

if [[ ${STASHNAME} == "" ]]; then
  echo ""
  echo "ERROR: No stash name provided..."
  exit 100
fi
if ! [[ "${STASHNAME}" =~ ^[a-zA-Z0-9\.:]+$ ]]; then
  echo ""
  echo "ERROR: The stash name is only allowed to contain characters, numbers, dots, and double colons: \"${STASHNAME}\""
  exit 100
fi

if [[ ${GITPATH} == "" ]]; then
  echo ""
  echo "ERROR: No git path provided..."
  exit 100
fi

if [[ ${GITBRANCH} == "" ]]; then
  echo ""
  echo "ERROR: No git branch provided..."
  exit 100
fi

if ( [[ ${GITPULLBEHAVIOR} == merge ]] || [[ ${GITPULLBEHAVIOR} == stash ]] || [[ ${GITPULLBEHAVIOR} == no ]] ); then
  echo " * Use the following git pull behavior: ${GITPULLBEHAVIOR}"
else
  echo " "
  echo "ERROR: Unknown git pull behavior: ${GITPULLBEHAVIOR}"
  confhelp
  exit 100
fi



############################################################################################################
# Step 5: Setup the repository

cd "${COSIPATH}"

# "no" means do not touch an existing repository at all. Leave before the branch checks
# below, since those contact the remote and would fail without network access.
if [[ ${GITPULLBEHAVIOR} == "no" ]] && [[ -d ${NAME} ]]; then
  echo "Keeping existing repository ${NAME} as is"
  exit 0
fi

# Check if the requested branch exits:
if [ "${GITBRANCH}" == "" ]; then
  GITBRANCH="main"
fi

FOUNDBRANCH=$(git ls-remote --heads "${GITPATH}" | awk -F"refs/heads/" '{ print $2 }' | grep -x "${GITBRANCH}")
if [[ ${FOUNDBRANCH} != ${GITBRANCH} ]]; then
  echo " "
  echo "INFO: The desired branch \"${GITBRANCH}\" does not exit in the repository"
  FOUNDBRANCH=$(git ls-remote --heads "${GITPATH}" | awk -F"refs/heads/" '{ print $2 }' | grep -x "main")
  if [[ ${FOUNDBRANCH} == main ]]; then
    echo "      Switching to the main branch..."
    GITBRANCH="main"
  else
    FOUNDBRANCH=$(git ls-remote --heads "${GITPATH}" | awk -F"refs/heads/" '{ print $2 }' | grep -x "master")
    if [[ ${FOUNDBRANCH} == master ]]; then
      echo "         Switching to the master branch..."
      GITBRANCH="master"
    else
      echo " "
      echo "ERROR: Unable to find the desired or the main/master branch"
      exit 100
    fi
  fi
fi


# The repository does not exist - clone it
if [[ ! -d ${NAME} ]]; then
  echo "Using git to clone the repository ${GITPATH} into the local directory ${NAME}..."
  git clone "${GITPATH}" ${NAME}
  if [ "$?" != "0" ]; then
    echo " "
    echo "ERROR: Unable to clone the requested repository from git"
    exit 100
  fi
  cd ${NAME}
    
# The repository does exist 
else
  echo "The repository ${NAME} already exists"
  cd ${NAME}

  # Check if we are already on the requested branch with the latest commit
  REMOTEBRANCHHASH=$(git ls-remote "${GITPATH}" ${GITBRANCH} | awk -F" " '{ print $1 }' | xargs)
  LOCALBRANCHHASH=$(git rev-parse HEAD | xargs)
  if [[ ${REMOTEBRANCHHASH} == ${LOCALBRANCHHASH} ]]; then
    echo "We are already on the requested branch with the latest commit"
    exit 0
  fi

  # Stash potential changes
  if [[ ${GITPULLBEHAVIOR} == "stash" ]]; then
    echo "Stashing any potential modifications if there are any"
    git stash push --include-untracked -m ${STASHNAME}
    if [ "$?" != "0" ]; then
      echo " "
      echo "Warning: Unable to stash with \"push -m\" -- your git version might be too old. Trying just git stash"
      git stash --include-untracked
      if [ "$?" != "0" ]; then
        echo " "
        echo "ERROR: Unable to stash any changes in your code"
        exit 100
      fi
    fi
  fi
fi


# Fetch all branches
echo "Getting all the latest changes from the repository..."
git fetch origin
if [ "$?" != "0" ]; then
  echo " "
  echo "ERROR: Unable to fetch the latest data from the repository"
  exit 100
fi

# Getting the current brnach
CURRENTBRANCH=`git rev-parse --abbrev-ref HEAD`
echo "Current branch: ${CURRENTBRANCH}"


 

# Switch to the desired branch if we are not yet there
if [ "${CURRENTBRANCH}" != "${GITBRANCH}" ]; then
  echo "Switching to branch ${GITBRANCH}"
  git checkout ${GITBRANCH}
  if [ "$?" != "0" ]; then
    echo " "
    echo "ERROR: Unable to update the git repository to branch ${GITBRANCH}"
    exit 100
  fi
fi


# Do a final pull
git pull
if [ "$?" != "0" ]; then
  echo " "
  echo "ERROR: Unable to perform a final pull."
  exit 100
fi 

cd "${COSIPATH}"

exit 1






 
