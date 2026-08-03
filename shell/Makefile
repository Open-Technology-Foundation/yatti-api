# Makefile for yatti-shell — BCS1212 compliant
# Targets: install, uninstall, setup, check, help

PREFIX   ?= /usr/local
BINDIR   ?= $(PREFIX)/bin
SBINDIR  ?= $(PREFIX)/sbin
SHAREDIR ?= $(PREFIX)/share/yatti-shell
CONFDIR  ?= $(SHAREDIR)/conf
SSHDIR   ?= /etc/ssh/sshd_config.d
DESTDIR  ?=

LAUNCHER := yatti-shell-launcher
GATE     := yatti-shell-gate
SCRIPTS  := yatti-user-add yatti-user-del yatti-user-list yatti-shell-setup
CONFIGS  := bashrc motd
SSHCONF  := 50-yatti-shell.conf

.PHONY: all install uninstall setup check help

all: help

install: $(LAUNCHER) $(GATE) $(SCRIPTS) $(CONFIGS) $(SSHCONF)
	install -d $(DESTDIR)$(BINDIR)
	install -m 755 $(LAUNCHER) $(DESTDIR)$(BINDIR)/$(LAUNCHER)
	install -m 755 $(GATE) $(DESTDIR)$(BINDIR)/$(GATE)
	install -d $(DESTDIR)$(SBINDIR)
	$(foreach s,$(SCRIPTS),install -m 755 $(s) $(DESTDIR)$(SBINDIR)/$(s);)
	install -d $(DESTDIR)$(CONFDIR)
	$(foreach c,$(CONFIGS),install -m 644 $(c) $(DESTDIR)$(CONFDIR)/$(c);)
	@test -f ../yatti-api.bash_completion && \
		install -m 644 ../yatti-api.bash_completion $(DESTDIR)$(CONFDIR)/yatti-api.bash_completion || \
		echo "Warning: yatti-api.bash_completion not found"
	install -d $(DESTDIR)$(SSHDIR)
	install -m 644 $(SSHCONF) $(DESTDIR)$(SSHDIR)/$(SSHCONF)
	@echo ""
	@echo "Installed. Run 'sudo make setup' to complete system configuration."

uninstall:
	rm -f $(DESTDIR)$(BINDIR)/$(LAUNCHER)
	rm -f $(DESTDIR)$(BINDIR)/$(GATE)
	$(foreach s,$(SCRIPTS),rm -f $(DESTDIR)$(SBINDIR)/$(s);)
	rm -f $(DESTDIR)$(SSHDIR)/$(SSHCONF)
	rm -rf $(DESTDIR)$(SHAREDIR)
	@echo "Uninstalled. Users and nftables rules not removed."
	@echo "To remove nftables: nft delete table inet yatti-shell"
	@echo "To remove users: yatti-user-del <username>"

setup:
	$(DESTDIR)$(SBINDIR)/yatti-shell-setup

check:
ifndef DESTDIR
	@command -v $(LAUNCHER) >/dev/null || { echo "$(LAUNCHER) not found in PATH"; exit 1; }
	@command -v bwrap >/dev/null || { echo "bubblewrap not found"; exit 1; }
	@command -v busybox >/dev/null || { echo "busybox not found"; exit 1; }
	@test -d $(SHAREDIR)/bin && echo "busybox symlinks OK" || echo "busybox symlinks missing — run 'make setup'"
	@test -f $(SSHDIR)/$(SSHCONF) && echo "SSH config OK" || echo "SSH config missing"
	@getent group yatti-shell >/dev/null && echo "group OK" || echo "group missing — run 'make setup'"
	@echo "Check complete."
endif

help:
	@echo "yatti-shell"
	@echo ""
	@echo "Targets:"
	@echo "  install    Install launcher, scripts, and config"
	@echo "  uninstall  Remove all installed files"
	@echo "  setup      Run one-time system setup (group, symlinks, nftables)"
	@echo "  check      Verify installation"
	@echo "  help       Show this message (default)"
	@echo ""
	@echo "Quick start:"
	@echo "  sudo make install"
	@echo "  sudo make setup"
	@echo "  sudo systemctl reload sshd"
	@echo "  sudo yatti-user-add <user> '<ssh-key>'   # API key prompted, never on argv"
	@echo ""
	@echo "Variables:"
	@echo "  PREFIX     $(PREFIX)"
	@echo "  BINDIR     $(BINDIR)"
	@echo "  SBINDIR    $(SBINDIR)"
	@echo "  SHAREDIR   $(SHAREDIR)"
	@echo "  SSHDIR     $(SSHDIR)"
	@echo "  DESTDIR    $(DESTDIR)"
