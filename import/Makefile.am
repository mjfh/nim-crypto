# -*- makefile-automake -*-
#
# $Id: a31393d760ce440365bef6c3b677b1bc03a77c29 $
#
# Blame: Jordan Hrycaj <jordan@teddy-net.com>

# NIMIMPORT:     list of NIM modules to import
# NIMSRC_SUBMOD: list of direct sub-modules in src/lib

# usage: $(NIMBLE_PATH) <package>
NIMBLEPATH = $(NIMBLE) --nimbleDir:$(CONF_DIR) path

# ---------------------------------------------------------------------------
# Settings
# ---------------------------------------------------------------------------

NIMBLE_IMPORT   = $(NIMBLE) --nimbleDir:$(CONF_DIR) --accept
NIMIMPORT_STAMP = $(CONF_DIR)/nim-imports.stamp
NIM_CONF        = $(CONF_DIR)/nim.cfg
SRC_CONF        = $(SRC_DIR)/nim.cfg
CLEANFILES      = $(NIMIMPORT_STAMP) $(NIM_CONF) $(SRC_CONF)

NIM_INFO        = is effective only on the command line (as of NIM 0.15.3)

.PHONY: prepare
all-local:: prepare
check-local:: prepare

prepare:: $(SRC_CONF)

# ---------------------------------------------------------------------------
# External library imports
# ---------------------------------------------------------------------------

.PHONY: update

update::
	rm -f $(NIMIMPORT_STAMP) $(SRC_CONF)

update:: $(SRC_CONF)


$(NIMIMPORT_STAMP):
	@for m in $(NIMIMPORT); do \
	  (set -x;$(NIMBLE_IMPORT) install $$m) ;\
	done
	touch $@

# .PRECIOUS: $(NIM_CONF) $(SRC_CONF)
$(SRC_CONF): $(NIM_CONF)
	rm -f $@
	cp $(NIM_CONF) $@

$(NIM_CONF): $(NIMIMPORT_STAMP) $(CONF_DIR)/config.h Makefile
	rm -f $@
	@echo "# generated: `date`"                     >> $@

	@echo                                           >> $@
	@echo '# Nimble import => global paths'         >> $@
	@for m in $(NIMIMPORT); do \
	  echo "*** Nimble import: $$m" ; \
	  echo "path=\"`$(NIMBLEPATH) $$m|sed 's!\\\\!/!g'`\"" >> $@; \
	 done

	@echo                                           >> $@
	@echo '# GIT modules => global paths'           >> $@
	@for m in $(NIMSRC_SUBMOD); do \
	  echo "*** Nim sub-module: `expr $$m : '\([^/]*\)'`" ; \
	  echo "path=\"$(SRCLIB_DIR)/$$m\""             >> $@; \
	 done

	@echo                                           >> $@
	@echo '# global options'                        >> $@
	@echo 'path = "$(SRC_DIR)"'                     >> $@
	@echo 'path = "$(SRCLIB_DIR)"'                  >> $@
	@echo "hints = off"                             >> $@
	@echo "app = console"                           >> $@

#	debugging support
if USE_DEBUG
	@echo "debugger = native"                       >> $@
	@echo "debuginfo"                               >> $@
	@echo "lineDir = on"                            >> $@
	@echo "embedsrc"                                >> $@
else
	@echo '# Note: d:release $(NIM_INFO)'           >> $@
	@echo "deadCodeElim = on"                       >> $@
	@echo "opt = speed"                             >> $@
	@echo "assertions = off"                        >> $@
endif


if CROSS_COMPILING
if USE_MINGW64
	@echo
	@echo "*** Configuring for Windows/amd64 crosss compiling"
	@echo
	@echo                                           >> $@
	@echo '@if windows:'                            >> $@
	@echo '  # Note: os:windows $(NIM_INFO)'        >> $@
	@echo '  cpu = amd64'                           >> $@
	@echo '  amd64.windows.gcc.path = "/usr/bin"'   >> $@
	@echo '  amd64.windows.gcc.exe = "$(CC)"'       >> $@
	@echo '  amd64.windows.gcc.linkerexe = "$(CC)"' >> $@
	@echo '  define = windows'                      >> $@
	@echo '@end'                                    >> $@
endif USE_MINGW64
endif CROSS_COMPILING


