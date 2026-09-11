#!/bin/bash

# This bash script is part of the MEGAlib & COSItools setup procedure.
# As such it is dual licenced under Apache 2.0 for COSItools and LGPL 3.0 for MEGAlib
#
# Development lead: Andreas Zoglauer
#
# Description:
# Helper functions shared by the COSItools setup scripts. Source it via
# ". ${SETUPPATH}/setup-helpers.sh" after SETUPPATH has been determined.
#
# Attention: setup.sh cannot use this file, since it is downloaded and run on its own
# before the cosi-setup repository exists. It carries its own copy of the functions.


# Resolve a command line argument to the full name of the option it names.
#
# An option may be abbreviated as long as the abbreviation is unique, the same way the
# GNU tools do it. With the options "branch heasoft healpix help" for example:
#   --branch=develop  ->  branch    the full name
#   --b=develop       ->  branch    unique abbreviation, no other option starts with b
#   --heas=cfitsio    ->  heasoft   unique, --heal would give healpix
#   --he              ->  ambiguous, it matches heasoft, healpix and help
#   --bogus           ->  unknown
#
# Only the text in front of the "=" is compared, thus the value of an option can never
# be mistaken for another option: "--branch=my-auto-fix" cannot trigger "auto", and
# "--root=/opt/gcc-auto" cannot either. This is why the comparison is done here instead
# of matching the whole argument against a pattern.
#
# ${1}: the command line argument, e.g. "--heas=cfitsio"
# ${2}: the known option names, separated by spaces, e.g. "branch heasoft healpix help"
#
# Returns 0 and echoes the resolved option name, e.g. "heasoft"
#         1 and echoes nothing if no option starts with the given name
#         2 and echoes all candidates if the abbreviation is not unique
resolveoption() {
  # Everything from the "=" on is the value, and the dashes are not part of the name
  local NAME="${1%%=*}"
  NAME="${NAME#--}"
  NAME="${NAME#-}"
  if [[ ${NAME} == "" ]]; then return 1; fi

  # Collect all options the name could stand for. A full name always wins, even if it
  # happens to be the beginning of a longer option as well.
  local MATCHES="" O
  for O in ${2}; do
    if [[ ${O} == "${NAME}" ]]; then echo "${O}"; return 0; fi
    if [[ ${O} == ${NAME}* ]]; then MATCHES+="${O} "; fi
  done

  # Turn the matches into positional parameters, since that is how we count them
  set -- ${MATCHES}
  if [[ $# == 1 ]]; then echo "${1}"; return 0; fi
  if [[ $# == 0 ]]; then return 1; fi
  echo "${MATCHES}"
  return 2
}


# Turn a path into an absolute one. The path does not have to exist, since the setup uses
# this for directories it is about to create - a "cd" into a not yet existing directory
# fails and used to leave only the last component behind. Thus "." and ".." are resolved
# textually here.
# ${1}: the path, absolute or relative to the current directory
absolutefilename() {
  local FULL="${1}"
  if [[ ${FULL} != /* ]]; then
    FULL="$(pwd)/${FULL}"
  fi

  # If the path exists, let the shell resolve it. "cd -P" follows symbolic links, thus a
  # ".." behind a link lands where the link really points, and the result agrees with the
  # "pwd -P" the scripts use to find their own location.
  local RESOLVED=""
  if [[ -d "${FULL}" ]]; then
    RESOLVED=$(cd -P -- "${FULL}" >/dev/null 2>&1 && pwd -P) || RESOLVED=""
    if [[ ${RESOLVED} != "" ]]; then echo "${RESOLVED}"; return 0; fi
  elif [[ -d "$(dirname "${FULL}")" ]]; then
    RESOLVED=$(cd -P -- "$(dirname "${FULL}")" >/dev/null 2>&1 && pwd -P) || RESOLVED=""
    if [[ ${RESOLVED} != "" ]]; then echo "${RESOLVED}/$(basename "${FULL}")"; return 0; fi
  fi

  # Nothing to "cd" into - the setup creates this directory later on, thus resolve the
  # "." and ".." components textually
  local PARTS=() PART RESULT=""
  IFS='/' read -ra PARTS <<< "${FULL}"
  for PART in "${PARTS[@]}"; do
    case "${PART}" in
      ""|".") ;;
      "..")   RESULT="${RESULT%/*}" ;;
      *)      RESULT="${RESULT}/${PART}" ;;
    esac
  done

  if [[ ${RESULT} == "" ]]; then RESULT="/"; fi
  echo "${RESULT}"
}

# Check whether a path can be used safely in the generated source script. The path ends
# up in shell statements there, thus anything the shell would interpret has to be kept
# out. Only letters, digits and . _ - / + @ : are allowed.
# ${1}: the path to check
# Returns 0 if the path is usable, 1 otherwise
checkpathcharacters() {
  # grep works line by line, thus a newline would split the path into pieces which each
  # look harmless on their own - reject it before grep ever sees it
  case "${1}" in
    *$'\n'*) return 1 ;;
  esac
  if printf '%s' "${1}" | LC_ALL=C grep -q '[^A-Za-z0-9._/+@:-]'; then
    return 1
  fi
  return 0
}

# Return the value of a command line option, i.e. everything behind the first "=". The
# whole remainder is returned, thus a value may contain "=" itself, e.g. a URL with a
# query string. An option without a "=" has an empty value.
# ${1}: the command line argument, e.g. "--root=/opt/a=b"
optionvalue() {
  case "${1}" in
    *=*) printf '%s' "${1#*=}" ;;
    *)   printf '%s' "" ;;
  esac
}

# Interpret the value of a boolean command line option. Such an option may be given on its
# own, e.g. "--auto", in which case it has no value and means "true", or with an explicit
# value, e.g. "--auto=no". Accepted are true/on/yes and false/off/no in any capitalization,
# abbreviated the same way as everywhere else in these scripts, e.g. "t", "n", "off".
#
# ${1}: the value of the option, i.e. what optionvalue returned. Empty means "true".
#
# Returns 0 and echoes "true" or "false"
#         1 and echoes nothing if the value does not name a boolean
booleanvalue() {
  local VALUE
  VALUE=$(echo "${1}" | tr '[:upper:]' '[:lower:]')
  case "${VALUE}" in
    ""|t*|on|y*) echo "true";  return 0 ;;
    f*|of*|n*)   echo "false"; return 0 ;;
  esac
  return 1
}

# Find the directory which actually holds a HEASoft installation. HEASoft installs its
# binaries into a platform specific sub-directory, e.g. x86_64-pc-linux-gnu-libc2.44, thus
# the path a user gives may be that directory or the one above it. Both headas-init.sh and
# bin/ftversion have to be present, so that the build directory - which has the init script
# but no binaries - is not mistaken for the installation.
#
# ${1}: a path to a HEASoft installation
#
# Returns 0 and echoes the directory holding headas-init.sh and bin/ftversion
#         1 and echoes nothing if there is no HEASoft installation at or below the path
heasoftdirectory() {
  local DIR
  for DIR in "${1}" "${1}"/*; do
    if [[ -f "${DIR}/headas-init.sh" ]] && [[ -x "${DIR}/bin/ftversion" ]]; then
      echo "${DIR}"
      return 0
    fi
  done
  return 1
}

# Read the allowed version range of one component out of allowed-versions.txt. That file
# holds lines such as "ROOT-Min:6.36", "ROOT-Max:6.40" and "ROOT-Blacklist:6.38 6.39".
#
# ${1}: the full path of allowed-versions.txt
# ${2}: the label used inside that file, e.g. "ROOT", "Geant4", "HEASoft", "Healpix", "Python"
# ${3}: the component name for the error message, e.g. "ROOT"
#
# Sets VERSIONMINSTRING and VERSIONMAXSTRING to the range as written, e.g. "6.36"
#      VERSIONMIN and VERSIONMAX to the same encoded for comparing, see encodeversion
#      VERSIONBLACKLIST to the black listed versions, separated by spaces
#
# Returns 0, or 1 after an error message if the file holds no usable range
readversionrange() {
  VERSIONMINSTRING=$(grep "${2}-Min" "${1}" | awk -F":" '{ print $2 }')
  VERSIONMAXSTRING=$(grep "${2}-Max" "${1}" | awk -F":" '{ print $2 }')
  VERSIONBLACKLIST=$(grep "${2}-Blacklist" "${1}" | awk -F":" '{ print $2 }')

  if [[ ! ${VERSIONMINSTRING} =~ ^[0-9]+\.[0-9]+$ ]] || [[ ! ${VERSIONMAXSTRING} =~ ^[0-9]+\.[0-9]+$ ]]; then
    echo ""
    echo "ERROR: Unable to read a valid ${3} version range from ${1}"
    return 1
  fi

  VERSIONMIN=$(encodeversion "${VERSIONMINSTRING}")
  VERSIONMAX=$(encodeversion "${VERSIONMAXSTRING}")
  return 0
}

# Turn a version into a single number, so that two of them can be compared. Only the major
# and the minor part decide, thus 6.38, 6.38.02 and 6.38/02 all become 638. Geant4 and ROOT
# write their patch level behind a "." or a "/", and both forms have to give the same
# number - doing this in one place is what keeps the two apart from crashing on the other.
# The "10#" stops a leading zero from being read as an octal number, e.g. in 11.02.
#
# ${1}: the version, e.g. "6.40", "11.02.p02", "6.38/02", "3.14.7"
#
# Returns 0 and echoes the number
#         1 and echoes nothing if the version does not start with major.minor
encodeversion() {
  # Everything from the second separator on is the patch level and does not count
  local MAJOR MINOR
  MAJOR=$(echo "${1}" | awk -F'[./]' '{ print $1 }')
  MINOR=$(echo "${1}" | awk -F'[./]' '{ print $2 }')
  if [[ ! ${MAJOR} =~ ^[0-9]+$ ]] || [[ ! ${MINOR} =~ ^[0-9]+$ ]]; then
    return 1
  fi
  echo $((100*10#${MAJOR} + 10#${MINOR}))
  return 0
}

# Decide whether one version may be used, and say what is wrong with it if not. Both the
# "--check" and the "--good-version" mode of the check scripts end here, so that the two
# can never drift apart and report different things about the same version.
# readversionrange has to have been called first.
#
# ${1}: the version, e.g. "6.40"
# ${2}: the component name for the messages, e.g. "ROOT"
#
# Returns 0 after saying that the version is good
#         1 after saying why it is not
checkversionrange() {
  local ENCODED
  if ! ENCODED=$(encodeversion "${1}"); then
    echo ""
    echo "ERROR: ${2} version (${1}) is not acceptable"
    echo "       It is not a valid version string."
    return 1
  fi

  if [[ ${ENCODED} -lt ${VERSIONMIN} ]] || [[ ${ENCODED} -gt ${VERSIONMAX} ]]; then
    echo ""
    echo "ERROR: ${2} version (${1}) is not acceptable"
    echo "       You require a version between ${VERSIONMINSTRING} and ${VERSIONMAXSTRING}"
    return 1
  fi

  # A version is black listed either in full, e.g. 6.38.02, or with major and minor only
  local NORMALIZED="${1//\//.}"
  if [[ " ${VERSIONBLACKLIST} " == *" ${NORMALIZED} "* ]] || [[ " ${VERSIONBLACKLIST} " == *" ${NORMALIZED%.*} "* ]]; then
    echo ""
    echo "ERROR: ${2} version (${1}) is not acceptable"
    echo "       It has been black listed as not working."
    return 1
  fi

  echo "Found a good ${2} version: ${1}"
  return 0
}

# Decide whether a tarball which is already on disk can be reused, or has to be fetched
# again. The archive always has to be a complete gzip file, and when the web server reports
# a size it has to match. The size is compared as a number: comparing it as text, which is
# what this used to do, accepts a truncated file whenever its size happens to be a
# substring of the real one, e.g. 1234 inside 51234.
#
# Not every server reports a size - GitHub sends its tarballs without one - and the network
# may be down altogether. In both cases the gzip check is all there is, and a complete
# archive is kept rather than fetched again, so that a rebuild also works offline.
#
# ${1}: the local file name
# ${2}: the URL the file comes from
#
# Returns 0 if the local file is complete and can be kept
#         1 if it has to be downloaded again, after saying why
tarballisgood() {
  if [[ ! -f "${1}" ]]; then
    echo "Tarball does not exist, downloading it"
    return 1
  fi

  # A truncated or corrupted archive fails here, whatever its size says
  if ! gunzip -t "${1}" >/dev/null 2>&1; then
    echo "Tarball already exists, but is corrupted. Requiring re-download."
    return 1
  fi

  # The headers are fetched on their own and not inside a pipe, since the exit status of a
  # pipe is the one of its last command and a failing curl would go unnoticed there
  local HEADERS="" REMOTESIZE="" LOCALSIZE
  HEADERS=$(curl -sSL --head "${2}" 2>/dev/null) || HEADERS=""

  # A redirect answers with several headers. The ones belonging to the redirect itself
  # carry a length of 0, thus drop those and take the last real one.
  if [[ ${HEADERS} != "" ]]; then
    REMOTESIZE=$(echo "${HEADERS}" | grep -i "^content-length:" | awk '{ print $2 }' | tr -d '\r' | grep -v '^0$' | tail -1)
  fi

  if [[ ! ${REMOTESIZE} =~ ^[0-9]+$ ]]; then
    echo "Tarball already exists and is a complete archive - the server reports no size to compare. No download required."
    return 0
  fi

  LOCALSIZE=$(wc -c < "${1}" | tr -d ' ')
  if [[ ${LOCALSIZE} -ne ${REMOTESIZE} ]]; then
    echo "Remote and local file sizes are different (local: ${LOCALSIZE} vs. remote: ${REMOTESIZE}). Downloading it."
    return 1
  fi

  echo "Tarball already exists and is complete. No download required."
  return 0
}
