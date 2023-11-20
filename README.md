# Setting up the COSItools

This repository contains the tools to setup a fully working COSItools development and end-user environment.
You need a 64-bit operating system to (completely) install and run the COSItools. 
The preferred operating systems are the latest LTS versions of Ubuntu and the latest two versions of macOS.

However, **whenever a new OS is released, please wait several months before you install it**.
This give us, and all the developers of the packages on which the COSItools are based, some time for testing and debugging.

## Quick guide

You can setup the environment by simply executing this command:
```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/cositools/cosi-setup/main/setup.sh)"
```
This script will likely run until a point where it tells you to install a few packages.
After you do that, just start the script again, and it will complete the setup.

A log file is stored in $COSITOOLS/cosi-setup/log. Please attach that to any bug report.

If the installation fails or you have an unsupported system, please try either the docker container, 
https://github.com/cositools/cosi-docker, 
or the singularity container 
https://github.com/cositools/cosi-singularity

## Advanced guide

### Accessing the options

The setup script has serveral advanced options accessible. Using the above one-line install script, you can add options the following way (pay attention to the underscore):

```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/cositools/cosi-setup/main/setup.sh)" _ --options --here
```

Alternatively, do the following:
```
mkdir COSItools
cd COSItools
git clone https://github.com/cositools/cosi-setup cosi-setup
cd cosi-setup
git checkout main
bash setup.sh --options --here
```

### Options

The following options are a copy-and-paste from ```bash setup.sh --help```:

```
--cositoolspath=[path to COSItools - default: "COSItools"]
    This is the path to where the COSItools will be installed. If the path exists, we will try to update them.

--branch=[name of a git branch - default: main]
    Choose a specific branch of the COSItools git repositories.
    If the option is not given the latest release will be used.
    If the branch does not exist for all repositories use the main/master branch.

--pull-behavior-git=[stash (default), merge]
     Choose how to handle changes in git repositories:
     "stash": stash the changes and pull the latest version
     "merge": merge the changes -- the script will stop on error
     "no": Do not change existing repositories in any way (no pull, no branch switch, etc.)

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
    --root=              Download and install the latest compatible version
    --root=[version]     Download the given ROOT version. Format must be "x.yy"
    --root=[GitHub tag]  Download the ROOT version with the given tag. Format must be "vx-yy-zz", "vx-yy-zz-patches", or "master"
    --root=[path]        Use the version of ROOT found in the path. The path cannot be of the format "x.yy", "vx-yy-zz", "vx-yy-zz-patches", or "master"

--geant=[options: empty (default), path to existing GEANT4 installation]
    --geant=           Download and install the latest compatible version.
    --geant=[path]     Use the version of Geant4 found in the path. If it is not compatible, the script will stop with an error.

--heasoft=[options: empty or heasoft, off, cfitsio (default), path to existing HEASoft installation]
    --heasoft=         Download and install the latest compatible version.
    --heasoft=heasoft  Download and install the latest compatible version.
    --heasoft=cfitsio  Download and install the latest cfitsio version.
    --heasoft=off      Do not install HEASoft.
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

We strongly recommend to stick with long(ish)-term support versions such as Ubuntu LTE. 

#### Ubuntu & derivatives

Version 20.04 and 22.04 should work with the default one-line install script. We have no indications sofar that any distributions derived from Ubuntu are not working. We only test long-term support (LTE) versions.

#### Redhat derivatives

##### Fedora

The one-line install should work. Latest tested version is 38. Fedora tends to be close to the cutting edge. Thus, consider to stay one version behind the latest version.

##### Centos Stream

The one-line install should work. Latest tested version is 9.

##### Scientific Linux and Centos 8 or earlier

Not supported. These versions are too old to run COSItools. Please use a container.

#### SUSE 

##### Leap

The one-line install should work. Latest tested version is 15.4.

##### Tumbleweed

Tumbleweed is a cutting edge rolling release thus not recommended for COSItools, as it might break at any moment in time. 
Sometimes it works, sometimes not.

##### SLES

The SUSE Linux Enterprise Server Distribution is a hit and miss, and depends on your actual server environment.

#### Debian

The one-line install should work. Latest tested version is 12.

#### Other Linux systems

No other systems have been been tested yet or are supported. Especially avoid any cutting edge rolling releases such as Arch (it sometimes compiles there, sometimes not), Gentoo, etc.

### macOS 

Only macOS Monterey and Ventura are supported. 

#### Xcode

Xcode must be installed from the App store. Afterwards install the command line tools via:
```
xcode-select --install
```
In addition, you must open Xcode at least once after installing it.

#### macports, homebrew & conda

You need to have either homebrew (preferred) or macports installed. Conda is not supported at the moment. In addition, you can only have *one* of the three (homebrew, macports, conda) active. If you have more than one installed, then please comment the others out in your .zprofile file (or .bash_profile or whatever you use) for the installation. You can try to comment them in again after the installation and see if everything works (depending on the complexity of your overall setup, it might or might not work).

Please keep in mind that sometimes homebrew or macports need to compile packages. This can take a long time. For example, setting up all macports package for the first time with macOS Ventura took several hours on an M1 CPU.

#### Installation (Apple & Intel silicon)

The installation should work using the default one line setup.

The following error may occur even if the XCode license has been accepted due to a mismatch between the installed version of XCode and the version of the cached license agreement:
```
Error: You have not accepted the XCode license!
    Either open XCode to accept the license, or run:
    sudo xcodebuild -license accept
