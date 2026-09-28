#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
CHECK_BINARY="$(mktemp -t helios-gateway-check)"
trap 'rm -f "$CHECK_BINARY"' EXIT
swiftc -D DEBUG -swift-version 6 Helios/Development/*.swift Helios/Networking/*.swift Helios/Operations/*.swift Tests/GatewayIntegrationCheck.swift -o "$CHECK_BINARY"
"$CHECK_BINARY"
