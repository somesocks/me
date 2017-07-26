
.PHONY: help dev build

help:
	@echo ""
	@echo "Makefile for Hugo site"
	@echo ""
	@echo "dev: run hugo dev-server"
	@echo "build: build site"
	@echo ""

dev:
	hugo server -D

build:
	hugo
