#!/bin/bash

# This bash script is part of the MEGAlib & COSItools setup procedure.
# As such it is dual licenced under Apache 2.0 for COSItools and LGPL 3.0 for MEGAlib
#
# Development lead: Andreas Zoglauer
#
# Description:
# This script downloads, compiles, and installs healpix


# Operating system type
OSTYPE=$(uname -s | awk '{print tolower($0)}')

# The basic compiler options
COMPILEROPTIONS=`gcc --version | head -n 1`

# Additional configure options 
CONFIGUREOPTIONS=" "


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
  echo "Building healpix"
  echo " "
  echo "Usage: ./build-healpix.sh [options]";
  echo " "
  echo " "
  echo "Options:"
  echo "--tarball=[file name of the healpix tar ball]"
  echo "    Use this tarball instead of downloading it from the healpix website"
  echo " "
  echo "--sourcescript=[file name of new environment script]"
  echo "    The source script which sets all environment variables for healpix."
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



echo "Getting healpix..."
VER=""
if [ "${TARBALL}" != "" ]; then
  # Use given tarball
  echo "The given healpix tarball is ${TARBALL}"

  # Check if it has the correct version:
  VER=`echo ${TARBALL} | awk -Fhealpix- '{ print $2 }' | awk -Fsrc '{ print $1 }'`;
  echo "Version of healpix is: ${VER}"
