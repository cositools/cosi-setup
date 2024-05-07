#!/bin/bash

# This bash script is part of the MEGAlib & COSItools setup procedure.
# As such it is dual licenced under Apache 2.0 for COSItools and LGPL 3.0 for MEGAlib
#
# Development lead: Andreas Zoglauer
#
# Description:
# This is the stage 2 script to setup the COSI tools
# It sets up all of the COSItools 


############################################################################################################
# Define default parameters

echo ""
echo "*****************************"
echo "" 
echo "Starting stage 2 of the setup"

TIMESTART=$(date +%s)

echo ""
echo "*****************************"
echo ""
echo "Call options:"
echo "$@"

# The command line
CMD=( "$@" )

# The path to where the COSItools will be installed
COSIPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; cd ..; pwd -P )"

# The path where the setup scripts are
SETUPPATH="${COSIPATH}/cosi-setup"

# The path to the COSItools install
GITBASEDIR="https://github.com/cositools"
GITBRANCH="main"
GITPULLBEHAVIOR="stash"

# Extra repositories to download
EXTRAS=""

# Operating system type
OSTYPE=$(uname -s)

# Keep all environment variables intact or not
KEEPENVASIS="off"

# Ignore the stage where we look for missing packages
IGNOREMISSINGPACKAGES=false

# C++ optimization and debugging options
CPPOPT="normal"
CPPDEBUG="off"

# The python path
PATHTOPYTHON=""

# Path to potentially existing ROOT, Geant4, and HEASoft installs
ROOTPATH=""
GEANT4PATH=""
HEASOFTPATH=""

# The directory where to install ROOT, Geant4, and HEASoft
EXTERNALPATH=${COSIPATH}/external
if [ ! -d ${EXTERNALPATH} ]; then
  mkdir ${EXTERNALPATH}
fi

# Name of the stash where we backup data
STASHNAME="BackupDuringCositoolsSetup:`date +'%y%m%d.%H%M%S'`"
  
# Maximum compile threads we are allwoed to use
MAXTHREADS=1;
if [[ ${OSTYPE} == *arwin* ]]; then
  MAXTHREADS=`sysctl -n hw.logicalcpu_max`
elif [[ ${OSTYPE} == *inux* ]]; then
  MAXTHREADS=`grep processor /proc/cpuinfo | wc -l`
fi
if [ "$?" != "0" ]; then
  MAXTHREADS=1
fi

# Prepare the environment script
ENVFILE="${COSIPATH}/new-source-script.sh"
rm -f ${ENVFILE}
echo "#/bin/bash" >> ${ENVFILE}
echo " " >> ${ENVFILE}
echo "# You can call this file everytime you want to work with COSItools via" >> ${ENVFILE}
echo "# source source.sh" >> ${ENVFILE}
echo "# or put the following line into your .bashrc, .zprofile, etc. file" >> ${ENVFILE}
echo "# . ${COSIPATH}/source.sh" >> ${ENVFILE}
echo " " >> ${ENVFILE}
echo "# Set all the paths" >> ${ENVFILE}
echo "COSITOOLSDIR=${COSIPATH}" >> ${ENVFILE}



############################################################################################################
# Helper functions


# Use the help of the main setup script since it describes the options
confhelp() {
  ${COSIPATH}/cosi-setup/setup.sh --help
}

# Tell the user where to look for past and present issues
issuereport() {
  echo " "
  echo "       Please take a look if you find the issue here (look at open and closed issues):"
  echo "       https://github.com/cositools/cosi-setup/issues"
  echo "       If not add your problem there. The COStools developers will be informed automatically."
  echo " "
}

absolutefilename() {
  echo "$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
}



############################################################################################################
# Extract the main parameters for the stage 1 script

# Check for help
for C in "${CMD[@]}"; do
  if [[ ${C} == *-h ]] || [[ ${C} == *-hel* ]]; then
    echo ""
    confhelp
    exit 0
  fi
done

# Overwrite default options with user options:
for C in "${CMD[@]}"; do
  if [[ ${C} == *-b* ]] && [[ ${C} != *-p*-b* ]]; then
    BRANCH=`echo ${C} | awk -F"=" '{ print $2 }'`
  elif [[ ${C} == *-ro*=* ]]; then
    ROOTPATH=`echo ${C} | awk -F"=" '{ print $2 }'`
  elif [[ ${C} == *-g*=* ]] && [[ ${C} != *-p*-g* ]] ; then
    GEANT4PATH=`echo ${C} | awk -F"=" '{ print $2 }'`
  elif [[ ${C} == *-hea*=* ]]; then
    HEASOFTPATH=`echo ${C} | awk -F"=" '{ print $2 }'`
  elif [[ ${C} == *-o*=* ]]; then
    CPPOPT=`echo ${C} | awk -F"=" '{ print $2 }'`
  elif [[ ${C} == *-d*=* ]]; then
    CPPDEBUG=`echo ${C} | awk -F"=" '{ print $2 }'`
  elif [[ ${C} == *-p*=* ]]; then
    GITPULLBEHAVIOR=`echo ${C} | awk -F"=" '{ print $2 }'`
  elif [[ ${C} == *-ma*=* ]]; then
    MAXTHREADS=`echo ${C} | awk -F"=" '{ print $2 }'`
  elif [[ ${C} == *-i*-m* ]]; then
    IGNOREMISSINGPACKAGES=true
  elif [[ ${C} == *-k*-e* ]]; then
    KEEPENVASIS=`echo ${C} | awk -F"=" '{ print $2 }'`
  elif [[ ${C} == *-e* ]] && [[ ${C} != *-k*-e* ]]; then
    EXTRAS=`echo ${C} | awk -F"=" '{ print $2 }'`
    EXTRAS=${EXTRAS/,/ }
  elif [[ ${C} == *-h ]] || [[ ${C} == *-hel* ]]; then
    echo ""
    confhelp
    exit 0
  else
    echo ""
    echo "ERROR: Unknown command line option: ${C}"
    echo "       See \"./setup.sh --help\" for a list of options"
    exit 1
  fi
done



############################################################################################################
# Sanity checks

# Setup the path to the COSI installation

echo ""
echo ""
echo "*****************************"
echo "" 
echo "Verifying input data"


