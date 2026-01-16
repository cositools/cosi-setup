#!/bin/bash

# This bash script is part of the MEGAlib & COSItools setup procedure.
# As such it is dual licenced under Apache 2.0 for COSItools and LGPL 3.0 for MEGAlib
#
# Development lead: Andreas Zoglauer
#
# Description:
# This script downloads, compiles, and installs ROOT


# Path to where this file is located
SETUPPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

# Operating system type
OSTYPE=$(uname -s | awk '{print tolower($0)}')

# The configuration options
CONFIGUREOPTIONS=" "
# Install path relative to the build path --- simply one up in this script
CONFIGUREOPTIONS+=" -DCMAKE_INSTALL_PREFIX=.."
# Make sure we ignore some default paths of macport.
type port >/dev/null 2>&1
if [[ $? -eq 0 ]]; then
  PORTPATH=$(which port)
  PORTPATH=${PORTPATH%/bin/port}
  CONFIGUREOPTIONS+=" -DCMAKE_IGNORE_PATH=${PORTPATH};${PORTPATH}/bin;${PORTPATH}/include;${PORTPATH}/include/libxml2;${PORTPATH}/include/unicode"
fi
# Until ROOT 6.24: C++ 11
# Until ROOT 6.28: C++ 14
CONFIGUREOPTIONS+=" -DCMAKE_CXX_STANDARD=17"
# We want a minimal system and enable what we really need:
#CONFIGUREOPTIONS+=" -Dgminimal=ON"
# Open GL -- needed by geomega
CONFIGUREOPTIONS+=" -Dopengl=ON"
# Mathmore -- needed for fitting, e.g. ARMs"
CONFIGUREOPTIONS+=" -Dmathmore=ON"
# XFT -- needed for smoothed fonts
CONFIGUREOPTIONS+=" -Dxft=ON"
# Afterimage -- support to draw images in pads and save as png, etc.
CONFIGUREOPTIONS+=" -Dasimage=ON"
# Stuff for linking, paths in so files, versioning etc
CONFIGUREOPTIONS+=" -Dexplicitlink=ON -Drpath=ON -Dsoversion=ON"
# Use builtin glew
CONFIGUREOPTIONS+=" -Dbuiltin_glew=ON"


# In case you have trouble with anything related to freetype, try to comment in this option
# CONFIGUREOPTIONS+=" -Dbuiltin-freetype=ON"

# In case you get strange error messages concerning jpeg, png, tiff
# CONFIGUREOPTIONS+=" -Dasimage=OFF -Dastiff=OFF -Dbuiltin_afterimage=OFF"

# In case you have trouble with zlib (gz... something error messages)
# CONFIGUREOPTIONS+=" -Dbuiltin_zlib=ON -Dbuiltin_lzma=ON"

# By default we build with python 3:
type python3 >/dev/null 2>&1
if [[ $? -eq 0 ]]; then
  PPATH=$(which python3)
  if [[ -f ${PPATH} ]]; then
    if [[ ${PPATH} == *conda* ]]; then
      echo "ERROR: You cannot use a python version installed via (ana)conda with ROOT."
      exit 1
    else
      CONFIGUREOPTIONS+=" -DPYTHON_EXECUTABLE:FILEPATH=${PPATH} -Dpython3=ON"
    fi
  fi
fi

# Enable cuda if available
type nvcc >/dev/null 2>&1
if [[ $? -eq 0 ]]; then
  CONFIGUREOPTIONS+=" -Dcuda=ON"
fi

# pkg-config is not always found
#type pkg-config >/dev/null 2>&1
#if [[ $? -eq 0 ]]; then
#  PPATH=$(which pkg-config)
#  if [[ -f ${PPATH} ]]; then
#    if [[ ${PPATH} == *pkg-config* ]]; then
#      CONFIGUREOPTIONS+=" -DPKG_CONFIG_EXECUTABLE=${PPATH}"
#    fi
#  fi
#fi


# In case ROOT complains about your python version
# CONFIGUREOPTIONS+=" -Dpython=OFF"
# CONFIGUREOPTIONS+=" -Dpython3=OFF"

