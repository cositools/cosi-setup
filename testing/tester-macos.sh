#!/bin/bash

# This bash script is part of the MEGAlib & COSItools setup procedure.
# As such it is dual licenced under Apache 2.0 for COSItools and LGPL 3.0 for MEGAlib
#
# Development lead: Andreas Zoglauer
#
# Description:
# This script checks if the COSItools install correctly on the various currently
# supported macOS versions. Each test runs in its own Virtualization.Framework VM,
# started via tart, one per macOS version and package manager combination. Each test
# writes its own log, and all results are collected in summary.txt.

set -euo pipefail

# Path to where this file is located, and to the repository it belongs to
TESTERPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
SETUPPATH="$( cd -- "${TESTERPATH}/.." >/dev/null 2>&1 ; pwd -P )"

# The shared helper functions, e.g. resolveoption
. "${SETUPPATH}/setup-helpers.sh"

# Every option this script accepts. Abbreviations are resolved against this list.
SETUPOPTIONS="versions packages cpus memory setup-branch keep-vm help"

# The command line
CMD=( "$@" )

# Test result counters - anything which is not a pass counts as a failure
PASSED=0
FAILURES=0

# Default values for optional command line parameters
VERSIONS="sonoma,sequoia,tahoe"
PACKAGES="brew,macports"

# Resources for each VM. A full ROOT/Geant4/HEASoft/MEGAlib build is memory hungry;
# raise these if "read jobs pipe: Resource temporarily unavailable" shows up.
CPUS=8
MEMORY=16384

# The cosi-setup branch under test. Both the bootstrap setup.sh and the cloned
# repository are taken from it, so that stage 1 and stage 2 are always the same
# version. Empty means use the branch this working copy is on.
SETUPBRANCH=""

# Keep the VMs after each test instead of deleting them (useful for debugging)
KEEPVM="false"


############################################################################################################
# Helper functions

confhelp() {
  echo ""
  echo "Test script for COSItools using tart (macOS / Apple Silicon)"
  echo " "
  echo "This script tests whether COSItools installs correctly on the various currently"
  echo "supported macOS releases. Each test boots one arm64 Virtualization.Framework"
  echo "VM (via tart) on the Apple Silicon host, installs exactly one package manager"
  echo "(brew or macports) inside it, and then runs the pushed cosi-setup setup.sh with"
  echo "--auto so that the install completes without a human in the loop."
  echo " "
  echo "The host needs: tart, sshpass, and to run macOS 13+ on Apple Silicon."
  echo " "
  echo "Usage: ./tester-macos.sh [options - all are optional!]"
  echo " "
  echo " "
  echo "Options:"
  echo " "
  echo "--versions=[comma-separated list of macOS names - default: sonoma,sequoia,tahoe]"
  echo "    Choose which macOS releases to test."
  echo "    Known names: sonoma (14), sequoia (15), tahoe (26)."
  echo "    Any other name is reported and skipped."
  echo " "
  echo "--packages=[comma-separated list of package managers - default: brew,macports]"
  echo "    Choose which package manager(s) to use inside the VMs. Known names: brew, macports."
  echo "    Only one package manager is ever active in a given VM, mirroring the README."
  echo " "
  echo "--cpus=[integer >=1 - default: ${CPUS}]"
  echo "    Number of CPUs given to each VM while it builds."
  echo " "
  echo "--memory=[integer >=1, in mega byte - default: ${MEMORY}]"
  echo "    Memory in mega byte given to each VM while it builds."
  echo " "
  echo "--setup-branch=[name of a cosi-setup git branch - default: the branch of this working copy]"
  echo "    Test this branch instead of the one this working copy is on."
  echo "    The VMs download the branch from GitHub, thus it has to be pushed first."
  echo " "
  echo "--keep-vm[=false/off/no, true/on/yes - default: false]"
  echo "    Do not stop and delete the VM after each test (useful for manual inspection"
  echo "    of a failing install)."
  echo " "
  echo "--help or -h"
  echo "    Show this help."
  echo " "
  echo " "
}



