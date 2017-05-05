# -*- makefile-automake -*-
#
# $Id$
#
# Blame: Jordan Hrycaj <jordan@teddy-net.com>

SUBDIRS =
CLEANFILES = *.exe msrc

NIMDOCHTML =
NIMNOCHECK =
NIM2DFLAGS =

all-local:: nim_paths_inc.nim
prepare:: nim_paths_inc.nim

nim_paths_inc.nim: $(BOOT_DIR)/nim-paths.sh
	@rm -f $@
	@echo Generating $@
	@$(SHELL) $(BOOT_DIR)/nim-paths.sh >> $@

include ../../../tools/am/Makefile.nimhelper

# End
