# cosi-setup

This repository contains the tools to setup a full working COSItools development and end-user environment.

## Quick guide

You can setup the environment by simply executing this command:
```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/cositools/cosi-setup/feature/initialsetup/setup.sh)"
```
This script will likely run until a point where it tells you to install a few packages.
After you do that, just start the script again, and it will complete the setup.

## Examples on how to install the COSItools on various system

### Personal computers and workstations

#### Ubuntu

Version 20.04 and 22.04 should work with the default one-line install script.

#### Fedora

Version 35 should work with the default one-line install script.

#### macOS 

##### With Apple M chip

Montery should work with macports excluding HEASoft. However, homebrew is not supported.

##### With Intel chip

Coming soon...

#### OpenSUSE Tumbleweed

HEASoft does not compile at the moment, thus disable it and just use the system default cfitsiso library which should be installed automatically with the packages:
```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/cositools/cosi-setup/feature/initialsetup/setup.sh)" _ --heasoft=off
```

#### Other systems

No other systems have been officially been tested yet or are supported.

### Clusters and supercomputers

Since the COSItools might be installed on a few systems where the user has not full control over the setup, and cannot install individual packages, below are a few examples on how to handle these cases.

#### UC Berkeley's savio cluster

This approach worked last on 4/20/2022.

The Savio cluster uses scientific linux as well as "environment modules" to load specific software packages. In order, to set up the COSItools, you need to load the following modules:

```
module load gcc/6.3.0 cmake/3.22.0 git/2.11.1 blas/3.8.0 ml/tensorflow/2.5.0-py37
```

Then launch the script with the following additional option:
```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/cositools/cosi-setup/feature/initialsetup/setup.sh)" _ --ignore-missing-packages --keep-environment-as-is=true --max-threads=6
```
It ignores not installed packages since the setup script cannot find packages installed via the "environment modules", it keeps all environment search paths intact, and it limits the number of threads to 6 otherwise the savio admins might complain that you use too many resources on the login nodes.

#### LBNL's cori supercomputer

This approach worked last on 4/XYZ/2022.

Lawrence Berkeley National Lab's cori supercomputer uses the SUSE Linux Enterprise as well as "environment modules" to load specific software packages. In order, to set up the COSItools, you need to load the following modules:

```
module swap PrgEnv-intel PrgEnv-gnu
```
Unfortunately the cfitsio README states, that "Cray supercomputers computers are currently not supported", thus we have to compile the COSItools without HEASoft.
Therefore, launch the script with the following additional option:
```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/cositools/cosi-setup/feature/initialsetup/setup.sh)" _ --ignore-missing-packages --keep-environment-as-is=true --heasoft=off --max-threads=6
```
It ignores not installed packages since the setup script cannot find packages installed via the "environment modules", it keeps all environment search paths intact, does not install HEASoft since the compilation crashes on cori, and it limits the number of threads to 6 otherwise the cori admins will complain that you use too many resources on the login nodes.


#### Clemson's Palmetto cluster
Test 