# Resolve a short macOS name to its full tart image reference
# See confhelp() for the list of names
ResolveMacOSImage() {
  case "$1" in
    sonoma)  echo "ghcr.io/cirruslabs/macos-sonoma-xcode" ;;
    sequoia) echo "ghcr.io/cirruslabs/macos-sequoia-xcode" ;;
    tahoe)   echo "ghcr.io/cirruslabs/macos-tahoe-xcode" ;;
    *)       echo "" ;;
  esac
}



# Return the shell statements which install the given package manager in the guest.
# They use "sudo", which BuildGuestCommand() has made password free beforehand.
# An unknown package manager returns "", and the caller then skips that test.
GetBootstrap() {
  case "$1" in
    brew)
      # The tart images are arm64, and the stage 2 script refuses a brew which built
      # x86_64 libraries on an arm64 machine, thus brew is installed in arm64 mode.
      # The brew installer stops when it is run as root, and it calls sudo itself where
      # it needs to. NONINTERACTIVE keeps it from waiting for a key press.
      cat <<'BREWBOOT'
      sudo xcode-select --reset
      sudo xcodebuild -license accept
      if ! command -v brew >/dev/null 2>&1; then
        NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      fi
      export PATH="$(/opt/homebrew/bin/brew --prefix)/bin:$(/opt/homebrew/bin/brew --prefix)/sbin:$(/opt/homebrew/bin/brew --prefix)/opt/binutils/libexec/gnubin:$PATH"
BREWBOOT
      ;;
    macports)
      cat <<'MACPORTBOOT'
      sudo xcode-select --reset
      sudo xcodebuild -license accept
      if ! command -v port >/dev/null 2>&1; then
        PKG_URL="$(curl -fsSL https://api.github.com/repos/macports/macports-base/releases/latest | grep -o 'https://[^"]*MacPorts-[^"]*arm64\.pkg' | head -n 1)"
        curl -fsSL "${PKG_URL}" -o MacPorts.pkg
        sudo installer -pkg MacPorts.pkg -target /
        rm -f MacPorts.pkg
      fi
      sudo /opt/local/bin/port -N selfupdate -q
MACPORTBOOT
      ;;
    *)
      echo ""
      ;;
  esac
}



# Return the script which is run inside the guest VM: install the package manager,
# then download setup.sh and install the COSItools with it. A bootstrap failure ends in
# exit code 90, which separates "this macOS image could not be prepared" from "the
# COSItools failed to install on it".
#
# The bootstrap script is downloaded to a file and run from there. Piping it straight
# into bash hides a failed download: curl writes nothing, bash runs an empty script and
# reports success, and the test would pass without ever having installed anything.
#
# The images come with an admin account whose password is known, but without a password
# free sudo. The first statements add it, after which the plain "sudo" of the bootstrap
# needs no password. The password is taken from TART_PASSWORD if it is set.
BuildGuestCommand() {
  local PKG="$1"
  local BOOTSTRAP="$(GetBootstrap "${PKG}")"
  if [[ -z "${BOOTSTRAP}" ]]; then
    echo ""
    return
  fi
  local ADMINPASSWORD="${TART_PASSWORD:-admin}"
  cat <<EOS
set -euo pipefail
ADMINPASSWORD="${ADMINPASSWORD}"
if [[ \$(id -u) != "0" ]] && ! command sudo -n true 2>/dev/null; then
  printf '%s\n' "\${ADMINPASSWORD}" | command sudo -S sh -c 'echo "admin ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/cosi-tester && chmod 0440 /etc/sudoers.d/cosi-tester'
fi
echo " * Testing on: macOS (${PKG})"
# A failing bootstrap statement means this macOS image could not be prepared, which is
# not a COSItools problem, thus it ends in exit code 90. "set -e" is left on so that a
# failure in the middle of the bootstrap is seen and not only one in its last statement.
# The bootstrap runs in this shell and not in a subshell, since it puts the package
# manager on the PATH.
trap 'exit 90' ERR
${BOOTSTRAP}
trap - ERR
curl -fsSL https://raw.githubusercontent.com/cositools/cosi-setup/${SETUPBRANCH}/setup.sh -o setup-bootstrap.sh
test -s setup-bootstrap.sh
/bin/bash setup-bootstrap.sh --auto --setup-branch=${SETUPBRANCH}
EOS
}