# Everything to lower case:
OSTYPE=`echo ${OSTYPE} | tr '[:upper:]' '[:lower:]'`
CPPOPT=`echo ${CPPOPT} | tr '[:upper:]' '[:lower:]'`
CPPDEBUG=`echo ${CPPDEBUG} | tr '[:upper:]' '[:lower:]'`
KEEPENVASIS=`echo ${KEEPENVASIS} | tr '[:upper:]' '[:lower:]'`
GITPULLBEHAVIOR=`echo ${GITPULLBEHAVIOR} | tr '[:upper:]' '[:lower:]'`

# Provide feed back and perform error checks:

if [[ "${IGNOREMISSINGPACKAGES}" == true ]]; then
  echo " * Do not check for missing packages"
else
  echo " * Check for missing packages"
fi

if [[ ${KEEPENVASIS} == of* ]] || [[ ${KEEPENVASIS} == n* ]] || [[ ${KEEPENVASIS} == f* ]]; then
  KEEPENVASIS="false"
  echo " * Clearing the environment paths PATH, LD_LIBRARY_PATH, CPATH"
  # We cannot clean PATH, otherwise no programs can be found anymore
  export LD_LIBRARY_PATH=""
  export CPATH=""
elif [[ ${KEEPENVASIS} == on ]] || [[ ${KEEPENVASIS} == y* ]] || [[ ${KEEPENVASIS} == t* ]]; then
  KEEPENVASIS="true"
  echo " * Keeping the existing environment paths as is."
else
  echo " "
  echo "ERROR: Unknown option for keeping MEGAlib or not: ${KEEPENVASIS}"
  confhelp
  exit 1
fi

if [[ ${BRANCH} != "" ]]; then
  echo " * Use default branch ${BRANCH}"
else
  BRANCH="master" # Will switch to main if non-existent
  echo " * Use the main branch"
fi


if [ "${ROOTPATH}" == "" ]; then
  echo " * Download latest compatible version of ROOT"
else
  echo " * Use this ROOT installation option: ${ROOTPATH}"
fi


if [ "${GEANT4PATH}" != "" ]; then
  GEANT4PATH=`absolutefilename ${GEANT4PATH}`
fi
if [[ "${GEANT4PATH}" != "${GEANT4PATH% *}" ]]; then
  echo "ERROR: Geant4 needs to be installed in a path without spaces,"
  echo "       but you chose: \"${GEANT4PATH}\""
  exit 1
fi
if [ "${GEANT4PATH}" == "" ]; then
  echo " * Download latest compatible version of Geant4"
else
  echo " * Use this installation of Geant4: ${GEANT4PATH}"
fi

if [[ "${HEASOFTPATH}" == "off" ]]; then
  echo " * Do not install HEASoft"
elif [[ "${HEASOFTPATH}" == "cfitsio" ]]; then
  echo " * Download the latest version of cfitsio"
elif [[ "${HEASOFTPATH}" == "heasoft" ]] || [[ "${HEASOFTPATH}" == "" ]] ; then
  echo " * Download the latest version of HEASoft"
else
  HEASOFTPATH=`absolutefilename ${HEASOFTPATH}`
  if [[ "${HEASOFTPATH}" != "${HEASOFTPATH% *}" ]]; then
    echo "ERROR: HEASoft needs to be installed in a path without spaces,"
    echo "       but you chose: \"${HEASOFTPATH}\""
    exit 1
  fi
  if [ "${HEASOFTPATH}" == "" ]; then
    echo " * Download latest compatible version of HEASoft"
  else
    echo " * Use this installation of HEASoft: ${HEASOFTPATH}"
  fi
fi


if [[ ${OSTYPE} == *inux* ]]; then
  OSTYPE="linux"
  echo " * Use operating system architecture Linux"
elif ( [[ ${OSTYPE} == d* ]] || [[ ${OSTYPE} == m* ]] ); then
  OSTYPE="darwin"
  echo " * Use operating system architecture Darwin (macOS)"
else
  echo " "
  echo "ERROR: Unknown operating system architecture: \"${OSTYPE}\""
  confhelp
  exit 1
fi


if ( [[ ${CPPOPT} == of* ]] || [[ ${CPPOPT} == no ]] ); then
  OPT="off"
  echo " * Use no C++ code optimizations"
elif ( [[ ${CPPOPT} == nor* ]] || [[ ${CPPOPT} == on ]] || [[ ${CPPOPT} == y* ]] ); then
  OPT="normal"
  echo " * Use normal C++ code optimizations"
elif ( [[ ${CPPOPT} == s* ]] || [[ ${CPPOPT} == h* ]] ); then
  OPT="strong"
  echo " * Use strong, CPU-specific code optimizations"
else
  echo " "
  echo "ERROR: Unknown code optimization: ${CPPOPT}"
  confhelp
  exit 1
fi


if ( [[ ${CPPDEBUG} == of* ]] || [[ ${CPPDEBUG} == no ]] ); then
  DEBUG="off"
  echo " * Use no debugging symbols"
elif ( [[ ${CPPDEBUG} == on ]] || [[ ${CPPDEBUG} == y* ]] || [[ ${CPPDEBUG} == nor* ]] ); then
  DEBUG="normal"
  echo " * Use debugging symbols (system specific)"
elif ( [[ ${CPPDEBUG} == st* ]] || [[ ${CPPDEBUG} == h* ]] ); then
  DEBUG="strong"
  echo " * Use more debugging symbols (system specific)"
else
  echo " "
  echo "ERROR: Unknown debugging code selection: ${CPPDEBUG}"
  confhelp
  exit 1
fi


if ( [[ ${GITPULLBEHAVIOR} == merge ]] || [[ ${GITPULLBEHAVIOR} == stash ]] || [[ ${GITPULLBEHAVIOR} == no ]]  ); then
  echo " * Use the following git pull behavior: ${GITPULLBEHAVIOR}"
else
  echo " "
  echo "ERROR: Unknown git pull behavior: ${GITPULLBEHAVIOR}"
  confhelp
  exit 1
fi


if [ ! -z "${MAXTHREADS##[0-9]*}" ] 2>/dev/null; then
  echo "ERROR: The maximum number of threads must be a number and not ${MAXTHREADS}!"
  exit 1
