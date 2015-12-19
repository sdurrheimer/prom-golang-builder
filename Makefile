
NAME := prom-golang-builder

build:
	docker build -t "sdurrheimer/$(NAME):$(shell git rev-parse --abbrev-ref HEAD)" .
	docker tag -f "sdurrheimer/$(NAME):$(shell git rev-parse --abbrev-ref HEAD)" "sdurrheimer/$(NAME):latest"

.PHONY: build
