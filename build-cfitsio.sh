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
COMPILEROPTIONS=`gcc --version | head -n 1`

# Additional configure options 
CONFIGUREOPTIONS=" "

# Comment this line in if you have trouble with readline
# CONFIGUREOPTIONS="--enable-readline "

# Check if some of the frequently used software is installed:
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

MAXTHREADS=1;
if [[ ${OSTYPE} == *arwin* ]]; then
  MAXTHREADS=`sysctl -n hw.logicalcpu_max`
elif [[ ${OSTYPE} == *inux* ]]; then
  MAXTHREADS=`grep processor /proc/cpuinfo | wc -l`
fi
if [ "$?" != "0" ]; then
  MAXTHREADS=1
fi


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
  echo "--sourcescript=[file name of new environment script]"
  echo "    The source script which sets all environment variables for cfitsio."
  echo " "
  echo "--help or -h"
  echo "    Show this help."
  echo " "
  echo " "
}


# Store command line
CMD=""
while [[ $# -gt 0 ]] ; do
    CMD="${CMD} $1"
    shift
done

# Check for help
for C in ${CMD}; do
  if [[ ${C} == *-h* ]]; then
    echo ""
    confhelp
    exit 0
  fi
done

TARBALL=""
ENVFILE=""

# Overwrite default options with user options:
for C in ${CMD}; do
  if [[ ${C} == *-t*=* ]]; then
    TARBALL=`echo ${C} | awk -F"=" '{ print $2 }'`
    echo "Using this tarball: ${TARBALL}"
  elif [[ ${C} == *-s* ]]; then
    ENVFILE=`echo ${C} | awk -F"=" '{ print $2 }'`
    echo "Using this environment file: ${ENVFILE}"
  elif [[ ${C} == *-h* ]]; then
    echo ""
    confhelp
    exit 0
  else
    echo ""
    echo "ERROR: Unknown command line option: ${C}"
    echo "       See \"$0 --help\" for a list of options"
    exit 1
  fi
done


echo "Getting cfitsio..."
VER=""
if [ "${TARBALL}" != "" ]; then
  # Use given tarball
  echo "The given cfitsio tarball is ${TARBALL}"

  # Check if it has the correct version:
  VER=`echo ${TARBALL} | awk -Fcfitsio- '{ print $2 }' | awk -Fsrc '{ print $1 }'`;
  echo "Version of cfitsio is: ${VER}"
else
  # Download it

  # The desired version is simply the highest version
  echo "Looking for latest cfitsio version on the cfitsio website"

  # Now check root repository for the given version:
  #TARBALL=`curl ftp://legacy.gsfc.nasa.gov/software/lcfitsio/release/ -sl | grep "^cfitsio\-" | grep "[0-9]src.tar.gz$"`
  TARBALL=$(curl https://heasarc.gsfc.nasa.gov/FTP/software/fitsio/c/ -sl | grep ">cfitsio-" | grep "[0-9].tar.gz<" | awk -F">" '{ print $3 }' | awk -F"<" '{print $1 }' | sort | tail -n 1)
  if [ "${TARBALL}" == "" ]; then
    echo "ERROR: Unable to find suitable cfitsio tar ball at the cfitsio website"
    exit 1
  fi
  echo "Using cfitsio tar ball ${TARBALL}"

  # Check if it already exists locally
  REQUIREDOWNLOAD="true"
  if [ -f "${TARBALL}" ]; then
    # ... and has the same size
    LOCALSIZE=$(wc -c < ${TARBALL} | tr -d ' ')
    REMOTESIZE=$(curl -s --head https://heasarc.gsfc.nasa.gov/FTP/software/fitsio/c/${TARBALL} | grep -i "Content-Length" | awk '{print $2}' | sed 's/[^0-9]*//g') 
    if [ "$?" != "0" ]; then
      echo "ERROR: Unable to determine remote tarball size"
      exit 1
    fi
    IDENTICAL=`echo ${REMOTESIZE} | grep ${LOCALSIZE}`
    if [ "${IDENTICAL}" != "" ]; then
      REQUIREDOWNLOAD="false"
      echo "File is already present and has same size, thus no download required!"
    else
      echo "Remote and local file sizes are different (local: ${LOCALSIZE} vs. remote: ${REMOTESIZE}). Downloading it."
    fi
  else
    echo "Tarball does not exist, downloading it"
  fi

  if [ "${REQUIREDOWNLOAD}" == "true" ]; then
    echo "Starting the download."
    echo "If the download fails, you can continue it via the following command and then call this script again - it will use the downloaded file."
    echo " "
    echo "curl -O -C - https://heasarc.gsfc.nasa.gov/FTP/software/lcfitsio/release/${TARBALL}"
    echo " "
    curl -O https://heasarc.gsfc.nasa.gov/FTP/software/fitsio/c/${TARBALL}
    if [ "$?" != "0" ]; then
      echo "ERROR: Unable to download the tarball from the cfitsio website!"
      exit 1
    fi
  fi

  # Check for the version number:
  VER=`echo ${TARBALL} | awk -Fcfitsio- '{ print $2 }' | awk -F.tar '{ print $1 }'`;
  echo "Version of cfitsio is: ${VER}"
fi



echo "Checking for old installation..."
if [ -d cfitsio_v${VER} ]; then
  cd cfitsio_v${VER}
  if [ -f COMPILE_SUCCESSFUL ]; then
    SAMEOPTIONS=`cat COMPILE_SUCCESSFUL | grep -F -x -- "${CONFIGUREOPTIONS}"`
    if [ "${SAMEOPTIONS}" == "" ]; then
      echo "The old installation used different compilation options..."
    fi
    SAMECOMPILER=`cat COMPILE_SUCCESSFUL | grep -F -x -- "${COMPILEROPTIONS}"`
    if [ "${SAMECOMPILER}" == "" ]; then
      echo "The old installation used a different compiler..."
    fi
    if ( [ "${SAMEOPTIONS}" != "" ] && [ "${SAMECOMPILER}" != "" ] ); then
      echo "Your already have a usable cfitsio version installed!"
      cd ..
      if [ "${ENVFILE}" != "" ]; then
        echo "Storing the cfitsio directory in the source script..."
        echo "CFITSIODIR=$(pwd)/cfitsio_v${VER}" >> ${ENVFILE}
      else
        setuphelp
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
mkdir cfitsio_v${VER}
cd cfitsio_v${VER}
tar xfz ../${TARBALL} > /dev/null
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
  echo "       Check the file "`pwd`"/config.log"
  exit 1
fi



echo "Compiling..."
make -j1 > build.log 2>&1
if [ "$?" != "0" ]; then
  echo "ERROR: Something went wrong while compiling cfitsio!"
  echo "       Check the file "`pwd`"/build.log"
  exit 1
fi
ERRORS=$(cat build.log | grep -v "char \*\*\*" | grep -v "\_\_PRETTY\_FUNCTION\_\_\,\" \*\*\*" | grep "\ \*\*\*\ ")
if [ "${ERRORS}" == "" ]; then
  echo "Installing ..."
  make -j1 install > install.log 2>&1
  ERRORS=$(cat install.log | grep -v "char \*\*\*" | grep -v "\_\_PRETTY\_FUNCTION\_\_\,\" \*\*\*" | grep "\ \*\*\*\ ")
  if [ "${ERRORS}" != "" ]; then
    echo "ERROR: Errors occured during the installation. Check your install.log"
    echo "       Check the file "`pwd`"/install.log"
    exit 1;
  fi
else
  echo "ERROR: Errors occured during the compilation. Check your build.log"
  echo "       Check the file "`pwd`"/build.log"
  exit 1;
fi


echo "Store our success story..."
cd ..
rm -f COMPILE_SUCCESSFUL
echo "${CONFIGUREOPTIONS}" >> COMPILE_SUCCESSFUL
echo "${COMPILEROPTIONS}" >> COMPILE_SUCCESSFUL



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