fi
if [ "${MAXTHREADS}" -le "0" ]; then
  echo "ERROR: The maximum number of threads must be at least 1 and not ${MAXTHREADS}!"
  exit 1
else
  echo " * Use this maximum number of threads: ${MAXTHREADS}"
fi



############################################################################################################
# Install all software packages

# Setup the path to the COSI installation

echo ""
echo "*****************************"
echo "" 
echo "Checking if all software packages are installed"

if [[ "${IGNOREMISSINGPACKAGES}" == true ]]; then
  echo ""
  echo "Not checking for missing packages."
else 
  # macOS
  if [[ ${OSTYPE} == *arwin* ]]; then
  
    # Check if Xcode is installed
    type xcode-select >/dev/null 2>&1
    if [ $? -ne 0 ]; then
      echo ""
      echo "ERROR: Cannot find Xcode. Please install XCode first form the App Store."
      echo " "
      echo "       Debugging: Failed test: Cannot find program xcode-select"
      echo " "
      exit 1
    fi
 
    # Check if the Xcode command line tools are installed
    CLTPATH=$(xcode-select -p)
    if [ $? -ne 0 ]; then
      echo ""
      echo "ERROR: Cannot find the Xcode command line tools. Please install them via:"
      echo " "
      echo "       xcode-select --install"
      echo " "
      echo "       Debugging: Failed test: \"xcode-select -p\" does not return 0 as it would on success)"
      echo " "
      exit 1
    fi
    if [[ ! -d "${CLTPATH}" ]]; then
      echo ""
      echo "ERROR: Cannot find the path to the Xcode command line tools. Please install them via:"
      echo " "
      echo "       xcode-select --install"
      echo " "
      echo "       Debugging: Failed test: \"xcode-select -p\" does not return the path to the Xcode command line tools"
      echo " "
      exit 1
    fi
    
    # Check if just the command line tools have been installed:
    XBOUT=$(xcodebuild -usage 2>&1)
    if [[ ${XBOUT} == *is\ a\ command\ line\ tools\ instance* ]]; then
      echo " "
      echo "Info: You seem to just have installed the command line tools and not a full instance of Xcode."
      echo "      In most cases this is OK."
      echo "      If you encounter any strange errors please install Xcode."
      echo " "
    else
      # Check if the license has been accepted
      CURRENT_VERSION=`xcodebuild -version | grep '^Xcode\s' | sed -E 's/^Xcode[[:space:]]+([0-9\.]+)/\1/'`
      ACCEPTED_LICENSE_VERSION=`defaults read /Library/Preferences/com.apple.dt.Xcode 2> /dev/null | grep IDEXcodeVersionForAgreedToGMLicense | cut -d '"' -f 2`
      if [[ "${CURRENT_VERSION}" != "${ACCEPTED_LICENSE_VERSION}"* ]]; then
        echo " "
        echo "Error: You have not accepted the XCode license!"
        echo "       Either open XCode to accept the license, or run:"
        echo " "
        echo "       sudo xcodebuild -license accept"
        echo " "
        echo "       Debugging: Current version ${CURRENT_VERSION} from \"xcodebuild -version | grep '^Xcode\s' | sed -E 's/^Xcode[[:space:]]+([0-9\.]+)/\1/'\""
        echo "                  Accepted version ${ACCEPTED_LICENSE_VERSION} from \" defaults read /Library/Preferences/com.apple.dt.Xcode 2> /dev/null | grep IDEXcodeVersionForAgreedToGMLicense | cut -d '\"' -f 2"
        echo " "
        echo "       If this error persists, please delete the file which stores which license has been accepted, and accept again:"
        echo "       sudo rm /Library/Preferences/com.apple.dt.Xcode.plist"
        echo "       sudo xcodebuild -license accept"
        echo " "
        exit 1
      fi
    fi
    
    # Check if the latest version is installed:
    UPDATEREQUIRED=$(softwareupdate --list 2>&1 | grep "Command Line Tools")
    if [[ ${UPDATEREQUIRED} != "" ]]; then
      echo ""
      echo "ERROR: There are missing updates for the command line tools."
      echo "       Please install them either via the normal macOS software update interface (preferred) or via the command line (does not always work):"
      echo " "
      echo "       softwareupdate --install -a"
      echo " "
      echo "       Debugging: Failed test: \"(softwareupdate --list 2>&1 | grep \"Command Line Tools\"\" contained the string \"Command Line Tools\""
      echo " "
      exit 1
    fi
    
  
    # Look for macports
    type port >/dev/null 2>&1
    if [ $? -eq 0 ]; then
      if [[ ! -f ${SETUPPATH}/setup-packages-macports.sh ]]; then
        echo ""
        echo "ERROR: Unable to find the macports package script!"
        exit 1
      fi

      ${SETUPPATH}/setup-packages-macports.sh
      EXITCODE=$?
      if [ "${EXITCODE}" != "0" ]; then
        # The error message is part of the above script
        exit ${EXITCODE}
      fi
    else
      type brew >/dev/null 2>&1
      if [ $? -eq 0 ]; then
        if [[ ! -f ${SETUPPATH}/setup-packages-brew.sh ]]; then
          echo ""
          echo "ERROR: Unable to find the brew package script!"
          exit 1
        fi

        ${SETUPPATH}/setup-packages-brew.sh
        EXITCODE=$?
        if [ "${EXITCODE}" != "0" ]; then
          # The error message is part of the above script
          exit ${EXITCODE}
        fi
        
        # We need a specific version of python for the next steps, and brew does not set it, thus we have to do it:
        PATHTOPYTHON=$(${SETUPPATH}/setup-packages-brew.sh --python-path)
        if [[ ${PATHTOPYTHON} == *libexec* ]]; then
          export PATH=${PATHTOPYTHON}:${PATH}
        else
          echo ""
          echo "ERROR: Unable to retrieve python path"
          exit 1
        fi
      else
        echo ""
        echo "ERROR: Please install homebrew (preferred) or macports to install the required COSItools packages"
        exit 1
      fi
    fi
  # Any Linux
  elif [[ ${OSTYPE} == *inux* ]]; then
    if [[ ! -f ${SETUPPATH}/setup-packages-linux.sh ]]; then
      echo ""
      echo "ERROR: Unable to find the linux package script!"
      exit 1
    fi

    ${SETUPPATH}/setup-packages-linux.sh
    EXITCODE=$?
    if [ "${EXITCODE}" != "0" ]; then
      # The error message is part of the above script
      exit ${EXITCODE}
    fi
  else  
    echo ""
    echo "ERROR: You are using an unsupported operating system: ${OSTYPE}"
    exit 1
  fi
