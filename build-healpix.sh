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
COMPILEROPTIONS=$(gcc --version | head -n 1)

# Additional configure options 
CONFIGUREOPTIONS=" "


# An upper limit only - the number of cores is determined further below and capped by this
MAXTHREADS=1024


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
  echo "--source-script=[file name of new environment script]"
  echo "    The source script which sets all environment variables for healpix."
  echo " "
  echo "--max-threads=[integer >=1 - default: the number of cores in your system]"
  echo "    The maximum number of threads to be used for compilation."
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



echo "Getting healpix..."
VER=""
if [ "${TARBALL}" != "" ]; then
  # Use given tarball
  echo "The given healpix tarball is ${TARBALL}"

  # Check if it has the correct version:
  # The official archive is named e.g. Healpix_3.83_2024Nov13.tar.gz
  VER=$(basename "${TARBALL}" | sed -n 's/^[Hh]ealpix[-_]\([0-9][0-9.]*[0-9]\).*/\1/p')
  if [[ ${VER} == "" ]]; then
    echo "ERROR: Unable to determine the healpix version from the tarball name ${TARBALL}"
    exit 1
  fi
  echo "Version of healpix is: ${VER}"

  # Check if the tarball-provided version is within the range given in allowed-versions.txt
  if ! "${SETUPPATH}/check-healpixversion.sh" --good-version=${VER} > /dev/null; then
    echo "ERROR: The healpix tarball does not contain an acceptable healpix version: ${VER}"
    "${SETUPPATH}/check-healpixversion.sh" --good-version=${VER}
    exit 1
  fi
else
  # Download it

  # The desired version is simply the highest version
  echo "Looking for latest healpix version on the healpix website"

  # Get the versions on offer, such as 3.83 - the tar ball looks like: Healpix_3.83_2024Nov13.tar.gz
  ALLVER=$(curl -s https://sourceforge.net/projects/healpix/files/ | grep -oE 'Healpix_[0-9]+\.[0-9]+' | cut -d'_' -f2 | sort -u -V -r)
  if [[ ${ALLVER} == "" ]]; then
    echo "ERROR: Unable to find any healpix version at the healpix website"
    exit 1
  fi

  # The newest version may be outside the range given in allowed-versions.txt, thus walk
  # down from the newest until one is acceptable
  VER=""
  for V in ${ALLVER}; do
    if "${SETUPPATH}/check-healpixversion.sh" --good-version=${V} > /dev/null; then
      VER=${V}
      break
    fi
    echo "Skipping healpix version ${V} - it is outside the supported version range"
  done
  if [[ ${VER} == "" ]]; then
    echo "ERROR: None of the healpix versions at the healpix website is within the supported version range"
    "${SETUPPATH}/check-healpixversion.sh" --good-version=$(echo ${ALLVER} | awk '{ print $1 }')
    exit 1
  fi
  echo "Using healpix version ${VER}"
  
  # Get specific tar ball, e.g., Healpix_3.83_2024Nov13.tar.gz
  TARBALL=$(curl -s "https://sourceforge.net/projects/healpix/files/Healpix_${VER}/" | grep -oE 'Healpix_[0-9.]+_20[0-9A-Za-z]+\.tar\.gz' | head -1)
  if [ "${TARBALL}" == "" ]; then
    echo "ERROR: Unable to find suitable healpix tar ball at the healpix website"
    exit 1
  fi
  echo "Using healpix tar ball ${TARBALL}"
  LINK="https://downloads.sourceforge.net/project/healpix/Healpix_${VER}/${TARBALL}"

  # Check if it already exists locally
  REQUIREDOWNLOAD="true"
  if tarballisgood "${TARBALL}" "${LINK}"; then
    REQUIREDOWNLOAD="false"
  fi

  if [ "${REQUIREDOWNLOAD}" == "true" ]; then
    echo "Starting the download."
    echo " "
    if ! downloadtarball "${LINK}" "${TARBALL}"; then
      echo "ERROR: Unable to download the tarball from the healpix website!"
      exit 1
    fi
  fi

  # Check for the version number:
  echo "Version of healpix is: ${VER}"
fi



echo "Checking for old installation..."
if [ -d "healpix_v${VER}" ]; then
  cd healpix_v${VER}
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
      echo "Your already have a usable healpix version installed!"
      cd ..
      if [ "${ENVFILE}" != "" ]; then
        echo "Storing the healpix directory in the source script..."
        echo "HEALPIXDIR=$(pwd)/healpix_v${VER}" >> ${ENVFILE}
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
TARBALL=$(absolutefilename "${TARBALL}")
mkdir healpix_v${VER}
cd healpix_v${VER}
MAINDIR=$(pwd)



echo "Unpacking..."
tar xfz "${TARBALL}" 2> /dev/null
if [ "$?" != "0" ]; then
  echo "ERROR: Something went wrong unpacking the healpix tarball!"
  exit 1
fi
mv Healpix_${VER} healpix_v${VER}-source



echo "Building helper library libsharp..."
cd "${MAINDIR}/healpix_v${VER}-source/src/common_libraries/libsharp"
if [ ! -f "./configure" ]; then 
  autoreconf -i
fi
sh configure "--prefix=${MAINDIR}" > config_libsharp.log 2>&1
if [ "$?" != "0" ]; then
  echo "ERROR: Something went wrong configuring libsharp!"
  echo "       Check the file "$(pwd)"/config_libsharp.log"
  exit 1
fi

CORES=$(numberofcores)
if [ "${CORES}" -gt "${MAXTHREADS}" ]; then
  CORES=${MAXTHREADS}
fi
echo "Using this number of cores for compilation: ${CORES}"

make -j${CORES} > build_libsharp.log 2>&1
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
cd "${MAINDIR}"



echo "Configuring..."
cd "${MAINDIR}/healpix_v${VER}-source/src/cxx"
make distclean 2>/dev/null || true
export PKG_CONFIG_PATH=${PKG_CONFIG_PATH}:${MAINDIR}/lib/pkgconfig
sh configure ${CONFIGUREOPTIONS} "--prefix=${MAINDIR}" > config.log 2>&1
if [ "$?" != "0" ]; then
  echo "ERROR: Something went wrong configuring healpix!"
  echo "       Check the file "$(pwd)"/config.log"
  exit 1
fi



echo "Compiling..."
make -j${CORES} > build.log 2>&1
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
cd "${MAINDIR}"
rm -f COMPILE_SUCCESSFUL
echo "Healpix compilation & installation successful" >> COMPILE_SUCCESSFUL
echo " " >> COMPILE_SUCCESSFUL
echo "* Configure options:" >> COMPILE_SUCCESSFUL
echo "${CONFIGUREOPTIONS}" >> COMPILE_SUCCESSFUL
echo " " >> COMPILE_SUCCESSFUL
echo "* Compile options:" >> COMPILE_SUCCESSFUL
echo "${COMPILEROPTIONS}" >> COMPILE_SUCCESSFUL
echo " " >> COMPILE_SUCCESSFUL



echo "Setting permissions..."
cd "${MAINDIR}/.."
chown -R ${USER}:${GROUP} healpix_v${VER}
chmod -R go+rX healpix_v${VER}

if [ "${ENVFILE}" != "" ]; then
  echo "Storing the healpix directory in the source script..."
  echo "HEALPIXDIR=$(pwd)/healpix_v${VER}" >> ${ENVFILE}
fi


echo "Done!"
exit 0
