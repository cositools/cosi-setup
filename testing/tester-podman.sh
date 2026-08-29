#!/bin/bash

# This bash script is part of the MEGAlib & COSItools setup procedure.
# As such it is dual licenced under Apache 2.0 for COSItools and LGPL 3.0 for MEGAlib
#
# Development lead: Andreas Zoglauer
#
# Description:
# This script checks if the COSItools install correctly on various OSes

set -euo pipefail

# List of operating system images to test
# See confhelp() how it works
IMAGES=(
  "ubuntu:22.04+2"
  "debian:12+"
  "fedora:43+"
  "rockylinux:8+"
  "almalinux:8+"
  "quay.io/centos/centos:stream9+"
  "opensuse/leap:16"
  "docker.io/manjarolinux/base:latest"
)

SETUPCMD='/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/cositools/cosi-setup/main/setup.sh)" _ --auto --setup-branch=feature/auto-install '

# The command line
CMD=( "$@" )

# Default values for optional command line parameters
OSLIST=""


############################################################################################################
# Helper functions

confhelp() {
  echo ""
  echo "Test script for COSItools using podman"
  echo " "
  echo "This script tests whether COSItools installs correctly on various operating system container images using podman."
  echo " "
  echo "Usage: ./tester-podman.sh [options - all are optional!]"
  echo " "
  echo " "
  echo "Options:"
  echo " "
  echo "--os=[comma-separated list of podman-compatible OS images - default: use full internal list"
  echo "    Choose which OS images to test."
  echo "    Example: --os=debian:11,fedora:43+"
  echo "    A list entry of the form \"os\", \"os:N\", \"os:N+\", or \"os:N+STEP\" "
  echo "    \"os\" is the operating system name, e.g., \"debian\", \"fedora\"."
  echo "    N is the version name, as in debian:13, fedora:44"
  echo "    + means the all newer releases are tested to, e.g., debian:12 expands to debian:12, debian:13, etc, until we don't find a newer release"
  echo "    +STEP let's you skip releases, e.g., Ubuntu:24.04+2 --> Ubunut:24.04, Ubunut:26.04, etc. "
  echo "    If the option is not given, the built-in list of images is used."
  echo " "
  echo "--help or -h"
  echo "    Show this help."
  echo " "
  echo " "
}


# Expand a "repo:N+" or "repo:N+STEP" range entry into concrete tags by probing
# See confhelp() for details
ExpandOSRange() {
  local ENTRY="$1"               # e.g. "quay.io/centos/centos:stream9+", "ubuntu:22.04+2"
  local REPO="${ENTRY%:*}"       # e.g. "quay.io/centos/centos", "ubuntu"
  local SPEC="${ENTRY##*:}"      # e.g. "stream9+", "22.04+2"
  local START="${SPEC%%+*}"      # e.g. "stream9", "22.04"
  local STEP="${SPEC#*+}"        # e.g. "", "2"
  if [[ "${STEP}" == "" ]]; then
    STEP=1                       # e.g. "1", "2"
  fi

  local PREFIX=""                
  local MAJOR=""                 
  local SUFFIX=""                
  if [[ ${START} =~ ^([A-Za-z]*)([0-9]+)\.([0-9]+)$ ]]; then   # "stream9" -> no match, "22.04" -> matches
    PREFIX="${BASH_REMATCH[1]}"  # e.g. n/a, ""
    MAJOR="${BASH_REMATCH[2]}"   # e.g. n/a, "22"
    SUFFIX=".${BASH_REMATCH[3]}" # e.g. n/a, ".04"
  elif [[ ${START} =~ ^([A-Za-z]*)([0-9]+)$ ]]; then            # "stream9" -> matches, "22.04" already matched above
    PREFIX="${BASH_REMATCH[1]}"  # e.g. "stream", n/a
    MAJOR="${BASH_REMATCH[2]}"   # e.g. "9", n/a
  fi

  if [[ -z "${MAJOR}" ]] || [[ ! ${STEP} =~ ^[0-9]+$ ]]; then
    echo "ERROR: \"${ENTRY}\" is not a valid range - expected repo:N+, repo:N+STEP, repo:prefixN+, or repo:N.MM+STEP, e.g. fedora:43+, quay.io/centos/centos:stream9+, ubuntu:22.04+2" >&2
    exit 1
  fi

  local VER="${MAJOR}"
  local MAXCHECKS=30
  local N=0
  local FOUND=()
  while [[ ${N} -lt ${MAXCHECKS} ]]; do
    if podman manifest inspect "${REPO}:${PREFIX}${VER}${SUFFIX}" >/dev/null 2>&1; then
      FOUND+=("${REPO}:${PREFIX}${VER}${SUFFIX}")
      VER=$((VER + STEP))
      N=$((N + 1))
    else
      break
    fi
  done

  if [[ ${#FOUND[@]} -eq 0 ]]; then
    echo "ERROR: \"${REPO}:${PREFIX}${MAJOR}${SUFFIX}\" does not exist - cannot start a range there" >&2
    exit 1
  fi

  echo " * Expanded ${ENTRY} to: ${FOUND[*]}" >&2
  printf '%s\n' "${FOUND[@]}"
}



# Derive the bootstrap command (installing curl/git/sudo) given the image name
GetBootstrap() {
  local IMAGE="$1"
  case "$IMAGE" in
    ubuntu*|debian*)
      echo "export DEBIAN_FRONTEND=noninteractive; apt-get update && apt-get install -y curl git sudo"
      ;;
    fedora*|rockylinux*|almalinux*|*centos*)
      echo "dnf install -y --allowerasing curl git sudo"
      ;;
    *suse*)
      echo "zypper --non-interactive install curl git sudo"
      ;;
    archlinux:*|*manjaro*)
      echo "pacman -Syu --noconfirm curl git sudo"
      ;;
    *)
      echo ""  # unknown family - caller will skip
      ;;
  esac
}