fi

# Make sure git lfs is setup
echo ""
echo "Setting up git lfs"
git lfs install
if [ "$?" != "0" ]; then
  echo ""
  echo "ERROR: Unable to setup git lfs"
  exit 1
fi




############################################################################################################
# Install ROOT

echo ""
echo "*****************************"
echo "" 
echo "Installing ROOT"
echo " "

ISPATH="TRUE"
echo "${ROOTPATH}"
if [[ ${ROOTPATH} == "" ]]; then
  ISPATH="FALSE"
elif [[ ${ROOTPATH} == ?.?? ]]; then
  ISPATH="FALSE"
elif [[ ${ROOTPATH} == master ]]; then
  echo "master"
  ISPATH="FALSE"
elif [[ ${ROOTPATH} == v?-??-?? ]]; then
  ISPATH="FALSE"
elif [[ ${ROOTPATH} == v?-??-??-patches ]]; then
  ISPATH="FALSE"
fi

# If we are given an existing ROOT installation, check is it is compatible
if [[ ${ISPATH} == TRUE ]]; then
  # Make an absolute path and check for spaces
  ROOTPATH=`absolutefilename ${ROOTPATH}`
  if [[ "${ROOTPATH}" != "${ROOTPATH% *}" ]]; then
    echo "ERROR: ROOT needs to be installed in a path without spaces,"
    echo "       but you chose: \"${ROOTPATH}\""
    exit 1
  fi

  # Check if we can use the given ROOT version
  if [[ ! -f ${SETUPPATH}/check-rootversion.sh ]]; then
    echo ""
    echo "ERROR: Unable to find the script to check the ROOT version!"
    exit 1
  fi
  
  ${SETUPPATH}/check-rootversion.sh --check=${ROOTPATH}
  if [ "$?" != "0" ]; then
    echo " "
    echo "ERROR: The directory ${ROOTPATH} cannot be used as your ROOT install for COSItools."
    exit 1
  fi
  
  # Add ROOT to the environment file
  echo "ROOTDIR=$(cd $(dirname ${ROOTPATH}); pwd)/$(basename ${ROOTPATH})" >> ${ENVFILE}
  
  # Source ROOT to be available for later installs
  . ${SETUPPATH}/source-root.sh -p=$(cd $(dirname ${ROOTPATH}); pwd)/$(basename ${ROOTPATH})
  if [[ "$?" != "0" ]]; then
    echo " "
    echo "ERROR: Unable to source ROOT"
    exit 1
  fi
  
# Install a new version of ROOT
else
  # Download and build a new ROOT version
  if [[ ! -f ${SETUPPATH}/build-root.sh ]]; then
    echo ""
    echo "ERROR: Unable to find the script to check the ROOT version!"
    exit 1
  fi
  
  echo "Switching to build-root.sh script..."
  
  cd ${EXTERNALPATH}
  
  bash ${SETUPPATH}/build-root.sh -root=${ROOTPATH} -source=${ENVFILE} -patch=no --debug=${CPPDEBUG} --maxthreads=${MAXTHREADS} --cleanup=yes --keepenvironmentasis=${KEEPENVASIS} 2>&1 | tee BuildLogROOT.txt
  RESULT=${PIPESTATUS[0]}

  # If we have a new ROOT directory, copy the build log there
  NEWROOTDIR=`grep ROOTDIR\= ${ENVFILE} | awk -F= '{ print $2 }'`
  if [[ -d ${NEWROOTDIR} ]]; then
    if [[ -f ${NEWROOTDIR}/BuildLogROOT.txt ]]; then
      mv ${NEWROOTDIR}/BuildLogROOT.txt ${NEWROOTDIR}/BuildLogROOT_before$(date +'%y%m%d%H%M%S').txt
    fi
    mv BuildLogROOT.txt ${NEWROOTDIR}
  fi

  # Now handle build errors
  if [ "${RESULT}" != "0" ]; then
    echo " "
    echo "ERROR: Something went wrong during the ROOT setup."
    if [[ -d ${NEWROOTDIR} ]]; then
      echo "       Please check the *whole* file ${NEWROOTDIR}/BuildLogROOT.txt for errors."
    else 
      echo "       Please check the *whole* file $(pwd)/BuildLogROOT.txt for errors."
    fi
    echo " "
    echo "       Since this is an issue with ROOT and not MEGAlib, please try to google the error message, "
    echo "       because other ROOT users might face the same issue."
    echo " "
    echo "       If that fails, please take a look if you find the issue here (look at open and closed issues):"
    echo "       https://github.com/cositools/cosi-setup/issues"
    echo " "
    echo "       If not, please add your problem there and attach your BuildLogROOT.txt file."
    echo " "
    exit 1
  fi
  
  # Source ROOT to be available for later installs
  . ${SETUPPATH}/source-root.sh -p=${NEWROOTDIR}
  if [[ "$?" != "0" ]]; then
    echo " "
    echo "ERROR: Unable to source ROOT"
    exit 1
  fi
  
  # The build-script will have added ROOT to the environment file
fi

echo " "
echo "SUCCESS: We have a usable ROOT version!"



############################################################################################################
# Install Geant4

echo ""
echo "*****************************"
echo " "
echo "Installing Geant4"
echo " "

