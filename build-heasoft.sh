#!/bin/bash

# This bash script is part of the MEGAlib & COSItools setup procedure.
# As such it is dual licenced under Apache 2.0 for COSItools and LGPL 3.0 for MEGAlib
#
# Development lead: Andreas Zoglauer
#
# Description:
# This script downloads, compiles, and installs HEASoft


# Path to this script

# Operating system type
OSTYPE=$(uname -s | awk '{print tolower($0)}')

# The basic compiler options
COMPILEROPTIONS=$(gcc --version | head -n 1)

# Additional configure options 
CONFIGUREOPTIONS=" "

# Components
COMPONENTS="ftools nustar Xspec"

# Comment this line in if you have trouble with readline
# CONFIGUREOPTIONS="--enable-readline "






confhelp() {
  echo ""
  echo "Building HEASoft"
  echo " "
  echo "Usage: ./build-heasoft.sh [options]";
  echo " "
  echo " "
  echo "Options:"
  echo "--tarball=[file name of HEASoft tar ball]"
  echo "    Use this tarball instead of downloading it from the HEASoft website"
  echo " "
  echo "--source-script=[file name of new environment script]"
  echo "    The source script which sets all environment variables for HEASoft."
  echo " "
  echo "--max-threads=[integer >=1 - default: 1]"
  echo "    The maximum number of threads to be used for compilation."
  echo "    The default is one thread due to parallel compile issues - raise it at your own risk."
  echo " "
  echo "--patch=[true/on/yes, false/off/no - default: false]"
  echo "    Apply internal HEASoft patches, if there are any for this version."
  echo " "
  echo "--help or -h"
  echo "    Show this help."
  echo " "
  echo " "
}

