# cosi-setup

This repository contains the tools to setup a full working COSItools development and end-user environment.

## Quick guide

You can setup the environment by simply executing this command:
```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/cositools/cosi-setup/feature/initialsetup/setup.sh)"
```
This script will likely run until a point where it tells you to install a few packages.
After you do that, just start the script again, and it will complete the setup.

## Advanced guide

### Accessing the options

The setup script has serveral advanced options accessible. Using the above one-line install script, you can add options the following way (pay attention to the underscore:

```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/cositools/cosi-setup/feature/initialsetup/setup.sh)" _ --options --here
```

Alternatively, do the following:
```
mkdir COSItools
cd COSItools
git clone https://github.com/cositools/cosi-setup cosi-setup
cd cosi-setup
git checkout feature/initialsetup
bash setup.sh --options --here
```

### Options

The following options are a copy-and-paste from ```bash setup.sh --help```:

```
--cositoolspath=[path to COSItools - default: "COSItools"]
    This is the path to where the COSItools will be installed. If the path exists, we will try to update them.
 
--branch=[name of a git branch - default: feature/initialsetup]
    Choose a specific branch of the COSItools git repositories.
    If the option is not given the latest release will be used.
    If the branch does not exist for all repositories use the main/master branch.

--extras=[list of extra packages not installed by default]
     Add a few extra packages not installed by default since, e.g., they are too large
     Example: --extras=cosi-data-challenge-1,cosi-data-challenge-2

--ignore-missing-packages
    Do not check for missing packages.
 
--keep-environment=[off/no, on/yes - default: off]
    By default all relevant environment paths (such as LD_LIBRRAY_PATH, CPATH) are reset to empty
    to avoid most libray conflicts. This flag toggles this behaviour and lets you decide to keep your environment or not.
    If you use this flag make sure the COSItools source script has not been called in the terminal you are using.
 
--root=[options: empty (default), path to existing ROOT installation]
    --root=            Download and install the latest compatible version
    --root=[path]      Use the version of ROOT found in the path. If it is not compatible, the script will stop with an error.
 
--geant=[options: empty (default), path to existing GEANT4 installation]
    --geant=           Download and install the latest compatible version.
    --geant=[path]     Use the version of Geant4 found in the path. If it is not compatible, the script will stop with an error.
 
--heasoft=[options: empty (default), off, cfitsio, path to existing HEASoft installation]
    --heasoft=         Download and install the latest compatible version.
    --heasoft=off      Do not install HEASoft.
    --heasoft=cfitsio  Download and install the latest cfitsio version.
    --heasoft=[path]   Use the version of HEASoft found in the path. If it is not compatible, the script will stop with an error.
 
--maxthreads=[integer >=1]
    The maximum number of threads to be used for compilation. Default is the number of cores in your system.
 
--debug=[off/no (default), on/yes]
    Debugging compiler flags for C++ programs ROOT, Geant4 & MEGAlib.
 
--optimization=[off/no, normal/on/yes (default), strong/hard]
    Compilation optimization compiler flags for MEGAlib only.
 
--help or -h
    Show this help.
```


## Examples on how to install the COSItools on various system

### Linux

We recommend to stick with long(ish)-term support versions such as Ubuntu LTE.

#### Ubuntu & derivatives

Version 20.04 and 22.04 should work with the default one-line install script. We have no indications sofar that any distributions derived from Ubuntu are not working. We only test long-term support (LTE) versions.

#### Redhat derivatives

##### Fedora

Version 32-35 should work with the default one-line install script

##### Centos Stream

Version 9 should work.

#### openSUSE 

##### Leap

Leap 15.3 should work out of the box.

##### Tumbleweed

Tumbleweed is a cutting edge rolling release thus not recommended for COSItools. HEASoft does not compile at the moment, thus disable it and just use the system default cfitsiso library which should be installed automatically with the packages:
```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/cositools/cosi-setup/feature/initialsetup/setup.sh)" _ --heasoft=off
```

#### Other Linux systems

No other systems have been been tested yet or are supported. Especially avoid any cutting edge rolling releases such as Arch (it sometimes compiles there, sometimes not), Gentoo, Tumbleweed, etc.

### macOS 

Only macOS Monterey is supported at the moment. 
Xcode must be installed from the App store, and then install the command line tools via:
```
xcode-select --install
```
In addition, you must open Xcode at least once after installing it.
Finally, you must have either macports or homebrew installed.

#### With Apple M chip

The full HEASoft install is not working at the moment (in arm64 mode), thus just compile cfitsio for the time being:
```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/cositools/cosi-setup/feature/initialsetup/setup.sh)" _ --heasoft=cfitsio
```

#### With Intel chip

Intel Mac's should work using the default one line setup.


### Windows

Please use Ubuntu 20.04 or 22.04 using the Windows subsystem for Linux (WSL). Windows 11 together with WSL2 is strongly recommended for easy GUI access.


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

This approach worked last on 5/10/2022.

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
This approach last worked on 4/25/22

Clemson's Palmetto High Performance Cluster runs centOS Linux 8, and it uses environment modules to load specific software packages. Additionally, Anaconda can be used to create and manage environments, as well as to install software packages. 


First, request an interactive node (installation can't be done on a login node):
```
qsub -I -X -l select=1:ncpus=2:mem=30gb:interconnect=1g,walltime=6:00:00
```

Next, create your conda environment (which we'll call COSITools):
```
module load git/2.27.0-gcc/8.3.1 anaconda3/2021.05-gcc/8.3.1
conda create --prefix full_install_path/COSITools
source activate full_install_path/COSITools
cd COSITools
```

Use conda to install blas and tensorflow:
```
conda install -c conda-forge blas
conda install -c conda-forge tensorflow
```

Remove anaconda module, in order to have the correct python version:
```
module rm anaconda3/2021.05-gcc/8.3.1
```

Finally, make main installation:
```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/cositools/cosi-setup/feature/initialsetup/setup.sh)
cd COSItools/cosi-setup
bash setup.sh --ignore-missing-packages --keep-environment-as-is=true --max-threads=6
```
Note: the following are listed as missing packages: glew-devel, mariadb-devel, fftw-devel, graphviz-devel, avahi-compat-libdns_sd-devel, python3-devel









