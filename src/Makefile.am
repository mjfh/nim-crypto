# -*- makefile-automake -*-
#
# $Id$
#
# Blame: Jordan Hrycaj <jordan@teddy-net.com>

# wrapper/c-interface for target library
NAME = session

# target library
LIBNAME = lib$(NAME)

# target demo program: default is static, Linux also supports dynlib
bin_PROGRAMS = cwraps

if !USE_MINGW
bin_PROGRAMS += cwrapd
endif

SUBDIRS      = lib
CLEANFILES   = *.exe cwrap $(NIMLIBWRAP)

if USE_DEBUG # Settings for GDB debugging session
NIMDBG    = --debuginfo --lineDir:on --embedsrc --debugger=native
AM_CFLAGS = -g
else         # Settings for optimising code
NIMDBG    = -d:release --gc:none
AM_CFLAGS = -s
endif

NIMDOCHTML = session
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
	@echo "      | docs            -- generate docs"
	@echo "      | try             -- run quick source file tests"
	@echo "      | check           -- run all tests"
	@echo

# ---------------------------------------------------------------------------
# Build library objects
# ---------------------------------------------------------------------------

# Collect non-pic/static objects in nimcache/dynlib/ sub-directory
#
CLEANFILES += $(LIBNAME).a $(NAME).lib
nimcache/static/$(NAME).h: $(NAME).nim
	@rm -f $@ nimcache/*.* nimcache/static/*
	$(NIM2A) $(NIM2CFLAGS) $(NAME).nim
	@mkdir -p               nimcache/static
	mv nimcache/*.$(OBJEXT) nimcache/static
	mv nimcache/$(NAME).h   nimcache/static
	rm -f $(LIBNAME).a $(NAME).lib

# Collect pic objects in nimcache/dynlib/ sub-directory
#
CLEANFILES += $(LIBNAME).so $(NAME).dll
nimcache/dynlib/$(NAME).h: $(NAME).nim
	@rm -f $@ nimcache/*.* nimcache/dynlib/*
	$(NIM2L) $(NIM2CFLAGS) $(NAME).nim
	@mkdir -p               nimcache/dynlib
	mv nimcache/*.$(OBJEXT) nimcache/dynlib
	mv nimcache/$(NAME).h   nimcache/dynlib
	rm -f $(LIBNAME).so $(NAME).dll


# Libtool stub, create stub.lo template
#
CLEANFILES += stub.$(EXEOBJ) stub.lo
stub.lo: stub.c
	$(LIBTOOL) --tag=CC --mode=compile $(CC) -c -o stub.$(OBJEXT) stub.c


# Kludge: emulate libtool/link behaviour without involing GCC directly
#
#         the idea is to separate pic and non-pic object files and then
#         write the extension independent .lo files
#
#         note that libtool checks for a particular header which is
#         extracted from stub.lo
#
CLEANFILES += $(LIBNAME).la
$(LIBNAME).la: nimcache/static/$(NAME).h nimcache/dynlib/$(NAME).h stub.lo
	@rm -f $@ nimcache/*.lo
	@for obj in nimcache/static/*.$(OBJEXT) ; do \
	  t=`basename $$obj .$(OBJEXT)` ;\
	  o=`basename $$obj` ;\
	  l=nimcache/$$t.lo  ;\
	  awk 'NR<6{print $0}' stub.lo|sed 's/stub/$$t/' >> $$l ;\
	  echo "pic_object='dynlib/$$o'"                 >> $$l ;\
	  echo "non_pic_object='static/$$o'"             >> $$l ;\
	done
	$(LINK) -no-undefined -rpath $(libdir) nimcache/*.lo -lm

$(LIBNAME).a: $(LIBNAME).la
	@rm -f $@
	$(LN_S) .libs/$@ .

$(LIBNAME).so: $(LIBNAME).la
	@rm -f $@
	$(LN_S) .libs/$@ .

CLEANFILES += $(NAME)-static.h
$(NAME)-static.h: $(LIBNAME).la
	@rm -f $@
	$(LN_S) nimcache/static/$(NAME).h $@

CLEANFILES += $(NAME)-dynlib.h
$(NAME)-dynlib.h: $(LIBNAME).la
	@rm -f $@
	$(LN_S) nimcache/dynlib/$(NAME).h $@

# ---------------------------------------------------------------------------
# Build target programs
# ---------------------------------------------------------------------------

main.c: $(NAME)-static.h $(NAME)-dynlib.h $(LIBNAME).a

AM_CFLAGS += -I$(NIMLIB) -Inimcache

if    !USE_MINGW
AM_LDFLAGS = -ldl
endif !USE_MINGW


cwraps_SOURCES = main.c
cwraps_CFLAGS  = $(AM_CFLAGS) -DSESSION_STATIC
cwraps_LDFLAGS =
cwraps_LDADD   = $(LIBNAME).a $(AM_LDFLAGS)

cwrapd_SOURCES = main.c
cwrapd_CFLAGS  = $(AM_CFLAGS) -DSESSION_DYNLIB
cwrapd_LDFLAGS =
cwrapd_LDADD   = -l$(NAME) $(AM_LDFLAGS)

# ---------------------------------------------------------------------------
# Helper
# ---------------------------------------------------------------------------

include ../tools/am/Makefile.nimhelper

# ---------------------------------------------------------------------------
# End
# ---------------------------------------------------------------------------
