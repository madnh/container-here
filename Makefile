#!/usr/bin/make -f

# Makefile for container-here version management

# Colors for output
RED = \033[31m
GREEN = \033[32m
YELLOW = \033[33m
BLUE = \033[34m
RESET = \033[0m

# Script file
SCRIPT_FILE = container-here

# Get current version from script
CURRENT_VERSION = $(shell grep '^SCRIPT_VERSION=' $(SCRIPT_FILE) | cut -d'"' -f2)

# Help target (default)
.PHONY: help
help:
	@echo "$(BLUE)Container-here Version Management$(RESET)"
	@echo ""
	@echo "$(YELLOW)Current version: $(CURRENT_VERSION)$(RESET)"
	@echo ""
	@echo "Available commands:"
	@echo "  $(GREEN)version$(RESET)       - Show current version"
	@echo "  $(GREEN)bump-patch$(RESET)    - Bump patch version (1.0.0 -> 1.0.1)"
	@echo "  $(GREEN)bump-minor$(RESET)    - Bump minor version (1.0.0 -> 1.1.0)"
	@echo "  $(GREEN)bump-major$(RESET)    - Bump major version (1.0.0 -> 2.0.0)"
	@echo "  $(GREEN)release$(RESET)       - Create git tag and commit for current version"
	@echo "  $(GREEN)test$(RESET)          - Run tests"
	@echo "  $(GREEN)install$(RESET)       - Install script to /usr/local/bin"
	@echo "  $(GREEN)uninstall$(RESET)     - Remove script from /usr/local/bin"
	@echo ""
	@echo "Examples:"
	@echo "  make bump-patch    # 1.0.0 -> 1.0.1"
	@echo "  make bump-minor    # 1.0.0 -> 1.1.0"
	@echo "  make bump-major    # 1.0.0 -> 2.0.0"
	@echo "  make release       # Create git tag v1.0.0"

# Show current version
.PHONY: version
version:
	@echo "$(YELLOW)Current version: $(CURRENT_VERSION)$(RESET)"

# Bump patch version (1.0.0 -> 1.0.1)
.PHONY: bump-patch
bump-patch:
	@echo "$(BLUE)Bumping patch version...$(RESET)"
	@$(MAKE) _bump TYPE=patch

# Bump minor version (1.0.0 -> 1.1.0)
.PHONY: bump-minor
bump-minor:
	@echo "$(BLUE)Bumping minor version...$(RESET)"
	@$(MAKE) _bump TYPE=minor

# Bump major version (1.0.0 -> 2.0.0)
.PHONY: bump-major
bump-major:
	@echo "$(BLUE)Bumping major version...$(RESET)"
	@$(MAKE) _bump TYPE=major

# Internal bump function
.PHONY: _bump
_bump:
	@if [ -z "$(TYPE)" ]; then \
		echo "$(RED)Error: TYPE not specified$(RESET)"; \
		exit 1; \
	fi
	@echo "$(YELLOW)Current version: $(CURRENT_VERSION)$(RESET)"
	@NEW_VERSION=$$(echo $(CURRENT_VERSION) | awk -F. -v type=$(TYPE) '{ \
		if (type == "patch") { \
			print $$1 "." $$2 "." ($$3 + 1) \
		} else if (type == "minor") { \
			print $$1 "." ($$2 + 1) ".0" \
		} else if (type == "major") { \
			print ($$1 + 1) ".0.0" \
		} \
	}'); \
	echo "$(GREEN)New version: $$NEW_VERSION$(RESET)"; \
	echo ""; \
	read -p "Continue with version bump? (y/N): " confirm; \
	if [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]; then \
		echo "$(BLUE)Updating version in $(SCRIPT_FILE)...$(RESET)"; \
		sed -i.bak "s/^SCRIPT_VERSION=\"$(CURRENT_VERSION)\"/SCRIPT_VERSION=\"$$NEW_VERSION\"/" $(SCRIPT_FILE); \
		rm -f $(SCRIPT_FILE).bak; \
		echo "$(GREEN)✓ Version updated to $$NEW_VERSION$(RESET)"; \
		echo ""; \
		echo "$(YELLOW)Next steps:$(RESET)"; \
		echo "1. Review changes: git diff"; \
		echo "2. Test the script: make test"; \
		echo "3. Commit changes: git add . && git commit -m 'bump: version $$NEW_VERSION'"; \
		echo "4. Create release: make release"; \
	else \
		echo "$(YELLOW)Version bump cancelled$(RESET)"; \
	fi

# Create git tag and commit for current version
.PHONY: release
release:
	@echo "$(BLUE)Creating release for version $(CURRENT_VERSION)...$(RESET)"
	@echo ""
	@if git status --porcelain | grep -q .; then \
		echo "$(RED)Error: Working directory is not clean$(RESET)"; \
		echo "Please commit your changes first."; \
		exit 1; \
	fi
	@if git tag -l | grep -q "^v$(CURRENT_VERSION)$$"; then \
		echo "$(RED)Error: Tag v$(CURRENT_VERSION) already exists$(RESET)"; \
		exit 1; \
	fi
	@echo "$(YELLOW)Creating git tag v$(CURRENT_VERSION)...$(RESET)"
	@git tag -a "v$(CURRENT_VERSION)" -m "Release version $(CURRENT_VERSION)"
	@echo "$(GREEN)✓ Created tag v$(CURRENT_VERSION)$(RESET)"
	@echo ""
	@echo "$(YELLOW)Next steps:$(RESET)"
	@echo "1. Push tag: git push origin v$(CURRENT_VERSION)"
	@echo "2. Push commits: git push origin main"

# Run tests
.PHONY: test
test:
	@echo "$(BLUE)Running tests...$(RESET)"
	@if [ -f "run-tests.sh" ]; then \
		./run-tests.sh; \
	else \
		echo "$(YELLOW)No test script found$(RESET)"; \
	fi

# Install script to /usr/local/bin
.PHONY: install
install:
	@echo "$(BLUE)Installing container-here to /usr/local/bin...$(RESET)"
	@if [ ! -w "/usr/local/bin" ]; then \
		echo "$(RED)Error: No write permission to /usr/local/bin$(RESET)"; \
		echo "Try: sudo make install"; \
		exit 1; \
	fi
	@cp $(SCRIPT_FILE) /usr/local/bin/container-here
	@chmod +x /usr/local/bin/container-here
	@echo "$(GREEN)✓ Installed container-here to /usr/local/bin$(RESET)"

# Remove script from /usr/local/bin
.PHONY: uninstall
uninstall:
	@echo "$(BLUE)Removing container-here from /usr/local/bin...$(RESET)"
	@if [ ! -w "/usr/local/bin" ]; then \
		echo "$(RED)Error: No write permission to /usr/local/bin$(RESET)"; \
		echo "Try: sudo make uninstall"; \
		exit 1; \
	fi
	@rm -f /usr/local/bin/container-here
	@echo "$(GREEN)✓ Removed container-here from /usr/local/bin$(RESET)"

# Validate version format
.PHONY: validate-version
validate-version:
	@if ! echo "$(CURRENT_VERSION)" | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$$' > /dev/null; then \
		echo "$(RED)Error: Invalid version format: $(CURRENT_VERSION)$(RESET)"; \
		echo "Version must be in format: MAJOR.MINOR.PATCH"; \
		exit 1; \
	fi
	@echo "$(GREEN)✓ Version format is valid: $(CURRENT_VERSION)$(RESET)"

# Show git status and version info
.PHONY: status
status:
	@echo "$(BLUE)Container-here Status$(RESET)"
	@echo ""
	@echo "$(YELLOW)Version: $(CURRENT_VERSION)$(RESET)"
	@echo "$(YELLOW)Git status:$(RESET)"
	@git status --short
	@echo ""
	@echo "$(YELLOW)Recent tags:$(RESET)"
	@git tag -l | tail -5 | sed 's/^/  /'
	@echo ""
	@echo "$(YELLOW)Uncommitted changes in $(SCRIPT_FILE):$(RESET)"
	@if git diff --name-only | grep -q "^$(SCRIPT_FILE)$$"; then \
		git diff $(SCRIPT_FILE) | head -10; \
	else \
		echo "  No changes"; \
	fi

# Clean up backup files
.PHONY: clean
clean:
	@echo "$(BLUE)Cleaning up...$(RESET)"
	@rm -f $(SCRIPT_FILE).bak
	@rm -f .container-here.conf
	@echo "$(GREEN)✓ Cleaned up backup files$(RESET)"

# Show current version in script and git
.PHONY: version-info
version-info:
	@echo "$(BLUE)Version Information$(RESET)"
	@echo ""
	@echo "$(YELLOW)Script version:$(RESET) $(CURRENT_VERSION)"
	@echo "$(YELLOW)Latest git tag:$(RESET) $$(git describe --tags --abbrev=0 2>/dev/null || echo 'No tags found')"
	@echo "$(YELLOW)Git commit:$(RESET) $$(git rev-parse --short HEAD 2>/dev/null || echo 'Not a git repo')"
	@echo "$(YELLOW)Git branch:$(RESET) $$(git branch --show-current 2>/dev/null || echo 'Not a git repo')"