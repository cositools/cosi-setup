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

COSIPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; cd ..; pwd -P )"



############################################################################################################
# Sanity checks

# Check if the source script exits

if [ ! -f ${COSIPATH}/source.sh ]; then
  echo " "
  echo "ERROR: source.sh not found: ${COSIPATH}/source.sh"
  exit 1
fi



############################################################################################################
# Install

HEADER="# COSItools options  --  do not modify"
SOURCER="source ${COSIPATH}/source.sh"
FOOTER="# COSItools end"

PROFILE=""
BASHRC="${HOME}/.bashrc"
ZSHRC="${HOME}/.zshrc"
if [[ ${SHELL} == *bash* ]]; then
  if [[ ! -f ${BASHRC} ]]; then
    touch ${BASHRC}
  fi
  PROFILE="${BASHRC}"
elif [[ ${SHELL} == *zsh* ]]; then
  if [[ ! -f ${ZSHRC} ]]; then
    touch ${ZSHRC}
  fi
  PROFILE="${ZSHRC}"
fi

if [[ ${PROFILE} != "" ]]; then
  HASSOURCER=$(grep "${SOURCER}" ${PROFILE})
  if [[ ${HASSOURCER} != "" ]]; then
    echo " "
    echo "Your shell configuration file (${PROFILE}) already contains the COSI source script."
    echo " "
    exit 0;
  fi
fi


echo " AAAA   TTTTTT  TTTTTT  EEEEE   N    N  TTTTTT  IIIIII   OOOO   N    N"
echo "A    A    TT      TT    E       NN   N    TT      II    O    O  NN   N"
echo "AAAAAA    TT      TT    EEEEE   N N  N    TT      II    O    O  N N  N"
echo "A    A    TT      TT    E       N  N N    TT      II    O    O  N  N N"
echo "A    A    TT      TT    EEEEE   N   NN    TT    IIIIII   OOOO   N   NN"
echo " "
echo " "
echo "In order to run the COSItools programs, a source script was created, which needs to be run each time before you can use the COSItools:"
echo " "
echo "${SOURCER}"
echo " "

if [[ ${SHELL} == *bash* ]]; then
  echo "Alternatively, you can execute the following line to add the above line to your bash configuration file:" 
  echo "echo \" \" >> ${BASHRC}; echo \"${HEADER}\" >> ${BASHRC}; echo \"${SOURCER}\" >> ${BASHRC}; echo \"${FOOTER}\" >> ${BASHRC}" 
elif [[ ${SHELL} == *zsh* ]]; then
  echo "Alternatively, you can execute the following line to add the above line to your zsh configuration file:"   
  echo "echo \" \" >> ${ZSHRC}; echo \"${HEADER}\" >> ${ZSHRC}; echo \"${SOURCER}\" >> ${ZSHRC}; echo \"${FOOTER}\" >> ${ZSHRC}"
else
  echo "Alternatively, you can add the above line to your shell configuration file."
fi
echo " "
echo "Since your environment might have changed significantly during installation, we recommend to open a new terminal before using COSItools."
echo ""
echo "Then type \"cosi\" to switch to the COSItools directory and automatically activate the COSI python environment."
echo ""

exit 0
