#!/bin/bash

# This bash script is part of the MEGAlib & COSItools setup procedure.
# As such it is dual licenced under Apache 2.0 for COSItools and LGPL 3.0 for MEGAlib
#
# Development lead: Andreas Zoglauer
#
# Description:
# This script checks that cosipy is usable within the COSItools python environment
#


PENV=../python-env

if [[ ! -f ${PENV}/bin/activate ]]; then
  echo ""
  echo "ERROR: Unable to find the python environment at ${PENV}!"
  exit 1
fi

# We do not want any site packages, thus clear PYTHONPATH
export PYTHONPATH=""

# Activate the environment
. "${PENV}/bin/activate"
if [[ "$?" != "0" ]]; then
  echo ""
  echo "ERROR: Unable to activate the python environment!"
  exit 1
fi

# Importing cosipy pulls in the whole dependency chain (histpy, mhealpy, scoords,
# astropy, astromodels, threeml, scipy, numba), thus this is a meaningful check
# and not just a syntax test.
python3 - <<'PYTHONCHECK'
import sys
print("Python:  " + sys.version.split()[0] + "  (" + sys.executable + ")")
# Keep this in sync with requires-python in cosipy's pyproject.toml
if sys.version_info < (3, 12):
    sys.exit("ERROR: cosipy requires python 3.12 or later")
import cosipy
print("cosipy:  " + cosipy.__version__ + "  (" + cosipy.__file__ + ")")
if cosipy.__version__ == "unknown":
    sys.exit("ERROR: cosipy was found, but it is not installed in the python environment")
PYTHONCHECK
if [[ "$?" != "0" ]]; then
  echo ""
  echo "ERROR: cosipy is not usable!"
  exit 1
fi

exit 0