# Switching off things we do not need right now but which are on by default
CONFIGUREOPTIONS+=" -Dalien=OFF -Dbonjour=OFF -Dcastor=OFF -Ddavix=OFF -Dfortran=OFF -Dfitsio=OFF -Dchirp=OFF -Ddcache=OFF -Dgfal=OFF -Dglite=off -Dhdfs=OFF -Dkerb5=OFF -Dldap=OFF -Dmonalisa=OFF -Dodbc=OFF -Doracle=OFF -Dpch=OFF -Dpgsql=OFF -Dpythia6=OFF -Dpythia8=OFF -Drfio=OFF -Dsapdb=OFF -Dshadowpw=OFF -Dsqlite=OFF -Dsrp=OFF -Dssl=OFF -Dxrootd=OFF"

# Explictly add gcc -- cmake seems to sometimes digg up other compilers on the system, not the default one...
if [[ ${OSTYPE} != *arwin* ]]; then
  CONFIGUREOPTIONS+=" -DCMAKE_C_COMPILER=$(which gcc) -DCMAKE_CXX_COMPILER=$(which g++)"
fi

# Turn off runtime modules on macOS
if [[ ${OSTYPE} == *arwin* ]]; then
  CONFIGUREOPTIONS+=" -Druntime_cxxmodules=OFF"
fi

# The compiler
COMPILEROPTIONS=`gcc --version | head -n 1`


# Check if some of the frequently used software is installed:
type cmake >/dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "ERROR: cmake must be installed"
  exit 1
