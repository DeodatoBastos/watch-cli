# Target installation directories
BIN_DIR ?= $(HOME)/.local/bin
CONFIG_DIR ?= $(HOME)/.config/watch-cli
DATA_DIR ?= $(HOME)/.config/watch-cli

# Helper files that go into CONFIG_DIR
HELPERS = marker.py toggle_watched.sh toogle_watched.py mark_watched.lua

.PHONY: all install symlink uninstall

all:
	@echo "Available targets:"
	@echo "  make install   - Copies the scripts to $(BIN_DIR)/ and helpers to $(CONFIG_DIR)/"
	@echo "  make symlink   - Creates symbolic links (good for development)"
	@echo "  make uninstall - Removes installed scripts and helpers"

install:
	mkdir -p $(BIN_DIR) $(CONFIG_DIR)
	cp watch-cli $(BIN_DIR)/watch-cli
	cp fetch_metadata.py $(BIN_DIR)/fetch_metadata.py
	chmod +x $(BIN_DIR)/watch-cli $(BIN_DIR)/fetch_metadata.py
	cp $(HELPERS) $(CONFIG_DIR)/
	chmod +x $(CONFIG_DIR)/toggle_watched.sh
	touch $(DATA_DIR)/watched.txt
	@echo "Installed successfully."
	@echo "  Scripts: $(BIN_DIR)/"
	@echo "  Helpers: $(CONFIG_DIR)/"

symlink:
	mkdir -p $(BIN_DIR) $(CONFIG_DIR)
	chmod +x watch-cli fetch_metadata.py toggle_watched.sh
	ln -sf $(CURDIR)/watch-cli $(BIN_DIR)/watch-cli
	ln -sf $(CURDIR)/fetch_metadata.py $(BIN_DIR)/fetch_metadata.py
	ln -sf $(CURDIR)/marker.py $(CONFIG_DIR)/marker.py
	ln -sf $(CURDIR)/toggle_watched.sh $(CONFIG_DIR)/toggle_watched.sh
	ln -sf $(CURDIR)/mark_watched.lua $(CONFIG_DIR)/mark_watched.lua
	ln -sf $(CURDIR)/toogle_watched.py $(CONFIG_DIR)/toogle_watched.py
	touch $(DATA_DIR)/watched.txt
	@echo "Created symbolic links."
	@echo "  Scripts: $(BIN_DIR)/ -> $(CURDIR)"
	@echo "  Helpers: $(CONFIG_DIR)/ -> $(CURDIR)"

uninstall:
	rm -f $(BIN_DIR)/watch-cli
	rm -f $(BIN_DIR)/fetch_metadata.py
	rm -f $(CONFIG_DIR)/marker.py
	rm -f $(CONFIG_DIR)/toggle_watched.sh
	rm -f $(CONFIG_DIR)/mark_watched.lua
	rm -f $(CONFIG_DIR)/toogle_watched.py
	@echo "Uninstalled scripts and helpers."
	@echo "Note: $(DATA_DIR)/watched.txt was preserved."
