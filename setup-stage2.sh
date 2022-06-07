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

# The command line
CMD=( "$@" )

# The path to where the COSItools will be installed
COSIPATH="$( cd -- "$(dirname ../"$0")" >/dev/null 2>&1 ; pwd -P )"

# The path where the setup scripts are
SETUPPATH="${COSIPATH}/cosi-setup"

# The path to the COSItools install
GITBASEDIR="https://github.com/cositools"
GITBRANCH="main"

# Operating system type
OSTYPE=$(uname -s)

# Keep all environment variables intact or not
KEEPENVASIS="off"

# Ignore the stage where we look for missing packages
IGNOREMISSINGPACKAGES=false

# C++ optimization and debugging options
CPPOPT="normal"
CPPDEBUG="off"

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
  if [[ ${C} == *-b* ]]; then
    BRANCH=`echo ${C} | awk -F"=" '{ print $2 }'`
  elif [[ ${C} == *-ro*=* ]]; then
    ROOTPATH=`echo ${C} | awk -F"=" '{ print $2 }'`
  elif [[ ${C} == *-g*=* ]]; then
    GEANT4PATH=`echo ${C} | awk -F"=" '{ print $2 }'`
  elif [[ ${C} == *-hea*=* ]]; then
    HEASOFTPATH=`echo ${C} | awk -F"=" '{ print $2 }'`
  elif [[ ${C} == *-o*=* ]]; then
    CPPOPT=`echo ${C} | awk -F"=" '{ print $2 }'`
  elif [[ ${C} == *-d*=* ]]; then
    CPPDEBUG=`echo ${C} | awk -F"=" '{ print $2 }'`
  elif [[ ${C} == *-ma*=* ]]; then
    MAXTHREADS=`echo ${C} | awk -F"=" '{ print $2 }'`
  elif [[ ${C} == *--i*-m* ]]; then
    IGNOREMISSINGPACKAGES=true
  elif [[ ${C} == *-k*-e* ]]; then
    KEEPENVASIS=`echo ${C} | awk -F"=" '{ print $2 }'`
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


if [ "${ROOTPATH}" != "" ]; then
  ROOTPATH=`absolutefilename ${ROOTPATH}`
fi
if [[ "${ROOTPATH}" != "${ROOTPATH% *}" ]]; then
  echo "ERROR: ROOT needs to be installed in a path without spaces,"
  echo "       but you chose: \"${ROOTPATH}\""
  exit 1
fi
if [ "${ROOTPATH}" == "" ]; then
  echo " * Download latest compatible version of ROOT"
else
  echo " * Use this installation of ROOT: ${ROOTPATH}"
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
else
  if [[ "${HEASOFTPATH}" != "" ]]; then
    HEASOFTPATH=`absolutefilename ${HEASOFTPATH}`
  fi
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
  
    # First check if Xcode and the XCode command line tools are installed
    type xcode-select >/dev/null 2>&1
    if [ $? -ne 0 ]; then
      echo ""
      echo "ERROR: Cannot find Xcode. Please install XCode first form the App Store."
      echo " "
      exit 1
    fi
    CLTPATH=$(xcode-select -p)
    if [ $? -ne 0 ]; then
      echo ""
      echo "ERROR: Cannot find the Xcode command line tools. Please install them via:"
      echo " "
      echo "xcode-select --install"
      echo " "
      exit 1
    fi
    if [[ ! -d "${CLTPATH}" ]]; then
      echo ""
      echo "ERROR: Cannot find the path to the Xcode command line tools. Please install them via:"
      echo " "
      echo "xcode-select --install"
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
      if [ "$?" != "0" ]; then
        # The error message is part of the above script
        exit 1
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
        if [ "$?" != "0" ]; then
          # The error message is part of the above script
          exit 1
        fi 
      else
        echo ""
        echo "ERROR: Please install macports to install the required COSItools packages:"
        echo "       https://www.macports.org/install.php"s
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
    if [ "$?" != "0" ]; then
      # The error message is part of the above script
      exit 1
    fi
  else  
    echo ""
    echo "ERROR: You are using an unsupported operating system: ${OSTYPE}"
    exit 1
  fi
fi



############################################################################################################
# Install ROOT

echo ""
echo "*****************************"
echo "" 
echo "Installing ROOT"
echo " "

# If we are given an existing ROOT installation, check is it is compatible
if [ "${ROOTPATH}" != "" ]; then
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
  
  bash ${SETUPPATH}/build-root.sh -source=${ENVFILE} -patch=no --debug=${CPPDEBUG} --maxthreads=${MAXTHREADS} --cleanup=yes --keepenvironmentasis=${KEEPENVASIS} 2>&1 | tee BuildLogROOT.txt
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
    echo "ERROR: Unable to find the script to build cfistio!"
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

