all:
	docker compose -f srcs/docker-compose.yml up --build -d

down:
	docker compose -f srcs/docker-compose.yml down

clean: down
	docker system prune -af

fclean: clean
	docker volume rm mariadb_data wordpress_data 2>/dev/null || true

re: fclean all

.PHONY: all down clean fclean re