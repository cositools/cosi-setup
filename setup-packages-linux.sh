#!/bin/bash

# This bash script is part of the MEGAlib & COSItools setup procedure.
# As such it is dual licenced under Apache 2.0 for COSItools and LGPL 3.0 for MEGAlib
#
# Development lead: Andreas Zoglauer
#
# Description:
# This script checks if all required Linux packages are installed considering different Linux versions.
#

IsDebianClone=0
IsRedhatClone=0
IsOpenSuseClone=0
IsArchClone=0
IsAlpineClone=0

if [ -f /etc/os-release ]; then
  OS=`cat /etc/os-release | grep "^ID_LIKE=" | awk -F= '{ print $2 }'`
  OS=${OS//\"/}

  # Hack for OS' without ID_LIKE
  if [[ ${OS} == "" ]]; then 
    OS=`cat /etc/os-release | grep "^ID=" | awk -F= '{ print $2 }'`
    OS=${OS//\"/}
  fi

  if [[ ${OS} == *debian* ]] || [[ ${OS} == *ubuntu* ]]; then
    IsDebianClone=1
  elif [[ ${OS} == *suse* ]]; then
    IsOpenSuseClone=1
  elif [[ ${OS} == scientific* ]] || [[ ${OS} == *fedora* ]] ; then
    IsRedhatClone=1
  elif [[ ${OS} == arch ]]; then
    IsArchClone=1
  elif [[ ${OS} == alpine ]]; then
    IsAlpineClone=1
  else
    echo ""
    echo "ERROR: Unknown operating system: ${OS}"
    exit 1
  fi
fi

REQUIRED=""
EXTRATEXT=""
TOBEINSTALLED=""
SUPPORTEDVERSION="true"
AUTOPACKAGEINSTALL="false"
REPOSETUP=true

confhelp() {
  echo ""
  echo "This script checks whether all packages required by the COSItools are installed."
  echo " "
  echo "Usage: ./setup-packages-linux.sh [options]";
  echo " "
  echo " "
  echo "Options:"
  echo " "
  echo "--autoinstall[=false/off/no, true/on/yes - default: false]"
  echo "    Install the missing packages instead of only listing them."
  echo "    This is only intended for automatic build tests and is ignored outside a container."
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
SETUPOPTIONS="autoinstall help"

# The command line
CMD=( "$@" )

for C in "${CMD[@]}"; do
  # "|| RESULT=$?" so that a non-zero return does not trip a "set -e"
  RESULT=0
  OPTION=$(resolveoption "${C}" "${SETUPOPTIONS}") || RESULT=$?
  if [[ ${RESULT} == 2 ]]; then
    echo ""
    echo "ERROR: The command line option \"${C}\" is ambiguous - it matches: ${OPTION}"
    echo "       See \"./setup-packages-linux.sh --help\" for a list of options"
    exit 1
  elif [[ ${RESULT} != 0 ]]; then
    echo ""
    echo "ERROR: Unknown command line option: ${C}"
    echo "       See \"./setup-packages-linux.sh --help\" for a list of options"
    exit 1
  fi

  case ${OPTION} in
    autoinstall)
      if ! AUTOPACKAGEINSTALL=$(booleanvalue "$(optionvalue "${C}")"); then
        echo ""
        echo "ERROR: Unknown value for the --autoinstall option: ${C}"
        echo "       Use true/on/yes or false/off/no, or give the option without a value"
        exit 1
      fi
      ;;
    help)
      echo ""
      confhelp
      exit 0
      ;;
  esac
done

# The automatic package installation is only intended for automatic build tests inside a container, switch it off anywhere else
if [[ ${AUTOPACKAGEINSTALL} == true ]]; then
  if [[ ! -f /run/.containerenv ]] && [[ ! -f /.dockerenv ]]; then
    echo " "
    echo "WARNING: The automatic package installation is only intended for automatic build tests inside a container."
    echo "         Switching it off - any missing packages along with installation instructions will be listed below."
    echo " "
    AUTOPACKAGEINSTALL="false"
  fi
fi



###############################################################################
# Debian / Ubuntu and clones

if [[ ${IsDebianClone} -eq 1 ]]; then
  
  # Check if this is Ubuntu:
  OS=`cat /etc/os-release | grep "^ID=" | awk -F= '{ print $2 }'`
  OS=${OS//\"/}
  #echo "OS: ${OS}"

  VERSIONID=$(cat /etc/os-release | grep "^VERSION_ID=" | awk -F= '{ print $2 }')
  VERSIONID=${VERSIONID//\"/}
  #echo "VERSION: ${VERSIONID}"

  # Debian testing & unstable have no VERSION_ID -- use a value which is not a released version
  if [[ ${VERSIONID} == "" ]]; then
    VERSIONID=99
  fi

  if [[ ${OS} == ubuntu ]]; then
    # Check the Ubuntu version
    if [[ ${VERSIONID} == 18.04 ]] || [[ ${VERSIONID} == 18.10 ]] || [[ ${VERSIONID} == 19.04 ]] || [[ ${VERSIONID} == 19.10 ]]; then
      REQUIRED="git git-lfs gawk dpkg-dev make g++ gcc gfortran gdb valgrind binutils libx11-dev libxpm-dev libxft-dev libxext-dev libssl-dev libpcre3-dev libglu1-mesa-dev libglew-dev libftgl-dev libmysqlclient-dev libfftw3-dev libgraphviz-dev libavahi-compat-libdnssd-dev libldap2-dev python3 python3-dev python3-tk python3-venv libxml2-dev libkrb5-dev libgsl-dev cmake libxmu-dev curl doxygen libblas-dev liblapack-dev expect dos2unix libncurses5-dev libboost-all-dev mlocate libcfitsio-dev libxerces-c-dev libhealpix-cxx-dev bc "
      echo " "
      echo "ERROR: Ubuntu ${VERSIONID} is no longer supported."
      exit 255
    elif [[ ${VERSIONID} == 20.04 ]] || [[ ${VERSIONID} == 20.10 ]] || [[ ${VERSIONID} == 21.04 ]] || [[ ${VERSIONID} == 21.10 ]]; then
      REQUIRED="git git-lfs gawk dpkg-dev make g++ gcc gfortran gdb valgrind binutils libx11-dev libxpm-dev libxft-dev libxext-dev libssl-dev libpcre3-dev libglu1-mesa-dev libglew-dev libftgl-dev libmysqlclient-dev libfftw3-dev libgraphviz-dev libavahi-compat-libdnssd-dev libldap2-dev python3 python3-dev python3-tk python3-venv python3-matplotlib libxml2-dev libkrb5-dev libgsl-dev cmake libxmu-dev curl doxygen libblas-dev liblapack-dev expect dos2unix libncurses5-dev libboost-all-dev mlocate libcfitsio-dev libxerces-c-dev libhealpix-cxx-dev bc libhdf5-dev "
      echo " "
      echo "ERROR: Ubuntu ${VERSIONID} is no longer supported."
      exit 255
    elif [[ ${VERSIONID} == 22.04 ]] || [[ ${VERSIONID} == 22.10 ]] || [[ ${VERSIONID} == 23.04 ]] || [[ ${VERSIONID} == 23.10 ]]; then
      REQUIRED="git git-lfs gawk dpkg-dev make g++ gcc gfortran gdb valgrind binutils libx11-dev libxpm-dev libxft-dev libxext-dev libssl-dev libpcre3-dev libglu1-mesa-dev libglew-dev libftgl-dev libmysqlclient-dev libfftw3-dev libgraphviz-dev libavahi-compat-libdnssd-dev libldap2-dev python3 python3-dev python3-tk python3-venv python3-matplotlib libxml2-dev libkrb5-dev libgsl-dev cmake libxmu-dev curl doxygen libblas-dev liblapack-dev expect dos2unix libncurses5-dev libboost-all-dev libcfitsio-dev libxerces-c-dev libhealpix-cxx-dev bc libhdf5-dev libbz2-dev libtbb-dev libccfits-dev libgif-dev liblz4-dev liblzma-dev libftgl-dev"
      echo " "
      echo "ERROR: Ubuntu ${VERSIONID} is no longer supported."
      exit 255
    elif [[ ${VERSIONID} == 24.04 ]] || [[ ${VERSIONID} == 24.10 ]] || [[ ${VERSIONID} == 25.04 ]] || [[ ${VERSIONID} == 25.10 ]]; then
      REQUIRED="git git-lfs gawk dpkg-dev make g++ gcc gfortran gdb valgrind binutils libx11-dev libxpm-dev libxft-dev libxext-dev libssl-dev libpcre3-dev libglu1-mesa-dev libglew-dev libftgl-dev libmysqlclient-dev libfftw3-dev libgraphviz-dev libavahi-compat-libdnssd-dev libldap2-dev python3 python3-dev python3-tk python3-venv python3-matplotlib libxml2-dev libkrb5-dev libgsl-dev cmake libxmu-dev curl doxygen libblas-dev liblapack-dev expect dos2unix libncurses-dev libboost-all-dev libcfitsio-dev libxerces-c-dev libhealpix-cxx-dev bc libhdf5-dev libbz2-dev libtbb-dev libccfits-dev libgif-dev liblz4-dev liblzma-dev libftgl-dev"
    elif [[ ${VERSIONID} == 26.04 ]] || [[ ${VERSIONID} == 26.10 ]] || [[ ${VERSIONID} == 27.04 ]] || [[ ${VERSIONID} == 27.10 ]]; then
      REQUIRED="git git-lfs gawk dpkg-dev make g++ gcc gfortran gdb valgrind binutils libx11-dev libxpm-dev libxft-dev libxext-dev libssl-dev libpcre2-dev libglu1-mesa-dev libglew-dev libftgl-dev libmysqlclient-dev libfftw3-dev libgraphviz-dev libavahi-compat-libdnssd-dev libldap2-dev python3 python3-dev python3-tk python3-venv python3-matplotlib libxml2-dev libkrb5-dev libgsl-dev cmake libxmu-dev curl doxygen libblas-dev liblapack-dev expect dos2unix libncurses-dev libboost-all-dev libcfitsio-dev libxerces-c-dev libhealpix-cxx-dev bc libhdf5-dev libbz2-dev libtbb-dev libccfits-dev libcrypt-dev libgif-dev liblz4-dev liblzma-dev libftgl-dev"
    else
      REQUIRED="git git-lfs gawk dpkg-dev make g++ gcc gfortran gdb valgrind binutils libx11-dev libxpm-dev libxft-dev libxext-dev libssl-dev libpcre2-dev libglu1-mesa-dev libglew-dev libftgl-dev libmysqlclient-dev libfftw3-dev libgraphviz-dev libavahi-compat-libdnssd-dev libldap2-dev python3 python3-dev python3-tk python3-venv python3-matplotlib libxml2-dev libkrb5-dev libgsl-dev cmake libxmu-dev curl doxygen libblas-dev liblapack-dev expect dos2unix libncurses-dev libboost-all-dev libcfitsio-dev libxerces-c-dev libhealpix-cxx-dev bc libhdf5-dev libbz2-dev libtbb-dev libccfits-dev libcrypt-dev libgif-dev liblz4-dev liblzma-dev libftgl-dev"
      
      SUPPORTEDVERSION="false"
    fi
  elif [[ ${OS} == debian ]] || [[ ${OS} == raspbian ]]; then
    if (( ${VERSIONID} <= 10 )); then
      REQUIRED="git git-lfs gawk dpkg-dev make g++ gcc gfortran gdb valgrind binutils libx11-dev libxpm-dev libxft-dev libxext-dev libssl-dev libpcre3-dev libglu1-mesa-dev libglew-dev libftgl-dev libmariadb-dev libfftw3-dev libgraphviz-dev libavahi-compat-libdnssd-dev libldap2-dev python python3-dev python3-tk python3-venv python3-matplotlib libxml2-dev libkrb5-dev libgsl-dev cmake libxmu-dev curl doxygen libblas-dev liblapack-dev expect dos2unix libncurses5-dev bc libxerces-c-dev libhealpix-cxx-dev bc libhdf5-dev libbz2-dev"
      echo " "
      echo "ERROR: Debian 10 or earlier is no longer supported."
      exit 255
    elif (( ${VERSIONID} >= 11 )) && (( ${VERSIONID} <= 12 )); then
      REQUIRED="git git-lfs gawk dpkg-dev make g++ gcc gfortran gdb valgrind binutils libx11-dev libxpm-dev libxft-dev libxext-dev libssl-dev libpcre3-dev libglu1-mesa-dev libglew-dev libftgl-dev libmariadb-dev libfftw3-dev libgraphviz-dev libavahi-compat-libdnssd-dev libldap2-dev python3 python3-dev python3-tk python3-venv python3-matplotlib libxml2-dev libkrb5-dev libgsl-dev cmake libxmu-dev curl doxygen libblas-dev liblapack-dev expect dos2unix libncurses5-dev bc libxerces-c-dev libhealpix-cxx-dev bc libhdf5-dev libtbb-dev libccfits-dev libgif-dev liblz4-dev liblzma-dev libzstd-dev libbz2-dev "
      echo " "
      echo "ERROR: Debian ${VERSIONID} is no longer supported."
      exit 255
   elif (( ${VERSIONID} >= 13 )); then
      REQUIRED="git git-lfs gawk dpkg-dev make g++ gcc gfortran gdb valgrind binutils libx11-dev libxpm-dev libxft-dev libxext-dev libssl-dev libglu1-mesa-dev libglew-dev libftgl-dev libmariadb-dev libfftw3-dev libgraphviz-dev libavahi-compat-libdnssd-dev libldap2-dev python3 python3-dev python3-tk python3-venv python3-matplotlib libxml2-dev libkrb5-dev libgsl-dev cmake libxmu-dev curl doxygen libblas-dev liblapack-dev expect dos2unix libncurses5-dev bc libxerces-c-dev libhealpix-cxx-dev bc libhdf5-dev libtbb-dev libccfits-dev libgif-dev liblz4-dev liblzma-dev libzstd-dev libbz2-dev "
    else
      REQUIRED="git git-lfs gawk dpkg-dev make g++ gcc gfortran gdb valgrind binutils libx11-dev libxpm-dev libxft-dev libxext-dev libssl-dev libpcre3-dev libglu1-mesa-dev libglew-dev libftgl-dev libmariadb-dev libfftw3-dev libgraphviz-dev libavahi-compat-libdnssd-dev libldap2-dev python3 python3-dev python3-tk python3-venv python3-matplotlib libxml2-dev libkrb5-dev libgsl-dev cmake libxmu-dev curl doxygen libblas-dev liblapack-dev expect dos2unix libncurses5-dev bc libxerces-c-dev libhealpix-cxx-dev bc libhdf5-dev libbz2-dev libtbb-dev libccfits-dev libgif-dev liblz4-dev liblzma-dev libzstd-dev libbz2-dev "
      SUPPORTEDVERSION="false"
    fi
  else
    REQUIRED="git git-lfs gawk dpkg-dev make g++ gcc gfortran gdb valgrind binutils libx11-dev libxpm-dev libxft-dev libxext-dev libssl-dev libpcre3-dev libglu1-mesa-dev libglew-dev libftgl-dev libmariadb-dev libfftw3-dev libgraphviz-dev libavahi-compat-libdnssd-dev libldap2-dev python3 python3-dev python3-tk python3-venv python3-matplotlib libxml2-dev libkrb5-dev libgsl-dev cmake libxmu-dev curl doxygen libblas-dev liblapack-dev expect dos2unix libncurses5-dev bc libxerces-c-dev libhealpix-cxx-dev bc libhdf5-dev libbz2-dev libtbb-dev libccfits-dev libgif-dev liblz4-dev liblzma-dev libzstd-dev libbz2-dev "
    SUPPORTEDVERSION="false"
  fi
  
  #echo "Required: ${REQUIRED}"
  if [[ "${REQUIRED}" == "" ]]; then exit 0; fi
  
  if [[ ${SUPPORTEDVERSION} == true ]]; then
    # Check if each of the packages exists:
    for PACKAGE in ${REQUIRED}; do 
      # Check if the file is installed
      STATUS=`dpkg-query -Wf'${db:Status-abbrev}' ${PACKAGE} 2>/dev/null | grep '^i'`
      #echo "${PACKAGE}: >${STATUS}<"
      if [[ "${STATUS}" == "" ]]; then
        # Check if it exists at all:
        echo "Not installed: ${PACKAGE}"
        TOBEINSTALLED="${TOBEINSTALLED} ${PACKAGE}"

        #STATUS=`apt-cache pkgnames ${PACKAGE} 2>/dev/null`
        #if [[ "${STATUS}" != "" ]]; then
        #  TOBEINSTALLED="${TOBEINSTALLED} ${PACKAGE}"
        #fi
      fi
    done
  
    if [[ "${TOBEINSTALLED}" != "" ]]; then
      if [[ ${AUTOPACKAGEINSTALL} == true ]]; then
        echo " "
        echo "Performing an automatic installation of the packages. I will do the following:"
        echo "sudo apt update; sudo apt install ${TOBEINSTALLED}"
        echo " "
        sudo DEBIAN_FRONTEND=noninteractive apt update
        sudo DEBIAN_FRONTEND=noninteractive apt install -y ${TOBEINSTALLED}
        if [[ "$?" != "0" ]]; then
          echo " "
          echo "ERROR: Something went wrong with the automatic package installation."
          exit 255
        else
          echo " "
          echo "All required packages seem to be installed now!"
          exit 0
        fi
      else 
        echo " "
        echo "Do the following to install all required packages:"
        echo "sudo apt update; sudo apt install ${TOBEINSTALLED}"
        echo " "
        exit 255
      fi
    else 
      echo " "
      echo "All required packages seem to be already installed!"
      exit 0
    fi
  else
    echo "This script has not yet been adapted for your version of Linux: Debian-derivative ${OS}"
    echo "Feel free to write the maintainers an email to update this script and send them the content of the file: /etc/os-release"
    echo " "
    echo "In the mean time, try to install the following packages -- remove the ones which do not work from the list:"
    echo "sudo apt update; sudo apt install ${REQUIRED}"
    echo " "
    exit 255
  fi
fi



###############################################################################
# OpenSUSE & clones

if [[ ${IsOpenSuseClone} -eq 1 ]]; then

  # Check if this is OpenSUSE:
  OS=`cat /etc/os-release | grep "^ID=" | awk -F= '{ print $2 }'`
  OS=${OS//\"/}
  #echo "OS: ${OS}"
  VERSIONID=""
  if [[ ${OS} == opensuse-leap ]]; then
    # Check the version:
    VERSIONID=$(cat /etc/os-release | grep "^VERSION_ID=" | awk -F= '{ print $2 }')
    VERSIONID=${VERSIONID//\"/}
    VERSIONID=$(echo ${VERSIONID} | awk -F'.' '{ print $1 }')
    #echo "VERSION: ${VERSIONID}"
    if (( ${VERSIONID} <= 15 )); then
      REQUIRED="git-core git-lfs bash binutils cmake gcc gcc-c++ git libXext-devel libXft-devel libXpm-devel python xrootd-client-devel xrootd-libs-devel fftw3-devel gsl-devel graphviz-devel Mesa glew-devel ncurses-devel python3-devel cfitsio-devel libxerces-c-devel hdf5-devel "
      echo " "
      echo "ERROR: opensuse Leap 15 or earlier is no longer supported."
      exit 255
    elif (( ${VERSIONID} == 16 )); then
      REQUIRED="git-core git-lfs bash binutils cmake gcc gcc-c++ git libXext-devel libXft-devel libXpm-devel fftw3-devel gsl-devel graphviz-devel Mesa glew-devel ncurses-devel python3-devel cfitsio-devel libxerces-c-devel hdf5-devel giflib-devel libjpeg8-devel liblz4-devel xz-devel libzstd-devel libpng16-devel libcurl-devel patch "
    else 
      REQUIRED="git-core git-lfs bash binutils cmake gcc gcc-c++ git libXext-devel libXft-devel libXpm-devel python xrootd-client-devel xrootd-libs-devel fftw3-devel gsl-devel graphviz-devel Mesa glew-devel ncurses-devel python3-devel cfitsio-devel libxerces-c-devel hdf5-devel "
      SUPPORTEDVERSION="false"
    fi

    # OpenSUSE is frequently behind with python. Thus add the latest version:
    REQUIRED+="$(zypper search -s python3*[0-9]-devel | tail -1 | awk -F"|" '{ print $2 }') "

  elif [[ ${OS} == opensuse-tumbleweed ]]; then
    REQUIRED="git-core git-lfs bash binutils cmake gcc gcc-c++ git libXext-devel libXft-devel libXpm-devel xrootd-client-devel xrootd-libs-devel fftw3-devel gsl-devel graphviz-devel Mesa glew-devel ncurses-devel patterns-devel-python-devel_python3 patterns-devel-base-devel_basis patterns-devel-C-C++-devel_C_C++ cfitsio-devel libxerces-c-devel hdf5-devel healpix_cxx-devel libcurl-devel giflib-devel libjpeg8-devel liblz4-devel xz-devel libzstd-devel libpng16-devel patch "
  else
    REQUIRED="git-core git-lfs bash binutils cmake gcc gcc-c++ git libXext-devel libXft-devel libXpm-devel xrootd-client-devel xrootd-libs-devel fftw3-devel gsl-devel graphviz-devel Mesa glew-devel ncurses-devel patterns-devel-python-devel_python3 patterns-devel-base-devel_basis patterns-devel-C-C++-devel_C_C++ cfitsio-devel libxerces-c-devel hdf5-devel healpix_cxx-devel libcurl-devel giflib-devel libjpeg8-devel liblz4-devel xz-devel libzstd-devel libpng16-devel patch "
    SUPPORTEDVERSION="false"
  fi

  if [[ "${REQUIRED}" == "" ]]; then exit 0; fi

  if [[ ${SUPPORTEDVERSION} == true ]]; then
    # Check if each of the packages exists:
    for PACKAGE in ${REQUIRED}; do
      # Check if the file is installed
      STATUS=$(rpm -q --queryformat "%{NAME}\n" ${PACKAGE})
      #echo "${PACKAGE}: >${STATUS}<"
      if [[ "${STATUS}" != "${PACKAGE}" ]]; then
        # Check if it exists at all:
        echo "Not installed: ${PACKAGE}"
        TOBEINSTALLED+="${PACKAGE} "
      fi
    done
    
  
    if [[ "${TOBEINSTALLED}" != "" ]]; then
      if [[ ${AUTOPACKAGEINSTALL} == true ]]; then
        echo " "
        echo "Performing an automatic installation of the packages. I will do the following:"
        echo "sudo zypper --non-interactive --gpg-auto-import-keys refresh"
        echo "sudo zypper --non-interactive install -y --force-resolution ${TOBEINSTALLED}"
        echo " "
        # --non-interactive and --gpg-auto-import-keys since a repository key or license
        # prompt has nobody to answer it and would hang the container
        # --force-resolution since zypper cannot ask us which of its solutions to pick when it hits a conflict
        sudo zypper --non-interactive --gpg-auto-import-keys refresh && sudo zypper --non-interactive install -y --force-resolution ${TOBEINSTALLED}
        if [[ "$?" != "0" ]]; then
          echo " "
          echo "ERROR: Something went wrong with the automatic package installation."
          exit 255
        fi

        # --force-resolution allows zypper to solve a conflict by not installing a package, thus verify that we really got everything
        MISSING=""
        for PACKAGE in ${TOBEINSTALLED}; do
          if [[ "$(rpm -q --queryformat "%{NAME}\n" ${PACKAGE})" != "${PACKAGE}" ]]; then
            MISSING+="${PACKAGE} "
          fi
        done
        if [[ ${MISSING} != "" ]]; then
          echo " "
          echo "ERROR: The following packages could not be installed: ${MISSING}"
          exit 255
        fi

        echo " "
        echo "All required packages seem to be installed now!"
        exit 0
      else
        echo " "
        echo "Do the following to install all required packages:"
        echo ""
        echo "sudo zypper install ${TOBEINSTALLED}"
        echo " "
        exit 255
      fi
    else 
      echo " "
      echo "All required packages seem to be already installed!"
      exit 0
    fi
  else
    echo " "
    echo "This script has not yet been adapted for your version of Linux:"
    echo "    SUSE-derivative: ${OS}"
    if [[ ${VERSIONID} != "" ]]; then
      echo "    Version:         ${VERSIONID}"
    fi
    echo "Feel free to open a GitHub issue and attach the content of the file: /etc/os-release"
    echo " "
    echo "In the mean time, try to install the following packages -- remove the ones which do not work from the list:"
    echo ""
    echo "sudo zypper install ${REQUIRED}"
    echo " "
    exit 255
  fi
fi



###############################################################################
# Redhat & clones

if [[ ${IsRedhatClone} -eq 1 ]]; then

  # Check which OS we really have:
  OS=`cat /etc/os-release | grep "^ID=" | awk -F= '{ print $2 }'`
  OS=${OS//\"/}
  #echo "OS: ${OS}"
  if [[ ${OS} == rhel ]] || [[ ${OS} == almalinux ]] || [[ ${OS} == rocky ]] || [[ ${OS} == centos ]]; then
    # Check the version
    VERSIONID=$(cat /etc/os-release | grep "^VERSION_ID=" | awk -F= '{ print $2 }')
    VERSIONID=${VERSIONID//\"/}
    VERSIONID=$(echo ${VERSIONID} | awk -F'.' '{ print $1 }')
    #echo "VERSION: ${VERSIONID}"
    if (( ${VERSIONID} == 7 )) ; then
      REQUIRED="openssl git git-lfs cmake gcc-c++ gcc binutils libX11-devel libXpm-devel libXft-devel libXext-devel libXt-devel gcc-gfortran openssl-devel pcre-devel mesa-libGL-devel mesa-libGLU-devel glew-devel mariadb-devel fftw-devel graphviz-devel avahi-compat-libdns_sd-devel python-devel libxml2-devel curl dos2unix ncurses-devel perl-devel cfitsio-devel xerces-c-devel healpix-c++-devel hdf5-devel libcurl-devel "
      echo " "
      echo "ERROR: Redhat 7 or earlier is no longer supported."
      exit 255
    elif (( ${VERSIONID} == 8 )) ; then
      REQUIRED="openssl patch git git-lfs make cmake gcc-c++ gcc binutils libX11-devel libXpm-devel libXft-devel libXext-devel libXt-devel gcc-gfortran openssl-devel pcre-devel mesa-libGL-devel mesa-libGLU-devel glew-devel mariadb-connector-c-devel fftw-devel graphviz-devel avahi-compat-libdns_sd-devel python36-devel libxml2-devel curl dos2unix ncurses-devel perl-devel cfitsio-devel xerces-c-devel hdf5-devel libcurl-devel autoconf automake libtool giflib-devel libjpeg-turbo-devel lz4-devel libzstd-devel "
      REPOSETUP="sudo dnf install -y dnf-plugins-core && sudo dnf config-manager --set-enabled powertools && sudo dnf install -y epel-release"
      echo " "
      echo "ERROR: Redhat 8 is no longer supported."
      exit 255
    elif (( ${VERSIONID} == 9 )) ; then
      REQUIRED="openssl patch git git-lfs make cmake gcc-c++ gcc binutils libX11-devel libXpm-devel libXft-devel libXext-devel libXt-devel gcc-gfortran openssl-devel pcre-devel mesa-libGL-devel mesa-libGLU-devel glew-devel mariadb-connector-c-devel fftw-devel graphviz-devel avahi-compat-libdns_sd-devel python3-devel libxml2-devel curl dos2unix ncurses-devel perl-devel cfitsio-devel xerces-c-devel hdf5-devel libcurl-devel autoconf automake libtool giflib-devel libjpeg-turbo-devel lz4-devel libzstd-devel "
      REPOSETUP="sudo dnf install -y dnf-plugins-core && sudo dnf config-manager --set-enabled crb && sudo dnf install -y epel-release"
      echo " "
      echo "ERROR: Redhat 9 is no longer supported."
      exit 255
    elif (( ${VERSIONID} >= 10 )) && (( ${VERSIONID} <= 100 )) ; then
      REQUIRED="openssl patch git git-lfs make cmake gcc-c++ gcc binutils libX11-devel libXpm-devel libXft-devel libXext-devel libXt-devel gcc-gfortran openssl-devel mesa-libGL-devel mesa-libGLU-devel glew-devel mariadb-connector-c-devel fftw-devel graphviz-devel avahi-compat-libdns_sd-devel python3-devel libxml2-devel curl dos2unix ncurses-devel perl-devel cfitsio-devel xerces-c-devel hdf5-devel libcurl-devel autoconf automake libtool giflib-devel libjpeg-turbo-devel lz4-devel libzstd-devel "
      REPOSETUP="sudo dnf install -y dnf-plugins-core && sudo dnf config-manager --set-enabled crb && sudo dnf install -y epel-release"
    else
      REQUIRED="openssl patch git git-lfs make cmake gcc-c++ gcc binutils libX11-devel libXpm-devel libXft-devel libXext-devel libXt-devel gcc-gfortran openssl-devel pcre-devel mesa-libGL-devel mesa-libGLU-devel glew-devel mariadb-connector-c-devel fftw-devel graphviz-devel avahi-compat-libdns_sd-devel python3-devel libxml2-devel curl dos2unix ncurses-devel perl-devel cfitsio-devel xerces-c-devel healpix-c++-devel hdf5-devel libcurl-devel autoconf automake libtool giflib-devel libjpeg-turbo-devel lz4-devel libzstd-devel "
      REPOSETUP="sudo dnf install -y dnf-plugins-core && sudo dnf config-manager --set-enabled crb && sudo dnf install -y epel-release"
      SUPPORTEDVERSION="false"
    fi
  elif [[ ${OS} == fedora ]]; then
    # Check the version
    VERSIONID=$(cat /etc/os-release | grep "^VERSION_ID=" | awk -F= '{ print $2 }')
    VERSIONID=${VERSIONID//\"/}
    VERSIONID=$(echo ${VERSIONID} | awk -F'.' '{ print $1 }')
    #echo "VERSION: ${VERSIONID}"
    if (( ${VERSIONID} <= 42 )) ; then
      echo " "
      echo "ERROR: Fedora 42 or earlier is no longer supported."
      exit 255
    elif (( ${VERSIONID} >= 43 )) && (( ${VERSIONID} <= 99 )) ; then
      REQUIRED="openssl patch git git-lfs make cmake gcc-c++ gcc binutils libX11-devel libXpm-devel libXft-devel libXext-devel libXt-devel gcc-gfortran openssl-devel pcre2-devel mesa-libGL-devel mesa-libGLU-devel glew-devel mariadb-devel fftw-devel graphviz-devel avahi-compat-libdns_sd-devel python3-devel libxml2-devel curl dos2unix ncurses-devel perl-devel boost-devel readline-devel cfitsio-devel xerces-c-devel healpix-c++-devel hdf5-devel libcurl-devel giflib-devel libjpeg-turbo-devel lz4-devel libzstd-devel "
      REPOSETUP="sudo dnf install -y dnf-plugins-core"
    else 
      REQUIRED="openssl patch git git-lfs make cmake gcc-c++ gcc binutils libX11-devel libXpm-devel libXft-devel libXext-devel libXt-devel gcc-gfortran openssl-devel pcre-devel mesa-libGL-devel mesa-libGLU-devel glew-devel mariadb-devel fftw-devel graphviz-devel avahi-compat-libdns_sd-devel python3-devel libxml2-devel curl dos2unix ncurses-devel perl-devel boost-devel readline-devel cfitsio-devel xerces-c-devel healpix-c++-devel hdf5-devel libcurl-devel giflib-devel libjpeg-turbo-devel lz4-devel libzstd-devel "
      REPOSETUP="sudo dnf install -y dnf-plugins-core"
      SUPPORTEDVERSION="false"
    fi
  else
    REQUIRED="openssl git git-lfs cmake gcc-c++ gcc binutils libX11-devel libXpm-devel libXft-devel libXext-devel libXt-devel gcc-gfortran openssl-devel pcre-devel mesa-libGL-devel mesa-libGLU-devel glew-devel mariadb-devel fftw-devel graphviz-devel avahi-compat-libdns_sd-devel python3-devel libxml2-devel curl dos2unix ncurses-devel perl-devel cfitsio-devel xerces-c-devel healpix-c++-devel hdf5-devel libcurl-devel "
    SUPPORTEDVERSION="false"
  fi
  
  if [[ "${REQUIRED}" == "" ]]; then exit 0; fi

  if [[ ${SUPPORTEDVERSION} == true ]]; then
    # Check if each of the packages exists:
    for PACKAGE in ${REQUIRED}; do
      # Check if the file is installed
      if ! rpm -q ${PACKAGE} >& /dev/null; then
        # Check if it exists at all:
        echo "Not installed: ${PACKAGE}"
        TOBEINSTALLED="${TOBEINSTALLED} ${PACKAGE}"
      fi
    done
  
  
    if [[ "${TOBEINSTALLED}" != "" ]]; then
      if [[ ${AUTOPACKAGEINSTALL} == true ]]; then
        echo " "
        echo "Performing an automatic installation of the packages. I will do the following:"
        if [[ ${REPOSETUP} != true ]]; then
          echo "${REPOSETUP}"
        fi
        echo "sudo dnf makecache"
        echo "sudo dnf install -y --allowerasing ${TOBEINSTALLED}"
        echo " "
        eval "${REPOSETUP}" && sudo dnf makecache && sudo dnf install -y --allowerasing ${TOBEINSTALLED}
        if [[ "$?" != "0" ]]; then
          echo " "
          echo "ERROR: Something went wrong with the automatic package installation."
          exit 255
        else
          echo " "
          echo "All required packages seem to be installed now!"
          exit 0
        fi
      else
        echo " "
        echo "Do the following to install all required packages:"
        if [[ ${REPOSETUP} != true ]]; then
          echo "${REPOSETUP}"
        fi
        echo "sudo yum install ${TOBEINSTALLED}"
        echo " "
        exit 255
      fi
    else
      echo " "
      echo "All required packages seem to be already installed!"
      exit 0
    fi
  else
    echo " "
    echo "This script has not yet been adapted for your version of Linux: ${OS} version ${VERSIONID}"
    echo "Feel free to write the maintainers an email to update this script and send them the content of the file: /etc/os-release"
    echo " "
    echo "In the mean time, try to install the following packages -- remove the ones which do not work from the list:"
    echo "sudo yum install ${REQUIRED}"
    echo " "
    exit 255
  fi
fi



###############################################################################
# Arch & clones

if [[ ${IsArchClone} -eq 1 ]]; then

  REQUIRED_PAC="git git-lfs gawk make gcc gcc-fortran gdb valgrind binutils libx11 libxpm libxft libxext openssl pcre glu glew ftgl fftw graphviz avahi libldap python tk libxml2 krb5 gsl cmake libxmu curl doxygen blas lapack expect dos2unix ncurses boost xerces-c gl2ps autoconf automake libtool pkgconf patch fakeroot debugedit"

  if [[ "${REQUIRED_PAC}" == "" ]]; then exit 0; fi

  # Check if each of the packages exists:
  NONEXISTENT_PAC=""
  for PACKAGE in ${REQUIRED_PAC}; do
    # Check if the package is installed
    if ! pacman -Si ${PACKAGE} >& /dev/null; then
      # Check if it exists at all:
      echo "Does not exist: ${PACKAGE}"
      NONEXISTENT_PAC="${NONEXISTENT_PAC} ${PACKAGE}"
    else
      if ! pacman -Qi ${PACKAGE} >& /dev/null; then
        # Check if it exists at all:
        echo "Not installed: ${PACKAGE}"
        TOBEINSTALLED_PAC="${TOBEINSTALLED_PAC} ${PACKAGE}"
      fi
    fi
  done

  # A package which is not in the repositories cannot be installed, thus stop here instead
  # of reporting further down that everything is fine
  if [[ "${NONEXISTENT_PAC}" != "" ]]; then
    echo " "
    echo "ERROR: The following required packages do not exist in the Arch repositories:${NONEXISTENT_PAC}"
    echo "       Either the package database is out of date - try \"sudo pacman -Sy\" -"
    echo "       or the list of required packages in this script has to be updated."
    exit 255
  fi

  if [[ "${TOBEINSTALLED_PAC}" != "" ]]; then
    if [[ ${AUTOPACKAGEINSTALL} == true ]]; then
      echo " "
      echo "Performing an automatic installation of the packages. I will do the following:"
      echo "sudo pacman -Syu --noconfirm ${TOBEINSTALLED_PAC}"
      echo " "

      # Arch does not support partial upgrades, thus we have to do a full one
      sudo pacman -Syu --noconfirm ${TOBEINSTALLED_PAC}
      if [[ "$?" != "0" ]]; then
        echo " "
        echo "ERROR: Something went wrong with the automatic package installation."
        exit 255
      fi

      # pacman can resolve a conflict by not installing a package, thus verify
      MISSING=""
      for PACKAGE in ${TOBEINSTALLED_PAC}; do
        if ! pacman -Qi "${PACKAGE}" >/dev/null 2>&1; then
          MISSING+="${PACKAGE} "
        fi
      done
      if [[ ${MISSING} != "" ]]; then
        echo " "
        echo "ERROR: The following packages could not be installed: ${MISSING}"
        exit 255
      fi

      echo " "
      echo "All required packages seem to be installed now!"
      exit 0
    else
      echo " "
      echo "Do the following to install all required packages:"
      echo "sudo pacman -S ${TOBEINSTALLED_PAC}"
      echo " "
      exit 255
    fi
  else
    echo " "
    echo "All required packages seem to be already installed!"
    exit 0
  fi

fi




###############################################################################
# Alpine - NOT SUPPORTED!

if [[ ${IsAlpineClone} -eq 1 ]]; then

  echo " "
  echo "ERROR: Alpine Linux is not supported due to an incompatibility between ROOT and Alpine."
  exit 255

  REQUIRED="git git-lfs libstdc++ gcompat gawk make gcc g++ gfortran patch libtbb-dev gdb valgrind binutils libx11 libxpm libxft-dev libxext-dev openssl pcre glu glew ftgl fftw graphviz avahi libldap python3 tk libxml2 krb5 gsl cmake libxmu libxpm-dev curl doxygen blas lapack expect dos2unix ncurses boost-dev cfitsio-dev xerces-c-dev"

  if [[ "${REQUIRED}" == "" ]]; then exit 0; fi

  # Check if each of the packages exists:
  INSTALLED=$(apk list -I)
  for PACKAGE in ${REQUIRED}; do
    # Check if the file is installed
    STATUS=$(echo "${INSTALLED}" | grep "^${PACKAGE}-")
    if [[ ${STATUS} != "" ]]; then
      echo "Installed: ${PACKAGE}"
    else
      echo "Not installed: ${PACKAGE}"
      TOBEINSTALLED="${TOBEINSTALLED} ${PACKAGE}"
    fi
  done


  if [[ "${TOBEINSTALLED}" != "" ]]; then
    echo " "
    echo "Do the following to install all required packages:"
    echo "sudo apk add ${TOBEINSTALLED}"
    echo " "
    exit 255
  else
    echo " "
    echo "All required packages seem to be already installed!"
    exit 0
  fi

fi

exit 0
