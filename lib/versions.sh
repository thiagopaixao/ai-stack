#!/usr/bin/env bash
# versions.sh — Version pins for every component installed by ai-stack.
# Each variable can be overridden from the environment, e.g.:
#   NODE_VERSION=22.11.0 ./install.sh
# (sourced; do not execute)

NODE_VERSION="${NODE_VERSION:-24.16.0}"
NVM_VERSION="${NVM_VERSION:-v0.40.1}"            # same as the legacy installer
OPENCODE_VERSION="${OPENCODE_VERSION:-1.18.31}"
SERENA_VERSION="${SERENA_VERSION:-1.5.1}"
SERENA_SPEC="${SERENA_SPEC:-serena-agent==${SERENA_VERSION}}"
SERENA_PYTHON="${SERENA_PYTHON:-3.13}"           # python used by `uv tool install -p`
BITLOOPS_VERSION="${BITLOOPS_VERSION:-0.0.30}"   # release tag is v${BITLOOPS_VERSION}
RIPGREP_VERSION="${RIPGREP_VERSION:-14.1.1}"
OH_MY_OPENCODE_SLIM_VERSION="${OH_MY_OPENCODE_SLIM_VERSION:-latest}"

# Optional components
NINEROUTER_VERSION="${NINEROUTER_VERSION:-0.5.95}"
HEADROOM_VERSION="${HEADROOM_VERSION:-0.38.0}"
PASEO_VERSION="${PASEO_VERSION:-0.7.2}"
HERDR_VERSION="${HERDR_VERSION:-0.6.8}"          # github.com/herdrdev/herdr releases
BUN_VERSION="${BUN_VERSION:-1.4.2}"