# If we are given an existing Geant4 installation, check is it is compatible
if [ "${GEANT4PATH}" != "" ]; then
  # Check if we can use the given Geant4 version
  if [[ ! -f ${SETUPPATH}/check-geant4version.sh ]]; then
    echo ""
    echo "ERROR: Unable to find the script to check the Geant4 version!"
    exit 1
  fi
  
  ${SETUPPATH}/check-geant4version.sh --check=${GEANT4PATH}
  if [ "$?" != "0" ]; then
    echo " "
    echo "ERROR: The directory ${GEANT4PATH} cannot be used as your Geant4 install for COSItools."
    exit 1
  fi
  
  # Add Geant4 to the environment file
  echo "GEANT4DIR=$(cd $(dirname ${GEANT4PATH}); pwd)/$(basename ${GEANT4PATH})" >> ${ENVFILE}
  
  # Source Geant4 to be available for later installs
  . ${SETUPPATH}/source-geant4.sh -p=$(cd $(dirname ${GEANT4PATH}); pwd)/$(basename ${GEANT4PATH})
  if [[ "$?" != "0" ]]; then
    echo " "
    echo "ERROR: Unable to source Geant4"
    exit 1
  fi
  
# Install a new version of Geant4
else
  # Download and build a new Geant4 version
  if [[ ! -f ${SETUPPATH}/build-geant4.sh ]]; then
    echo ""
    echo "ERROR: Unable to find the script to check the Geant4 version!"
    exit 1
  fi
  
  echo "Switching to build-geant4.sh script..."
  cd ${EXTERNALPATH}
  
  bash ${SETUPPATH}/build-geant4.sh -source=${ENVFILE} -patch=no --debug=${CPPDEBUG} --maxthreads=${MAXTHREADS} --cleanup=yes --keepenvironmentasis=${KEEPENVASIS} 2>&1 | tee BuildLogGeant4.txt
  RESULT=${PIPESTATUS[0]}

  # If we have a new Geant4 dir, copy the build log there
  NEWGEANT4DIR=`grep GEANT4DIR\= ${ENVFILE} | awk -F= '{ print $2 }'`
  if [[ -d ${NEWGEANT4DIR} ]]; then
    if [[ -f ${NEWGEANT4DIR}/BuildLogGeant4.txt ]]; then
      mv ${NEWGEANT4DIR}/BuildLogGeant4.txt ${NEWGEANT4DIR}/BuildLogGeant4_before$(date +'%y%m%d%H%M%S').txt
    fi
    mv BuildLogGeant4.txt ${NEWGEANT4DIR}
  fi

  # Now handle build errors
  if [ "${RESULT}" != "0" ]; then
    echo " "
    echo "ERROR: Something went wrong during the Geant4 setup."
    issuereport
    exit 1
  fi
  
  # Source Geant4 to be available for later installs
  . ${SETUPPATH}/source-geant4.sh -p=${NEWGEANT4DIR}
  if [[ "$?" != "0" ]]; then
    echo " "
    echo "ERROR: Unable to source Geant4"
    exit 1
  fi
    
  # The build-script will have added Geant4 to the environment file
fi

echo " "
echo "SUCCESS: We have a usable Geant4 version!"



############################################################################################################
# Install HEASoft/cfitsio

echo ""
echo "*****************************"
echo " "
echo "Installing HEASoft/cfitsio"
echo " "

# We do not want to install HEASoft
if [[ "${HEASOFTPATH}" == "off" ]]; then

  echo " "
  echo "Command line option --heasoft=off: Do not install HEASoft"


# Compile cfitsio instead of full HEASoft
elif [[ "${HEASOFTPATH}" == "cfitsio" ]]; then

  # Download and build a new cfitsio version
  if [[ ! -f ${SETUPPATH}/build-cfitsio.sh ]]; then
    echo ""  
    echo "ERROR: Unable to find the script to build cfitsio!"
    exit 1
  fi
  
  echo "Switching to build-cfitsio.sh script..."
  cd ${EXTERNALPATH}

  ${SETUPPATH}/build-cfitsio.sh -source=${ENVFILE} 2>&1 | tee BuildLogCFitsIO.txt
  RESULT=${PIPESTATUS[0]}
  
  
  # If we have a new cfitsio dir, copy the build log there
  NEWCFITSIODIR=`grep CFITSIODIR\= ${ENVFILE} | awk -F= '{ print $2 }'`
  if [[ -d ${NEWCFITSIODIR} ]]; then
    if [[ -f ${NEWCFITSIODIR}/BuildLogCFitsIO.txt ]]; then
      mv ${NEWCFITSIODIR}/BuildLogCFitsIO.txt ${NEWCFITSIODIR}/BuildLogCFitsIO_before$(date +'%y%m%d%H%M%S').txt
    fi
    mv BuildLogCFitsIO.txt ${NEWCFITSIODIR}
  fi
  
  # Now handle build errors
  if [ "${RESULT}" != "0" ]; then
    echo " "
    echo "ERROR: Something went wrong during the cfitsio setup."
    issuereport
    exit 1
  fi
  
  # Source cfitsio to be available for later installs
  . ${SETUPPATH}/source-cfitsio.sh -p=${NEWCFITSIODIR}
  if [[ "$?" != "0" ]]; then
    echo " "
    echo "ERROR: Unable to source cfitsio"
    exit 1
  fi
    
  # The build-script will have added cfitsio to the environment file

  cd ${COSIPATH}

  echo " "
  echo "SUCCESS: We have a usable cfitsio version!"


# Compile HEASoft
elif [[ "${HEASOFTPATH}" == "heasoft" ]] || [[ "${HEASOFTPATH}" == "" ]]; then

  # Download and build a new HEASoft version
  if [[ ! -f ${SETUPPATH}/build-heasoft.sh ]]; then
    echo ""
    echo "ERROR: Unable to find the script to check the HEASoft version!"
    exit 1
  fi

  echo "Switching to build-heasoft.sh script..."
  cd ${EXTERNALPATH}

  ${SETUPPATH}/build-heasoft.sh -source=${ENVFILE} 2>&1 | tee BuildLogHEASoft.txt
  RESULT=${PIPESTATUS[0]}


  # If we have a new HEASoft dir, copy the build log there
  NEWHEASOFTDIR=`grep HEASOFTDIR\= ${ENVFILE} | awk -F= '{ print $2 }'`
  if [[ -d ${NEWHEASOFTDIR} ]]; then
    if [[ -f ${NEWHEASOFTDIR}/BuildLogHEASoft.txt ]]; then
      mv ${NEWHEASOFTDIR}/BuildLogHEASoft.txt ${NEWHEASOFTDIR}/BuildLogHEASoft_before$(date +'%y%m%d%H%M%S').txt
    fi
    mv BuildLogHEASoft.txt ${NEWHEASOFTDIR}
  fi

  # Now handle build errors
  if [ "${RESULT}" != "0" ]; then
    echo " "
    echo "ERROR: Something went wrong during the HEASoft setup."
    issuereport
    exit 1
  fi

  # Source HEASoft to be available for later installs
  . ${SETUPPATH}/source-heasoft.sh -p=${NEWHEASOFTDIR}
  if [[ "$?" != "0" ]]; then
    echo " "
    echo "ERROR: Unable to source HEAsoft"
    exit 1
  fi

  # The build-script will have added HEAsoft to the environment file

  cd ${COSIPATH}

  echo " "
  echo "SUCCESS: We have a usable HEASoft version!"


