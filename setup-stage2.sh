#!/bin/bash

# This bash script file is part of the COSItools.
#
# The original file is part of MEGAlib.
# Port to COSItools and license change approved by original author, Andreas Zoglauer  
#
# Development lead: Andreas Zoglauer
# License: Apache 2.0

# Description:
# This is the stage 2 script to setup the COSI tools
# It sets up all of the COSItools 


############################################################################################################
# Step 1: Define default parameters

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
# Step 2: helper functions


# Use the help of the main setup script sinmce it must be the same anyway 
confhelp() {
  ${COSIPATH}/cosi-setup/setup-print-options.sh
}

# Tell the user where to look for past and present issues
issuereport() {
  echo " "
  echo "       Please take a look if you find the issue here (look at open and closed issues):"
  echo "       https://github.com/cositools/cosi-setup/issues"
  echo "       If not add your problem there. The COStools developers will be informed automatically."
  echo " "
}


############################################################################################################
# Step 3: extract the main parameters for the stage 1 script

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
# Step 5: Sanity checks

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


# Provide feed back and perform error checks:

if [[ ${BRANCH} != "" ]]; then
  echo " * Using branch ${BRANCH}"
else
  BRANCH="master" # Will switch to main if non-existent
  echo " * Using the main branch"
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
  echo " * Using the installation of ROOT: ${ROOTPATH}"
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
  echo " * Using the installation of Geant4: ${GEANT4PATH}"
fi


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
  echo " * Using the installation of HEASoft ${HEASOFTPATH}"
fi


if [[ ${OSTYPE} == *inux* ]]; then
  OSTYPE="linux"
  echo " * Using operating system architecture Linux"
elif ( [[ ${OSTYPE} == d* ]] || [[ ${OSTYPE} == m* ]] ); then
  OSTYPE="darwin"
  echo " * Using operating system architecture Darwin (Mac OS X)"
else
  echo " "
  echo "ERROR: Unknown operating system architecture: \"${OSTYPE}\""
  confhelp
  exit 1
fi


if ( [[ ${CPPOPT} == of* ]] || [[ ${CPPOPT} == no ]] ); then
  OPT="off"
  echo " * Using no code optimization"
elif ( [[ ${CPPOPT} == nor* ]] || [[ ${CPPOPT} == on ]] || [[ ${CPPOPT} == y* ]] ); then
  OPT="normal"
  echo " * Using normal code optimization"
elif ( [[ ${CPPOPT} == s* ]] || [[ ${CPPOPT} == h* ]] ); then
  OPT="strong"
  echo " * Using strong code optimization"
else
  echo " "
  echo "ERROR: Unknown code optimization: ${CPPOPT}"
  confhelp
  exit 1
fi


if ( [[ ${CPPDEBUG} == of* ]] || [[ ${CPPDEBUG} == no ]] ); then
  DEBUG="off"
  echo " * Using no debugging code"
elif ( [[ ${CPPDEBUG} == on ]] || [[ ${CPPDEBUG} == y* ]] || [[ ${CPPDEBUG} == nor* ]] ); then
  DEBUG="normal"
  echo " * Using debugging code"
elif ( [[ ${CPPDEBUG} == st* ]] || [[ ${CPPDEBUG} == h* ]] ); then
  DEBUG="strong"
  echo " * Using more debug flags"
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
  echo " * Using this maximum number of threads: ${MAXTHREADS}"
fi



############################################################################################################
# Step 6: Install all software packages

# Setup the path to the COSI installation

echo ""
echo "*****************************"
echo "" 
echo "Checking if all software packages are installed"

# macOS
if [[ ${OSTYPE} == *arwin* ]]; then
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
      echo ""
      echo "ERROR: Brew is currently not supported to install the required packages for COSItools!"
      echo "       Please use macports: https://www.macports.org/install.php"
      exit 1
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



############################################################################################################
# Step 7: Install ROOT

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
  
  bash ${SETUPPATH}/build-root.sh -source=${ENVFILE} -patch=yes --debug=${CPPDEBUG} --maxthreads=${MAXTHREADS} --cleanup=yes --keepenvironmentasis=no 2>&1 | tee BuildLogROOT.txt
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
# Step 8: Install Geant4

echo ""
echo "*****************************"
echo " "
echo "Installing Geant4:"
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
  
  bash ${SETUPPATH}/build-geant4.sh -source=${ENVFILE} -patch=yes --debug=${CPPDEBUG} --maxthreads=${MAXTHREADS} --cleanup=yes --keepenvironmentasis=no 2>&1 | tee BuildLogGeant4.txt
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
# Step 9: Install HEASoft

echo ""
echo "*****************************"
echo " "
echo "Installing HEASoft"
echo " "

# Until HEAsoft compiles in ARM mode, we cannot install it here:
if [[ $(uname) == *arwin ]] && [[ $(uname -m) == arm64 ]]; then
  echo "Warning: For the time being HEAsoft cannot be compiled in arm64 mode,"
  echo "         and thus we cannot link against it with COSItools,"
  echo "         and we will not install HEAsoft."
else 
  # If we are given an existing HEASoft installation, check is it is compatible
  if [ "${HEASOFTPATH}" != "" ]; then
    # Check if we can use the given HEASoft version
    if [[ ! -f ${SETUPPATH}/check-heasoftversion.sh ]]; then
      echo ""
      echo "ERROR: Unable to find the script to check the Geant4 version!"
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
      echo "ERROR: Unable to find the script to check the Geant4 version!"
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
      mv HEASoftBuildLog.txt ${NEWHEASOFTDIR}
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
    
    # The build-script will have added Geant4 to the environment file
  fi

  cd ${COSIPATH}

  echo " "
  echo "SUCCESS: We have a usable HEASoft version!"
fi


############################################################################################################
# Step 10: Install MEGAlib

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
# Step 11: Install CosiPy

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
# Step 12: Install COSIpy-classic

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
# Step 13: Install cosi-data-challenge

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
# Step 14: Install cosi-docs

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
# Step 15: Install mass models

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
  echo "ERROR: Something went wrong while retrieving cosi-data-challenges from the repository"
  issuereport
  exit 1
fi  

# Then extract mass model release versions relevant for the data analysis into their own directories
# This is a curated list for the moment

cd massmodels

if [[ ! -d massmodel-coserl-v1 ]]; then
  git clone -c advice.detachedHead=false --branch v1.0 https://github.com/cositools/massmodel-coserl massmodel-coserl-v1
  rm -rf massmodel-coserl-v1/.git
fi

cd ${COSIPATH}



############################################################################################################
# Step 16: Setup python environment

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
# Step 17: Finalize the setup script

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
if grep -q "HEASOFTDIR" ${ENVFILE}; then  # We currently don't install HEASoft on M1 machines
  echo ". ${SETUPPATH}/source-heasoft.sh -p=\${HEASOFTDIR}" >> ${ENVFILE}
fi
echo ". ${SETUPPATH}/source-root.sh -p=\${ROOTDIR}" >> ${ENVFILE}
echo " " >> ${ENVFILE}
echo "alias cosi='cd ${COSIPATH}; source python-env/bin/activate'" >> ${ENVFILE}
echo " "

echo "Renaming and moving the environment script"
mv ${ENVFILE} ${COSIPATH}/source.sh
chmod +x source.sh



############################################################################################################
# Step 18: Final remarks

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





 
