SRCDIR := srcs
LOGDIR := logs
DATADIR := /home/dchrysov/data
COMPOSE_FILE = $(SRCDIR)/docker-compose.yml
export COMPOSE_FILE

COMPOSE = docker compose

GREEN = \033[0;32m
BLUE = \033[0;34m
NC = \033[0m

.DEFAULT_GOAL := help

logdir:
	@mkdir -p $(LOGDIR)

datadir:
	@mkdir -p $(DATADIR)/database
	@mkdir -p $(DATADIR)/web

build: datadir
	@echo "$(GREEN)Building services...$(NC)"
	$(COMPOSE) up --build -d

up: datadir
	@echo "$(GREEN)Starting LEMP stack...$(NC)"
	$(COMPOSE) up -d

down:
	@echo "$(BLUE)Stopping LEMP stack...$(NC)"
	$(COMPOSE) down

restart: datadir
	@echo "$(GREEN)Restarting services...$(NC)"
	$(COMPOSE) down
	$(COMPOSE) up -d

re: restart

logs: logdir
	@echo "$(BLUE)Writing service logs to $(LOGDIR)/...$(NC)"
	$(COMPOSE) logs mariadb > $(LOGDIR)/mdb.log
	$(COMPOSE) logs nginx > $(LOGDIR)/nginx.log
	$(COMPOSE) logs wordpress > $(LOGDIR)/wp.log

status:
	@echo "\n$(BLUE)Showing status of containers, networks, and volumes...$(NC)"
	@echo "\n$(BLUE)Showing containers$(NC)"
	$(COMPOSE) ps
	@echo "\n$(BLUE)Showing volumes$(NC)"
	docker volume ls
	@echo "\n$(BLUE)Showing networks$(NC)"
	docker network ls
	@echo "\n"

clean:
	@echo "$(BLUE)Removing containers, networks, and volumes...$(NC)"
	$(COMPOSE) down --volumes --remove-orphans
	@docker stop $$(docker ps -qa) 2>/dev/null || true
	@docker rm $$(docker ps -qa) 2>/dev/null || true
	@docker rmi -f $$(docker images -qa) 2>/dev/null || true
	@docker network rm $$(docker network ls -q) 2>/dev/null || true
	@docker volume rm $$(docker volume ls -q) 2>/dev/null || true
	@rm -rf $(LOGDIR)

fclean: clean
	@sudo rm -rf ~/data/*

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

.PHONY: build up down restart re logs status clean fclean help logdir datadir