.PHONY: help install check update backup security compliance weekly-os lint syntax-check clean

# Color output
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[0;33m
NC := \033[0m # No Color

help: ## Show this help message
	@echo "$(BLUE)Ansible Workstation Management$(NC)"
	@echo ""
	@echo "$(GREEN)Available targets:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(GREEN)Usage examples:$(NC)"
	@echo "  make install         # First-time setup"
	@echo "  make weekly-os       # Weekly maintenance"
	@echo "  make check           # Dry-run before executing"
	@echo "  make update          # Update packages only"
	@echo ""

install: ## Install Ansible and dependencies
	@echo "$(BLUE)Installing dependencies...$(NC)"
	@command -v ansible >/dev/null 2>&1 || { \
		echo "$(YELLOW)Ansible not found. Installing via Homebrew...$(NC)"; \
		brew install ansible; \
	}
	@echo "$(BLUE)Installing Ansible collections...$(NC)"
	ansible-galaxy collection install -r requirements.yml
	@echo "$(GREEN)✓ Installation complete$(NC)"

check: ## Run syntax check on all playbooks
	@echo "$(BLUE)Running syntax checks...$(NC)"
	@ansible-playbook --syntax-check playbooks/*.yml
	@echo "$(GREEN)✓ Syntax check passed$(NC)"

lint: ## Run ansible-lint on all playbooks
	@echo "$(BLUE)Running ansible-lint...$(NC)"
	@command -v ansible-lint >/dev/null 2>&1 || { \
		echo "$(YELLOW)ansible-lint not found. Installing...$(NC)"; \
		pip3 install ansible-lint; \
	}
	@ansible-lint playbooks/ || true
	@echo "$(GREEN)✓ Lint check complete$(NC)"

update: ## Update system packages only
	@echo "$(BLUE)Running system update...$(NC)"
	ansible-playbook playbooks/update.yml

backup: ## Run backup only
	@echo "$(BLUE)Running backup...$(NC)"
	ansible-playbook playbooks/backup.yml

security: ## Apply security hardening only
	@echo "$(BLUE)Applying security hardening...$(NC)"
	ansible-playbook playbooks/security.yml --ask-become-pass

compliance: ## Run compliance check only
	@echo "$(BLUE)Running compliance check...$(NC)"
	@echo "$(YELLOW)Note: Some checks may require sudo password$(NC)"
	ansible-playbook playbooks/compliance.yml --ask-become-pass

weekly-os: ## Run weekly OS maintenance
	@echo "$(BLUE)Running weekly OS maintenance...$(NC)"
	ansible-playbook playbooks/weekly-os.yml --ask-become-pass

full: ## Run all roles (complete management)
	@echo "$(BLUE)Running complete workstation management...$(NC)"
	ansible-playbook playbooks/full.yml --ask-become-pass

dry-run: ## Dry run of playbooks/full.yml (check mode)
	@echo "$(BLUE)Running dry-run (check mode)...$(NC)"
	@echo "$(YELLOW)Note: Some security tasks may require sudo password$(NC)"
	ansible-playbook playbooks/full.yml --check --diff --ask-become-pass

dry-run-weekly: ## Dry run of weekly-os.yml (check mode)
	@echo "$(BLUE)Running weekly-os dry-run (check mode)...$(NC)"
	@echo "$(YELLOW)Note: Some security tasks may require sudo password$(NC)"
	ansible-playbook playbooks/weekly-os.yml --check --diff --ask-become-pass

list-tags: ## List all available tags
	@echo "$(BLUE)Available tags:$(NC)"
	@ansible-playbook playbooks/full.yml --list-tags

list-tasks: ## List all tasks in playbooks/full.yml
	@echo "$(BLUE)Tasks in playbooks/full.yml:$(NC)"
	@ansible-playbook playbooks/full.yml --list-tasks

clean: ## Clean up cache and logs
	@echo "$(BLUE)Cleaning up...$(NC)"
	rm -rf .ansible_cache/
	rm -f ansible.log
	rm -f *.retry
	@echo "$(GREEN)✓ Cleanup complete$(NC)"

inventory-graph: ## Show inventory structure
	@echo "$(BLUE)Inventory structure:$(NC)"
	@ansible-inventory --graph

facts: ## Gather and display system facts
	@echo "$(BLUE)Gathering system facts...$(NC)"
	@ansible localhost -m setup | head -100

version: ## Show Ansible version
	@echo "$(BLUE)Ansible version:$(NC)"
	@ansible --version

test-connection: ## Test connection to all hosts
	@echo "$(BLUE)Testing connection to all hosts...$(NC)"
	@ansible all -m ping

# Development targets
dev-check: check lint ## Run all checks (syntax + lint)

dev-setup: install ## Setup development environment
	@echo "$(BLUE)Setting up development environment...$(NC)"
	@command -v pre-commit >/dev/null 2>&1 || pip3 install pre-commit
	@echo "$(GREEN)✓ Development setup complete$(NC)"
