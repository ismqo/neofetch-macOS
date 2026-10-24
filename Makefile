PREFIX = /usr/local
MANDIR = $(PREFIX)/share/man

all:
	@echo Run \'make install\' to install Neofetch.

install:
	@mkdir -p $(DESTDIR)$(PREFIX)/bin
	@mkdir -p $(DESTDIR)$(MANDIR)/man1
	@cp -p neofetch $(DESTDIR)$(PREFIX)/bin/neofetch
	@cp -p neofetch.1 $(DESTDIR)$(MANDIR)/man1
	@chmod 755 $(DESTDIR)$(PREFIX)/bin/neofetch

uninstall:
	@rm -f $(DESTDIR)$(PREFIX)/bin/neofetch $(DESTDIR)$(MANDIR)/man1/neofetch.1* || \
		{ echo "Couldn't remove the installed files; run 'sudo make uninstall'."; exit 1; }
	@echo "Uninstalled $(DESTDIR)$(PREFIX)/bin/neofetch and its man page."
	@# Per-user leftovers: the config directory (config.conf and the
	@# config.conf.bak written by --customize) and interrupted --customize temp
	@# files. They belong to the user who ran 'sudo', not root. Skipped when
	@# DESTDIR is set (staged/packaged uninstall).
	@if [ -z "$(DESTDIR)" ]; then \
		user="$${SUDO_USER:-$$(id -un)}"; \
		if [ -n "$$SUDO_USER" ]; then \
			home="$$(eval echo "~$$user")"; \
			conf="$$home/.config/neofetch"; \
			tmp="$$(sudo -u "$$user" getconf DARWIN_USER_TEMP_DIR 2>/dev/null)"; \
		else \
			conf="$${XDG_CONFIG_HOME:-$$HOME/.config}/neofetch"; \
			tmp="$${TMPDIR:-$$(getconf DARWIN_USER_TEMP_DIR 2>/dev/null)}"; \
		fi; \
		if [ -d "$$conf" ]; then rm -rf "$$conf" && echo "Removed $$conf"; fi; \
		for dir in "$$tmp" /tmp; do \
			[ -d "$$dir" ] || continue; \
			find "$$dir" -maxdepth 1 -name 'neofetch-layout.*' -user "$$user" \
				-print -exec rm -f {} + | sed 's/^/Removed /'; \
		done; \
	fi
