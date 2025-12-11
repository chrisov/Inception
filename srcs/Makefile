COMPOSE = docker compose

GREEN = \033[0;32m
BLUE = \033[0;34m
NC = \033[0m

.DEFAULT_GOAL := help

up:
	@echo "$(GREEN)Starting LEMP stack...$(NC)"
	$(COMPOSE) up -d

down:
	@echo "$(BLUE)Stopping LEMP stack...$(NC)"
	$(COMPOSE) down

logs:
	@echo "$(BLUE)Displaying logs (Ctrl+C to exit)...$(NC)"
	$(COMPOSE) logs mariadb > mdb.log
	$(COMPOSE) logs wordpress > wp.log

re:
	@echo "$(GREEN)Restarting services...$(NC)"
	$(COMPOSE) down
	$(COMPOSE) up

build:
	@echo "$(GREEN)Building services...$(NC)"
	$(COMPOSE) up --build

ps:
	$(COMPOSE) ps

clean:
	@echo "$(BLUE)Removing containers, networks, and volumes...$(NC)"
	$(COMPOSE) down
	@rm -rf database
	@rm -rf ../web

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
