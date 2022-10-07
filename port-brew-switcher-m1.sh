#!/bin/bash

# This bash script is part of the MEGAlib & COSItools setup procedure.
# As such it is dual licenced under Apache 2.0 for COSItools and LGPL 3.0 for MEGAlib
#
# Development lead: Andreas Zoglauer
#
# Description:
# Swicth between macports and homebrew on Apple Silicon
#

if [[ $(uname -s) == *arwin* ]]; then
  if [[ -d /opt/homebrew ]] && [[ -d  /opt/local_disabled ]]; then
    sudo mv /opt/homebrew /opt/homebrew_disabled
    sudo mv /opt/local_disabled /opt/local
    echo "Disabled homebrew and enabled macports"  
  elif [[ -d /opt/homebrew_disabled ]] && [[ -d  /opt/local ]]; then 
    sudo mv /opt/homebrew_disabled /opt/homebrew
    sudo mv /opt/local /opt/local_disabled
    echo "Enabled homebrew and disabled macports"  
  else
    echo "For this script to work, both macports and homebrew must be installed, and one of them needs already be disabled (port: /opt/local_disable or brew: /opt/homebrew_disabled)"
  fi
else
  echo "This script only works on macOS with Mx chip"
fi

exit 0






 
