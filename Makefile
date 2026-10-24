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
	@# files. They belong to the user who ran 'sudo', not root, whose home is
	@# looked up in the directory service (no 'eval'). Only absolute paths are
	@# removed. Skipped when DESTDIR is set (staged/packaged uninstall).
	@if [ -z "$(DESTDIR)" ]; then \
		user="$${SUDO_USER:-$$(id -un)}"; conf=; tmp=; \
		case "$$user" in \
			'' | -* | *[!A-Za-z0-9._-]*) user= ;; \
		esac; \
		if [ -z "$$user" ]; then \
			echo "Skipped the per-user cleanup: unexpected user name."; \
		elif [ -n "$$SUDO_USER" ]; then \
			home="$$(dscl . -read "/Users/$$user" NFSHomeDirectory 2>/dev/null | \
				sed -n 's/^NFSHomeDirectory: //p')"; \
			[ -n "$$home" ] && conf="$$home/.config/neofetch"; \
			tmp="$$(sudo -u "$$user" getconf DARWIN_USER_TEMP_DIR 2>/dev/null)"; \
		else \
			conf="$${XDG_CONFIG_HOME:-$$HOME/.config}/neofetch"; \
			tmp="$${TMPDIR:-$$(getconf DARWIN_USER_TEMP_DIR 2>/dev/null)}"; \
		fi; \
		case "$$conf" in \
			/?*/neofetch) [ -d "$$conf" ] && rm -rf "$$conf" && echo "Removed $$conf" ;; \
			"") ;; \
			*) echo "Skipped $$conf: not an absolute path." ;; \
		esac; \
		if [ -n "$$user" ]; then \
			for dir in "$$tmp" /tmp; do \
				[ -d "$$dir" ] || continue; \
				find "$$dir" -maxdepth 1 -name 'neofetch-layout.*' -user "$$user" \
					-print -exec rm -f {} + | sed 's/^/Removed /'; \
			done; \
		fi; \
	fi
