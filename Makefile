# Target installation directory
BIN_DIR ?= $(HOME)/.local/bin

.PHONY: all install symlink uninstall

all:
	@echo "Available targets:"
	@echo "  make install   - Copies the scripts to $(BIN_DIR)/"
	@echo "  make symlink   - Creates symbolic links in $(BIN_DIR)/ pointing to this directory (good for development)"
	@echo "  make uninstall - Removes the scripts from $(BIN_DIR)/"

install:
	mkdir -p $(BIN_DIR)
	cp watch-cli $(BIN_DIR)/watch-cli
	cp fetch_metadata.py $(BIN_DIR)/fetch_metadata.py
	chmod +x $(BIN_DIR)/watch-cli
	chmod +x $(BIN_DIR)/fetch_metadata.py
	@echo "Installed successfully to $(BIN_DIR)/"

symlink:
	mkdir -p $(BIN_DIR)
	chmod +x watch-cli fetch_metadata.py
	ln -sf $(CURDIR)/watch-cli $(BIN_DIR)/watch-cli
	ln -sf $(CURDIR)/fetch_metadata.py $(BIN_DIR)/fetch_metadata.py
	@echo "Created symbolic links in $(BIN_DIR)/ pointing to $(CURDIR)"

uninstall:
	rm -f $(BIN_DIR)/watch-cli
	rm -f $(BIN_DIR)/fetch_metadata.py
	@echo "Uninstalled scripts from $(BIN_DIR)/"