# Expand the setup command for specific OSes given the image name
ExpandSetup() {
  local IMAGE="$1"
  case "$IMAGE" in
    rockylinux*|almalinux*|opensuse/leap*)
      echo "--healpix= "
      ;;
    *)
      echo ""  # unknown family - caller will skip
      ;;
  esac
}



# Test a single operating system
TestSingleOS() {
  local IMAGE="$1"
  local BOOTSTRAP="$(GetBootstrap "$IMAGE")"
  local TAG="${IMAGE//[:\/]/_}"
  local LOG="$LOGDIR/$TAG.log"
  local CMD="${SETUPCMD}$(ExpandSetup "$IMAGE")"

  echo " "
  echo "Testing ${IMAGE}..."

  if [[ -z "${BOOTSTRAP}" ]]; then
    echo "SKIP: ${IMAGE} (unrecognized OS family, add a case in GetBootstrap() function)" | tee -a "${LOGDIR}/summary.txt"
    return
  fi

  # Exit code 90 flags a failure to bootstrap the container itself (broken distro
  # mirror, missing repository metadata, ...) so that "this OS image is broken
  # today" can be told apart from "COSItools failed to install".
  if podman run --rm --pull=always -it "${IMAGE}" bash -c "set -e; { ${BOOTSTRAP}; } || exit 90; useradd -m tester && echo 'tester ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/tester && chmod 0440 /etc/sudoers.d/tester && sudo -H -u tester bash -lc 'cd; ${CMD}'" > "$LOG" 2>&1; then
    echo "PASS: ${IMAGE}" | tee -a "${LOGDIR}/summary.txt"
  else
    STATUS=$?
    if [[ ${STATUS} -eq 90 ]]; then
      echo "INFRA-FAIL: ${IMAGE} (could not bootstrap the container -- broken distro repository/mirror, not a COSItools problem; see ${LOG})" | tee -a "${LOGDIR}/summary.txt"
    else
      echo "FAIL: ${IMAGE} (see ${LOG})" | tee -a "${LOGDIR}/summary.txt"
    fi
  fi
}



############################################################################################################
# Extract the main parameters

# Check for help
for C in "${CMD[@]}"; do
  if [[ ${C} == *-h ]] || [[ ${C} == *-hel* ]]; then
    confhelp
    exit 0
  fi
done

echo ""
echo "Podman based OS compatibility tester"
echo ""

# Check if podman is installed
if ! type podman >/dev/null 2>&1; then
  echo "ERROR: podman must be installed"
  exit 1
fi

# Overwrite default options with user options:
for C in "${CMD[@]}"; do
  if [[ ${C} == *-os*=* ]]; then
    OSLIST=`echo ${C} | awk -F"=" '{ print $2 }'`
  else
    echo ""
    echo "ERROR: Unknown command line option: ${C}"
    echo "       See \"./tester-podman.sh --help\" for a list of options"
    exit 1
  fi
done

# If the user gave a list of OSes, it replaces the built-in IMAGES array
if [[ "${OSLIST}" != "" ]]; then
  IFS=',' read -ra IMAGES <<< "${OSLIST}"
fi

# Expand any "repo:N+" or "repo:N+STEP" range entries into concrete tags
echo "Checking for OS images to test"
RESOLVEDIMAGES=()
for ENTRY in "${IMAGES[@]}"; do
  if [[ ${ENTRY} == *:*+* ]]; then
    EXPANDED="$(ExpandOSRange "${ENTRY}")"
    if [[ $? -ne 0 ]]; then
      exit 1
    fi
    while IFS= read -r IMG; do
      RESOLVEDIMAGES+=("${IMG}")
    done <<< "${EXPANDED}"
  else
    RESOLVEDIMAGES+=("${ENTRY}")
  fi
done
IMAGES=("${RESOLVEDIMAGES[@]}")


############################################################################################################
# Run the tests

LOGDIR="logs/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$LOGDIR"

for IMG in "${IMAGES[@]}"; do
  TestSingleOS "${IMG}"
done

echo ""
echo "Done. Logs + summary in ${LOGDIR}"
echo ""

exit 0

############################################################################################################