setuphelp() {
  if ( [[ ${SHELL} == *ash ]] || [[ ${SHELL} == *csh ]] ); then
    echo " "
    echo "If you are not using the source script,"
    echo "then you can use the following lines to setup HEASoft: "
    echo " "

    HEASOFTPATH=$(ls -d heasoft_v${VER}/*86*)
    if [[ ${SHELL} == *csh ]]; then
      echo "You seem to use a C shell variant so, in your \$HOME/.cshrc or \$HOME/.tcshrc do:"
      echo " "
      echo "setenv HEADAS "$(pwd)"/${HEASOFTPATH}"
      echo "alias heainit \"source \$HEADAS/headas-init.csh\""
      echo " "
      echo "And then also add \"heainit\" to your setup script or call it each time before you use this software package."
      echo " "
    elif [[ ${SHELL} == *ash ]]; then
      echo "You seem to use a bourne shell variant so, in your \$HOME/.bashrc or \$HOME/.login or \$HOME/.profile do:"
      echo " "
      echo "export HEADAS="$(pwd)"/${HEASOFTPATH}"
      echo "alias heainit=\"source \$HEADAS/headas-init.sh\""
      echo " "
      echo "And then also add \"heainit\" to your setup script or call it each time before you use this software package."
      echo " "
    fi
  fi
}


# Path to where this file is located
SETUPPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

# The shared helper functions, e.g. resolveoption
. "${SETUPPATH}/setup-helpers.sh"

# Every option this script accepts. Abbreviations are resolved against this list.
SETUPOPTIONS="tarball source-script patch max-threads help"

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
PATCH="false"

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
    patch)
      PATCH=$(optionvalue "${C}")
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

if ! BOOLEAN=$(booleanvalue "${PATCH}"); then
  echo " "
  echo "ERROR: Unknown value for the --patch option: ${PATCH}"
  echo "       Use true/on/yes or false/off/no"
  exit 1
fi
PATCH="${BOOLEAN}"
if [[ ${PATCH} == true ]]; then
  echo " * Apply internal HEASoft patches"
else
  echo " * Don't apply internal HEASoft patches"
fi


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


echo "Getting HEASoft..."
VER=""
if [ "${TARBALL}" != "" ]; then
  # Use given tarball
  echo "The given HEASoft tarball is ${TARBALL}"

  # Check if it has the correct version:
  VER=$(echo "${TARBALL}" | awk -Fheasoft- '{ print $2 }' | awk -Fsrc '{ print $1 }');
  echo "Version of HEASoft is: ${VER}"

  # Check if the tarball-provided version is within the range given in allowed-versions.txt
  if ! "${SETUPPATH}/check-heasoftversion.sh" --good-version=${VER} > /dev/null; then
    echo "ERROR: The HEASoft tarball does not contain an acceptable HEASoft version: ${VER}"
    "${SETUPPATH}/check-heasoftversion.sh" --good-version=${VER}
    exit 1
  fi
else
  # Download it

  echo "Looking for latest HEASoft version on the HEASoft website"

  # The tar balls are named heasoft-6.37.1src.tar.gz - newest first
  ALLTARBALLS=$(curl https://heasarc.gsfc.nasa.gov/FTP/software/lheasoft/release/ -sl | grep ">heasoft-" | grep "[0-9]src.tar.gz<" | awk -F">" '{ print $3 }' | awk -F"<" '{print $1 }' | sort -u -V -r)
  if [ "${ALLTARBALLS}" == "" ]; then
    echo "ERROR: Unable to find suitable HEASoft tar ball at the HEASoft website"
    exit 1
  fi

  # The newest version may be outside the range given in allowed-versions.txt, thus walk
  # down from the newest until one is acceptable
  TARBALL=""
  for T in ${ALLTARBALLS}; do
    V=$(echo "${T}" | awk -Fheasoft- '{ print $2 }' | awk -Fsrc '{ print $1 }')
    if "${SETUPPATH}/check-heasoftversion.sh" --good-version=${V} > /dev/null; then
      TARBALL=${T}
      break
    fi
    echo "Skipping HEASoft version ${V} - it is outside the supported version range"
  done
  if [ "${TARBALL}" == "" ]; then
    echo "ERROR: None of the HEASoft versions at the HEASoft website is within the supported version range"
    exit 1
  fi
  echo "Using HEASoft tar ball ${TARBALL}"

  # Check if it already exists locally
  REQUIREDOWNLOAD="true"
  if tarballisgood "${TARBALL}" "https://heasarc.gsfc.nasa.gov/FTP/software/lheasoft/release/${TARBALL}"; then
    REQUIREDOWNLOAD="false"
  fi

  if [ "${REQUIREDOWNLOAD}" == "true" ]; then
    echo "Starting the download."
    echo "If the download fails, you can continue it via the following command and then call this script again - it will use the downloaded file."
    echo " "
    echo "curl -fOL -C - https://heasarc.gsfc.nasa.gov/FTP/software/lheasoft/release/${TARBALL}"
    echo " "
    if ! downloadtarball "https://heasarc.gsfc.nasa.gov/FTP/software/lheasoft/release/${TARBALL}" "${TARBALL}"; then
      echo "ERROR: Unable to download the tarball from the HEASoft website!"
      exit 1
    fi
  fi

  # Check for the version number:
  VER=$(echo "${TARBALL}" | awk -Fheasoft- '{ print $2 }' | awk -Fsrc '{ print $1 }');
  echo "Version of HEASoft is: ${VER}"
fi



HEASOFTCORE=heasoft_v${VER}


echo "Checking for old installation..."
if [ -d "heasoft_v${VER}" ]; then
  cd heasoft_v${VER}
  if [ -f COMPILE_SUCCESSFUL ]; then
    SAMEOPTIONS=$(cat COMPILE_SUCCESSFUL | grep -F -x -- "${CONFIGUREOPTIONS}")
    if [ "${SAMEOPTIONS}" == "" ]; then
      echo "The old installation used different compilation options..."
    fi
    SAMECOMPILER=$(cat COMPILE_SUCCESSFUL | grep -F -x -- "${COMPILEROPTIONS}")
    if [ "${SAMECOMPILER}" == "" ]; then
      echo "The old installation used a different compiler..."
    fi
    SAMECOMPONENTS=$(cat COMPILE_SUCCESSFUL | grep -F -x -- "${COMPONENTS}")
    if [ "${SAMECOMPONENTS}" == "" ]; then
      echo "The old installation used different components..."
    fi

    SAMEPATCH=""
    PATCHPRESENT="no"
    if [ -f "${SETUPPATH}/patches/${HEASOFTCORE}.patch" ]; then
      PATCHPRESENT="yes"
      PATCHPRESENTMD5=$(openssl md5 "${SETUPPATH}/patches/${HEASOFTCORE}.patch" | awk -F" " '{ print $2 }')
    fi
    PATCHSTATUS=$(cat COMPILE_SUCCESSFUL | grep -- "^Patch")
    if [[ ${PATCHSTATUS} == Patch\ applied* ]]; then
      PATCHMD5=$(echo ${PATCHSTATUS} | awk -F" " '{ print $3 }')
    fi

    if [[ ${PATCH} == true ]]; then
      if [[ ${PATCHPRESENT} == yes ]] && [[ ${PATCHSTATUS} == Patch\ applied* ]] && [[ ${PATCHPRESENTMD5} == ${PATCHMD5} ]]; then
        SAMEPATCH="YES";
      elif [[ ${PATCHPRESENT} == no ]] && [[ ${PATCHSTATUS} == Patch\ not\ applied* ]]; then
        SAMEPATCH="YES";
      else
        echo "The old installation didn't use the same patch..."
        SAMEPATCH=""
      fi
    elif [[ ${PATCH} == false ]]; then
      if [[ ${PATCHSTATUS} == Patch\ not\ applied* ]] || [[ -z ${PATCHSTATUS}  ]]; then    # last one means empty
        SAMEPATCH="YES";
      else
        echo "The old installation used a patch, but now we don't want any..."
        SAMEPATCH=""
      fi
    fi

    if ( [ "${SAMEOPTIONS}" != "" ] && [ "${SAMECOMPILER}" != "" ] && [ "${SAMECOMPONENTS}" != "" ] && [ "${SAMEPATCH}" != "" ] ); then
      echo "Your already have a usable HEASoft version installed!"
      if [ "${ENVFILE}" != "" ]; then
        echo "Storing the HEASoft directory in the source script..."
        DIR=$(find $(pwd) -name "ftversion" | grep -v "heatools" | awk '{ print substr( $0, 1, length($0)-14) }')
        echo "HEASOFTDIR=${DIR}" >> ${ENVFILE}
      else
        cd ..
        setuphelp
      fi
      exit 0
    fi
  fi

  echo "Old installation is either incompatible or incomplete. Removing heasoft_v${VER}"
  cd ..
  if echo "heasoft_v${VER}" | grep -E '[ "]' >/dev/null; then
    echo "ERROR: Feeding my paranoia of having a \"rm -r\" in a script:"
    echo "       There should not be any spaces in the HEASoft version..."
    exit 1
  fi
  chmod -R u+w "heasoft_v${VER}"
  rm -r "heasoft_v${VER}"
else
   echo "No old installation present"
fi



echo "Unpacking..."
TARBALL=$(absolutefilename "${TARBALL}")
tar xfz "${TARBALL}" > /dev/null
if [ "$?" != "0" ]; then
  echo "ERROR: Something went wrong unpacking the HEASoft tarball!"
  exit 1
fi
mv heasoft-${VER} heasoft_v${VER}



PATCHAPPLIED="Patch not applied"
if [[ ${PATCH} == true ]]; then
  echo "Patching..."
  if [ -f "${SETUPPATH}/patches/${HEASOFTCORE}.patch" ]; then
    cd heasoft_v${VER}
    patch -p1 < "${SETUPPATH}/patches/${HEASOFTCORE}.patch"
    if [ "$?" != "0" ]; then
      echo "ERROR: Something went wrong applying the HEASoft patch!"
      exit 1
    fi
    cd ..
    PATCHMD5=$(openssl md5 "${SETUPPATH}/patches/${HEASOFTCORE}.patch" | awk -F" " '{ print $2 }')
    PATCHAPPLIED="Patch applied ${PATCHMD5}"
    echo "Applied patch: ${SETUPPATH}/patches/${HEASOFTCORE}.patch"
  else
    echo "No required patch found for this version of HEASoft"
  fi
fi



echo "Configuring..."
# Minimze the LD_LIBRARY_PATH to prevent problems with multiple readline's
cd heasoft_v${VER}/BUILD_DIR
#export LD_LIBRARY_PATH=/usr/lib
sh configure ${CONFIGUREOPTIONS} --with-components="${COMPONENTS}" > config.log 2>&1
if [ "$?" != "0" ]; then
  echo "ERROR: Something went wrong configuring HEASoft!"
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
  echo "ERROR: Something went wrong while compiling HEASoft!"
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


# Create a libcfitsio.so, etc. link
LIBDIR=""
for D in ../*libc*/lib; do
  if [ -d "${D}" ]; then
    LIBDIR="${D}"
    break
  fi
done
if [[ ${LIBDIR} != "" ]]; then
  cd "${LIBDIR}"
  if [ "$?" != "0" ]; then
    echo "ERROR: Unable to enter the HEASoft library directory ${LIBDIR}"
    exit 1
  fi
  CFITSIO=$(find . \( -name "libcfitsio.so" -o -name "libcfitsio.a" -o -name "libcfitsio.dylib" -o -name "libcfitsio.dll" \))
  LONGCFITSIO=$(find . \( -name "libcfitsio_*.so" -o -name "libcfitsio_*.a" -o -name "libcfitsio_*.dylib" -o -name "libcfitsio_*.dll" \))
  if ( [ "${CFITSIO}" == "" ] && [ "${LONGCFITSIO}" != "" ] ); then
    # find can return several matches, e.g. a shared and a static library - link the first
    LONGCFITSIO=$(echo "${LONGCFITSIO}" | head -1)
    LONGCFITSIO=$(basename "${LONGCFITSIO}")

    # The name is e.g. libcfitsio_4.6.3.dylib and HEASoft looks for libcfitsio.dylib, thus
    # drop the version but keep the extension. The version has a varying number of parts,
    # which is why this cannot simply count the fields between the dots.
    NEWCFITSIO=$(echo "${LONGCFITSIO}" | sed -n 's/^\(libcfitsio\)_[0-9][0-9.]*\.\([A-Za-z]*\)$/\1.\2/p')
    if [[ ${NEWCFITSIO} == "" ]]; then
      echo "ERROR: Unable to derive the cfitsio link name from ${LONGCFITSIO}"
      exit 1
    fi
    ln -s "${LONGCFITSIO}" "${NEWCFITSIO}"
  fi
  cd ..
fi


echo "Store our success story..."
cd ..
rm -f COMPILE_SUCCESSFUL
echo "HEASoft compilation & installation successful" >> COMPILE_SUCCESSFUL
echo " " >> COMPILE_SUCCESSFUL
echo "* Configure options:" >> COMPILE_SUCCESSFUL
echo "${CONFIGUREOPTIONS}" >> COMPILE_SUCCESSFUL
echo " " >> COMPILE_SUCCESSFUL
echo "* Compile options:" >> COMPILE_SUCCESSFUL
echo "${COMPILEROPTIONS}" >> COMPILE_SUCCESSFUL
echo " " >> COMPILE_SUCCESSFUL
echo "* Components:" >> COMPILE_SUCCESSFUL
echo "${COMPONENTS}" >> COMPILE_SUCCESSFUL
echo " " >> COMPILE_SUCCESSFUL
echo "* Patch application status:" >> COMPILE_SUCCESSFUL
echo "${PATCHAPPLIED}" >> COMPILE_SUCCESSFUL
echo " " >> COMPILE_SUCCESSFUL


echo "Setting permissions..."
cd ..
chown -R ${USER}:${GROUP} heasoft_v${VER}
chmod -R go+rX heasoft_v${VER}

if [ "${ENVFILE}" != "" ]; then
  echo "Storing the HEASoft directory in the source script..."
  DIR=$(find $(pwd)/heasoft_v${VER} -name "ftversion" | grep -v "heatools" | awk '{ print substr( $0, 1, length($0)-14) }')
  echo "HEASOFTDIR=${DIR}" >> ${ENVFILE}
else
  setuphelp
fi


echo "Done!"
exit 0