```
If this occurs, the cached license can be cleared by deleting the XCode plist file located at /Library/Preferences/com.apple.dt.Xcode.plist. Once the file has been removed, accept the license again to resolve the mismatch.


### Windows

Please use Ubuntu 20.04 or 22.04 using the Windows subsystem for Linux (WSL). Windows 11 together with WSL2 is strongly recommended for easy GUI access. There is a known bug in WSL2 which makes the MEGAlib/ROOT menu bars show up at random places on the screen. That'a a WSL2 / ROOT bug.


### Clusters and supercomputers

Since the COSItools might be installed on a few systems where the user has not full control over the setup, and cannot install individual packages, below are a few examples on how to handle these cases.

#### UC Berkeley's savio cluster

##### Using a singularity container

As of 5/8/2023 the system setup is too old to run COSItools. However, the savio cluster supports running singularity containers.
As consequence, follow the instructions given at https://github.com/cositools/cosi-singularity to setup a singularity container directly on savio -- copying an existing container will not work since the singularity version on Savio is too old.

##### Compiling everything

This approach worked last on 4/20/2022 but not as of 5/8/2023

The Savio cluster uses scientific linux as well as "environment modules" to load specific software packages. In order, to set up the COSItools, you need to load the following modules:

```
module load gcc/6.3.0 cmake/3.22.0 git/2.11.1 blas/3.8.0 ml/tensorflow/2.5.0-py37
```

Then launch the script with the following additional option:
```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/cositools/cosi-setup/main/setup.sh)" _ --ignore-missing-packages --keep-environment-as-is=true --max-threads=6
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
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/cositools/cosi-setup/main/setup.sh)" _ --ignore-missing-packages --keep-environment-as-is=true --heasoft=off --max-threads=6
```
It ignores not installed packages since the setup script cannot find packages installed via the "environment modules", it keeps all environment search paths intact, does not install HEASoft since the compilation crashes on cori, and it limits the number of threads to 6 otherwise the cori admins will complain that you use too many resources on the login nodes.


#### Clemson's Palmetto cluster

This approach last worked on 4/25/22.

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
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/cositools/cosi-setup/main/setup.sh)
cd COSItools/cosi-setup
bash setup.sh --ignore-missing-packages --keep-environment-as-is=true --max-threads=6
```
Note: the following are listed as missing packages: glew-devel, mariadb-devel, fftw-devel, graphviz-devel, avahi-compat-libdns_sd-devel, python3-devel


## Frequently encountered issues

### During ROOT build: "read jobs pipe: Resource temporarily unavailable."

The built of ROOT fails with something similar like this (instead of LZMA, it couls be FREETYPE, or TBB, or ...):
```
CMake Error at /Users/andreas/Documents/Science/Software/COSItools/external/root_v6.28.08/root_v6.28.08-build/LZMA-prefix/src/LZMA-stamp/LZMA-build-Release.cmake:49 (message):
  Command failed: 2

   '/Applications/Xcode.app/Contents/Developer/usr/bin/make'

  See also

    /Users/andreas/Documents/Science/Software/COSItools/external/root_v6.28.08/root_v6.28.08-build/LZMA-prefix/src/LZMA-stamp/LZMA-build-*.log
```
If you open the log file you see:
```
read jobs pipe: Resource temporarily unavailable
```
The origin of this issue is not entirely clear, but it pops up from time to time on various systems. Reducing the number of threads to compile ROOR usually helps. You do this via the "--max-threads" command line option of the setup script. In the worst case you have to go down to one single thread, which will make the compile take a long time.



