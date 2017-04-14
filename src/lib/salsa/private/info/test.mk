#! /bin/make

CLOCK = `awk '$$1=="cpu" && $$2=="MHz"{print $$4;exit}' /proc/cpuinfo`

.PHONY: help
help:
	@echo "Usage: make [option]"
	@echo
	@echo "Option: all   -- compile"
	@echo "        run   -- speed test"
	@echo "        tv    -- generate test vectors"
	@echo "        clean -- clean up"
	@echo

.PHONY: all
all: ecrypt-test

.PHONY: run tv
run: ecrypt-test
	./ecrypt-test -c $(CLOCK)

tv: ecrypt-test
	./ecrypt-test -v

ecrypt-test: merged/ecrypt-test
	rm -f $@
	ln -s merged/$@ $@

merged/ecrypt-test:
	$(MAKE) -C merged

.PHONY: clean distclean
clean distclean:
	$(MAKE) -C merged clean
	rm -f *.o */*.o *~ */*~ ecrypt-test

# End