# Test a single (macOS, package manager) combination
TestSingle() {
  local ENTRY="$1"
  local VERSION="${ENTRY%%:*}"
  local PKG="${ENTRY##*:}"
  local VMNAME="$(echo "${VERSION}_${PKG}" | tr '[:upper:]' '[:lower:]')"
  local TAG="${VERSION}_${PKG}"
  local LOG="$LOGDIR/$TAG.log"
  local IMAGENAME="$(ResolveMacOSImage "${VERSION}")"

  echo " "
  echo "Testing ${ENTRY}..."

  if [[ -z "${IMAGENAME}" ]]; then
    echo "SKIP: ${ENTRY} (unknown macOS version, add a case in ResolveMacOSImage())" | tee -a "${LOGDIR}/summary.txt"
    FAILURES=$((FAILURES + 1))
    return
  fi
  if [[ -z "$(GetBootstrap "${PKG}")" ]]; then
    echo "SKIP: ${ENTRY} (unknown package manager, add a case in GetBootstrap())" | tee -a "${LOGDIR}/summary.txt"
    FAILURES=$((FAILURES + 1))
    return
  fi

  local GUESTCMD="$(BuildGuestCommand "${PKG}")"

  # Bring the VM up, run the guest script over SSH, and take back its exit code.
  # Anything which goes wrong before the guest answers means the VM could not be
  # brought up on this host, which is reported as INFRA-FAIL and not as FAIL.
  local STATUS=0
  local IP=""
  local PREP_OK="true"

  # "tart clone" downloads the image if it is not there yet, and creates the local VM
  # from it in one step
  if [[ ${PREP_OK} == "true" ]] && ! tart clone "${IMAGENAME}" "${VMNAME}" 2>&1 | tee -a "${LOG}"; then
    PREP_OK="false"
  fi
  if [[ ${PREP_OK} == "true" ]] && ! tart set "${VMNAME}" --cpus "${CPUS}" --memory "${MEMORY}" 2>&1 | tee -a "${LOG}"; then
    PREP_OK="false"
  fi
  # "tart run" has no detach option and occupies the shell until the VM shuts down, thus
  # it is put into the background. Whether the VM really came up is answered by the
  # readiness check below, and it is shut down again with "tart stop"
  if [[ ${PREP_OK} == "true" ]]; then
    tart run --no-graphics "${VMNAME}" >> "${LOG}" 2>&1 &
  fi

  # Wait for the VM to come up and answer over the network. The login is done with a
  # password, thus no "BatchMode=yes": it switches password authentication off, and the
  # probe could never succeed.
  local READY="false"
  if [[ ${PREP_OK} == "true" ]]; then
    local N=0
    while [[ ${N} -lt 60 ]]; do
      IP=$(tart ip "${VMNAME}" 2>/dev/null) || IP=""
      if [[ -n "${IP}" ]] && ping -c1 "${IP}" >/dev/null 2>&1 && \
         sshpass -p "${TART_PASSWORD:-admin}" ssh -o StrictHostKeyChecking=no \
           -o UserKnownHostsFile=/dev/null -o ConnectTimeout=5 \
           admin@"${IP}" "echo ready" >/dev/null 2>&1; then
        READY="true"
        break
      fi
      sleep 5
      N=$((N + 1))
    done
    if [[ ${READY} == false ]]; then
      PREP_OK="false"
    fi
  fi

  if [[ ${PREP_OK} != "true" ]]; then
    echo ""
    echo "INFRA-FAIL: ${ENTRY} (VM did not come up / could not be reached - not a COSItools problem; see ${LOG})" | tee -a "${LOGDIR}/summary.txt"
    if [[ ${KEEPVM} == false ]]; then
      tart stop "${VMNAME}" 2>/dev/null || true
      tart rm "${VMNAME}" 2>/dev/null || true
    fi
    FAILURES=$((FAILURES + 1))
    return
  fi

  echo " * VM ${VMNAME} is up at ${IP}"
  # Feed the guest script into the remote bash via stdin, write the output to this
  # test's log, and take back the guest exit code: 0 is a pass, 90 an infrastructure
  # failure, anything else a failed installation.
  # Under "set -e" a non-zero pipeline would end the script before PIPESTATUS can be
  # read, thus the if/else.
  if printf '%s\n' "${GUESTCMD}" | sshpass -p "${TART_PASSWORD:-admin}" \
        ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        "admin@${IP}" bash -s 2>&1 | tee -a "${LOG}"; then
    STATUS=0
  else
    STATUS=${PIPESTATUS[1]}
  fi

  if [[ ${KEEPVM} == false ]]; then
    tart stop "${VMNAME}" 2>/dev/null || true
    tart rm "${VMNAME}" 2>/dev/null || true
  else
    echo " * Keeping VM ${VMNAME}; inspect via \"tart run ${VMNAME}\""
  fi

  if [[ ${STATUS} -eq 0 ]]; then
    echo "PASS: ${ENTRY}" | tee -a "${LOGDIR}/summary.txt"
    PASSED=$((PASSED + 1))
  elif [[ ${STATUS} -eq 90 ]]; then
    echo "INFRA-FAIL: ${ENTRY} (VM up, but bootstrap / setup.sh could not complete; see ${LOG})" | tee -a "${LOGDIR}/summary.txt"
    FAILURES=$((FAILURES + 1))
  else
    echo "FAIL: ${ENTRY} (see ${LOG})" | tee -a "${LOGDIR}/summary.txt"
    FAILURES=$((FAILURES + 1))
  fi
}



