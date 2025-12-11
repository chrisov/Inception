SRCDIR = srcs
LOGDIR = logs
COMPOSE_FILE = $(SRCDIR)/docker-compose.yml
export COMPOSE_FILE

COMPOSE = docker compose

GREEN = \033[0;32m
BLUE = \033[0;34m
NC = \033[0m

.DEFAULT_GOAL := help

LOGDIR:
	@mkdir -p $(LOGDIR)

up:
	@echo "$(GREEN)Starting LEMP stack...$(NC)"
	$(COMPOSE) up -d

down:
	@echo "$(BLUE)Stopping LEMP stack...$(NC)"
	$(COMPOSE) down

logs: LOGDIR
	@echo "$(BLUE)Writing service logs to $(LOGDIR)/...$(NC)"
	$(COMPOSE) logs mariadb > $(LOGDIR)/mdb.log
	$(COMPOSE) logs nginx > $(LOGDIR)/nginx.log
	$(COMPOSE) logs wordpress > $(LOGDIR)/wp.log


re: restart

restart:
	@echo "$(GREEN)Restarting services...$(NC)"
	$(COMPOSE) down
	$(COMPOSE) up -d

build:
	@echo "$(GREEN)Building services...$(NC)"
	$(COMPOSE) up --build -d

ps:
	$(COMPOSE) ps

clean:
	@echo "$(BLUE)Removing containers, networks, and volumes...$(NC)"
	$(COMPOSE) down --volumes --remove-orphans
	@rm -rf web/

help:
	@echo "Available commands:"
	@echo ""
	@echo "  make up        - Start all services"
	@echo "  make down      - Stop all services"
	@echo "  make logs      - Show logs"
	@echo "  make restart   - Restart all services"
	@echo "  make build     - Build/rebuild services"
	@echo "  make ps        - Show running containers"
	@echo "  make clean     - Remove containers + volumes"
	@echo ""

.PHONY: up down logs re restart build ps clean help