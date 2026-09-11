#!/bin/bash

# This bash script is part of the MEGAlib & COSItools setup procedure.
# As such it is dual licenced under Apache 2.0 for COSItools and LGPL 3.0 for MEGAlib
#
# Development lead: Andreas Zoglauer
#
# Description:
# This script downloads, compiles, and installs Geant4



# Operating system type
OSTYPE=$(uname -s | awk '{print tolower($0)}')

# Start with the configure options, since we want to compare them to what was done previously
CONFIGUREOPTIONS=""
# On Linux use the default gcc compiler, but not on mac
if [[ $(uname -a) != *arwin* ]]; then
  type g++ >/dev/null 2>&1
  if [ $? -eq 0 ]; then
    # echo "g++ compiler found - using it as default!";
    CONFIGUREOPTIONS="-DCMAKE_C_COMPILER=gcc -DCMAKE_CXX_COMPILER=g++"
  fi
fi
CONFIGUREOPTIONS="${CONFIGUREOPTIONS} -DCMAKE_INSTALL_PREFIX=.. -DGEANT4_USE_GDML=ON -DGEANT4_INSTALL_DATA=ON -DGEANT4_USE_OPENGL_X11=OFF -DGEANT4_INSTALL_DATA_TIMEOUT=14400 -DGEANT4_USE_SYSTEM_EXPAT=OFF -DCMAKE_CXX_STANDARD=17"
CONFIGUREOPTIONS+=" -DCMAKE_POLICY_VERSION_MINIMUM=3.5"
CONFIGUREOPTIONS+=" -DGEANT4_USE_SYSTEM_ZLIB=ON"

# No deprecated and developer warnings - we are not the maintainers of the cmake files
CONFIGUREOPTIONS+=" -Wno-dev -DCMAKE_WARN_DEPRECATED=OFF"

# Reduce the warning messages:
WARNINGS="-Wno-shadow -Wno-implicit-fallthrough -Wno-overloaded-virtual -Wno-deprecated-copy -Wno-unused-result -Wno-format-overflow="

COMPILEROPTIONS=`gcc --version | head -n 1`

# The Geant4 website from which to download the tarball
WEBSITE="https://geant4-data.web.cern.ch/releases"


confhelp() {
  echo ""
  echo "Building GEANT4"
  echo " " 
  echo "Usage: ./build-geant4.sh [options]";
  echo " "
  echo " "
  echo "Options:"
  echo "--tarball=[file name of Geant4 tarball]"
  echo "    Use this tarball instead of downloading it from the Geant4 website" 
  echo " "
  echo "--geant4-version=[e.g. 10.02 (but not 10.02.p03)]"
  echo "    Specifiy the Geant4 version (ignores the requested version), if empty read he default version stated oin the setup scripts"
  echo " "
  echo "--source-script=[file name of new environment script]"
  echo "    The source script which sets all environment variables for Geant4." 
  echo " "
  echo "--debug=[off/no, on/yes, strong/hard - default: off]"
  echo "    Compile with degugging options."
  echo "    The strong level is the same as on here - it only differs for MEGAlib itself."
  echo " "
  echo "--keep-environment-as-is=[true/on/yes, false/off/no - default: false]"
  echo "    By default all relevant environment paths (such as LD_LIBRRAY_PATH, CPATH) are reset to empty to avoid most libray conflicts."
  echo "    This flag toggles this behaviour and lets you decide to keep your environment or not."
  echo " "
  echo "--max-threads=[integer >=1 - default: the number of cores in your system]"
  echo "    The maximum number of threads to be used for compilation. Default is the number of cores in your system."
  echo " "
  echo "--patch=[true/on/yes, false/off/no - default: false]"
  echo "    Apply Geant4 patches, if there are any."
  echo " "
  echo "--cleanup=[true/on/yes, false/off/no - default: false]"
  echo "    Remove intermediate build files"
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
SETUPOPTIONS="tarball source-script max-threads debug patch cleanup geant4-version keep-environment-as-is help"

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
MAXTHREADS=1024
WANTEDVERSION=""
PATCH="false"
DEBUG="off"
DEBUGSTRING=""
DEBUGOPTIONS=""
PATCH="false"
CLEANUP="false"
KEEPENVASIS="false"

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
      ;;
    source-script)
      ENVFILE=$(optionvalue "${C}")
      echo "Using this environment file: ${ENVFILE}"
      ;;
    max-threads)
      MAXTHREADS=$(optionvalue "${C}")
      ;;
    debug)
      DEBUG=$(optionvalue "${C}")
      ;;
    patch)
      PATCH=$(optionvalue "${C}")
      ;;
    cleanup)
      CLEANUP=$(optionvalue "${C}")
      ;;
    geant4-version)
      WANTEDVERSION=$(optionvalue "${C}")
      ;;
    keep-environment-as-is)
      KEEPENVASIS=$(optionvalue "${C}")
      ;;
    help)
      echo ""
      confhelp
      exit 0
      ;;
  esac
