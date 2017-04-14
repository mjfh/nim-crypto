# -*- makefile-automake -*-
#
# $Id: ca75d92dd4048d9c4a0b0abd521f736195ee5f15 $
#
# Blame: Jordan Hrycaj <jordan@teddy-net.com>

# wrapper/c-interface for target library
NAME = session

# target library
LIBNAME = lib$(NAME)

# target demo program
bin_PROGRAMS = cwrap

SUBDIRS      = lib
CLEANFILES   = *.exe *.html $(NIMLIBWRAP)

if USE_DEBUG
# Settings for GDB debugging session
NIMDBG = --debuginfo --lineDir:on --embedsrc --debugger=native
else
# Settings for optimising code
NIMDBG = -d:release --gc:none
endif

NIM2CFLAGS =
NIM2XFLAGS =
NIMNOCHECK =

if    USE_MINGW
NIM2CFLAGS += -d:windows --os:windows
endif USE_MINGW

if    USE_CPU64
NIM2CFLAGS += -d:amd64
endif USE_CPU64

if    USE_CPU32
NIM2CFLAGS += -d:i386
endif USE_CPU32

all-local::

.PHONY: help
help:
	@echo
	@echo "$(MAKE) [target]"
	@echo
	@echo "target: all [dist]clean -- standard targets dist/clean"
	@echo "      | force           -- force recompiling main target"
	@echo "      | docs            -- generate docs"
	@echo "      | try             -- run quick source file tests"
	@echo "      | check           -- run all tests"
	@echo

# ---------------------------------------------------------------------------
# Libtool stub, pulls in command variables COMPILE and LTCOMPILE
# ---------------------------------------------------------------------------

lib_LTLIBRARIES = libstub.la
libstub_la_SOURCES = stub.c

# ---------------------------------------------------------------------------
# Build library objects
# ---------------------------------------------------------------------------

all-local:: $(LIBNAME).la

CLEANFILES  += $(LIBNAME).so $(LIBNAME).a $(LIBNAME).la


# Collect non-pic/ststic objects in nimcache/dynlib/ sub-directory
#
.PHONY: static
static: $(NAME).nim
	@rm -f $@ nimcache/*.* nimcache/static/*
	$(NIM2A) $(NIM2CFLAGS) $(NAME).nim
	@mkdir -p               nimcache/static
	mv nimcache/*.$(OBJEXT) nimcache/static


# Collect pic objects in nimcache/dynlib/ sub-directory
#
.PHONY: dynlib
dynlib: $(NAME).nim
	@rm -f $@ nimcache/*.* nimcache/dynlib/*
	$(NIM2L) $(NIM2CFLAGS) $(NAME).nim
	@mkdir -p               nimcache/dynlib
	mv nimcache/*.$(OBJEXT) nimcache/dynlib

# Kludge: emulate libtool/link behaviour without involing GCC directly
#
#         the idea is to separate pic and non-pic object files and then
#         write the extension independent .lo files
#
#         note that libtool checks for a particular header which is
#         extracted from stub.lo
#
$(LIBNAME).la: static dynlib stub.lo
	@rm -f $@ nimcache/*.lo
	for obj in nimcache/static/* ; do \
	  t=`basename $$obj .$(OBJEXT)` ;\
	  o=`basename $$obj` ;\
	  l=nimcache/$$t.lo  ;\
	  awk 'NR<6{print $0}' stub.lo|sed 's/stub/$$t/' >> $$l ;\
	  echo "pic_object='dynlib/$$o'"                 >> $$l ;\
	  echo "non_pic_object='static/$$o'"             >> $$l ;\
	done
	$(LINK) -rpath $(libdir) nimcache/*.lo -ldl -lm

clean-local::
	rm -f nimcache/static/* nimcache/dynlib/*
	rmdir nimcache/static   nimcache/dynlib 2>/dev/null ||:

# ---------------------------------------------------------------------------
# Build target programs
# ---------------------------------------------------------------------------

cwrap_SOURCES      = main.c
cwrap_CFLAGS       = -Inimcache -I$(NIMLIB)
cwrap_LDFLAGS      =
cwrap_LDADD        = -l$(NAME)
cwrap_DEPENDENCIES =

main.c: nimcache/$(NAME).h
nimcache/$(NAME).h: $(LIBNAME).la

if USE_DEBUG
cwrap_CFLAGS += -g
else
cwrap_CFLAGS += -O2 -s
endif

# ---------------------------------------------------------------------------
# Helper
# ---------------------------------------------------------------------------

include ../tools/am/Makefile.nimhelper

# End
