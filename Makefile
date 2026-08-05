NAME = inception
COMPOSE = docker-compose -f srcs/docker-compose.yml

all:
	# Build images if needed and start containers in the background
	$(COMPOSE) up --build -d

clean:
	# Stop and remove containers + project network
	$(COMPOSE) down

fclean: clean
	# Remove this project's containers, network, images and volumes only
	$(COMPOSE) down --rmi all -v

re: fclean all

.PHONY: all clean fclean re