else
  # Download it

  # The desired version is simply the highest version
  echo "Looking for latest healpix version on the healpix website"

  # Get the huighest version such as 3.83 - the tar ball looks like: Healpix_3.83_2024Nov13.tar.gz
  VER=$(curl -s https://sourceforge.net/projects/healpix/files/ | grep -oP 'Healpix_[0-9]+\.[0-9]+' | head -1 | cut -d'_' -f2)
  
  # Get specific tar ball, e.g., Healpix_3.83_2024Nov13.tar.gz
  TARBALL=$(curl -s "https://sourceforge.net/projects/healpix/files/Healpix_${VER}/" | grep -oP 'Healpix_[0-9.]+_20[0-9A-Za-z]+\.tar\.gz' | head -1)
  if [ "${TARBALL}" == "" ]; then
    echo "ERROR: Unable to find suitable healpix tar ball at the healpix website"
    exit 1
  fi
  echo "Using healpix tar ball ${TARBALL}"
  LINK="https://downloads.sourceforge.net/project/healpix/Healpix_${VER}/${TARBALL}"

  # Check if it already exists locally
  REQUIREDOWNLOAD="true"
  if [ -f "${TARBALL}" ]; then
    # ... and has the same size
    LOCALSIZE=$(wc -c < ${TARBALL} | tr -d ' ')
    REMOTESIZE=$(curl -L -I ${LINK} | grep -i "Content-Length" | awk '{print $2}' | sed 's/[^0-9]*//g') 
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
    echo " "
    curl -L ${LINK} -o ${TARBALL}
    if [ "$?" != "0" ]; then
      echo "ERROR: Unable to download the tarball from the healpix website!"
      exit 1
    fi
  fi

  # Check for the version number:
  echo "Version of healpix is: ${VER}"
fi



echo "Checking for old installation..."
if [ -d healpix_v${VER} ]; then
  cd healpix_v${VER}
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
      echo "Your already have a usable healpix version installed!"
      cd ..
      if [ "${ENVFILE}" != "" ]; then
        echo "Storing the healpix directory in the source script..."
        echo "HEALPIXDIR=$(pwd)/healpix_v${VER}" >> ${ENVFILE}
      else
        setuphelp
      fi
      exit 0
    fi
  fi

  echo "Old installation is either incompatible or incomplete. Removing healpix_v${VER}"
  cd ..
  if echo "healpix_v${VER}" | grep -E '[ "]' >/dev/null; then
    echo "ERROR: Feeding my paranoia of having a \"rm -r\" in a script:"
    echo "       There should not be any spaces in the healpix version..."
    exit 1
  fi
  chmod -R u+w "healpix_v${VER}"
  rm -r "healpix_v${VER}"
else
   echo "No old installation present"
fi



echo "Creating main directory"
mkdir healpix_v${VER}
cd healpix_v${VER}
MAINDIR=$(pwd)



echo "Unpacking..."
tar xfz ../${TARBALL} 2> /dev/null
if [ "$?" != "0" ]; then
  echo "ERROR: Something went wrong unpacking the healpix tarball!"
  exit 1
fi
mv Healpix_${VER} healpix_v${VER}-source



echo "Building helper library libsharp..."
cd ${MAINDIR}/healpix_v${VER}-source/src/common_libraries/libsharp
if [ ! -f "./configure" ]; then 
  autoreconf -i
fi
sh configure --prefix=${MAINDIR} > config_libsharp.log 2>&1
if [ "$?" != "0" ]; then
  echo "ERROR: Something went wrong configuring libsharp!"
  echo "       Check the file "$(pwd)"/config_libsharp.log"
  exit 1
fi
make -j${MAXTHREADS} > build_libsharp.log 2>&1
if [ "$?" != "0" ]; then
  echo "ERROR: Something went wrong compiling libsharp!"
  echo "       Check the file "$(pwd)"/build_libsharp.log"
  exit 1
fi
make install > install_libsharp.log 2>&1
if [ "$?" != "0" ]; then
  echo "ERROR: Something went wrong installing libsharp!"
  echo "       Check the file "$(pwd)"/install_libsharp.log"
  exit 1
fi
cd ${MAINDIR}



echo "Configuring..."
# Minimze the LD_LIBRARY_PATH to prevent problems with multiple readline's
cd ${MAINDIR}/healpix_v${VER}-source/src/cxx

make distclean 2>/dev/null || true

export SHARP_INCDIR=${MAINDIR}/include
export SHARP_LIBDIR=${MAINDIR}/lib

if [[ "${ENVFILE}" != "" ]]; then
  HEASOFTDIR=$(cat ${ENVFILE} | grep HEASOFTDIR)
  if [[ ${HEASOFTDIR} != "" ]]; then
    export CFITSIO_INCDIR=${HEASOFTDIR}/include
    export CFITSIO_LIBDIR=${HEASOFTDIR}/lib
  fi
fi 

sh configure ${CONFIGUREOPTIONS} --prefix=${MAINDIR} > config.log 2>&1
if [ "$?" != "0" ]; then
  echo "ERROR: Something went wrong configuring healpix!"
  echo "       Check the file "$(pwd)"/config.log"
  exit 1
fi



echo "Compiling..."
make -j${MAXTHREADS} > build.log 2>&1
if [ "$?" != "0" ]; then
  echo "ERROR: Something went wrong while compiling healpix!"
  echo "       Check the file "$(pwd)"/build.log"
  exit 1
fi



echo "Installing ..."
make install > install.log 2>&1
if [ "$?" != "0" ]; then
  echo "ERROR: Something went wrong installing healpix!"
  echo "       Check the file "$(pwd)"/install.log"
  exit 1;
fi



echo "Store our success story..."
cd ${MAINDIR}
rm -f COMPILE_SUCCESSFUL
echo "${CONFIGUREOPTIONS}" >> COMPILE_SUCCESSFUL
echo "${COMPILEROPTIONS}" >> COMPILE_SUCCESSFUL



echo "Setting permissions..."
cd ${MAINDIR}/..
chown -R ${USER}:${GROUP} healpix_v${VER}
chmod -R go+rX healpix_v${VER}

if [ "${ENVFILE}" != "" ]; then
  echo "Storing the healpix directory in the source script..."
  echo "HEALPIXDIR=$(pwd)/healpix_v${VER}" >> ${ENVFILE}
fi


echo "Done!"
exit 0






exit


# --- Step 1: Versioning and Paths ---
# We use 3.83 as the stable release for COSI integration
HPX_VER="3.83"
HPX_DATE="2024Nov13"
TARBALL="Healpix_${HPX_VER}_${HPX_DATE}.tar.gz"
INSTALL_DIR="Healpix_${HPX_VER}"

# Ensure COSITOOLS is defined
if [ -z "$COSITOOLS" ]; then
  echo "Error: The COSITOOLS environment variable is not set."
  echo "Please source your cosi-setup environment first."
  exit 1
fi

# Path for healpix (standard COSI setup puts it here)
healpix_PATH=$COSITOOLS/healpix

# --- Step 2: Download and Extract ---
cd $COSITOOLS

if [ ! -f $TARBALL ]; then
  echo "Downloading HEALPix ${HPX_VER}..."
  wget https://downloads.sourceforge.net/project/healpix/Healpix_${HPX_VER}/${TARBALL}
fi

if [ ! -d $INSTALL_DIR ]; then
  echo "Extracting HEALPix..."
  # Silence metadata noise common in SourceForge tarballs
  tar -xzf $TARBALL 2>/dev/null || tar -xzf $TARBALL
fi

cd $INSTALL_DIR

# --- Step 3: Build Libsharp ---
# Required for C++ components
echo "Building Libsharp..."
cd src/common_libraries/libsharp
if [ ! -f "./configure" ]; then autoreconf -i; fi
./configure --prefix=$COSITOOLS/healpix
make -j$(nproc)
make install
cd ../../..

# --- Step 4: Build C++ Components ---
echo "Building HEALPix C++..."
cd src/cxx

# Cleaning for fresh build
make distclean 2>/dev/null || true

# Point to COSI-specific healpix and our new libsharp
export healpix_INCDIR=$healpix_PATH/include
export healpix_LIBDIR=$healpix_PATH/lib
export SHARP_INCDIR=$COSITOOLS/healpix/include
export SHARP_LIBDIR=$COSITOOLS/healpix/lib

./configure --prefix=$COSITOOLS/healpix

make -j$(nproc)
make install
cd ../..

# --- Step 5: Build C Components ---
echo "Building HEALPix C..."
cd src/C/autotools
if [ ! -f "./configure" ]; then autoreconf -i; fi

# Point C build to healpix
./configure --prefix=$COSITOOLS/healpix --with-healpix=$healpix_PATH
make -j$(nproc)
make install
cd ../../..

echo "--------------------------------------------------"
echo "HEALPix build complete and installed in $COSITOOLS/healpix"
echo "--------------------------------------------------"