done



echo ""
echo ""
echo ""
echo "Setting up Geant4..."
echo ""
echo "Verifying chosen configuration options:"
echo ""

if [ "${TARBALL}" != "" ]; then
  if [[ ! -f "${TARBALL}" ]]; then
    echo "ERROR: The chosen tarball cannot be found: ${TARBALL}"
    exit 1     
  else   
    echo " * Using this tarball: ${TARBALL}"    
  fi
fi


if [ "${ENVFILE}" != "" ]; then
  if [[ ! -f "${ENVFILE}" ]]; then
    echo "ERROR: The chosen environment file cannot be found: ${ENVFILE}"
    exit 1     
  else   
    echo " * Using this environment file: ${ENVFILE}"    
  fi
fi


if [[ ! ${MAXTHREADS} =~ ^[0-9]+$ ]]; then
  echo "ERROR: The maximum number of threads must be number and not ${MAXTHREADS}!"
  exit 1
fi
if [ "${MAXTHREADS}" -le "0" ]; then
  echo "ERROR: The maximum number of threads must be at least 1 and not ${MAXTHREADS}!"
  exit 1
else 
  echo " * Using this maximum number of threads: ${MAXTHREADS}"
fi


DEBUG=`echo ${DEBUG} | tr '[:upper:]' '[:lower:]'`
if ( [[ ${DEBUG} == of* ]] || [[ ${DEBUG} == no ]] ); then
  DEBUG="off"
  DEBUGSTRING=""
  DEBUGOPTIONS=""
  echo " * Using no debugging code"
elif ( [[ ${DEBUG} == on ]] || [[ ${DEBUG} == y* ]] || [[ ${DEBUG} == nor* ]] ); then
  DEBUG="normal"
  DEBUGSTRING="_debug"
  DEBUGOPTIONS="-DCMAKE_BUILD_TYPE=Debug"
  echo " * Using debugging code"
elif ( [[ ${DEBUG} == st* ]] || [[ ${DEBUG} == h* ]] ); then
  # MEGAlib knows a third level which turns on the address sanitizer for its own sources.
  # There is no equivalent for a cmake build of Geant4, thus treat it like the normal level
  # instead of refusing a value the setup script accepts and passes on.
  DEBUG="normal"
  DEBUGSTRING="_debug"
  DEBUGOPTIONS="-DCMAKE_BUILD_TYPE=Debug"
  echo " * Using debugging code - the strong level only applies to MEGAlib itself"
else
  echo "ERROR: Unknown debugging code selection: ${DEBUG}"
  confhelp
  exit 1
fi


if ! BOOLEAN=$(booleanvalue "${PATCH}"); then
  echo " "
  echo "ERROR: Unknown value for the --patch option: ${PATCH}"
  echo "       Use true/on/yes or false/off/no"
  confhelp
  exit 1
fi
PATCH="${BOOLEAN}"
if [[ ${PATCH} == true ]]; then
  echo " * Apply internal ROOT and Geant4 patches"
else
  echo " * Don't apply internal ROOT and Geant4 patches"
fi


if ! BOOLEAN=$(booleanvalue "${CLEANUP}"); then
  echo " "
  echo "ERROR: Unknown value for the --cleanup option: ${CLEANUP}"
  echo "       Use true/on/yes or false/off/no"
  confhelp
  exit 1
fi
CLEANUP="${BOOLEAN}"
if [[ ${CLEANUP} == true ]]; then
  echo " * Clean up intermediate build files"
else
  echo " * Don't clean up intermediate build files"
fi


if ! BOOLEAN=$(booleanvalue "${KEEPENVASIS}"); then
  echo " "
  echo "ERROR: Unknown value for the --keep-environment-as-is option: ${KEEPENVASIS}"
  echo "       Use true/on/yes or false/off/no"
  confhelp
  exit 1
fi
KEEPENVASIS="${BOOLEAN}"
if [[ ${KEEPENVASIS} == true ]]; then
  echo " * Keeping the existing environment paths as is."
