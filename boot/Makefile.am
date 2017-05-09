# -*- makefile-automake -*-
#
# $Id$
#
# Blame: Jordan Hrycaj <jordan@teddy-net.com>

# ---------------------------------------------------------------------------
# Settings
# ---------------------------------------------------------------------------

NIMBLE_IMPORT   = $(NIMBLE) --nimbleDir:$(CONF_DIR) --accept
NIMIMPORT_STAMP = $(CONF_DIR)/nim-imports.stamp
CLEANFILES      = $(NIMIMPORT_STAMP)

all-local:: prepare
check-local:: prepare

prepare:: nim-cfg.sh nim-check.sh nim-compile.sh nim-paths.sh

# Kludge - first subsystem to be called
prepare::
	$(MAKE) -C $(SRC_DIR)         $@
	$(MAKE) -C $(SRCLIB_DIR)/misc $@

# ---------------------------------------------------------------------------
# External library imports
# ---------------------------------------------------------------------------

.PHONY: update

update::
	rm -f $(NIMIMPORT_STAMP)

$(NIMIMPORT_STAMP):
	@for m in $(NIMIMPORT); do \
	  (set -x;$(NIMBLE_IMPORT) install $$m) ;\
	done
	touch $@

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
