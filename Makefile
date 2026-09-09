NAME		= inception
LOGIN		= noaziki

SRCS_DIR	= srcs
COMPOSE		= docker compose -f $(SRCS_DIR)/docker-compose.yml --env-file $(SRCS_DIR)/.env
DATA_DIR	= /home/$(LOGIN)/data

.PHONY: all build up down start stop restart clean fclean re logs ps prepare

all: prepare up

# Create the host folders the named volumes will bind to before compose runs.
prepare:
	@mkdir -p $(DATA_DIR)/wordpress
	@mkdir -p $(DATA_DIR)/mariadb

build: prepare
	$(COMPOSE) build

up: prepare
	$(COMPOSE) up -d --build

start:
	$(COMPOSE) start

stop:
	$(COMPOSE) stop

down:
	$(COMPOSE) down

restart: down up

logs:
	$(COMPOSE) logs -f

ps:
	$(COMPOSE) ps

# Stop and remove containers + the named volumes' docker metadata
# (does NOT touch host data by default -- use fclean for that).
clean: down
	$(COMPOSE) down -v --remove-orphans

# Full wipe: containers, volumes, images built by this project, and host data.
fclean: clean
	-docker rmi -f mariadb nginx wordpress redis ftp adminer portfolio 2>/dev/null
	-sudo rm -rf $(DATA_DIR)

re: fclean all
