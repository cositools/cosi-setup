# This bash script is part of the MEGAlib & COSItools setup procedure.
# As such it is dual licenced under Apache 2.0 for COSItools and LGPL 3.0 for MEGAlib
#
# Development lead: Andreas Zoglauer
#
# Description:
# Source all MEGAlib-related environment variables



# Make this script work with zsh
if [ -n "$ZSH_VERSION" ]; then emulate -L ksh; fi


# Print some help 
confhelp() {
  echo ""
  echo "This script sources all MEGAlib-related environment variables"
  echo " "
  echo "Usage: . ./source-megalib.sh --path=[full path to the MEGAlib installation]";
  echo " "
}


# This script sets environment variables in the calling shell, thus it has to be sourced.
# Running it would set them in a shell which ends right away, and on top of that a "return"
# outside a sourced script does not stop anything, so the sanity checks below would not
# hold. An unrecognized shell is assumed to be sourcing, so that this can never block the
# normal path. "exit" is correct here and only here: there is no calling shell to end.
__TMP_SOURCED=true
if [ -n "${ZSH_VERSION}" ]; then
  case ${ZSH_EVAL_CONTEXT} in *:file) ;; *) __TMP_SOURCED=false ;; esac
elif [ -n "${BASH_VERSION}" ]; then
  if [ "${BASH_SOURCE[0]}" = "${0}" ]; then __TMP_SOURCED=false; fi
fi
if [ "${__TMP_SOURCED}" = "false" ]; then
  echo ""
  echo "ERROR: This script has to be sourced, not run."
  confhelp
  exit 1
fi


# Parse the command line
CMD=( "$@" )

__TMP_PATH=""
__TMP_HERE=$(pwd)

for C in "${CMD[@]}"; do
  if [[ ${C} == *-p*=* ]]; then
    __TMP_PATH="${C#*=}"
  elif [[ ${C} == *-h ]] || [[ ${C} == *-hel* ]]; then
    echo ""
    confhelp
    return 0
  fi
done


# Perform sanity checks

# We require an absolute path
if [[ ${__TMP_PATH} != /* ]]; then
  echo ""
  echo "ERROR: The MEGAlib path must be an absolute path: ${__TMP_PATH}"
  echo ""
  return 1
fi

# The directory must exist
if [[ ! -d ${__TMP_PATH} ]]; then
  echo ""
  echo "ERROR: MEGAlib directory not found: ${__TMP_PATH}"
  echo ""
  return 1
fi


# Source the MEGAlib environment 

export MEGALIB=${__TMP_PATH}   
export PATH=${MEGALIB}/bin:${PATH}    
export LD_LIBRARY_PATH=${MEGALIB}/lib:${LD_LIBRARY_PATH}
if [[ $(uname -a) == *Darwin* ]]; then
  export DYLD_LIBRARY_PATH=${MEGALIB}/lib:${LD_LIBRARY_PATH}
fi


return