else 
  # If we are given an existing HEASoft installation, check if it is compatible
  if [[ "${HEASOFTPATH}" != "" ]]; then
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
  
  # Install a new version of HEASoft
  else
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

${SETUPPATH}/setup-retrieve-git-repository.sh -c=${COSIPATH} -n=megalib -b=${BRANCH} -r=https://github.com/zoglauer/megalib.git -s=${STASHNAME}
if [ "$?" != "0" ]; then
  echo " "
  echo "ERROR: Something went wrong while retrieving MEGAlib from the repository"
  issuereport
  exit 1
fi  

cd ${COSIPATH}/megalib

echo "The MEGAlib source code has been updated"

echo "Configuring MEGAlib..."
export MEGALIB=${COSIPATH}/megalib
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
${SETUPPATH}/setup-retrieve-git-repository.sh -c=${COSIPATH} -n=nuclearizer -b=${BRANCH} -r=https://github.com/cositools/nuclearizer.git -s=${STASHNAME}
if [ "$?" != "0" ]; then
  echo " "
  echo "ERROR: Something went wrong while retrieving cosipy from the repository"
  issuereport
  exit 1
fi  
echo "The Nuclearizer source code has been updated"

cd ${COSIPATH}/nuclearizer

echo "Compiling Nuclearizer..."
export NUCLEARIZER=${COSIPATH}/nuclearizer
make clean
make -j${MAXTHREADS}
if [ "$?" != "0" ]; then
  echo "ERROR: Something went wrong while compiling MEGAlib!"
  issuereport
  exit 1
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
${SETUPPATH}/setup-retrieve-git-repository.sh -c=${COSIPATH} -n=cosipy -b=${BRANCH} -r=https://github.com/cositools/cosipy.git -s=${STASHNAME}
if [ "$?" != "0" ]; then
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
${SETUPPATH}/setup-retrieve-git-repository.sh -c=${COSIPATH} -n=cosipy-classic -b=${BRANCH} -r=https://github.com/tsiegert/cosipy.git -s=${STASHNAME}
if [ "$?" != "0" ]; then
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
${SETUPPATH}/setup-retrieve-git-repository.sh -c=${COSIPATH} -n=cosi-data-challenges -b=${BRANCH} -r=https://github.com/cositools/cosi-data-challenges.git -s=${STASHNAME}
if [ "$?" != "0" ]; then
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
${SETUPPATH}/setup-retrieve-git-repository.sh -c=${COSIPATH} -n=cosi-docs -b=${BRANCH} -r=https://github.com/cositools/cosi-docs.git -s=${STASHNAME}
if [ "$?" != "0" ]; then
  echo " "
  echo "ERROR: Something went wrong while retrieving cosi-data-challenges from the repository"
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

echo "Switching to file setup-retrieve-git-repository.sh"
${SETUPPATH}/setup-retrieve-git-repository.sh -c=${COSIPATH}/massmodels -n=massmodel-coserl -b=${BRANCH} -r=https://github.com/cositools/massmodel-coserl.git -s=${STASHNAME}
if [ "$?" != "0" ]; then
  echo " "
  echo "ERROR: Something went wrong while retrieving massmodel-coserl from the repository"
  issuereport
  exit 1
fi  

# Then extract mass model release versions relevant for the data analysis into their own directories
# This is a curated list for the moment

cd massmodels

if [[ ! -d massmodel-coserl-v1 ]]; then
  git clone -c advice.detachedHead=false --branch v1.0 https://github.com/cositools/massmodel-coserl massmodel-coserl-v1
  if [ "$?" != "0" ]; then
    echo " "
    echo "ERROR: Something went wrong while retrieving massmodel-coserl (v1) from the repository"
    issuereport
    exit 1
  fi  
  rm -rf massmodel-coserl-v1/.git
fi

cd ${COSIPATH}



############################################################################################################
# Setup python environment

echo ""
echo "*****************************"
echo " "
echo "Setting up the python3 environment"
echo " "

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
echo " "
echo "SUCCESS: The COSItools should be installed now"
echo " "
echo " "
echo "ATTENTION:"
echo " "
echo "In order to run the COSItools programs, a source script was created, which needs to be run beforehand:"
echo " "
echo "source ${COSIPATH}/source.sh"
echo " "
if [[ ${SHELL} == *zsh* ]]; then
  echo "You can add this line to your ~/.zprofile file,"
else
  echo "You can add this line to your ~/.bashrc file (or ~/.bash_profile on macOS),"
fi
echo "or execute this line everytime you want to use COSItools."
echo " "
echo "Then type \"cosi\" to switch to the COSItools directory and automatically activate the COSI python environment."
echo " "
echo " "
echo "Signing off"
echo " "

exit 0

############################################################################################################





 
