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
  OS=`cat /etc/os-release | grep "^ID_LIKE\=" | awk -F= '{ print $2 }'`
  OS=${OS//\"/}

  # Hack for OS' without ID_LIKE
  if [[ ${OS} == "" ]]; then 
    OS=`cat /etc/os-release | grep "^ID\=" | awk -F= '{ print $2 }'`
    OS=${OS//\"/}
  fi

  if [[ ${OS} == debian ]]; then
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
TOBEINSTALLED=""



###############################################################################
# Debian / Ubuntu and clones

if [[ ${IsDebianClone} -eq 1 ]]; then
  
  # Check if this is Ubuntu:
  OS=`cat /etc/os-release | grep "^ID\=" | awk -F= '{ print $2 }'`
  OS=${OS//\"/}
  #echo "OS: ${OS}"

  VERSIONID=$(cat /etc/os-release | grep "^VERSION_ID\=" | awk -F= '{ print $2 }')
  VERSIONID=${VERSIONID//\"/}
  #echo "VERSION: ${VERSIONID}"

  if [[ ${OS} == ubuntu ]]; then
    # Check th Ubuntu version
    if [[ ${VERSIONID} == 18.04 ]] || [[ ${VERSIONID} == 18.10 ]] || [[ ${VERSIONID} == 19.04 ]] || [[ ${VERSIONID} == 19.10 ]]; then
      REQUIRED="git git-lfs gawk dpkg-dev make g++ gcc gfortran gdb valgrind binutils libx11-dev libxpm-dev libxft-dev libxext-dev libssl-dev libpcre3-dev libglu1-mesa-dev libglew-dev libftgl-dev libmysqlclient-dev libfftw3-dev libgraphviz-dev libavahi-compat-libdnssd-dev libldap2-dev python3 python3-dev python3-tk python3-venv libxml2-dev libkrb5-dev libgsl-dev cmake libxmu-dev curl doxygen libblas-dev liblapack-dev expect dos2unix libncurses5-dev libboost-all-dev mlocate libcfitsio-dev libxerces-c-dev libhealpix-cxx-dev bc "
    elif [[ ${VERSIONID} == 20.04 ]] || [[ ${VERSIONID} == 20.10 ]] || [[ ${VERSIONID} == 21.04 ]] || [[ ${VERSIONID} == 21.10 ]]; then
      REQUIRED="git git-lfs gawk dpkg-dev make g++ gcc gfortran gdb valgrind binutils libx11-dev libxpm-dev libxft-dev libxext-dev libssl-dev libpcre3-dev libglu1-mesa-dev libglew-dev libftgl-dev libmysqlclient-dev libfftw3-dev libgraphviz-dev libavahi-compat-libdnssd-dev libldap2-dev python3 python3-dev python3-tk python3-venv python3-matplotlib libxml2-dev libkrb5-dev libgsl-dev cmake libxmu-dev curl doxygen libblas-dev liblapack-dev expect dos2unix libncurses5-dev libboost-all-dev mlocate libcfitsio-dev libxerces-c-dev libhealpix-cxx-dev bc "
    elif [[ ${VERSIONID} == 22.04 ]] || [[ ${VERSIONID} == 22.10 ]] || [[ ${VERSIONID} == 23.04 ]] || [[ ${VERSIONID} == 23.10 ]]; then
      REQUIRED="git git-lfs gawk dpkg-dev make g++ gcc gfortran gdb valgrind binutils libx11-dev libxpm-dev libxft-dev libxext-dev libssl-dev libpcre3-dev libglu1-mesa-dev libglew-dev libftgl-dev libmysqlclient-dev libfftw3-dev libgraphviz-dev libavahi-compat-libdnssd-dev libldap2-dev python3 python3-dev python3-tk python3-venv python3-matplotlib libxml2-dev libkrb5-dev libgsl-dev cmake libxmu-dev curl doxygen libblas-dev liblapack-dev expect dos2unix libncurses5-dev libboost-all-dev mlocate libcfitsio-dev libxerces-c-dev libhealpix-cxx-dev bc "
    else
      REQUIRED="git git-lfs gawk dpkg-dev make g++ gcc gfortran gdb valgrind binutils libx11-dev libxpm-dev libxft-dev libxext-dev libssl-dev libpcre3-dev libglu1-mesa-dev libglew-dev libftgl-dev libmysqlclient-dev libfftw3-dev libgraphviz-dev libavahi-compat-libdnssd-dev libldap2-dev python3 python3-dev python3-tk python3-venv python3-matplotlib libxml2-dev libkrb5-dev libgsl-dev cmake libxmu-dev curl doxygen libblas-dev liblapack-dev expect dos2unix libncurses5-dev libboost-all-dev mlocate libcfitsio-dev libxerces-c-dev libhealpix-cxx-dev bc "
      
      echo "This script has not yet been adapted for your version of Ubuntu: ${VERSIONID}"
      echo " "
      echo "Anyway, try to install the following packages -- remove the ones which do not work form the list:"
      echo "sudo apt update; sudo apt install ${REQUIRED}"
      echo " "
      exit 255  
    fi
  elif [[ ${OS} == debian ]] || [[ ${OS} == raspbian ]]; then
    if [[ ${VERSIONID} == 10 ]]; then
      REQUIRED="git git-lfs gawk dpkg-dev make g++ gcc gfortran gdb valgrind binutils libx11-dev libxpm-dev libxft-dev libxext-dev libssl-dev libpcre3-dev libglu1-mesa-dev libglew-dev libftgl-dev libmariadb-dev libfftw3-dev libgraphviz-dev libavahi-compat-libdnssd-dev libldap2-dev python python3-dev python3-tk python3-venv python3-matplotlib libxml2-dev libkrb5-dev libgsl-dev cmake libxmu-dev curl doxygen libblas-dev liblapack-dev expect dos2unix libncurses5-dev bc libxerces-c-dev libhealpix-cxx-dev bc "
    elif (( ${VERSIONID} >= 11 )); then
      REQUIRED="git git-lfs gawk dpkg-dev make g++ gcc gfortran gdb valgrind binutils libx11-dev libxpm-dev libxft-dev libxext-dev libssl-dev libpcre3-dev libglu1-mesa-dev libglew-dev libftgl-dev libmariadb-dev libfftw3-dev libgraphviz-dev libavahi-compat-libdnssd-dev libldap2-dev python3 python3-dev python3-tk python3-venv python3-matplotlib libxml2-dev libkrb5-dev libgsl-dev cmake libxmu-dev curl doxygen libblas-dev liblapack-dev expect dos2unix libncurses5-dev bc libxerces-c-dev libhealpix-cxx-dev bc "
    else
      REQUIRED="git git-lfs gawk dpkg-dev make g++ gcc gfortran gdb valgrind binutils libx11-dev libxpm-dev libxft-dev libxext-dev libssl-dev libpcre3-dev libglu1-mesa-dev libglew-dev libftgl-dev libmariadb-dev libfftw3-dev libgraphviz-dev libavahi-compat-libdnssd-dev libldap2-dev python3 python3-dev python3-tk python3-venv python3-matplotlib libxml2-dev libkrb5-dev libgsl-dev cmake libxmu-dev curl doxygen libblas-dev liblapack-dev expect dos2unix libncurses5-dev bc libxerces-c-dev libhealpix-cxx-dev bc "
      
      echo "This script has not yet been adapted for your version of ${OS}: ${VERSIONID}"
      echo " "
      echo "Anyway, try to install the following packages -- remove the ones which do not work form the list:"
      echo "sudo apt update; sudo apt install ${REQUIRED}"
      echo " "
      exit 255  
    fi
  else
    REQUIRED="git git-lfs gawk dpkg-dev make g++ gcc gfortran gdb valgrind binutils libx11-dev libxpm-dev libxft-dev libxext-dev libssl-dev libpcre3-dev libglu1-mesa-dev libglew-dev libftgl-dev libmariadb-dev libfftw3-dev libgraphviz-dev libavahi-compat-libdnssd-dev libldap2-dev python3 python3-dev python3-tk python3-venv python3-matplotlib libxml2-dev libkrb5-dev libgsl-dev cmake libxmu-dev curl doxygen libblas-dev liblapack-dev expect dos2unix libncurses5-dev bc libxerces-c-dev libhealpix-cxx-dev bc "
 
    echo "This script has not yet been adapted for your version of Linux: Debian-derivative ${OS}"
    echo "Feel free to write the maintainers an email to update this script and send them the content of the file: /etc/os-release"
    echo " "
    echo "In the mean time, try to install the following packages -- remove the ones which do not work form the list:"
    echo "sudo apt update; sudo apt install ${REQUIRED}"
    echo " "
    exit 255      
  fi
  
  #echo "Required: ${REQUIRED}"
  if [[ "${REQUIRED}" == "" ]]; then exit 0; fi
    
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
    echo " "
    echo "Do the following to install all required packages:"
    echo "sudo apt update; sudo apt install ${TOBEINSTALLED}"
    echo " "
    exit 255
  else 
    echo " "
    echo "All required packages seem to be already installed!"
    exit 0
  fi
fi



###############################################################################
# OpenSUSE & clones

if [[ ${IsOpenSuseClone} -eq 1 ]]; then

  # Check if this is OpenSUSE:
  OS=`cat /etc/os-release | grep "^ID\=" | awk -F= '{ print $2 }'`
  OS=${OS//\"/}
  #echo "OS: ${OS}"
  if [[ ${OS} == opensuse-leap ]]; then
    # Check the version:
    VERSIONID=$(cat /etc/os-release | grep "^VERSION_ID\=" | awk -F= '{ print $2 }')
    VERSIONID=${VERSIONID//\"/}
    VERSIONID=$(echo ${VERSIONID} | awk -F'.' '{ print $1 }')
    #echo "VERSION: ${VERSIONID}"
    if [[ ${VERSIONID} == 15 ]]; then
      REQUIRED="git-core git-lfs bash cmake gcc-c++ gcc gcc-fortran binutils libX11-devel libXpm-devel xorg-x11-devel libXext-devel fftw3-devel python-devel gsl-devel graphviz-devel Mesa glew-devel ncurses-devel python3-devel mlocate cfitsio-devel libxerces-c-devel "
    else 
      REQUIRED="git-core git-lfs bash cmake gcc-c++ gcc gcc-fortran binutils libX11-devel libXpm-devel xorg-x11-devel libXext-devel fftw3-devel python-devel gsl-devel graphviz-devel Mesa glew-devel ncurses-devel python3-devel mlocate cfitsio-devel libxerces-c-devel "

      echo " "
      echo "This script has not yet been adapted for your version of opensuse: ${VERSIONID}"
      echo "Feel free to write the maintainers an email to update this script and send them the content of the file: /etc/os-release"
      echo " "
      echo "In the mean time, try to install the following packages -- remove the ones which do not work form the list:"
      echo "sudo zypper install ${REQUIRED}"
      echo "sudo updatedb"
      echo " "
      exit 255 
    fi
  elif [[ ${OS} == opensuse-tumbleweed ]]; then
    REQUIRED="git-core git-lfs bash cmake gcc-c++ gcc gcc-fortran binutils libX11-devel libXpm-devel xorg-x11-devel libXext-devel fftw3-devel gsl-devel graphviz-devel Mesa glew-devel ncurses-devel patterns-devel-python-devel_python3 patterns-devel-base-devel_basis patterns-devel-C-C++-devel_C_C++ mlocate cfitsio-devel libxerces-c-devel "
  else
    REQUIRED="git-core git-lfs bash cmake gcc-c++ gcc binutils libX11-devel libXpm-devel xorg-x11-devel libXext-devel fftw3-devel python-devel gsl-devel graphviz-devel Mesa glew-devel python3-devel mlocate cfitsio-devel libxerces-c-devel "

    echo " "
    echo "This script has not yet been adapted for your version of Linux: SUSE-derivative ${OS}"
    echo "Feel free to write the maintainers an email to update this script and send them the content of the file: /etc/os-release"
    echo " "
    echo "In the mean time, try to install the following packages -- remove the ones which do not work form the list:"
    echo "sudo zypper install ${REQUIRED}"
    echo " "
    exit 255
  fi
  
  if [[ "${REQUIRED}" == "" ]]; then exit 0; fi

  # Check if each of the packages exists:
  for PACKAGE in ${REQUIRED}; do 
    # Check if the file is installed
    STATUS=$(rpm -q --queryformat "%{NAME}\n" ${PACKAGE})
    #echo "${PACKAGE}: >${STATUS}<"
    if [[ "${STATUS}" != "${PACKAGE}" ]]; then
      # Check if it exists at all:
      echo "Not installed: ${PACKAGE}"
      TOBEINSTALLED="${TOBEINSTALLED} ${PACKAGE}"
    fi
  done
  
  
  if [[ "${TOBEINSTALLED}" != "" ]]; then
    echo " "
    echo "Do the following to install all required packages:"
    echo "sudo zypper install ${TOBEINSTALLED}"
    echo "sudo updatedb"
    echo " "
    exit 255
  else 
    echo " "
    echo "All required packages seem to be already installed!"
    exit 0
  fi
fi



###############################################################################
# Redhat & clones

if [[ ${IsRedhatClone} -eq 1 ]]; then

  # Check which OS we really have:
  OS=`cat /etc/os-release | grep "^ID\=" | awk -F= '{ print $2 }'`
  OS=${OS//\"/}
  #echo "OS: ${OS}"
  if [[ ${OS} == rhel ]]; then
    # Check the version
    VERSIONID=$(cat /etc/os-release | grep "^VERSION_ID\=" | awk -F= '{ print $2 }')
    VERSIONID=${VERSIONID//\"/}
    VERSIONID=$(echo ${VERSIONID} | awk -F'.' '{ print $1 }')
    #echo "VERSION: ${VERSIONID}"
    if [[ ${VERSIONID} == 7 ]]; then
      REQUIRED="openssl git git-lfs cmake gcc-c++ gcc binutils libX11-devel libXpm-devel libXft-devel libXext-devel libXt-devel gcc-gfortran openssl-devel pcre-devel mesa-libGL-devel mesa-libGLU-devel glew-devel mariadb-devel fftw-devel graphviz-devel avahi-compat-libdns_sd-devel python-devel libxml2-devel curl dos2unix ncurses-devel perl-devel cfitsio-devel xerces-c-devel healpix-c++-devel "
    else 
      REQUIRED="openssl git git-lfs cmake gcc-c++ gcc binutils libX11-devel libXpm-devel libXft-devel libXext-devel libXt-devel gcc-gfortran openssl-devel pcre-devel mesa-libGL-devel mesa-libGLU-devel glew-devel mariadb-devel fftw-devel graphviz-devel avahi-compat-libdns_sd-devel python-devel libxml2-devel curl dos2unix ncurses-devel perl-devel cfitsio-devel xerces-c-devel healpix-c++-devel "

      echo " "
      echo "This script has not yet been adapted for your version of SL ${VERSIONID}"
      echo "Feel free to write the maintainers an email to update this script and send them the content of the file: /etc/os-release"
      echo " "
      echo "In the mean time, try to install the following packages -- remove the ones which do not work form the list:"
      echo "sudo yum install ${REQUIRED}"
      echo " "
      exit 255
    fi
  elif [[ ${OS} == fedora ]]; then
    # Check the version
    VERSIONID=$(cat /etc/os-release | grep "^VERSION_ID\=" | awk -F= '{ print $2 }')
    VERSIONID=${VERSIONID//\"/}
    VERSIONID=$(echo ${VERSIONID} | awk -F'.' '{ print $1 }')
    #echo "VERSION: ${VERSIONID}"
    if (( ${VERSIONID} >= 28 )) && (( ${VERSIONID} <= 40 )) ; then
      REQUIRED="openssl patch git git-lfs make cmake gcc-c++ gcc binutils libX11-devel libXpm-devel libXft-devel libXext-devel libXt-devel gcc-gfortran openssl-devel pcre-devel mesa-libGL-devel mesa-libGLU-devel glew-devel mariadb-devel fftw-devel graphviz-devel avahi-compat-libdns_sd-devel python3-devel libxml2-devel curl dos2unix ncurses-devel perl-devel boost-devel readline-devel cfitsio-devel xerces-c-devel healpix-c++-devel "
    else 
      REQUIRED="openssl patch git git-lfs make cmake gcc-c++ gcc binutils libX11-devel libXpm-devel libXft-devel libXext-devel libXt-devel gcc-gfortran openssl-devel pcre-devel mesa-libGL-devel mesa-libGLU-devel glew-devel mariadb-devel fftw-devel graphviz-devel avahi-compat-libdns_sd-devel python3-devel libxml2-devel curl dos2unix ncurses-devel perl-devel boost-devel readline-devel cfitsio-devel xerces-c-devel healpix-c++-devel "

      echo " "
      echo "This script has not yet been adapted for your version of SL ${VERSIONID}"
      echo "Feel free to write the maintainers an email to update this script and send them the content of the file: /etc/os-release"
      echo " "
      echo "In the mean time, try to install the following packages -- remove the ones which do not work form the list:"
      echo "sudo yum install ${REQUIRED}"
      echo " "
      exit 255
    fi
  elif [[ ${OS} == centos ]]; then
    # Check the version
    VERSIONID=$(cat /etc/os-release | grep "^VERSION_ID\=" | awk -F= '{ print $2 }')
    VERSIONID=${VERSIONID//\"/}
    VERSIONID=$(echo ${VERSIONID} | awk -F'.' '{ print $1 }')
    #echo "VERSION: ${VERSIONID}"
    if [[ ${VERSIONID} == 7 ]]; then
      REQUIRED="openssl git git-lfs cmake gcc-c++ gcc binutils libX11-devel libXpm-devel libXft-devel libXext-devel libXt-devel gcc-gfortran openssl-devel pcre-devel mesa-libGL-devel mesa-libGLU-devel glew-devel mariadb-devel fftw-devel graphviz-devel avahi-compat-libdns_sd-devel python-devel libxml2-devel curl dos2unix ncurses-devel perl-devel cfitsio-devel xerces-c-devel healpix-c++-devel "
    elif [[ ${VERSIONID} == 8 ]]; then
      REQUIRED="openssl git git-lfs cmake gcc-c++ gcc binutils libX11-devel libXpm-devel libXft-devel libXext-devel libXt-devel gcc-gfortran openssl-devel pcre-devel mesa-libGL-devel mesa-libGLU-devel glew-devel mariadb-devel fftw-devel graphviz-devel avahi-compat-libdns_sd-devel python3-devel libxml2-devel curl dos2unix ncurses-devel perl-devel cfitsio-devel xerces-c-devel healpix-c++-devel "
      
      echo ""
      echo "Centos 8 - please make sure to enable the powertools repository:"
      echo "sudo dnf -y install dnf-plugins-core"
      echo "sudo dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm"
      echo "sudo dnf config-manager --set-enabled powertools"
      echo ""

    elif [[ ${VERSIONID} == 9 ]]; then
      REQUIRED="openssl git git-lfs cmake gcc-c++ gcc binutils libX11-devel libXpm-devel libXft-devel libXext-devel libXt-devel gcc-gfortran openssl-devel pcre-devel mesa-libGL-devel mesa-libGLU-devel fftw-devel python3-devel libxml2-devel curl dos2unix ncurses-devel perl-devel xerces-c-devel healpix-c++-devel "


    else 
      REQUIRED="openssl git git-lfs cmake gcc-c++ gcc binutils libX11-devel libXpm-devel libXft-devel libXext-devel libXt-devel gcc-gfortran openssl-devel pcre-devel mesa-libGL-devel mesa-libGLU-devel glew-devel mariadb-devel fftw-devel graphviz-devel avahi-compat-libdns_sd-devel python3-devel libxml2-devel curl dos2unix ncurses-devel perl-devel cfitsio-devel xerces-c-devel healpix-c++-devel "

      echo " "
      echo "This script has not yet been adapted for your version of Centos ${VERSIONID}"
      echo "Feel free to write the maintainers an email to update this script and send them the content of the file: /etc/os-release"
      echo " "
      echo "In the mean time, try to install the following packages -- remove the ones which do not work form the list:"
      echo "sudo yum install ${REQUIRED}"
      echo " "
      exit 255
    fi
  else
    REQUIRED="openssl git git-lfs cmake gcc-c++ gcc binutils libX11-devel libXpm-devel libXft-devel libXext-devel libXt-devel gcc-gfortran openssl-devel pcre-devel mesa-libGL-devel mesa-libGLU-devel glew-devel mariadb-devel fftw-devel graphviz-devel avahi-compat-libdns_sd-devel python3-devel libxml2-devel curl dos2unix ncurses-devel perl-devel cfitsio-devel xerces-c-devel healpix-c++-devel "

    echo " "
    echo "This script has not yet been adapted for your version of Linux: Redhat-derivative ${OS}"
    echo "Feel free to write the maintainers an email to update this script and send them the content of the file: /etc/os-release"
    echo " "
    echo "In the mean time, try to install the following packages -- remove the ones which do not work form the list:"
    echo "sudo yum install ${REQUIRED}"
    echo " "
    exit 255 
  fi
  
  if [[ "${REQUIRED}" == "" ]]; then exit 0; fi

  # Check if each of the packages exists:
  for PACKAGE in ${REQUIRED}; do 
    # Check if the file is installed
    STATUS=$(yum list installed ${PACKAGE} >& /dev/null)
    if [[ $? == 1 ]]; then
      # Check if it exists at all:
      echo "Not installed: ${PACKAGE}"
      TOBEINSTALLED="${TOBEINSTALLED} ${PACKAGE}"
    fi
  done
  
  
  if [[ "${TOBEINSTALLED}" != "" ]]; then
    echo " "
    echo "Do the following to install all required packages:"
    echo "sudo yum install ${TOBEINSTALLED}"
    echo " "
    exit 255
  else 
    echo " "
    echo "All required packages seem to be already installed!"
    exit 0
  fi

fi



###############################################################################
# Arch & clones - NOT SUPPORTED

if [[ ${IsArchClone} -eq 1 ]]; then

  REQUIRED="git git-lfs gawk make gcc gcc-fortran gdb valgrind binutils libx11 libxpm libxft libxext openssl pcre glu glew ftgl  fftw graphviz avahi libldap python3 tk libxml2 krb5 gsl cmake libxmu curl doxygen blas lapack expect dos2unix ncurses boost "

  if [[ "${REQUIRED}" == "" ]]; then exit 0; fi

  # Check if each of the packages exists:
  for PACKAGE in ${REQUIRED}; do
    # Check if the file is installed
    #echo "Testing: ${PACKAGE}"
    STATUS=$(pacman -Ss ${PACKAGE} >& /dev/null)
    if [[ $? == 1 ]]; then
      # Check if it exists at all:
      echo "Does not exist: ${PACKAGE}"
    else
      STATUS=$(pacman -Qi ${PACKAGE} >& /dev/null)
      if [[ $? == 1 ]]; then
        # Check if it exists at all:
        echo "Not installed: ${PACKAGE}"
        TOBEINSTALLED="${TOBEINSTALLED} ${PACKAGE}"
      fi
    fi
  done


  if [[ "${TOBEINSTALLED}" != "" ]]; then
    echo " "
    echo "Do the following to install all required packages:"
    echo "sudo pacman -S ${TOBEINSTALLED}"
    echo " "
    exit 255
  else
    echo " "
    echo "All required packages seem to be already installed!"
    exit 0
  fi

fi




###############################################################################
# Alpine - NOT SUPPORTED!

if [[ ${IsAlpineClone} -eq 1 ]]; then

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
