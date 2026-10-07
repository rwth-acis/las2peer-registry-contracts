#!/bin/sh
# Waits for the Ethereum client, deploys the registry contracts and writes the
# las2peer RegistryConfiguration properties to $REGISTRY_CONFIG (stdout if unset).
set -eu
ETH_HOST=${ETH_HOST:-127.0.0.1}
ETH_PORT=${ETH_PORT:-8545}
NETWORK_ID=${NETWORK_ID:-456719}
ENDPOINT=${ENDPOINT:-http://$ETH_HOST:$ETH_PORT}
cd "$(dirname "$0")/.."

# never leave a config from an earlier chain behind while deploying
[ -n "${REGISTRY_CONFIG:-}" ] && rm -f "$REGISTRY_CONFIG"

rpc_ready() {
  node -e '
    const req = require("http").request({ host: process.argv[1], port: process.argv[2], method: "POST",
      headers: { "content-type": "application/json" } }, res => process.exit(res.statusCode === 200 ? 0 : 1))
    req.on("error", () => process.exit(1))
    req.end(JSON.stringify({ jsonrpc: "2.0", id: 1, method: "net_version", params: [] }))' "$ETH_HOST" "$ETH_PORT"
}
until rpc_ready; do
  echo "waiting for Ethereum client at $ETH_HOST:$ETH_PORT ..."; sleep 1
done

npx truffle migrate --reset --network development
node scripts/export-registry-config.js "$NETWORK_ID" "$ENDPOINT" ${REGISTRY_CONFIG:-}
