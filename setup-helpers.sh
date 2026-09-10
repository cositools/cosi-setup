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

  # Drop empty and "." components, and let ".." remove the component in front of it
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
