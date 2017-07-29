SRC = ./src

STATIC = $(SRC)/static
STATIC_STYLES = $(STATIC)/styles
STATIC_SCRIPTS = $(STATIC)/scripts
STATIC_IMAGES = $(STATIC)/images

# find all scss source files and build appropriate target file paths
SCSS_SRC = $(wildcard $(SRC)/scss/*.scss)
SCSS_DEST := $(addprefix $(STATIC_STYLES)/,$(notdir $(SCSS_SRC:.scss=.css)))


.PHONY: help dev build build-static build-scss setup

help:
	@echo ""
	@echo "Makefile for Hugo site"
	@echo ""
	@echo "dev: run hugo dev-server"
	@echo "build: build site"
	@echo ""
	@echo "setup: install tools"

setup:
	npm install -g node-sass

dev: build-static
	cd ./src && hugo server -D

build: build-static
	cd ./src && hugo

build-static: build-scss
	@echo "static files built"

build-scss: $(SCSS_DEST) $(STATIC_STYLES)
	@echo "scss built"

$(STATIC_STYLES)/%.css: $(SRC)/scss/%.scss $(STATIC_STYLES)
	@echo "compiling scss" $< "to" $@
	node-sass $< $@
	@echo "done!"

$(STATIC_STYLES):
	echo  $(STATIC_STYLES)
	mkdir -p $(STATIC_STYLES)
