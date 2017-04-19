# nim-crypto

Travis/Build Status, Branch=*jenkins* &nbsp; [![Build Status](https://travis-ci.org/mjfh/nim-crypto.svg?branch=jenkins)](https://travis-ci.org/mjfh/nim-crypto)

# Simple Crypto Session Tool for C and NIM

This repository is an excerpt from my
[PAN scanner](//mjh-it.com/post/deadpan-tooling)
where I needed a small encryption tool for safely storing journal data.
For the [PAN scanner](//mjh-it.com/post/deadpan-tooling), encrypted
journals are produced on-site, then transported to a safe site for
decryption and further processing.

### This library supports

 * Create public/private key pairs for encrypting messages.
 * Encrypt or decrypt a data stream (aka messages).
 * Produce a linkable library to be accessed by a C program.
 * Use code as [NIM](//nim-lang.org) source code library.

### Development State

 * Supported and tested auto-configure platforms for C and NIM:
   + Linux64: native and Linux32
   + Linux64/MinGW: Win32/64
   + MinGW32/MSys, MinGW32/MSys + gcc64
 * On-the-fly NIM compilation (within repository):
   + Linux, MinGW32/MSys (will ignore gcc64)
 * Nimble (NIM package manager)
   + *TODO*
   
# Quick Compilation On Linux

 * [NIM](//nim-lang.org) version 0.16 or newer must be installed
   + Debian/Linux 9.0 (stretch) provides it with APT,
   + Ubuntu 16.04/Xenial provides NIM with APT but was too old
     at the time of writing this README file.
   + See [NIM Installation Instructions](//nim-lang.org/download.html)
     for a generic installation.
 * A decent C compiler (e.c. *gcc*) and *binutils* are needed. This is
   normally available with *NIM* because it relies on them.
 
 Download/clone *nim-crypto* and enter the root directory. Then type
 
       make -f Makefile.simple
	   
 This will produce a binary command file *src/cwrap* which can
 be run as

       ./src/cwrap
	   
It will perform some simple key generation and encryption. You are
invited to analyse the files
 
> src/Makefile.simple &nbsp; -- see the BUILD recipe<br>
> src/main.c          &nbsp; -- run code instuctions in main()<br>
> src/session.nim     &nbsp; -- link library interface<br>

For clean up run

      make -f Makefile.simple clean

# Auto-configure

This repository comes with a full auto-configure suite. It also supports
a local installation of the latest and greatest *NIM* compiler inside
the repository.

## Prerequisites

The auto-configure tools need to be bootstrapped. Once bootstrapped,
the helper tools listed below are not necessary anymore.

#### Bootstrap Helper Tools

The following tools must be installed for bootstrap:

* autoconf 2.68 or newer
* automake 1.13 or newer
* libtool 2.4 or newer
* git 2.10 or newer

#### Additional Requirements, OS Dependent

Some platforms need extra consideration. The following binaries
should be accessible from the command line:

* Command *realpath* on MSYS/MinGW (just include WinGIT binaries in PATH)
* Command *hg* on Linux (part of Mercurial, needed for NIMBLE)

#### C Complier

If a *NIM* compiler is installed already, the following tools will
be available by default.

* *Make* (e.g. GNU make)
* *Gcc* (others C compilers might do as well) and the
  compiler (e.g. *binutils*) tool-chain.
* Optionally, *MinGW* on Linux for X-compiling.

## Bootstrapping

Download/clone the *nim-crypto* repository from GitHUB and enter its root
directory. All bootstrapping commands are bundled into a single *make*
command script called *Build*. It is accessible in the root
directory. A help page is printed if called without arguments as in

      ./Build

This command script expects the *make* command installed as
*/usr/bin/make*. You need to edit the first line of this script
accordingly if this is not the case.

#### Optional: Local NIM Installation

Unless a *NIM* compiler is installed, it can be done locally within
the *nim-crypto* repository with the command:

     ./Build nim
	 
This local compiler will also be used parallel to an existing system
wide *NIM* installation.

#### Bootstrap Configure Script

Run

     ./Build config

#### Reset All to Original State

For undoing the bootstrap and resetting the repository run

     ./Build clobber

## Configuring, Compiling, and Testing

After bootstrapping the configure script run

     ./configure
	 make

for making a statically linked binary *src/cwraps* and probably a
dynamically linked one *src/cwrapd*. Just run them to find out how the
encryption works. Note that the dynamically linked binary *src/cwrapd*
is often a wrapper that calls *src/.libs/cwrapd*. Use

     ldd src/cwraps
     ldd src/.libs/cwrapd
 
to inspect the dynamic linkages. Run

     make help
	 
for other make commands. Running unit tests on the sources is done with

     make check
	 
As mention earlier, you are invited to analyse the code files
 
> src/main.c          &nbsp; -- run code instuctions in main()<br>
> src/session.nim     &nbsp; -- link library interface<br>

# Cross Compiling

Bootstrap and configuration can be done with a single *Build*
command. Currently, the following configurations have been tested
on Linux64

> i386, amd64     &nbsp; -- native variants<br>
> win32, win64    &nbsp; -- MinGW cross compiling<br>

For instance, to compile for a 32 bit Windows platform on Linux64
run

     ./Build win32
	 
or

     ./Build win32-debug
	 
This expects that the corresponding *MinGW* compiler and tool-chain are
available. The resulting binary might be tested on Linux with *wine* as
in

     wine src/cwraps.exe

# Windows Architectures

This repository compiles on MinGW32/MSys (tested on Windows 7). Optionally,
for 64bit systems a gcc64 bit compiler might be used (e.g.
[tdm64](//tdm-gcc.tdragon.net)). It will work if the command path has
precedence in the PATH environment variable. For gcc64 related build use

    ./Build mgw32

or

    ./Build mgw64

for bootstrapping (or alternatively the targets *mgw32-debug* or
*mgw64-debug*). Otherwise

    ./Build native

(or the target *native-debug*) must be used.

-- jordan
