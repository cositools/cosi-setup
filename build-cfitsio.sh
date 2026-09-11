#!/bin/bash

# This bash script is part of the MEGAlib & COSItools setup procedure.
# As such it is dual licenced under Apache 2.0 for COSItools and LGPL 3.0 for MEGAlib
#
# Development lead: Andreas Zoglauer
#
# Description:
# This script downloads, compiles, and installs cfitsio


# Operating system type
OSTYPE=$(uname -s | awk '{print tolower($0)}')

# The basic compiler options
COMPILEROPTIONS=$(gcc --version | head -n 1)

# Additional configure options 
CONFIGUREOPTIONS=" "

# Comment this line in if you have trouble with readline
# CONFIGUREOPTIONS="--enable-readline "




confhelp() {
  echo ""
  echo "Building cfitsio"
  echo " "
  echo "Usage: ./build-cfitsio.sh [options]";
  echo " "
  echo " "
  echo "Options:"
  echo "--tarball=[file name of the cfitsio tar ball]"
  echo "    Use this tarball instead of downloading it from the cfitsio website"
  echo " "
  echo "--source-script=[file name of new environment script]"
  echo "    The source script which sets all environment variables for cfitsio."
  echo " "
  echo "--max-threads=[integer >=1 - default: 1]"
  echo "    The maximum number of threads to be used for compilation."
  echo "    The default is one thread due to parallel compile issues - raise it at your own risk."
  echo " "
  echo "--help or -h"
  echo "    Show this help."
  echo " "
  echo " "
}


# Path to where this file is located
SETUPPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

# The shared helper functions, e.g. resolveoption
. "${SETUPPATH}/setup-helpers.sh"

# Every option this script accepts. Abbreviations are resolved against this list.
SETUPOPTIONS="tarball source-script max-threads help"

# Store command line
CMD=( "$@" )

# Check for help
for C in "${CMD[@]}"; do
  if [[ ${C} == "-h" ]] || [[ $(resolveoption "${C}" "${SETUPOPTIONS}") == "help" ]]; then
    echo ""
    confhelp
    exit 0
  fi
done

TARBALL=""
ENVFILE=""

# One thread due to parallel compile issues - see further below
MAXTHREADS=1

# Overwrite default options with user options:
for C in "${CMD[@]}"; do
  # "|| RESULT=$?" so that a non-zero return does not trip a "set -e"
  RESULT=0
  OPTION=$(resolveoption "${C}" "${SETUPOPTIONS}") || RESULT=$?
  if [[ ${RESULT} == 2 ]]; then
    echo ""
    echo "ERROR: The command line option \"${C}\" is ambiguous - it matches: ${OPTION}"
    echo "       See \"$0 --help\" for a list of options"
    exit 1
  elif [[ ${RESULT} != 0 ]]; then
    echo ""
    echo "ERROR: Unknown command line option: ${C}"
    echo "       See \"$0 --help\" for a list of options"
    exit 1
  fi

  case ${OPTION} in
    tarball)
      TARBALL=$(optionvalue "${C}")
      echo "Using this tarball: ${TARBALL}"
      ;;
    source-script)
      ENVFILE=$(optionvalue "${C}")
      echo "Using this environment file: ${ENVFILE}"
      ;;
    max-threads)
      MAXTHREADS=$(optionvalue "${C}")
      if [[ ! ${MAXTHREADS} =~ ^[0-9]+$ ]] || [ "${MAXTHREADS}" -le "0" ]; then
        echo "ERROR: The maximum number of threads must be a number larger than 0 and not ${MAXTHREADS}!"
        exit 1
      fi
      echo "Using at most ${MAXTHREADS} threads for compilation"
      ;;
    help)
      echo ""
      confhelp
      exit 0
      ;;
  esac
done


# The tools this build needs. Checked after the command line has been read, so that
# --help still works on a machine which cannot build.
type gfortran >/dev/null 2>&1
if [ $? -ne 0 ]; then
  type g95 >/dev/null 2>&1
  if [ $? -ne 0 ]; then
    type g77 >/dev/null 2>&1
    if [ $? -ne 0 ]; then
      echo "ERROR: A fortran compiler must be installed"
      exit 1
    fi
  fi