############################################################################################################
# Extract the main parameters

# Check for help
for C in "${CMD[@]}"; do
  if [[ ${C} == "-h" ]] || [[ $(resolveoption "${C}" "${SETUPOPTIONS}") == "help" ]]; then
    confhelp
    exit 0
  fi
done

echo ""
echo "Tart based macOS compatibility tester"
echo ""

# Check that the tools required on the host are present
for T in tart sshpass; do
  if ! type "${T}" >/dev/null 2>&1; then
    echo "ERROR: ${T} must be installed on this host (e.g. brew install tart sshpass)"
    exit 1
  fi
done

if [[ $(uname -s) != *arwin* ]] || [[ $(uname -m) != arm64 ]]; then
  echo "ERROR: This tester assumes an Apple Silicon host; you are on: $(uname -s) / $(uname -m)"
  exit 1
fi

# Overwrite default options with user options:
for C in "${CMD[@]}"; do
  # "|| RESULT=$?" so that a non-zero return does not trip a "set -e"
  RESULT=0
  OPTION=$(resolveoption "${C}" "${SETUPOPTIONS}") || RESULT=$?
  if [[ ${RESULT} == 2 ]]; then
    echo "ERROR: The command line option \"${C}\" is ambiguous - it matches: ${OPTION}"
    echo "       See \"./tester-macos.sh --help\" for a list of options"
    exit 1
  elif [[ ${RESULT} != 0 ]]; then
    echo "ERROR: Unknown command line option: ${C}"
    echo "       See \"./tester-macos.sh --help\" for a list of options"
    exit 1
  fi

  case ${OPTION} in
    versions)     VERSIONS=$(optionvalue "${C}") ;;
    packages)     PACKAGES=$(optionvalue "${C}") ;;
    setup-branch) SETUPBRANCH=$(optionvalue "${C}") ;;
    cpus)
      CPUS=$(optionvalue "${C}")
      if [[ ! ${CPUS} =~ ^[0-9]+$ ]] || [[ ${CPUS} -lt 1 ]]; then
        echo "ERROR: The number of CPUs must be a number larger than 0 and not ${CPUS}"
        exit 1
      fi
      ;;
    memory)
      MEMORY=$(optionvalue "${C}")
      if [[ ! ${MEMORY} =~ ^[0-9]+$ ]] || [[ ${MEMORY} -lt 1 ]]; then
        echo "ERROR: The memory in mega byte must be a number larger than 0 and not ${MEMORY}"
        exit 1
      fi
      ;;
    keep-vm)
      if ! KEEPVM=$(booleanvalue "$(optionvalue "${C}")"); then
        echo "ERROR: Unknown value for the --keep-vm option: ${C}"
        echo "       Use true/on/yes or false/off/no, or give the option without a value"
        exit 1
      fi
      ;;
    help)         confhelp; exit 0 ;;
  esac
