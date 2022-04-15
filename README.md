# cosi-setup

This repository contains the tools to setup a full working COSItools development and end-user environment.

## Quick guide

You can setup the environment by simply executing this command:
```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/cositools/cosi-setup/feature/initialsetup/setup.sh)"
```
This script will likely run until a point where it tells you to install a few packages.
After you do that, just start the script again, and it will complete the setup.

## Examples on how to get the COSItools started on supercomputing clusters

Since the COSItools might be installed on a few systems where the user has not full control over the setup, and cannot install individual packages, below are a few examples on how to handle these cases.

### UC Berkeley's savio cluster

This approach work last on 4/15/2022.

The Savio cluster uses scientific linux as well as "environment modules" to load specific software packages. In order, to compile COSItools, you need to load the following modules:

```
# Load modules
module load gcc/4.8.5 cmake/3.15.1 python/3.6 cuda tensorflow
# Fix blas on savio
export BLAS_LIBS="/global/home/groups/consultsw/sl-7.x86_64/modules/blas/3.8.0"
```

Then launch the script once to setup the basic directory structure:
```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/cositools/cosi-setup/feature/initialsetup/setup.sh)"
```
Ignore the request to install more packages, and switch directly into the cosi-setup directory, from where you restart the setup script, by telling it to ignore not installed packages, to not install HEASoft, and limit the number of threads to 4 (otherwise the admins might complain for using too much resources on the login nodes):
```
cd COSItools/cosi-setup
bash setup.sh --heasoft= --ignore-missing-packages --max-threads=4
```
This should install a working version of the COSItools.

### LBNL's cori supercomputer


### Clemson's Palmetto cluster









