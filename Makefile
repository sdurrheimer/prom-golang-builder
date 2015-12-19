
NAME := prom-golang-builder

build:
	docker build -t "sdurrheimer/$(NAME):$(shell git rev-parse --short HEAD)" .

.PHONY: build
