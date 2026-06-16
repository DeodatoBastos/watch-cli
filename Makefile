# Target installation directories
BIN_DIR ?= $(HOME)/.local/bin
CONFIG_DIR ?= $(HOME)/.config/watch-cli

# Helper files installed to CONFIG_DIR
HELPERS = marker.py toggle_watched.py mark_watched.lua \
          preview.sh preview_season.sh preview_episode.sh render_poster.sh

.PHONY: all install symlink uninstall test

all:
	@echo "Available targets:"
	@echo "  make install   - Copies scripts to $(BIN_DIR)/ and helpers to $(CONFIG_DIR)/"
	@echo "  make symlink   - Creates symbolic links (good for development)"
	@echo "  make uninstall - Removes installed scripts and helpers"
	@echo "  make test      - Runs the unit tests"

test:
	@python3 test/test_watched.py

install:
	mkdir -p $(BIN_DIR) $(CONFIG_DIR)
	cp src/watch-cli $(BIN_DIR)/watch-cli
	cp src/fetch_metadata.py $(BIN_DIR)/fetch_metadata.py
	chmod +x $(BIN_DIR)/watch-cli $(BIN_DIR)/fetch_metadata.py
	@for f in $(HELPERS); do cp src/$$f $(CONFIG_DIR)/$$f; done
	chmod +x $(CONFIG_DIR)/preview.sh $(CONFIG_DIR)/preview_season.sh $(CONFIG_DIR)/preview_episode.sh
	touch $(CONFIG_DIR)/watched.txt
	@echo "Installed successfully."
	@echo "  Scripts: $(BIN_DIR)/"
	@echo "  Helpers: $(CONFIG_DIR)/"

symlink:
	mkdir -p $(BIN_DIR) $(CONFIG_DIR)
	chmod +x src/watch-cli src/fetch_metadata.py src/preview.sh src/preview_season.sh src/preview_episode.sh
	ln -sf $(CURDIR)/src/watch-cli $(BIN_DIR)/watch-cli
	ln -sf $(CURDIR)/src/fetch_metadata.py $(BIN_DIR)/fetch_metadata.py
	@for f in $(HELPERS); do ln -sf $(CURDIR)/src/$$f $(CONFIG_DIR)/$$f; done
	touch $(CONFIG_DIR)/watched.txt
	@echo "Created symbolic links."
	@echo "  Scripts: $(BIN_DIR)/ -> $(CURDIR)/src"
	@echo "  Helpers: $(CONFIG_DIR)/ -> $(CURDIR)/src"

uninstall:
	rm -f $(BIN_DIR)/watch-cli $(BIN_DIR)/fetch_metadata.py
	@for f in $(HELPERS); do rm -f $(CONFIG_DIR)/$$f; done
	@echo "Uninstalled scripts and helpers."
	@echo "Note: $(CONFIG_DIR)/watched.txt was preserved."
