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
if USE_MINGW
LINK_LIBS  = -lm
LINK_FLAGS = -no-undefined
else
LINK_LIBS  = -lm -ldl
endif
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
	$(LINK) $(LINK_FLAGS) -rpath $(libdir) nimcache/*.lo $(LINK_LIBS)

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

cwrap_SOURCES = main.c
cwrap_LDFLAGS =
cwrap_CFLAGS  = -I$(NIMLIB) -Inimcache
cwrap_LDADD   =

main.c: $(main_c_deps)

if USE_MINGW
main_c_deps   = $(NAME)-static.h $(LIBNAME).a
cwrap_CFLAGS += -DSESSION_STATIC
cwrap_LDADD  += $(LIBNAME).a
else
main_c_deps   = $(NAME)-dynlib.h
cwrap_CFLAGS += -DSESSION_DYNLIB
cwrap_LDADD  += -l$(NAME)
endif

if USE_DEBUG
cwrap_CFLAGS += -g
else
cwrap_CFLAGS += -O2 -s
endif

# ---------------------------------------------------------------------------
# Helper
# ---------------------------------------------------------------------------

include ../tools/am/Makefile.nimhelper

# ---------------------------------------------------------------------------
# End
# ---------------------------------------------------------------------------
