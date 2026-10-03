# ai-stack — atalhos. Variáveis: HOME_DIR=<dir> (padrão: ~/ai-stack), ARGS="--with herdr"
SHELL := /usr/bin/env bash
HOME_DIR ?= $(HOME)/ai-stack
ARGS ?=

.PHONY: help install install-config dry-run verify sync uninstall list

help:
	@echo "Targets: install | install-config | dry-run | list | verify | sync | uninstall"
	@echo "Variáveis: HOME_DIR=$(HOME_DIR)  ARGS='--with herdr --shell'"

install:
	./install.sh --home "$(HOME_DIR)" $(ARGS)

install-config:
	./install.sh --home "$(HOME_DIR)" --config-only -y $(ARGS)

dry-run:
	./install.sh --home "$(HOME_DIR)" --dry-run -y $(ARGS)

list:
	./install.sh --list

verify:
	./scripts/verify.sh

sync:
	./scripts/sync-from-live.sh $(ARGS)

uninstall:
	./uninstall.sh --home "$(HOME_DIR)" $(ARGS)
