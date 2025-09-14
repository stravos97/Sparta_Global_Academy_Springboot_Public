# ==============================================================================
# Sparta Global Academy - Enhanced Makefile
# ==============================================================================

# Variables
SHELL := /bin/bash
.DEFAULT_GOAL := help

# Docker Configuration
REGISTRY ?= ghcr.io
IMAGE_NAME := sparta_global_academy_springboot_public
IMAGE_TAG ?= latest
IMAGE := $(REGISTRY)/stravos97/$(IMAGE_NAME):$(IMAGE_TAG)

# Docker Compose Files
COMPOSE_LOCAL := docker-compose.local.yml
COMPOSE_REMOTE := docker-compose.remote.yml

# Environment file
ENV_FILE := .env

# Colors for output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
NC := \033[0m # No Color

# Print helpers (portable ANSI via printf)
PRINT = printf "%b\n"
PRINTN = printf "%b"

# ==============================================================================
# Help & Documentation
# ==============================================================================

.PHONY: help
help: ## Show this help message
		@$(PRINT) "$(GREEN)Sparta Global Academy - Docker & Development Commands$(NC)"
		@$(PRINT) ""
		@$(PRINT) "$(YELLOW)Available targets:$(NC)"
		@grep -E '^[a-zA-Z0-9_.-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
			awk 'BEGIN {FS = ":.*?## "}; {printf "  %-22s %s\n", $$1, $$2}'
		@$(PRINT) ""
		@$(PRINT) "$(YELLOW)Quick Start:$(NC)"
		@$(PRINT) "  1. cp .env.example .env && edit .env"
		@$(PRINT) "  2. make up-local"
		@$(PRINT) "  3. make health-local"
		@$(PRINT) "  4. Visit http://localhost:8091"

# ==============================================================================
# Environment Checks
# ==============================================================================

.PHONY: check-env
check-env: ## Check if .env file exists and is configured
		@if [ ! -f $(ENV_FILE) ]; then \
			$(PRINT) "$(RED)Error: .env file not found!$(NC)"; \
			echo "Run: cp .env.example .env"; \
			exit 1; \
		fi
		@$(PRINT) "$(GREEN)✓ .env file exists$(NC)"

.PHONY: validate-env
validate-env: check-env ## Validate required environment variables
		@source $(ENV_FILE) && \
		if [ -z "$$APP_DB_USERNAME" ] || [ -z "$$APP_DB_PASSWORD" ]; then \
			$(PRINT) "$(RED)Error: Required variables not set in .env$(NC)"; \
			exit 1; \
		fi
		@$(PRINT) "$(GREEN)✓ Environment variables validated$(NC)"

# ==============================================================================
# Local Stack (MySQL + API)
# ==============================================================================

.PHONY: preflight-local
preflight-local:
			@# Remove any leftover containers created with fixed names (from older compose files)
			@docker ps -a --filter name='^/sparta_mysql$$' -q | xargs -r docker rm -f >/dev/null 2>&1 || true
			@docker ps -a --filter name='^/sparta_api$$' -q | xargs -r docker rm -f >/dev/null 2>&1 || true

.PHONY: up-local
up-local: validate-env preflight-local ## Start local MySQL + API with seed data
		@$(PRINT) "$(YELLOW)Starting local stack...$(NC)"
		docker compose --env-file $(ENV_FILE) -f $(COMPOSE_LOCAL) up -d
		@$(PRINT) "$(GREEN)✓ Local stack started$(NC)"
		@$(PRINT) "Waiting for MySQL to be ready (this may take 30 seconds)..."
		@$(MAKE) -s wait-mysql-local

.PHONY: down-local
down-local: ## Stop local stack
		@$(PRINT) "$(YELLOW)Stopping local stack...$(NC)"
		docker compose --env-file $(ENV_FILE) -f $(COMPOSE_LOCAL) down
		@$(PRINT) "$(GREEN)✓ Local stack stopped$(NC)"

.PHONY: restart-local
restart-local: down-local up-local ## Restart local stack

.PHONY: logs-local
logs-local: ## Tail logs from local API (follow mode)
	docker compose --env-file $(ENV_FILE) -f $(COMPOSE_LOCAL) logs -f --tail=100

.PHONY: logs-local-all
logs-local-all: ## Show all logs from local stack
	docker compose --env-file $(ENV_FILE) -f $(COMPOSE_LOCAL) logs

.PHONY: ps-local
ps-local: ## Show status of local containers
	docker compose --env-file $(ENV_FILE) -f $(COMPOSE_LOCAL) ps

.PHONY: clean-local
clean-local: ## Stop local stack and remove volumes (full reset)
		@$(PRINT) "$(RED)Warning: This will delete all local data!$(NC)"
		@read -p "Continue? [y/N] " -n 1 -r; \
		echo; \
		if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
			docker compose --env-file $(ENV_FILE) -f $(COMPOSE_LOCAL) down -v; \
			# Also remove any leftover containers with old hardcoded names
				docker ps -a --filter name='^/sparta_mysql$$' -q | xargs -r docker rm -f >/dev/null 2>&1 || true; \
				docker ps -a --filter name='^/sparta_api$$' -q | xargs -r docker rm -f >/dev/null 2>&1 || true; \
			$(PRINT) "$(GREEN)✓ Local stack cleaned$(NC)"; \
		fi

# ==============================================================================
# Remote Stack (API only, connects to remote DB)
# ==============================================================================

.PHONY: up-remote
up-remote: validate-env ## Start API connected to remote database
		@$(PRINT) "$(YELLOW)Starting remote-connected API...$(NC)"
		docker compose --env-file $(ENV_FILE) -f $(COMPOSE_REMOTE) up -d
		@$(PRINT) "$(GREEN)✓ Remote API started$(NC)"

.PHONY: down-remote
down-remote: ## Stop remote-connected API
		@$(PRINT) "$(YELLOW)Stopping remote API...$(NC)"
		docker compose --env-file $(ENV_FILE) -f $(COMPOSE_REMOTE) down
		@$(PRINT) "$(GREEN)✓ Remote API stopped$(NC)"

.PHONY: restart-remote
restart-remote: down-remote up-remote ## Restart remote-connected API

.PHONY: logs-remote
logs-remote: ## Tail logs from remote-connected API
	docker compose --env-file $(ENV_FILE) -f $(COMPOSE_REMOTE) logs -f --tail=100

.PHONY: ps-remote
ps-remote: ## Show status of remote containers
	docker compose --env-file $(ENV_FILE) -f $(COMPOSE_REMOTE) ps

# ==============================================================================
# Database Operations
# ==============================================================================

.PHONY: wait-mysql-local
wait-mysql-local: ## Wait for local MySQL to be ready
		@$(PRINTN) "Waiting for MySQL to be healthy"
		@for i in $$(seq 1 30); do \
			if docker compose --env-file $(ENV_FILE) -f $(COMPOSE_LOCAL) exec mysql mysqladmin ping -h 127.0.0.1 --silent 2>/dev/null; then \
				$(PRINT) ""; \
				$(PRINT) "$(GREEN)✓ MySQL is ready$(NC)"; \
				exit 0; \
			fi; \
			$(PRINTN) "."; \
			sleep 2; \
		done; \
			$(PRINT) ""; \
			$(PRINT) "$(RED)✗ MySQL failed to start$(NC)"; \
			exit 1

.PHONY: verify-seed
verify-seed: ## Verify local database was seeded correctly
		@$(PRINT) "$(YELLOW)Verifying seed data...$(NC)"
	@docker compose --env-file $(ENV_FILE) -f $(COMPOSE_LOCAL) exec -T mysql \
		mysql -h127.0.0.1 -u$$APP_DB_USERNAME -p$$APP_DB_PASSWORD sparta_academy \
		-e "SELECT 'Trainers:' as '', COUNT(*) as count FROM trainers \
		    UNION ALL \
		    SELECT 'Courses:' as '', COUNT(*) as count FROM courses;" 2>/dev/null || \
		(echo "$(RED)Failed to verify seed data$(NC)" && exit 1)
		@$(PRINT) "$(GREEN)✓ Seed data verified$(NC)"

.PHONY: mysql-shell
mysql-shell: ## Open MySQL shell in local container
	docker compose --env-file $(ENV_FILE) -f $(COMPOSE_LOCAL) exec mysql \
		mysql -u$$APP_DB_USERNAME -p$$APP_DB_PASSWORD sparta_academy

.PHONY: backup-local
backup-local: ## Backup local database to file
	@mkdir -p backups
	@BACKUP_FILE="backups/backup_$$(date +%Y%m%d_%H%M%S).sql"; \
	docker compose --env-file $(ENV_FILE) -f $(COMPOSE_LOCAL) exec -T mysql \
		mysqldump -u$$APP_DB_USERNAME -p$$APP_DB_PASSWORD sparta_academy > $$BACKUP_FILE && \
	echo "$(GREEN)✓ Database backed up to $$BACKUP_FILE$(NC)"

# ==============================================================================
# Health Checks & Testing
# ==============================================================================

.PHONY: health-local
health-local: ## Check local API health
		@$(PRINT) "$(YELLOW)Checking local API health...$(NC)"
		@for i in $$(seq 1 30); do \
			if curl -fsS http://localhost:8091/actuator/health 2>/dev/null; then \
				$(PRINT) ""; \
				$(PRINT) "$(GREEN)✓ API is healthy$(NC)"; \
				exit 0; \
			fi; \
			sleep 2; \
			$(PRINTN) "."; \
		done; \
			$(PRINT) ""; \
			$(PRINT) "$(RED)✗ Health check failed$(NC)"; \
			exit 1

.PHONY: health-remote
health-remote: ## Check remote-connected API health
	@echo "$(YELLOW)Checking remote API health...$(NC)"
	@$(MAKE) -s health-local

.PHONY: test-api
test-api: ## Run basic API tests
	@echo "$(YELLOW)Testing API endpoints...$(NC)"
	@curl -fsS http://localhost:8091/db/ping > /dev/null && echo "$(GREEN)✓ Database ping OK$(NC)" || echo "$(RED)✗ Database ping failed$(NC)"
	@curl -fsS http://localhost:8091/trainers > /dev/null && echo "$(GREEN)✓ Trainers endpoint OK$(NC)" || echo "$(RED)✗ Trainers endpoint failed$(NC)"
	@curl -fsS http://localhost:8091/courses > /dev/null && echo "$(GREEN)✓ Courses endpoint OK$(NC)" || echo "$(RED)✗ Courses endpoint failed$(NC)"

# ==============================================================================
# Docker Image Management
# ==============================================================================

.PHONY: pull-image
pull-image: ## Pull latest Docker image from GHCR
		@$(PRINT) "$(YELLOW)Pulling image: $(IMAGE)$(NC)"
		docker pull $(IMAGE)
		@$(PRINT) "$(GREEN)✓ Image pulled successfully$(NC)"

.PHONY: build-local-image
build-local-image: ## Build Docker image locally
		@$(PRINT) "$(YELLOW)Building local image...$(NC)"
		docker build -t sparta-api:local .
		@$(PRINT) "$(GREEN)✓ Local image built$(NC)"

.PHONY: list-images
list-images: ## List all related Docker images
	@docker images | grep -E "(sparta|$(IMAGE_NAME))" || echo "No related images found"

# ==============================================================================
# Development Tools
# ==============================================================================

.PHONY: print-env
print-env: ## Show environment values
			@$(PRINT) "$(YELLOW)Environment Configuration (raw):$(NC)"
		@if [ -f $(ENV_FILE) ]; then \
			source $(ENV_FILE); \
			echo "DB_URL=$${DB_URL:-<not set>}"; \
			echo "APP_DB_USERNAME=$${APP_DB_USERNAME:-<not set>}"; \
			echo "APP_DB_PASSWORD=$${APP_DB_PASSWORD:-<not set>}"; \
			echo "MYSQL_ROOT_PASSWORD=$${MYSQL_ROOT_PASSWORD:-<not set>}"; \
			echo "MYSQL_ADMIN_PASSWORD=$${MYSQL_ADMIN_PASSWORD:-<not set>}"; \
		else \
				$(PRINT) "$(RED).env file not found$(NC)"; \
			fi

# ==============================================================================
# .env Generation
# ==============================================================================

.PHONY: gen-env
gen-env: ## Generate secure .env file
	@if [ -f $(ENV_FILE) ]; then \
		$(PRINT) ".env file already exists"; \
		$(PRINT) "To preserve existing values, backup your current .env:"; \
		echo "  cp .env .env.backup"; \
		$(PRINT) "Then run: make gen-env-force"; \
		$(PRINT) "Or delete .env and run this command again."; \
		exit 1; \
	fi
	@$(MAKE) -s gen-env-force

.PHONY: gen-env-force
gen-env-force: ## Generate .env file (overwrite existing)
		@bash -lc '\
		  set -e; \
		  TIMESTAMP=$$(date "+%Y-%m-%d %H:%M:%S"); \
		  gen_pw(){ if command -v openssl >/dev/null 2>&1; then openssl rand -base64 32 | head -c 25; else head -c 32 /dev/urandom | base64 | tr -d "\n" | head -c 25; fi; }; \
		  APP_PASS=$$(gen_pw); \
		  ROOT_PASS=$$(gen_pw); \
		  ADMIN_PASS=$$(gen_pw); \
		  { \
		    echo "# ============================================================================"; \
		    echo "# Sparta Global Academy - Environment Configuration"; \
		    echo "# ============================================================================"; \
		    echo "# AUTO-GENERATED by make gen-env - $$TIMESTAMP"; \
		    echo "#"; \
		    echo "# SECURITY WARNING: Never commit this file to Git!"; \
		    echo "# Keep these credentials secure and rotate them regularly."; \
		    echo "#"; \
		    echo "# Quick verification: make print-env"; \
		    echo "# ============================================================================"; \
		    echo; \
		    echo "# Application Database Credentials"; \
		    echo "# Used by Spring Boot API to connect to MySQL database"; \
		    echo "APP_DB_USERNAME=sparta_user"; \
		    echo "APP_DB_PASSWORD=$$APP_PASS"; \
		    echo; \
		    echo "# Local MySQL Instance Settings (docker-compose.local.yml only)"; \
		    echo "# These are used when running MySQL in Docker locally"; \
		    echo "MYSQL_ROOT_PASSWORD=$$ROOT_PASS"; \
		    echo "MYSQL_ADMIN_PASSWORD=$$ADMIN_PASS"; \
		    echo; \
		    echo "# Remote Database URL (Optional Override)"; \
		    echo "# If connecting to an external MySQL server, set DB_URL explicitly."; \
		    echo "# Default compose uses: jdbc:mysql://mysql:3306/sparta_academy"; \
		    echo "# Example remote: jdbc:mysql://your-remote-host:3306/sparta_academy"; \
		    echo "# DB_URL="; \
		    echo; \
		    echo "# ============================================================================"; \
		    echo "# Environment Usage:"; \
		    echo "# - Local development: make up-local   (uses all above credentials)"; \
		    echo "# - Remote database:   make up-remote  (uses APP_DB_* credentials only)"; \
		    echo "# ============================================================================"; \
		  } > .env; \
		  echo "Secure .env file generated successfully!"; \
		  echo "  - Generated $$TIMESTAMP"; \
		  echo "Next steps:"; \
		  echo "  1. Verify settings: make print-env"; \
		  echo "  2. Start local stack: make up-local"; \
		  echo "  3. Or remote stack: make up-remote";'

.PHONY: open-swagger
open-swagger: ## Open Swagger UI in browser
		@$(PRINT) "$(YELLOW)Opening Swagger UI...$(NC)"
	@command -v open >/dev/null 2>&1 && open http://localhost:8091 || \
	command -v xdg-open >/dev/null 2>&1 && xdg-open http://localhost:8091 || \
	echo "Visit: http://localhost:8091"

.PHONY: watch-logs
watch-logs: ## Watch logs with color highlighting
	@docker compose --env-file $(ENV_FILE) -f $(COMPOSE_LOCAL) logs -f | \
		grep --line-buffered -E --color=auto 'ERROR|WARNING|INFO|$'

# ==============================================================================
# Maven Commands (for local development)
# ==============================================================================

.PHONY: mvn-clean
mvn-clean: ## Clean Maven build
	./mvnw clean

.PHONY: mvn-test
mvn-test: ## Run Maven tests
	./mvnw test

.PHONY: mvn-build
mvn-build: ## Build Maven package
	./mvnw clean package -DskipTests

.PHONY: mvn-run
mvn-run: ## Run application with Maven
	./mvnw spring-boot:run

# ==============================================================================
# Git & Publishing
# ==============================================================================

.PHONY: publish-public
publish-public: ## Force-push single-commit snapshot to public repo
	@echo "$(YELLOW)Publishing to public repository...$(NC)"
	@PUBLIC_REPO=$${PUBLIC_REPO:-stravos97/Sparta_Global_Academy_Springboot_Public}; \
	TMP_DIR=$$(mktemp -d); \
	trap "rm -rf $$TMP_DIR" EXIT; \
	echo "Creating snapshot in $$TMP_DIR..."; \
	git ls-files -z | tar --null -T - -c | tar -x -C "$$TMP_DIR"; \
	cd "$$TMP_DIR" && \
	git init -q && \
	git config user.name "local-publisher" && \
	git config user.email "local@publisher" && \
	git add -A && \
	git commit -q -m "Public snapshot: $$(date +%Y-%m-%d_%H:%M:%S)" && \
	git branch -M main && \
	if [ -n "$$PUBLIC_REPO_TOKEN" ]; then \
		git remote add public https://x-access-token:$$PUBLIC_REPO_TOKEN@github.com/$$PUBLIC_REPO.git; \
	else \
		git remote add public https://github.com/$$PUBLIC_REPO.git; \
	fi && \
	git push -f public main && \
	echo "$(GREEN)✓ Published to $$PUBLIC_REPO$(NC)"

# ==============================================================================
# Utility Targets
# ==============================================================================

.PHONY: status
status: ## Show complete system status
		@$(PRINT) "$(YELLOW)=== System Status ===$(NC)"
		@$(PRINT) ""
		@$(PRINT) "$(YELLOW)Local Stack:$(NC)"
		@docker compose --env-file $(ENV_FILE) -f $(COMPOSE_LOCAL) ps
		@$(PRINT) ""
		@$(PRINT) "$(YELLOW)Remote Stack:$(NC)"
		@docker compose --env-file $(ENV_FILE) -f $(COMPOSE_REMOTE) ps
		@$(PRINT) ""
		@$(PRINT) "$(YELLOW)Port Usage:$(NC)"
	@lsof -i :8091 2>/dev/null | grep LISTEN || echo "  Port 8091: Available"
	@lsof -i :3306 2>/dev/null | grep LISTEN || echo "  Port 3306: Available"

.PHONY: all
all: up-local wait-mysql-local verify-seed health-local test-api ## Complete local setup with verification

.PHONY: reset
reset: clean-local all ## Full reset and restart of local environment

# ==============================================================================
# Advanced/Debug Commands
# ==============================================================================

.PHONY: debug-env
debug-env: ## Debug environment variables (shows actual values - use with caution!)
	@echo -e "$(RED)Warning: This shows actual passwords!$(NC)"
	@read -p "Continue? [y/N] " -n 1 -r; \
	echo; \
	if [[ $REPLY =~ ^[Yy]$ ]]; then \
		source $(ENV_FILE) && env | grep -E "(DB_|MYSQL_)" | sort; \
	fi

.PHONY: shell-api
shell-api: ## Open shell in API container
	docker compose --env-file $(ENV_FILE) -f $(COMPOSE_LOCAL) exec api /bin/sh

.PHONY: inspect-network
inspect-network: ## Inspect Docker network configuration
	@NETWORK=$$(docker compose --env-file $(ENV_FILE) -f $(COMPOSE_LOCAL) ps -q mysql 2>/dev/null | xargs -r docker inspect -f '{{range .NetworkSettings.Networks}}{{.NetworkID}}{{end}}' | head -n1); \
	if [ -n "$$NETWORK" ]; then \
		docker network inspect $$NETWORK; \
	else \
		echo "No active network found"; \
	fi

# ==============================================================================
# END
# ==============================================================================