if CROSS_COMPILING
if USE_MINGW32
	@echo
	@echo "*** Configuring for Windows/i386 crosss compiling"
	@echo
	@echo                                           >> $@
	@echo '@if windows:'                            >> $@
	@echo '  # Note: os:windows $(NIM_INFO)'        >> $@
	@echo '  cpu = i386'                            >> $@
	@echo '  i386.windows.gcc.path = "/usr/bin"'    >> $@
	@echo '  i386.windows.gcc.exe = "$(CC)"'        >> $@
	@echo '  i386.windows.gcc.linkerexe = "$(CC)"'  >> $@
	@echo '@end'                                    >> $@
endif USE_MINGW32
endif CROSS_COMPILING


if !CROSS_COMPILING
if  USE_MINGW64
if  USE_CPU64
	@echo
	@echo "*** Configuring for amd64 native Windows/MinGW 6bit"
	@echo
	@echo                                           >> $@
	@echo '@if windows:'                            >> $@
	@echo '  # Note: os:windows $(NIM_INFO)'        >> $@
	@echo '  cpu = amd64'                           >> $@
	@echo '  amd64.windows.gcc.exe = "$(CC)"'       >> $@
	@echo '  amd64.windows.gcc.linkerexe = "$(CC)"' >> $@
	@echo '  passC = "$(CFLAGS_CC_M64)"'            >> $@
	@echo '  passL = "$(CFLAGS_CC_M64)"'            >> $@
	@echo '  define = windows'                      >> $@
	@echo '@end'                                    >> $@
endif  USE_CPU64
endif  USE_MINGW64
endif !CROSS_COMPILING


if !CROSS_COMPILING
if  USE_MINGW64
if  USE_CPU32
	@echo
	@echo "*** Configuring for i386 on Windows/MinGW 64bit"
	@echo
	@echo                                           >> $@
	@echo '@if windows:'                            >> $@
	@echo '  # Note: os:windows $(NIM_INFO)'        >> $@
	@echo '  cpu = i386'                            >> $@
	@echo '  amd64.windows.gcc.exe = "$(CC)"'       >> $@
	@echo '  amd64.windows.gcc.linkerexe = "$(CC)"' >> $@
	@echo '  passC = "$(CFLAGS_CC_M32)"'            >> $@
	@echo '  passL = "$(CFLAGS_CC_M32)"'            >> $@
	@echo '  define = windows'                      >> $@
	@echo '@end'                                    >> $@
endif  USE_CPU32
endif  USE_MINGW64
endif !CROSS_COMPILING


if !CROSS_COMPILING
if !USE_MINGW
if  USE_CPU32
	@echo
	@echo "*** Configuring for Posix/i386"
	@echo
	@echo                                           >> $@
	@echo '@if i386:'                               >> $@
	@echo '  cpu = i386'                            >> $@
	@echo '  passC = "$(CFLAGS_CC_M32)"'            >> $@
	@echo '  passL = "$(CFLAGS_CC_M32)"'            >> $@
	@echo '@end'                                    >> $@
endif  USE_CPU32
endif !USE_MINGW
endif !CROSS_COMPILING


if !CROSS_COMPILING
if !USE_MINGW
if  USE_CPU64
	@echo
	@echo "*** Configuring for Posix/amd64"
	@echo
	@echo                                           >> $@
	@echo '@if amd64:'                              >> $@
	@echo '  cpu = amd64'                           >> $@
	@echo '  passC = "$(CFLAGS_CC_M64)"'            >> $@
	@echo '  passL = "$(CFLAGS_CC_M64)"'            >> $@
	@echo '@end'                                    >> $@
endif  USE_CPU64
endif !USE_MINGW
endif !CROSS_COMPILING

	@echo                                           >> $@
	@echo '# end'                                   >> $@



distclean-local::
	rm -f $(NIMIMPORT_STAMP)
	@for m in $(NIMIMPORT); do \
	  p=`$(NIMBLE_IMPORT) path $$m` ; \
	  case "$$p" in $(CONF_DIR)/*)(set -x;rm -rf $$p);esac; \
	done
	rmdir $(CONF_DIR)/* 2>/dev/null ||:

# ---------------------------------------------------------------------------
# End
# ---------------------------------------------------------------------------