else
  VER=`cmake --version | grep ^cmake`
  VER=${VER#cmake version };
  OLDIFS=${IFS}; IFS='.'; Tokens=( ${VER} ); IFS=${OLDIFS};
  VERSION=$(( 10000*${Tokens[0]} + 100*${Tokens[1]} + ${Tokens[2]} ));
  if (( ${VERSION} < 30403 )); then
    echo "ERROR: the version of cmake needs to be at least 3.4.3 and not ${VER}"
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


confhelp() {
  echo ""
  echo "Building ROOT"
  echo " "
  echo "Usage: ./build-root.sh [options]";
  echo " "
  echo " "
  echo "Options:"
  echo "--tarball=[file name of ROOT tar ball]"
  echo "    Use this tarball instead of downloading it from the ROOT website"
  echo " "
  echo "--rootversion=[e.g. 5.34, 6.10, v6-28-02, master]"
  echo "    Use the given ROOT version instead of the required one."
  echo " "
  echo "--sourcescript=[file name of new environment script]"
  echo "    The source script which sets all environment variables for HEASoft."
  echo " "
  echo "--debug=[off/no, on/yes - default: off]"
  echo "    Compile with degugging options."
  echo " "
  echo "--keepenvironmentasis=[false/off/no, true/on/yes - default: false]"
  echo "    By default all relevant environment paths (such as LD_LIBRRAY_PATH, CPATH) are reset to empty to avoid most libray conflicts."
  echo "    This flag toggles this behaviour and lets you decide to keep your environment or not."
  echo " "
  echo "--maxthreads=[integer >=1 - default: 1]"
  echo "    The maximum number of threads to be used for compilation. Default is the number of cores in your system."
  echo " "
  echo "--patch=[yes or no - default: no]"
  echo "    Apply internal ROOT patches, if there are any for this version."
  echo " "
  echo "--cleanup=[off/no, on/yes - default: off]"
  echo "    Remove intermediate build files"
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
MAXTHREADS=1024
DEBUG="off"
DEBUGSTRING=""
DEBUGOPTIONS=""
PATCH="off"
CLEANUP="off"
KEEPENVASIS="off"
WANTEDVERSION=""

# Overwrite default options with user options:
for C in ${CMD}; do
  if [[ ${C} == *-t*=* ]]; then
    TARBALL=`echo ${C} | awk -F"=" '{ print $2 }'`
  elif [[ ${C} == *-s*=* ]] || [[ ${C} == *-e*=* ]]; then
    ENVFILE=`echo ${C} | awk -F"=" '{ print $2 }'`
  elif [[ ${C} == *-m*=* ]]; then
    MAXTHREADS=`echo ${C} | awk -F"=" '{ print $2 }'`
  elif [[ ${C} == *-d*=* ]]; then
    DEBUG=`echo ${C} | awk -F"=" '{ print $2 }'`
  elif [[ ${C} == *-p*=* ]]; then
    PATCH=`echo ${C} | awk -F"=" '{ print $2 }'`
  elif [[ ${C} == *-cl*=* ]]; then
    CLEANUP=`echo ${C} | awk -F"=" '{ print $2 }'`
  elif [[ ${C} == *-r*=* ]]; then
    WANTEDVERSION=`echo ${C} | awk -F"=" '{ print $2 }'`
  elif [[ ${C} == *-k*=* ]]; then
    KEEPENVASIS=`echo ${C} | awk -F"=" '{ print $2 }'`
  elif [[ ${C} == *-h* ]]; then
    echo ""
    confhelp
    exit 0
  else
    echo ""
    echo "ERROR: Unknown command line option: ${C}"
    echo "       See \"$0 --help\" for a list of options"
    echo " "
    exit 1
  fi
done



echo ""
echo ""
echo ""
echo "Setting up ROOT..."
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


if [ ! -z "${MAXTHREADS##[0-9]*}" ] 2>/dev/null; then
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
else
  echo "ERROR: Unknown debugging code selection: ${DEBUG}"
  confhelp
  exit 0
fi


PATCH=`echo ${PATCH} | tr '[:upper:]' '[:lower:]'`
if ( [[ ${PATCH} == of* ]] || [[ ${PATCH} == n* ]] ); then
  PATCH="off"
  echo " * Don't apply internal ROOT and Geant4 patches"
elif ( [[ ${PATCH} == on ]] || [[ ${PATCH} == y* ]] ); then
  PATCH="on"
  echo " * Apply internal ROOT and Geant4 patches"
else
  echo " "
  echo "ERROR: Unknown option for updates: ${PATCH}"
  confhelp
  exit 1
fi


CLEANUP=`echo ${CLEANUP} | tr '[:upper:]' '[:lower:]'`
if ( [[ ${CLEANUP} == of* ]] || [[ ${CLEANUP} == n* ]] ); then
  CLEANUP="off"
  echo " * Don't clean up intermediate build files"
elif ( [[ ${CLEANUP} == on ]] || [[ ${CLEANUP} == y* ]] ); then
  CLEANUP="on"
  echo " * Clean up intermediate build files"
else
  echo " "
  echo "ERROR: Unknown option for clean up: ${CLEANUP}"
  confhelp
  exit 1
fi


KEEPENVASIS=`echo ${KEEPENVASIS} | tr '[:upper:]' '[:lower:]'`
if [[ ${KEEPENVASIS} == f* ]] || [[ ${KEEPENVASIS} == of* ]] || [[ ${KEEPENVASIS} == n* ]]; then
  KEEPENVASIS="false"
  echo " * Clearing the environment paths LD_LIBRARY_PATH, CPATH"
  # We cannot clean PATH, otherwise no programs can be found anymore
  export LD_LIBRARY_PATH=""
  export SHLIB_PATH=""
  export CPATH=""
  export CMAKE_PREFIX_PATH=""
  export DYLD_LIBRARY_PATH=""
  export JUPYTER_PATH=""
  export LIBPATH=""
  export MANPATH=""
elif [[ ${KEEPENVASIS} == t* ]] || [[ ${KEEPENVASIS} == on ]] || [[ ${KEEPENVASIS} == y* ]]; then
  KEEPENVASIS="true"
  echo " * Keeping the existing environment paths as is."
else
  echo " "
  echo "ERROR: Unknown option for keeping environemnt or not: ${KEEPENVASIS}"
  confhelp
  exit 1
fi

echo " * Choosing this ROOT version: ${WANTEDVERSION}"

echo " "
echo " "
echo "Getting ROOT..."
VER=""
ROOTTOPDIR=""

# Make sure we have a tar ball
if [[ ${TARBALL} == "" ]]; then
  # Get desired version:
  if [[ ${WANTEDVERSION} == "" ]]; then
    WANTEDVERSION=`${SETUPPATH}/check-rootversion.sh --get-max`
    if [ "$?" != "0" ]; then
      echo "ERROR: Unable to determine required ROOT version!"
      exit 1
    fi
  fi
  echo "Looking for ROOT version ${WANTEDVERSION} on the ROOT GitHub website --- sometimes this takes a few minutes..."

  #
  NEWWANTED=""
  NEWWANTED_GITNAME=""
  if [[ ${WANTEDVERSION} == v* ]]; then
    # Get all good tags and check if ours is in there
    ALLROOTVER=$(git ls-remote https://github.com/root-project/root | awk -F/ '{ print $NF }' | awk '(length($1) == 8 || length($1) == 16) { print $1 }')
    if [[ ${ALLROOTVER} != *${WANTEDVERSION}* ]]; then
      echo "ERROR: Unable to find this ROOT version (i.e. its tag) on GitHub: ${WANTEDVERSION}"
      exit 1
    fi
    NEWWANTED_GITNAME=${WANTEDVERSION}
    NEWWANTED=${WANTEDVERSION//v/}
    NEWWANTED=${NEWWANTED//-/.}
  elif [[ ${WANTEDVERSION} == master ]]; then
    NEWWANTED_GITNAME=${WANTEDVERSION}
    NEWWANTED=${WANTEDVERSION}
  else
    RVER=$(echo "${WANTEDVERSION}" | awk -F. '{ print $1 }')
    RREV=$(echo "${WANTEDVERSION}" | awk -F. '{ print $2 }')

    ALLROOTVER=$(git ls-remote https://github.com/root-project/root | grep v${RVER}-${RREV} | grep -v "\^" | grep -v "rc" | awk -F/ '{ print $NF }' | sort -r)

    # The versions are sorted reverse thus use the first not blacklisted one
    for V in ${ALLROOTVER}; do
      NEWWANTED=${V//v/}
      NEWWANTED=${NEWWANTED//-/.}
      ${SETUPPATH}/check-rootversion.sh --good-version=${NEWWANTED} > /dev/null
      if [ "$?" != "0" ]; then
        echo "Skipping blacklisted ${NEWWANTED}..."
        continue
      else
        NEWWANTED_GITNAME=${V}
        break
      fi
    done

    if [[ ${NEWWANTED_GITNAME} = "" ]]; then
      echo "ERROR: Unable to find this ROOT version (i.e. its tag) on GitHub: ${WANTEDVERSION}"
      exit 1
    fi
  fi

  # Create tar ball name
  TARBALL="root_v${NEWWANTED}.source.tar.gz"

  # Check if it already exists locally
  REQUIREDOWNLOAD="true"
  if [ -f ${TARBALL} ]; then
    # check if the gziped file is not corrupted
    gunzip -t ${TARBALL} >/dev/null 2>&1
    if [ "$?" != "0" ]; then
      REQUIREDOWNLOAD="true"
      echo "Tarball already exists, but is corrupted. Requiring re-download."
    else
      # These two types of tarballs will change, thus we need to redownload them
      if [[ ${TARBALL} == *master* ]] || [[ ${TARBALL} == *patches* ]]; then
        REQUIREDOWNLOAD="true"
        echo "Tarball exists, but is that of an active development branch. Requiring re-download."
      else
        REQUIREDOWNLOAD="false"
        echo "Tarball already exists and is good. No download required."
      fi
    fi
  fi

  if [ "${REQUIREDOWNLOAD}" == "true" ]; then
    echo "Starting the download from GitHub."
    echo " "
    curl -L https://github.com/root-project/root/tarball/${NEWWANTED_GITNAME} -o ${TARBALL}
    if [ "$?" != "0" ]; then
      echo "ERROR: Unable to download the tarball from GitHub!"
      exit 1
    fi
  fi
fi

# Check if the tarball exists
if [ ! -f ${TARBALL} ]; then
  echo "ERROR: The tar ball \"${TARBALL}\" does not exist!"
  exit 1
fi


# Use given ROOT tarball
echo "Name of the used ROOT tarball: ${TARBALL}"

# Determine the name of the top level directory in the tar ball
ROOTTOPDIR=`tar tzf ${TARBALL} | sed -e 's@/.*@@' | uniq`
RESULT=$?
if [ "${RESULT}" != "0" ]; then
  echo "ERROR: Cannot find top level directory in the tar ball!"
  exit 1
fi

# Check if it has the correct version:
VER=""
if tar -tf ${TARBALL} | grep -q "${ROOTTOPDIR}/build/version_number"; then
  VER=`tar xfzO ${TARBALL} ${ROOTTOPDIR}/build/version_number | sed 's|/|.|g'`
elif tar -tf ${TARBALL} | grep -q "${ROOTTOPDIR}/core/foundation/inc/ROOT/RVersion.hxx"; then
  VER+=$(tar xfzO ${TARBALL} ${ROOTTOPDIR}/core/foundation/inc/ROOT/RVersion.hxx | grep "ROOT_VERSION_MAJOR" | head -n 1 | awk '{ print $3 }')
  VER+="."
  VER+=$(tar xfzO ${TARBALL} ${ROOTTOPDIR}/core/foundation/inc/ROOT/RVersion.hxx | grep "ROOT_VERSION_MINOR" | head -n 1 | awk '{ print $3 }')
  VER+="."
  VER+=$(tar xfzO ${TARBALL} ${ROOTTOPDIR}/core/foundation/inc/ROOT/RVersion.hxx | grep "ROOT_VERSION_PATCH" | head -n 1 | awk '{ print $3 }')
else
  echo "ERROR: Cannot find the ROOT version in the tarball!"
  exit 1
fi
if echo ${VER} | grep -E '[ "]' >/dev/null; then
  echo "ERROR: Something terrible is wrong with your version string..."
  exit 1
fi
echo "Version of ROOT is: ${VER}"

if [[ ${WANTEDVERSION} != "" ]]; then
  if [[ ${WANTEDVERSION} != master ]] && [[ ${WANTEDVERSION} != *patches* ]] && [[ ${VER} != ${WANTEDVERSION}* ]]; then
    echo "ERROR: The ROOT tarball has not the same version (${VER}) you wanted on the command line (${WANTEDVERSION})!"
    exit 1
  fi
else
  ${SETUPPATH}/check-rootversion.sh --good-version=${VER}
  if [ "$?" != "0" ]; then
    if [[ ${WANTEDVERSION} != "master" ]]; then
      echo "ERROR: The ROOT tarball does not contain an acceptable ROOT version!"
      exit 1
    else
      echo ""
      echo "WARNING: The ROOT tarball does not contain an acceptable ROOT version!"
      echo "         However, since you request the master version, that is likely expected,"
      echo "         and I assume you know what you are doing (e.g. testing)!"
      echo ""
    fi
  fi
fi




ROOTCORE=root_v${VER}
ROOTDIR=root_v${VER}${DEBUGSTRING}
ROOTSOURCEDIR=root_v${VER}-source   # Attention: the cleanup checks this name pattern before removing it
ROOTBUILDDIR=root_v${VER}-build     # Attention: the cleanup checks this name pattern before removing it

# Hardcoding default patch conditions
# Needs to be done after the ROOT version is known and before we check the exiting installation
if [[ ${ROOTCORE} == "root_v6.24.08" ]] || [[ ${ROOTCORE} == "root_v6.24.10" ]]; then
  echo "This version of ROOT requires a mandatory patch"
  PATCH="on"
fi


echo "Checking for old installation..."
if [ -d ${ROOTDIR} ]; then
  cd ${ROOTDIR}
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
    if [ -f "${SETUPPATH}/patches/${ROOTCORE}.patch" ]; then
      PATCHPRESENT="yes"
      PATCHPRESENTMD5=`openssl md5 "${SETUPPATH}/patches/${ROOTCORE}.patch" | awk -F" " '{ print $2 }'`
    fi
    PATCHSTATUS=`cat COMPILE_SUCCESSFUL | grep -- "^Patch"`
    if [[ ${PATCHSTATUS} == Patch\ applied* ]]; then
      PATCHMD5=`echo ${PATCHSTATUS} | awk -F" " '{ print $3 }'`
    fi

    if [[ ${PATCH} == on ]]; then
      if [[ ${PATCHPRESENT} == yes ]] && [[ ${PATCHSTATUS} == Patch\ applied* ]] && [[ ${PATCHPRESENTMD5} == ${PATCHMD5} ]]; then
        SAMEPATCH="YES";
      elif [[ ${PATCHPRESENT} == no ]] && [[ ${PATCHSTATUS} == Patch\ not\ applied* ]]; then
        SAMEPATCH="YES";
      else
        echo "The old installation didn't use the same patch..."
        SAMEPATCH=""
      fi
    elif [[ ${PATCH} == off ]]; then
      if [[ ${PATCHSTATUS} == Patch\ not\ applied* ]] || [[ -z ${PATCHSTATUS}  ]]; then    # last one means empty
        SAMEPATCH="YES";
      else
        echo "The old installation used a patch, but now we don't want any..."
        SAMEPATCH=""
      fi
    fi


    if ( [ "${SAMEOPTIONS}" != "" ] && [ "${SAMECOMPILER}" != "" ] && [ "${SAMEPATCH}" != "" ] ); then
      echo "Your already have a usable ROOT version installed!"
      if [ "${ENVFILE}" != "" ]; then
        echo "Storing the ROOT directory in the source script..."
        echo "ROOTDIR=`pwd`" >> ${ENVFILE}
      fi
      exit 0
    fi
  fi

  echo "Old installation is either incompatible or incomplete. Removing ${ROOTDIR}..."

  cd ..
  if echo "${ROOTDIR}" | grep -E '[ "]' >/dev/null; then
    echo "ERROR: Feeding my paranoia of having a \"rm -r\" in a script:"
    echo "       There should not be any spaces in the ROOT version..."
    exit 1
  fi
  rm -rf "${ROOTDIR}"
fi



echo "Unpacking..."
mkdir ${ROOTDIR}
cd ${ROOTDIR}
tar xfz ../${TARBALL} > /dev/null
if [ "$?" != "0" ]; then
  echo "ERROR: Something went wrong unpacking the ROOT tarball!"
  exit 1
fi
mv ${ROOTTOPDIR} ${ROOTSOURCEDIR}
mkdir ${ROOTBUILDDIR}



PATCHAPPLIED="Patch not applied"
if [[ ${PATCH} == on ]]; then
  echo "Patching..."
  if [ -f "${SETUPPATH}/patches/${ROOTCORE}.patch" ]; then
    patch -p1 < ${SETUPPATH}/patches/${ROOTCORE}.patch
    PATCHMD5=`openssl md5 "${SETUPPATH}/patches/${ROOTCORE}.patch" | awk -F" " '{ print $2 }'`
    PATCHAPPLIED="Patch applied ${PATCHMD5}"
    echo "Applied patch: ${SETUPPATH}/patches/${ROOTCORE}.patch"
  fi
fi



echo "Configuring..."
cd ${ROOTBUILDDIR}
export ROOTSYS=${ROOTDIR}
#if [[ ${OSTYPE} == *arwin* ]]; then
#  export CPLUS_INCLUDE_PATH=`xcrun --show-sdk-path`/usr/include
#  export LIBRARY_PATH=$LIBRARY_PATH:`xcrun --show-sdk-path`/usr/lib
#fi
echo "Configure command: cmake ${CONFIGUREOPTIONS} ${DEBUGOPTIONS} ../${ROOTSOURCEDIR}"
cmake ${CONFIGUREOPTIONS} ${DEBUGOPTIONS} ../${ROOTSOURCEDIR}
if [ "$?" != "0" ]; then
  echo "ERROR: Something went wrong configuring (cmake'ing) ROOT!"
  exit 1
fi



CORES=1;
if [[ ${OSTYPE} == *arwin* ]]; then
  CORES=`sysctl -n hw.logicalcpu_max`
elif [[ ${OSTYPE} == *inux* ]]; then
  CORES=`grep processor /proc/cpuinfo | wc -l`
fi
if [ "$?" != "0" ]; then
  CORES=1
fi
if [ "${CORES}" -gt "${MAXTHREADS}" ]; then
  CORES=${MAXTHREADS}
fi
echo "Using this number of cores for compilation: ${CORES}"



echo "Compiling..."
make -j${CORES}
if [ "$?" != "0" ]; then
  echo "ERROR: Something went wrong while compiling ROOT!"
  exit 1
fi



echo "Installing..."
make install
if [ "$?" != "0" ]; then
  echo "ERROR: Something went wrong while installing ROOT!"
  exit 1
fi

# Done. Switch to main ROOT directory
cd ..

if [[ ${CLEANUP} == on ]]; then
  echo "Cleaning up ..."
  # Just a sanity check before our remove...
  if [[ ${ROOTBUILDDIR} == root_v*-build ]]; then
    rm -rf ${ROOTBUILDDIR}
    if [ "$?" != "0" ]; then
      echo "ERROR: Unable to remove build directory!"
      exit 1
    fi
  else
    echo "INFO: Not cleaning up the build directory, because it is not named as expected: ${ROOTBUILDDIR}"
  fi
  if [[ ${ROOTSOURCEDIR} == root_v*-source ]]; then
    rm -rf ${ROOTSOURCEDIR}
    if [ "$?" != "0" ]; then
      echo "ERROR: Unable to remove source directory!"
      exit 1
    fi
  else
    echo "INFO: Not cleaning up the source directory, because it is not named as expected: ${ROOTSOURCEDIR}"
  fi
fi


echo "Store our success story..."
rm -f COMPILE_SUCCESSFUL
echo "ROOT compilation & installation successful" >> COMPILE_SUCCESSFUL
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
chown -R ${USER}:${GROUP} ${ROOTDIR}
chmod -R go+rX ${ROOTDIR}


if [ "${ENVFILE}" != "" ]; then
  echo "Storing the ROOT directory in the source script..."
  echo "ROOTDIR=`pwd`/${ROOTDIR}" >> ${ENVFILE}
fi


echo "Done!"
exit 0