fi


echo "Getting cfitsio..."
VER=""
if [ "${TARBALL}" != "" ]; then
  # Use given tarball
  echo "The given cfitsio tarball is ${TARBALL}"

  # Check if it has the correct version:
  # The official archive is named e.g. cfitsio-4.7.0.tar.gz
  VER=$(basename "${TARBALL}" | sed -n 's/^cfitsio[-_]\([0-9][0-9.]*[0-9]\).*/\1/p')
  if [[ ${VER} == "" ]]; then
    echo "ERROR: Unable to determine the cfitsio version from the tarball name ${TARBALL}"
    exit 1
  fi
  echo "Version of cfitsio is: ${VER}"
else
  # Download it

  # The desired version is simply the highest version
  echo "Looking for latest cfitsio version on the cfitsio website"

  # Now check root repository for the given version:
  #TARBALL=$(curl ftp://legacy.gsfc.nasa.gov/software/lcfitsio/release/ -sl | grep "^cfitsio\-" | grep "[0-9]src.tar.gz$")
  TARBALL=$(curl https://heasarc.gsfc.nasa.gov/FTP/software/fitsio/c/ -sl | grep ">cfitsio-" | grep "[0-9].tar.gz<" | awk -F">" '{ print $3 }' | awk -F"<" '{print $1 }' | sort | tail -n 1)
  if [ "${TARBALL}" == "" ]; then
    echo "ERROR: Unable to find suitable cfitsio tar ball at the cfitsio website"
    exit 1
  fi
  echo "Using cfitsio tar ball ${TARBALL}"

  # Check if it already exists locally
  REQUIREDOWNLOAD="true"
  if tarballisgood "${TARBALL}" "https://heasarc.gsfc.nasa.gov/FTP/software/fitsio/c/${TARBALL}"; then
    REQUIREDOWNLOAD="false"
  fi

  if [ "${REQUIREDOWNLOAD}" == "true" ]; then
    echo "Starting the download."
    echo "If the download fails, you can continue it via the following command and then call this script again - it will use the downloaded file."
    echo " "
    echo "curl -fOL -C - https://heasarc.gsfc.nasa.gov/FTP/software/fitsio/c/${TARBALL}"
    echo " "
    if ! downloadtarball "https://heasarc.gsfc.nasa.gov/FTP/software/fitsio/c/${TARBALL}" "${TARBALL}"; then
      echo "ERROR: Unable to download the tarball from the cfitsio website!"
      exit 1
    fi
  fi

  # Check for the version number:
  VER=$(echo "${TARBALL}" | awk -Fcfitsio- '{ print $2 }' | awk -F.tar '{ print $1 }');
  echo "Version of cfitsio is: ${VER}"
fi



echo "Checking for old installation..."
if [ -d "cfitsio_v${VER}" ]; then
  cd cfitsio_v${VER}
  if [ -f COMPILE_SUCCESSFUL ]; then
    SAMEOPTIONS=$(cat COMPILE_SUCCESSFUL | grep -F -x -- "${CONFIGUREOPTIONS}")
    if [ "${SAMEOPTIONS}" == "" ]; then
      echo "The old installation used different compilation options..."
    fi
    SAMECOMPILER=$(cat COMPILE_SUCCESSFUL | grep -F -x -- "${COMPILEROPTIONS}")
    if [ "${SAMECOMPILER}" == "" ]; then
      echo "The old installation used a different compiler..."
    fi
    if ( [ "${SAMEOPTIONS}" != "" ] && [ "${SAMECOMPILER}" != "" ] ); then
      echo "Your already have a usable cfitsio version installed!"
      cd ..
      if [ "${ENVFILE}" != "" ]; then
        echo "Storing the cfitsio directory in the source script..."
        echo "CFITSIODIR=$(pwd)/cfitsio_v${VER}" >> ${ENVFILE}
      fi
      exit 0
    fi
  fi

  echo "Old installation is either incompatible or incomplete. Removing cfitsio_v${VER}"
  cd ..
  if echo "cfitsio_v${VER}" | grep -E '[ "]' >/dev/null; then
    echo "ERROR: Feeding my paranoia of having a \"rm -r\" in a script:"
    echo "       There should not be any spaces in the cfitsio version..."
    exit 1
  fi
  chmod -R u+w "cfitsio_v${VER}"
  rm -r "cfitsio_v${VER}"
else
   echo "No old installation present"
fi


echo "Unpacking..."
TARBALL=$(absolutefilename "${TARBALL}")
mkdir cfitsio_v${VER}
cd cfitsio_v${VER}
tar xfz "${TARBALL}" > /dev/null
if [ "$?" != "0" ]; then
  echo "ERROR: Something went wrong unpacking the cfitsio tarball!"
  exit 1
fi
mv cfitsio-${VER} cfitsio_v${VER}-source




echo "Configuring..."
# Minimze the LD_LIBRARY_PATH to prevent problems with multiple readline's
cd cfitsio_v${VER}-source
#export LD_LIBRARY_PATH=/usr/lib
sh configure ${CONFIGUREOPTIONS} --prefix=$(pwd)/.. > config.log 2>&1
if [ "$?" != "0" ]; then
  echo "ERROR: Something went wrong configuring cfitsio!"
  echo "       Check the file "$(pwd)"/config.log"
  exit 1
fi



# One thread by default due to parallel compile issues - raise it with --max-threads
CORES=$(numberofcores)
if [ "${CORES}" -gt "${MAXTHREADS}" ]; then
  CORES=${MAXTHREADS}
fi
echo "Using this number of cores for compilation: ${CORES}"

echo "Compiling..."
make -j${CORES} > build.log 2>&1
if [ "$?" != "0" ]; then
  echo "ERROR: Something went wrong while compiling cfitsio!"
  echo "       Check the file "$(pwd)"/build.log"
  exit 1
fi
ERRORS=$(cat build.log | grep -v "char \*\*\*" | grep -v "\_\_PRETTY\_FUNCTION\_\_\,\" \*\*\*" | grep "\ \*\*\*\ ")
if [ "${ERRORS}" == "" ]; then
  echo "Installing ..."
  make -j${CORES} install > install.log 2>&1
  INSTALLRESULT=$?
  # The log is searched as well as the exit status checked: make does not always report a
  # broken build, and not every failure prints a line the pattern below matches
  ERRORS=$(cat install.log | grep -v "char \*\*\*" | grep -v "\_\_PRETTY\_FUNCTION\_\_\,\" \*\*\*" | grep "\ \*\*\*\ ")
  if [ "${INSTALLRESULT}" != "0" ] || [ "${ERRORS}" != "" ]; then
    echo "ERROR: Errors occured during the installation. Check your install.log"
    echo "       Check the file "$(pwd)"/install.log"
    exit 1;
  fi
else
  echo "ERROR: Errors occured during the compilation. Check your build.log"
  echo "       Check the file "$(pwd)"/build.log"
  exit 1;
fi


echo "Store our success story..."
cd ..
rm -f COMPILE_SUCCESSFUL
echo "cfitsio compilation & installation successful" >> COMPILE_SUCCESSFUL
echo " " >> COMPILE_SUCCESSFUL
echo "* Configure options:" >> COMPILE_SUCCESSFUL
echo "${CONFIGUREOPTIONS}" >> COMPILE_SUCCESSFUL
echo " " >> COMPILE_SUCCESSFUL
echo "* Compile options:" >> COMPILE_SUCCESSFUL
echo "${COMPILEROPTIONS}" >> COMPILE_SUCCESSFUL
echo " " >> COMPILE_SUCCESSFUL



echo "Setting permissions..."
cd ..
chown -R ${USER}:${GROUP} cfitsio_v${VER}
chmod -R go+rX cfitsio_v${VER}

if [ "${ENVFILE}" != "" ]; then
  echo "Storing the cfitsio directory in the source script..."
  echo "CFITSIODIR=$(pwd)/cfitsio_v${VER}" >> ${ENVFILE}
fi


echo "Done!"
exit 0