# If we are given an existing HEASoft installation, check if it is compatible
else
  # Check if we can use the given HEASoft version
  if [[ ! -f ${SETUPPATH}/check-heasoftversion.sh ]]; then
    echo ""
    echo "ERROR: Unable to find the script to check the HEASoft version!"
    exit 1
  fi
  
  ${SETUPPATH}/check-heasoftversion.sh --check=${HEASOFTPATH}
  if [[ "$?" != "0" ]]; then
    echo " "
    echo "ERROR: The directory ${HEASOFTPATH} cannot be used as your HEASoft install for COSItools."
    exit 1
  fi
  
  # Add HEASoft to the environment file
  echo "HEASOFTDIR=$(cd $(dirname ${HEASOFTPATH}); pwd)/$(basename ${HEASOFTPATH})" >> ${ENVFILE}
  
  # Source HEASoft to be available for later installs
  . ${SETUPPATH}/source-heasoft.sh -p=$(cd $(dirname ${HEASOFTPATH}); pwd)/$(basename ${HEASOFTPATH})
  if [[ "$?" != "0" ]]; then
    echo " "
    echo "ERROR: Unable to source HEAsoft"
    exit 1
  fi
  
  cd ${COSIPATH}

  echo " "
  echo "SUCCESS: We have a usable HEASoft version!"
fi



############################################################################################################
# Install MEGAlib

echo ""
echo "*****************************"
echo " "
echo "Installing MEGAlib"
echo " "

echo "Switching to file setup-retrieve-git-repository.sh"
if [[ ! -f ${SETUPPATH}/setup-retrieve-git-repository.sh ]]; then
  echo ""
  echo "ERROR: Unable to find the script to git repositories!"
  exit 1
fi

${SETUPPATH}/setup-retrieve-git-repository.sh -c=${COSIPATH} -n=megalib -b=${BRANCH} -r=https://github.com/zoglauer/megalib.git -p=${GITPULLBEHAVIOR} -s=${STASHNAME}
REPOSTATUS=$?
if [ ${REPOSTATUS} -ge 2 ]; then
  echo " "
  echo "ERROR: Something went wrong while retrieving MEGAlib from the repository"
  issuereport
  exit 1
fi  


cd ${COSIPATH}/megalib

# Check if MEGAlib has been compiled
if [ ${REPOSTATUS} -eq 0 ]; then
  if [[ ! -f bin/cosima ]]; then
    REPOSTATUS=1
  fi
fi

# Now check if we need to recompile
export MEGALIB=${COSIPATH}/megalib
if [[ "$(bin/megalib-config --compiler)" != "$(gcc --version | head -n 1)" ]]; then
  REPOSTATUS=1
elif [[ "$(bin/megalib-config --python3)" != "$(python3 --version)" ]]; then
  REPOSTATUS=1
elif [[ "$(bin/megalib-config --root)" != "$(root-config --version)" ]]; then
  REPOSTATUS=1
elif [[ "$(bin/megalib-config --geant4)" != "$(geant4-config --version)" ]]; then
  REPOSTATUS=1
fi

MEGALIBRECOMPILED="FALSE"
if [ ${REPOSTATUS} -eq 1 ]; then
  echo "MEGAlib needs to be compiled"

  echo "Configuring MEGAlib..."
  bash configure --os=${OSTYPE} --debug=${CPPDEBUG} --opt=${CPPOPT} --updates=off
  if [ "$?" != "0" ]; then
    echo " "
    echo "ERROR: Something went wrong during MEGAlib configuration"
    issuereport
    exit 1
  fi


  echo "Compiling MEGAlib..."
  make -j${MAXTHREADS}
  if [ "$?" != "0" ]; then
    echo "ERROR: Something went wrong while compiling MEGAlib!"
    issuereport
    exit 1
  fi

  MEGALIBRECOMPILED="TRUE"
fi

echo "MEGALIBDIR=${COSIPATH}/megalib" >> ${ENVFILE}

cd ${COSIPATH}

echo " "
echo "SUCCESS: MEGAlib has been installed" 



############################################################################################################
# Install Nuclearizer

echo ""
echo "*****************************"
echo " "
echo "Installing nuclearizer"
echo " "

echo "Switching to file setup-retrieve-git-repository.sh"
${SETUPPATH}/setup-retrieve-git-repository.sh -c=${COSIPATH} -n=nuclearizer -b=${BRANCH} -r=https://github.com/cositools/nuclearizer.git -p=${GITPULLBEHAVIOR} -s=${STASHNAME}
REPOSTATUS=$?
if [ ${REPOSTATUS} -ge 2 ]; then
  echo " "
  echo "ERROR: Something went wrong while retrieving nuclearizer from the repository"
  issuereport
  exit 1
fi  

cd ${COSIPATH}/nuclearizer

# Check if Nuclearizer has been compiled
if [ ${REPOSTATUS} -eq 0 ]; then
  if [[ ! -f ${COSIPATH}/megalib/bin/nuclearizer ]]; then
    REPOSTATUS=1
  fi
fi

# Check if MEGAlib has been compiled
if [[ ${MEGALIBRECOMPILED} == "TRUE" ]]; then
  REPOSTATUS=1
fi


if [ ${REPOSTATUS} -eq 1 ]; then
  echo "Nuclearizer needs to be compiled"

  echo "Compiling Nuclearizer..."
  export NUCLEARIZER=${COSIPATH}/nuclearizer
  make clean
  make -j${MAXTHREADS}
  if [ "$?" != "0" ]; then
    echo "ERROR: Something went wrong while compiling MEGAlib!"
    issuereport
    exit 1
  fi
