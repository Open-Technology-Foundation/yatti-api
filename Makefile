# Makefile for yatti-api — BCS1212 compliant
# Targets: install, uninstall, check, test, help

SCRIPT   := yatti-api
VERSION  := $(shell grep -m1 "^declare -r VERSION=" $(SCRIPT) | cut -d"'" -f2)

PREFIX   ?= /usr/local
BINDIR   ?= $(PREFIX)/bin
MANDIR   ?= $(PREFIX)/share/man/man1
COMPDIR  ?= /etc/bash_completion.d
DESTDIR  ?=

ASSETS   := $(SCRIPT).1 $(SCRIPT).bash_completion

.PHONY: all install uninstall check test lint help

all: help

install: $(SCRIPT) $(ASSETS)
	install -d $(DESTDIR)$(BINDIR)
	install -m 755 $(SCRIPT) $(DESTDIR)$(BINDIR)/$(SCRIPT)
	install -d $(DESTDIR)$(MANDIR)
	install -m 644 $(SCRIPT).1 $(DESTDIR)$(MANDIR)/$(SCRIPT).1
	install -d $(DESTDIR)$(COMPDIR)
	install -m 644 $(SCRIPT).bash_completion $(DESTDIR)$(COMPDIR)/$(SCRIPT)
ifndef DESTDIR
	-mandb -q 2>/dev/null
endif

uninstall:
	rm -f $(DESTDIR)$(BINDIR)/$(SCRIPT)
	rm -f $(DESTDIR)$(MANDIR)/$(SCRIPT).1
	rm -f $(DESTDIR)$(COMPDIR)/$(SCRIPT)
ifndef DESTDIR
	-mandb -q 2>/dev/null
endif

check:
ifndef DESTDIR
	@command -v $(SCRIPT) >/dev/null || { echo "$(SCRIPT) not found in PATH"; exit 1; }
	@$(SCRIPT) version >/dev/null
	@echo "$(SCRIPT) $(VERSION) installed OK"
	@test -f $(MANDIR)/$(SCRIPT).1 && echo "man page OK" || echo "man page missing"
	@test -f $(COMPDIR)/$(SCRIPT) && echo "completion OK" || echo "completion missing"
endif

test:
	./tests/run_tests.sh

lint:
	shellcheck $(SCRIPT)

help:
	@echo "$(SCRIPT) $(VERSION)"
	@echo ""
	@echo "Targets:"
	@echo "  install    Install script, man page, and bash completion"
	@echo "  uninstall  Remove all installed files"
	@echo "  check      Verify installation"
	@echo "  test       Run test suite"
	@echo "  lint       Run shellcheck"
	@echo "  help       Show this message (default)"
	@echo ""
	@echo "Variables:"
	@echo "  PREFIX     $(PREFIX)"
	@echo "  BINDIR     $(BINDIR)"
	@echo "  MANDIR     $(MANDIR)"
	@echo "  COMPDIR    $(COMPDIR)"
	@echo "  DESTDIR    $(DESTDIR)"
