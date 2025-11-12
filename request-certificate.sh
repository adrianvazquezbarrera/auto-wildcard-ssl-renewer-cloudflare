#!/bin/sh

set -e

(
    # Change to the directory of the script
    cd "$(dirname "$0")"
    docker compose up --build
)