fi

echo "NUCLEARIZERDIR=${COSIPATH}/nuclearizer" >> ${ENVFILE}

cd ${COSIPATH}

echo " "
echo "SUCCESS: Nuclearizer has been installed" 



############################################################################################################
# Install CosiPy

echo ""
echo "*****************************"
echo " "
echo "Installing cosipy"
echo " "

echo "Switching to file setup-retrieve-git-repository.sh"
${SETUPPATH}/setup-retrieve-git-repository.sh -c=${COSIPATH} -n=cosipy -b=${BRANCH} -r=https://github.com/cositools/cosipy.git -p=${GITPULLBEHAVIOR} -s=${STASHNAME}
REPOSTATUS=$?
if [ ${REPOSTATUS} -ge 2 ]; then
  echo " "
  echo "ERROR: Something went wrong while retrieving cosipy from the repository"
  issuereport
  exit 1
fi  

echo " "
echo "SUCCESS: COSIpy has been installed" 



############################################################################################################
# Install COSIpy-classic

echo ""
echo "*****************************"
echo " "
echo "Installing cosipy-classic"
echo " "

echo "Switching to file setup-retrieve-git-repository.sh"
${SETUPPATH}/setup-retrieve-git-repository.sh -c=${COSIPATH} -n=cosipy-classic -b=${BRANCH} -r=https://github.com/tsiegert/cosipy.git -p=${GITPULLBEHAVIOR} -s=${STASHNAME}
REPOSTATUS=$?
if [ ${REPOSTATUS} -ge 2 ]; then
  echo " "
  echo "ERROR: Something went wrong while retrieving cosipy-classic from the repository"
  issuereport
  exit 1
fi  

echo " "
echo "SUCCESS: cosipy-classic has been installed" 



############################################################################################################
# Install cosi-data-challenge

echo ""
echo "*****************************"
echo " "
echo "Installing cosi-data-challenges"
echo " "

echo "Switching to file setup-retrieve-git-repository.sh"
${SETUPPATH}/setup-retrieve-git-repository.sh -c=${COSIPATH} -n=cosi-data-challenges -b=${BRANCH} -r=https://github.com/cositools/cosi-data-challenges.git -p=${GITPULLBEHAVIOR} -s=${STASHNAME}
REPOSTATUS=$?
if [ ${REPOSTATUS} -ge 2 ]; then
  echo " "
  echo "ERROR: Something went wrong while retrieving cosi-data-challenges from the repository"
  issuereport
  exit 1
fi  

echo " "
echo "SUCCESS: cosi-data-challenges has been installed" 



############################################################################################################
# Install cosi-docs

echo ""
echo "*****************************"
echo " "
echo "Installing cosi-docs"
echo " "

echo "Switching to file setup-retrieve-git-repository.sh"
${SETUPPATH}/setup-retrieve-git-repository.sh -c=${COSIPATH} -n=cosi-docs -b=${BRANCH} -r=https://github.com/cositools/cosi-docs.git -p=${GITPULLBEHAVIOR} -s=${STASHNAME}
REPOSTATUS=$?
if [ ${REPOSTATUS} -ge 2 ]; then
  echo " "
  echo "ERROR: Something went wrong while retrieving cosi-docs from the repository"
  issuereport
  exit 1
fi  

echo " "
echo "SUCCESS: cosi-docs has been installed" 



############################################################################################################
# Install mass models

echo ""
echo "*****************************"
echo " "
echo "Installing mass models"
echo " "

# All mass models are in a subdirectory massmodels
if [[ ! -d massmodels ]]; then
  mkdir massmodels
fi

# First retrieve the mass model repositories

echo "Retrieving Coserl"
${SETUPPATH}/setup-retrieve-git-repository.sh -c=${COSIPATH}/massmodels -n=massmodel-coserl -b=${BRANCH} -r=https://github.com/cositools/massmodel-coserl.git -p=${GITPULLBEHAVIOR} -s=${STASHNAME}
REPOSTATUS=$?
if [ ${REPOSTATUS} -ge 2 ]; then
  echo " "
  echo "ERROR: Something went wrong while retrieving massmodel-coserl from the repository"
  issuereport
  exit 1
fi

VERSIONEDBRANCHES=$(git -C massmodels/massmodel-coserl branch -r | sed 's/origin\///g' | awk '{$1=$1;print}' | grep "^v")
for V in ${VERSIONEDBRANCHES}; do
  if [[ ! -d massmodels/massmodel-coserl-${V} ]]; then
    git clone -c advice.detachedHead=false --branch ${V} https://github.com/cositools/massmodel-coserl massmodels/massmodel-coserl-${V}
    if [ "$?" != "0" ]; then
      echo " "
      echo "ERROR: Something went wrong while retrieving massmodel-coserl (${V}) from the repository"
      issuereport
      exit 1
    fi  
    rm -rf massmodels/massmodel-coserl-${V}/.git
  fi
done
echo ""

echo "Retrieving COSI balloon"
${SETUPPATH}/setup-retrieve-git-repository.sh -c=${COSIPATH}/massmodels -n=massmodel-cosi-balloon -b=${BRANCH} -r=https://github.com/cositools/massmodel-cosi-balloon.git -p=${GITPULLBEHAVIOR} -s=${STASHNAME}
REPOSTATUS=$?
if [ ${REPOSTATUS} -ge 2 ]; then
  echo " "
  echo "ERROR: Something went wrong while retrieving massmodel-cosi-balloon from the repository"
  issuereport
  exit 1
fi  

VERSIONEDBRANCHES=$(git -C massmodels/massmodel-cosi-balloon branch -r | sed 's/origin\///g' | awk '{$1=$1;print}' | grep "^v")
for V in ${VERSIONEDBRANCHES}; do
  if [[ ! -d massmodels/massmodel-cosi-balloon-${V} ]]; then
    git clone -c advice.detachedHead=false --branch ${V} https://github.com/cositools/massmodel-cosi-balloon massmodels/massmodel-cosi-balloon-${V}
    if [ "$?" != "0" ]; then
      echo " "
      echo "ERROR: Something went wrong while retrieving massmodel-cosi-balloon (${V}) from the repository"
      issuereport
      exit 1
    fi  
    rm -rf massmodels/massmodel-cosi-balloon-${V}/.git
  fi