else
  echo " * Clearing the environment paths LD_LIBRARY_PATH, CPATH, CMAKE_PREFIX_PATH, DYLD_LIBRARY_PATH"
  # We cannot clean PATH, otherwise no programs can be found anymore.
  # CMAKE_PREFIX_PATH and DYLD_LIBRARY_PATH matter because this is a cmake build: a stale
  # value there sends cmake to the wrong version of a dependency without saying so.
  export LD_LIBRARY_PATH=""
  export CPATH=""
  export CMAKE_PREFIX_PATH=""
  export DYLD_LIBRARY_PATH=""
fi


echo " "
echo " " 
# The tools this build needs. Checked after the command line has been read, so that
# --help still works on a machine which cannot build.
type cmake >/dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "ERROR: cmake must be installed"
  exit 1
else 
  VER=`cmake --version | grep ^cmake`
  VER=${VER#cmake version }; 
  OLDIFS=${IFS}; IFS='.'; Tokens=( ${VER} ); IFS=${OLDIFS}; 
  VERSION=$(( 10000*${Tokens[0]} + 100*${Tokens[1]} + ${Tokens[2]} )); 
  if (( ${VERSION} < 30300 )); then 
    echo "ERROR: the version of cmake needs to be at least 3.3 and not ${VER}"
    exit 1
  fi
fi
type curl >/dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "ERROR: curl must be installed"
  exit 1
fi 
type openssl >/dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "ERROR: openssl must be installed"
  exit 1
fi 


echo "Getting Geant4..."
VER=""

if [ "${TARBALL}" != "" ]; then
  # Use given tarball
  echo "The given Geant4 tarball is ${TARBALL}"
  
  # Check if it has the correct version:
  NUMVER=`echo "${TARBALL}" | awk -F'geant4[-.]v?' '{ print $NF }' | awk -F.t '{ print $1 }'`;
  VER="v${NUMVER}"
  # Old versions use a zero-padded minor, i.e. 10.02 is the same version as 10.2
  SHORTVER=`echo ${NUMVER} | awk -F. '{ printf "%d.%d", $1, $2 }'`;
  echo "Version of Geant4 is: ${VER}"
  
  if [[ ${WANTEDVERSION} != "" ]]; then
    if [[ ${SHORTVER} != `echo ${WANTEDVERSION} | awk -F. '{ printf "%d.%d", $1, $2 }'` ]]; then
      echo "ERROR: You stated you want version ${WANTEDVERSION} but the tar ball has version ${SHORTVER}!"
      exit 1
    fi
  else 
    "${SETUPPATH}/check-geant4version.sh" --good-version=${NUMVER}
    if [ "$?" != "0" ]; then
      echo "ERROR: The Geant4 tarball you supplied does not contain an acceptable Geant4 version!"
      exit 1
    fi
  fi
else
  # Download it
  
  if [[ ${WANTEDVERSION} == "" ]]; then
    # Get desired version:
    WANTEDVERSION=`"${SETUPPATH}/check-geant4version.sh" --get-max`
    if [ "$?" != "0" ]; then
      echo "ERROR: Unable to determine required Geant4 version!"
      exit 1
    fi
  fi
  echo "Looking for Geant4 version ${WANTEDVERSION} with latest patch on the Geant4 website --- sometimes this takes a few minutes..."
  
  # Now check Geant4 repository for the given version, and collect the patch levels which
  # are on offer - newest first, since that is the order we want to try them in
  PATCHES=""
  for s in `seq 0 10`; do
    TESTTARBALL="geant4-v${WANTEDVERSION}.${s}.tar.gz"
    echo "Trying to find ${TESTTARBALL}..."
    EXISTS=`curl -s --head ${WEBSITE}/${TESTTARBALL} | grep gzip`
    if [ "${EXISTS}" == "" ]; then
      break
    fi
    PATCHES="${s} ${PATCHES}"
  done

  # The newest patch is not automatically a usable one - it may be black listed in
  # allowed-versions.txt, thus walk down until one is acceptable
  TARBALL=""
  for s in ${PATCHES}; do
    if "${SETUPPATH}/check-geant4version.sh" --good-version=${WANTEDVERSION}.${s} > /dev/null; then
      TARBALL="geant4-v${WANTEDVERSION}.${s}.tar.gz"
      break
    fi
    echo "Skipping Geant4 version ${WANTEDVERSION}.${s} - it is black listed or outside the supported version range"
  done
  if [ "${TARBALL}" == "" ]; then
    echo "ERROR: Unable to find an acceptable Geant4 tar ball at the Geant4 website"
    exit 1
  fi
  echo "Using Geant4 tar ball ${TARBALL}"
  
  # Check if it already exists locally
  REQUIREDOWNLOAD="true"
  if tarballisgood "${TARBALL}" "${WEBSITE}/${TARBALL}"; then
    REQUIREDOWNLOAD="false"
  fi
  
  if [ "${REQUIREDOWNLOAD}" == "true" ]; then
    echo "Starting the download."
    echo "If the download fails, you can continue it via the following command and then call this script again - it will use the downloaded file."
    echo " "
    echo "curl -fOL -C - ${WEBSITE}/${TARBALL}"
    echo " "
    if ! downloadtarball "${WEBSITE}/${TARBALL}" "${TARBALL}"; then
      echo "ERROR: Unable to download the tarball from the Geant4 website!"
      exit 1
    fi
  fi
  
  VER=`echo "${TARBALL}" | awk -Fgeant4. '{ print $2 }' | awk -F.t '{ print $1 }'`;
  if [ "$?" != "0" ]; then
    echo "ERROR: Something went wrong during determining the Geant4 version"
    exit 1
  fi
  echo "Version of Geant4 is: ${VER}"
fi



GEANT4CORE=geant4_${VER}
GEANT4DIR=geant4_${VER}${DEBUGSTRING}
GEANT4SOURCEDIR=geant4_${VER}-source   # Attention: the cleanup checks this name pattern before removing it
GEANT4BUILDDIR=geant4_${VER}-build     # Attention: the cleanup checks this name pattern before removing it


# Hardcoding default patch conditions
# Needs to be done after the Geant4 version is known and before we check the exiting installation
if [[ ${GEANT4CORE} == "geant4_v10.02.p03" ]]; then
  PATCH="true"
  echo "This version of Geant4 version requires a mandatory patch"
fi
if [[ ${GEANT4CORE} == "geant4_v11.02.p02" ]]; then
  PATCH="true"
  echo "This version of Geant4 requires a mandatory patch"
fi

echo "Checking for old installation..."
if [ -d "${GEANT4DIR}" ]; then
  cd "${GEANT4DIR}"
  if [ -f COMPILE_SUCCESSFUL ]; then
  
    SAMEOPTIONS=`cat COMPILE_SUCCESSFUL | grep -F -x -- "${CONFIGUREOPTIONS}"`
    if [ "${SAMEOPTIONS}" == "" ]; then
      echo "The old installation used different compilation options..."
    fi

    SAMECOMPILER=`cat COMPILE_SUCCESSFUL | grep -F -x -- "${COMPILEROPTIONS}"`
    if [ "${SAMECOMPILER}" == "" ]; then
      echo "The old installation used a different compiler..."
    fi
    
    SAMEPATCH=""
    PATCHPRESENT="no"
    if [ -f "${SETUPPATH}/patches/${GEANT4CORE}.patch" ]; then
      PATCHPRESENT="yes"
      PATCHPRESENTMD5=`openssl md5 "${SETUPPATH}/patches/${GEANT4CORE}.patch" | awk -F" " '{ print $2 }'`
    fi
    PATCHSTATUS=`cat COMPILE_SUCCESSFUL | grep -- "^Patch"`
    if [[ ${PATCHSTATUS} == Patch\ applied* ]]; then
      PATCHMD5=`echo ${PATCHSTATUS} | awk -F" " '{ print $3 }'`
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
    
    
    if ( [ "${SAMEOPTIONS}" != "" ] && [ "${SAMECOMPILER}" != "" ] && [ "${SAMEPATCH}" != "" ] ); then
      echo "You already have a usable Geant4 version installed!"
      if [ "${ENVFILE}" != "" ]; then
        echo "Storing the Geant4 directory in the source script..."
        echo "GEANT4DIR=`pwd`" >> ${ENVFILE}
      fi
      exit 0
    fi
  fi
  
  echo "Old installation is either incompatible or incomplete. Removing ${GEANT4DIR}..."
  cd ..
  if echo "${GEANT4DIR}" | grep -E '[ "]' >/dev/null; then
    echo "ERROR: Feeding my paranoia of having a \"rm -r\" in a script:"
    echo "       There should not be any spaces in the Geant4 version..."
    exit 1
  fi
  rm -rf "${GEANT4DIR}"
fi



echo "Unpacking..."
mkdir "${GEANT4DIR}"
cd "${GEANT4DIR}"
if ( [[ ${TARBALL} == *.tgz ]] || [[ ${TARBALL} == *.tar.gz ]] ); then
  tar xfz "../${TARBALL}" > /dev/null
elif [[ ${TARBALL} == *.tar ]] ; then
  tar xf "../${TARBALL}" > /dev/null
else
  echo "ERROR: File has unknown suffix: ${TARBALL} (known: tgz, tar.gz, tar)"
  exit 1
fi
if [ "$?" != "0" ]; then
  echo "ERROR: Something went wrong unpacking the Geant4 tarball!"
  exit 1
fi
mv geant4-${VER} "${GEANT4SOURCEDIR}"
mkdir "${GEANT4BUILDDIR}"



PATCHAPPLIED="Patch not applied"
if [[ ${PATCH} == true ]]; then
  echo "Patching... "
  if [[ -f "${SETUPPATH}/patches/${GEANT4CORE}.patch" ]]; then
    patch -p1 < "${SETUPPATH}/patches/${GEANT4CORE}.patch"
    if [ "$?" != "0" ]; then
      echo "ERROR: Something went wrong applying the Geant4 patch!"
      exit 1
    fi
    PATCHMD5=`openssl md5 "${SETUPPATH}/patches/${GEANT4CORE}.patch" | awk -F" " '{ print $2 }'`
    PATCHAPPLIED="Patch applied ${PATCHMD5}"
    echo "Applied patch: ${SETUPPATH}/patches/${GEANT4CORE}.patch"
  else
    echo "No required patch found for this version of Geant4"
  fi
fi



echo "Configuring ..."
cd "${GEANT4BUILDDIR}"
echo "Configure command: cmake ${CONFIGUREOPTIONS} ${DEBUGOPTIONS} ../${GEANT4SOURCEDIR}"
cmake ${CONFIGUREOPTIONS} ${DEBUGOPTIONS} "../${GEANT4SOURCEDIR}"
if [ "$?" != "0" ]; then
  echo "ERROR: Something went wrong configuring (cmake'ing) Geant4!"
  exit 1
fi



CORES=$(numberofcores)
if [ "${CORES}" -gt "${MAXTHREADS}" ]; then
  CORES=${MAXTHREADS}
fi
echo "Using this number of cores: ${CORES}"



echo "Compiling..."
make -j${CORES}
if [ "$?" != "0" ]; then
  echo "ERROR: Something went wrong while compiling Geant4!"
  exit 1
fi



echo "Installing..."
make install
if [ "$?" != "0" ]; then
  echo "ERROR: Something went wrong while installing Geant4!"
  exit 1
fi



# Done. Switch to main GEANT4 directory
cd ..



if [[ ${CLEANUP} == true ]]; then
  echo "Cleaning up ..."
  # Just a sanity check before our remove...
  if [[ ${GEANT4BUILDDIR} == geant4_v*-build ]]; then 
    rm -rf "${GEANT4BUILDDIR}"
    if [ "$?" != "0" ]; then
      echo "ERROR: Unable to remove buuld directory!"
      exit 1
    fi
  else
    echo "INFO: Not cleaning up the build directory, because it is not named as expected: ${GEANT4BUILDDIR}"
  fi
  if [[ ${GEANT4SOURCEDIR} == geant4_v*-source ]]; then 
    rm -rf "${GEANT4SOURCEDIR}"
    if [ "$?" != "0" ]; then
      echo "ERROR: Unable to remove source directory!"
      exit 1
    fi
  else
    echo "INFO: Not cleaning up the source directory, because it is not named as expected: ${GEANT4SOURCEDIR}"
  fi
fi


echo "Store our success story..."
rm -f COMPILE_SUCCESSFUL
echo "Geant4 compilation & installation successful" >> COMPILE_SUCCESSFUL
echo " " >> COMPILE_SUCCESSFUL
echo "* Configure options:" >> COMPILE_SUCCESSFUL
echo "${CONFIGUREOPTIONS}" >> COMPILE_SUCCESSFUL
echo " " >> COMPILE_SUCCESSFUL
echo "* Compile options:" >> COMPILE_SUCCESSFUL
echo "${COMPILEROPTIONS}" >> COMPILE_SUCCESSFUL
echo " " >> COMPILE_SUCCESSFUL
echo "* Patch application status:" >> COMPILE_SUCCESSFUL
echo "${PATCHAPPLIED}" >> COMPILE_SUCCESSFUL
echo " " >> COMPILE_SUCCESSFUL



echo "Setting permissions..."
cd ..
chown -R ${USER}:${GROUP} "${GEANT4DIR}"
chmod -R go+rX "${GEANT4DIR}"



if [ "${ENVFILE}" != "" ]; then
  echo "Storing the Geant4 directory in the source script..."
  echo "GEANT4DIR=`pwd`/${GEANT4DIR}" >> ${ENVFILE}
fi



echo "SUCCESS!"
exit 0