done

# Without an explicit branch, test what this working copy is on
if [[ ${SETUPBRANCH} == "" ]]; then
  SETUPBRANCH=$(git -C "${SETUPPATH}" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
  if [[ ${SETUPBRANCH} == "" ]] || [[ ${SETUPBRANCH} == "HEAD" ]]; then
    echo "ERROR: Cannot determine which branch to test - this is not a git working copy,"
    echo "       or it has a detached HEAD. Give the branch with --setup-branch=..."
    exit 1
  fi
  echo " * Testing the branch of this working copy: ${SETUPBRANCH}"
else
  echo " * Testing the branch: ${SETUPBRANCH}"
fi

# The VMs download the scripts from GitHub, thus only what has been pushed is tested.
# Warn about the two ways in which the test would silently run old code.
REMOTEHEAD=$(git -C "${SETUPPATH}" ls-remote origin "refs/heads/${SETUPBRANCH}" 2>/dev/null | awk '{ print $1 }')
LOCALHEAD=$(git -C "${SETUPPATH}" rev-parse "${SETUPBRANCH}" 2>/dev/null || echo "")
if [[ ${REMOTEHEAD} == "" ]]; then
  echo " * WARNING: The branch ${SETUPBRANCH} does not exist on origin - the test will fail to download it"
elif [[ ${LOCALHEAD} != "" ]] && [[ ${REMOTEHEAD} != "${LOCALHEAD}" ]]; then
  echo " * WARNING: The local branch ${SETUPBRANCH} differs from origin - the test uses what is on GitHub"
fi

# Build the test matrix from the macOS versions and the package managers. Entries which
# do not resolve are left intact, and TestSingle() reports and skips them.
IFS=',' read -ra VLIST <<< "${VERSIONS}"
IFS=',' read -ra PLIST <<< "${PACKAGES}"
IMAGES=()
for V in "${VLIST[@]}"; do
  for P in "${PLIST[@]}"; do
    IMAGES+=("${V}:${P}")
  done
done

echo "Checking for macOS / package manager combinations to test"
for E in "${IMAGES[@]}"; do
  echo "  ${E}"
done



############################################################################################################
# Run the tests

# Next to this script, so that the logs land in the same place no matter where it is called from
LOGDIR="${TESTERPATH}/logs/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$LOGDIR"

for ENTRY in "${IMAGES[@]}"; do
  TestSingle "${ENTRY}"
done

echo ""
echo "Done. Logs + summary in ${LOGDIR}"
echo "Passed: ${PASSED}, failed: ${FAILURES} (skipped and infrastructure failures count as failures)"
echo ""

if [[ ${FAILURES} -gt 0 ]]; then
  exit 1
fi

exit 0

############################################################################################################