done
echo ""


echo "Retrieving Compton sphere"
${SETUPPATH}/setup-retrieve-git-repository.sh -c=${COSIPATH}/massmodels -n=massmodel-comptonsphere -b=${BRANCH} -r=https://github.com/cositools/massmodel-comptonsphere.git -p=${GITPULLBEHAVIOR} -s=${STASHNAME}
REPOSTATUS=$?
if [ ${REPOSTATUS} -ge 2 ]; then
  echo " "
  echo "ERROR: Something went wrong while retrieving massmodel-comptonsphere from the repository"
  issuereport
  exit 1
fi

VERSIONEDBRANCHES=$(git -C massmodels/massmodel-comptonsphere branch -r | sed 's/origin\///g' | awk '{$1=$1;print}' | grep "^v")
for V in ${VERSIONEDBRANCHES}; do
  if [[ ! -d massmodels/massmodel-comptonsphere-${V} ]]; then
    git clone -c advice.detachedHead=false --branch ${V} https://github.com/cositools/massmodel-comptonsphere massmodels/massmodel-comptonsphere-${V}
    if [ "$?" != "0" ]; then
      echo " "
      echo "ERROR: Something went wrong while retrieving massmodel-comptonsphere (${V}) from the repository"
      issuereport
      exit 1
    fi
    rm -rf massmodels/massmodel-comptonsphere-${V}/.git
  fi
done
echo ""

cd ${COSIPATH}



############################################################################################################
# Install extra repositories

if [[ ${EXTRAS} != "" ]]; then
  for REPO in ${EXTRAS}; do 
    echo ""
    echo "*****************************"
    echo " "
    echo "Installing extra repository ${REPO}"
    echo " "
    echo "Switching to file setup-retrieve-git-repository.sh"
    ${SETUPPATH}/setup-retrieve-git-repository.sh -c=${COSIPATH} -n=${REPO} -b=${BRANCH} -r=https://github.com/cositools/${REPO}.git -p=${GITPULLBEHAVIOR} -s=${STASHNAME}
    REPOSTATUS=$?
    if [ ${REPOSTATUS} -ge 2 ]; then
      echo " "
      echo "ERROR: Something went wrong while retrieving ${REPO} from the repository"
      issuereport
      exit 1
    fi  

    echo " "
    echo "SUCCESS: ${REPO} has been installed" 
  done
fi


############################################################################################################
# Setup python environment

echo ""
echo "*****************************"
echo " "
echo "Setting up the python3 environment"
echo " "


if [[ $(uname -a) != *-686-* ]]; then
  cd ${SETUPPATH}

  if [[ ! -f ${SETUPPATH}/setup-python3.sh ]]; then
    echo ""
    echo "ERROR: Unable to find the python setup script!"
    exit 1
  fi

  ${SETUPPATH}/setup-python3.sh
  if [ "$?" != "0" ]; then
    # The error message is part of the above script
    exit 1
  fi
else
  echo ""
  echo "WARNING: You are using a 32-bit operating system."
  echo "         Unfortunately, several required python libraries only support 64-bit OSes"
  echo "         Therefore, I cannot install the python environment, and the python-based parts of COSItools will not work"
  echo ""
fi



############################################################################################################
# Finalize the setup script

echo ""
echo "*****************************"
echo " "
echo "Finalizing setup script"
echo " "

echo " " >> ${ENVFILE}
echo "# Source the inividual environment variables" >> ${ENVFILE}
echo "# Order is important!" >> ${ENVFILE}
echo ". ${SETUPPATH}/source-geant4.sh -p=\${GEANT4DIR}" >> ${ENVFILE}
echo ". ${SETUPPATH}/source-megalib.sh -p=\${MEGALIBDIR}" >> ${ENVFILE}
echo ". ${SETUPPATH}/source-nuclearizer.sh -p=\${NUCLEARIZERDIR}" >> ${ENVFILE}
if grep -q "CFITSIODIR" ${ENVFILE}; then
  echo ". ${SETUPPATH}/source-cfitsio.sh -p=\${CFITSIODIR}" >> ${ENVFILE}
fi
if grep -q "HEASOFTDIR" ${ENVFILE}; then
  echo ". ${SETUPPATH}/source-heasoft.sh -p=\${HEASOFTDIR}" >> ${ENVFILE}
fi
echo ". ${SETUPPATH}/source-root.sh -p=\${ROOTDIR}" >> ${ENVFILE}
echo " " >> ${ENVFILE}
echo "export COSITOOLSDIR=\"${COSIPATH}\"" >> ${ENVFILE}
echo " " >> ${ENVFILE}
if [[ ${PATHTOPYTHON} != "" ]]; then
  echo "export PATH=${PATHTOPYTHON}:\${PATH}" >> ${ENVFILE}
  echo " " >> ${ENVFILE}
fi
echo "alias cosi='cd ${COSIPATH}; source python-env/bin/activate'" >> ${ENVFILE}
echo " "

echo "Renaming and moving the environment script"
mv ${ENVFILE} ${COSIPATH}/source.sh
chmod +x ${COSIPATH}/source.sh

echo "Linking it at the default MEGAlib location"
if [ -f ${COSIPATH}/megalib/bin/source-megalib.sh ]; then
  rm ${COSIPATH}/megalib/bin/source-megalib.sh
fi
ln -s ${COSIPATH}/source.sh ${COSIPATH}/megalib/bin/source-megalib.sh  

echo " "
echo " "

if [[ ! -f ${SETUPPATH}/setup-terminal.sh ]]; then
  echo ""
  echo "ERROR: Unable to find the terminal setup script!"
  exit 1
fi

${SETUPPATH}/setup-terminal.sh


############################################################################################################
# Final remarks

TIMEEND=$(date +%s)
TIMEDIFF=$(( ${TIMEEND} - ${TIMESTART} ))

echo ""
echo "*****************************"
echo " "
echo " "
echo "Finished! Execution duration: ${TIMEDIFF} seconds"
echo " "

exit 0

############################################################################################################





 
