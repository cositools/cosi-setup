# This bash script is part of the MEGAlib & COSItools setup procedure.
# As such it is dual licenced under Apache 2.0 for COSItools and LGPL 3.0 for MEGAlib
#
# Development lead: Andreas Zoglauer
#
# Description:
# Source all HEASoft-related environment variables



# Make this script work with zsh
if [ -n "$ZSH_VERSION" ]; then emulate -L ksh; fi


# Print some help 
confhelp() {
  echo ""
  echo "This script sources all HEASoft-related environment variables"
  echo " "
  echo "Usage: . ./source-heasoft.sh --path=[full path to the HEASoft installation]";
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
  echo "ERROR: The HEASoft path must be an absolute path: ${__TMP_PATH}"
  echo ""
  return 1
fi

# The directory must exist
if [[ ! -d ${__TMP_PATH} ]]; then
  echo ""
  echo "ERROR: HEASoft directory not found: ${__TMP_PATH}"
  echo ""
  return 1
fi


# Source the HEASoft environment 

__TMP_HEADASFOUND=false
__TMP_CFITSIOFOUND=false
if [[ -f ${__TMP_PATH}/headas-init.sh ]]; then 
  export HEADAS=${__TMP_PATH}
  alias heainit=". ${HEADAS}/headas-init.sh"
  source ${HEADAS}/headas-init.sh
  __TMP_HEADASFOUND=true
fi

# Register cfitsio with pkg-config, so that it is findable
if [[ -f ${__TMP_PATH}/lib/pkgconfig/cfitsio.pc ]]; then
  export PKG_CONFIG_PATH=${__TMP_PATH}/lib/pkgconfig:${PKG_CONFIG_PATH}
elif [[ -f ${__TMP_PATH}/lib64/pkgconfig/cfitsio.pc ]]; then
  export PKG_CONFIG_PATH=${__TMP_PATH}/lib64/pkgconfig:${PKG_CONFIG_PATH}
fi
if [[ `uname -a` == *Linux* ]]; then
  if [[ -f ${__TMP_PATH}/lib/libcfitsio.so ]]; then 
    __TMP_CFITSIOFOUND=true
  fi
else
  # Too many installation options here - don't do the check...
  __TMP_CFITSIOFOUND=true
fi

if [[ ${__TMP_HEADASFOUND} == false ]]; then
  echo ""
  echo "ERROR: HEADAS software not found in HEADAS directory"
  echo ""
  return 1
fi
if [[ ${__TMP_CFITSIOFOUND} == false ]]; then
  echo ""
  echo "ERROR: libcfitsio not found in the HEADAS library directory"
  echo "       You should make a link such as libcfitsio_3.XY.so -> libcfitsio.so"
  return 1
fi


return
