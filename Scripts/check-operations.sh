#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
CHECK_BINARY="$(mktemp -t helios-operations-check)"
trap 'rm -f "$CHECK_BINARY"' EXIT
swiftc -swift-version 6 Helios/Networking/*.swift Helios/Operations/*.swift Tests/OperationsIntegrationCheck.swift -o "$CHECK_BINARY"
"$CHECK_BINARY"
