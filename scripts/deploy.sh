#!/usr/bin/env bash
# Deploys the registry contracts and writes the las2peer RegistryConfiguration properties
# to $REGISTRY_CONFIG (stdout if unset).
#   ETH_HOST/ETH_PORT  RPC to deploy to (default 127.0.0.1:8545)
#   ENDPOINT           RPC URL as the las2peer node sees it (default http://$ETH_HOST:$ETH_PORT)
#   DEPLOYER_KEY       private key paying for the deployment (default: dev account 0)
# On a local anvil chain the las2peer dev accounts are funded first.
set -euo pipefail
cd "$(dirname "$0")/.."
ETH_HOST=${ETH_HOST:-127.0.0.1}
ETH_PORT=${ETH_PORT:-8545}
RPC="http://$ETH_HOST:$ETH_PORT"
export ENDPOINT=${ENDPOINT:-$RPC}

# Dev-only keys: what las2peer derives from the 10 well-known dev mnemonics (raw BIP39 seed,
# not BIP44, so anvil's own --mnemonic accounts do not match). Never use them on a real chain.
DEV_KEYS=(
  0x95395d5cd006cf4a95a01f219a66205d4b7d02e54b0da326e9154fa618f083fa
  0xaae2ed23109633f821c9bd39cfd2d7de2ff6dd49796663a30b3eb5b6880c63db
  0xe5c65369fb1021efbc6f1317da46407ba87bf510611457e25dde4eca7c8e80d3
  0x3ad62eea7750b111613227e78620054b85f290f93b8fd6284fef44d974fc5f91
  0xbc2f0a9bc4628f12aa5a8fc697b2f43ffed83da0496b881fa81d45a86909b1df
  0x3bbd32652e6e86c6f7c6e4e3bdd950afaa83d274c097c28a509dcd9569051787
  0xbe1c179fbfd7ad41bcee685d56d13bcc6dd555ac2bb5a97e095adc75b9397441
  0x8318fa509f77c65fb233d2f143dc7276fe2cf3d8538ad15ed31b14e87b39222c
  0xf14be57edb9e8ebe272e0f4875ae3737217273657307116a459ccc30abae25b1
  0xea9350dc7c1a7cff22832576d555590ea32f83e3fcccd2e55b74475075117481
)
DEPLOYER_KEY=${DEPLOYER_KEY:-${DEV_KEYS[0]}}

# never leave a config from an earlier chain behind while deploying
[[ -n "${REGISTRY_CONFIG:-}" ]] && rm -f "$REGISTRY_CONFIG"

until cast chain-id --rpc-url "$RPC" >/dev/null 2>&1; do echo "waiting for Ethereum client at $RPC ..."; sleep 1; done

if cast client --rpc-url "$RPC" 2>/dev/null | grep -qi anvil; then
  echo "local anvil chain: funding las2peer dev accounts"
  for key in "${DEV_KEYS[@]}"; do
    cast rpc --rpc-url "$RPC" anvil_setBalance "$(cast wallet address --private-key "$key")" 0xD3C21BCECCEDA1000000 >/dev/null # 1M ETH
  done
  # the node pays faucet rewards from its operator account (dev account 0) and shows eth_coinbase as the pool
  cast rpc --rpc-url "$RPC" anvil_setCoinbase "$(cast wallet address --private-key "${DEV_KEYS[0]}")" >/dev/null
fi

mkdir -p deployments
forge script script/Deploy.s.sol --rpc-url "$RPC" --private-key "$DEPLOYER_KEY" --broadcast --slow -q
if [[ -n "${REGISTRY_CONFIG:-}" ]]; then
  cp deployments/registry.properties "$REGISTRY_CONFIG"
  echo "wrote $REGISTRY_CONFIG"
else
  cat deployments/registry.properties
fi
