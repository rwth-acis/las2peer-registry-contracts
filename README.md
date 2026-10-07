# las2peer Service Registry Smart Contracts

Solidity contracts for the Ethereum-based registry of [las2peer](https://github.com/rwth-acis/las2peer): users, groups, services (releases and deployments), community tags and reputation.

Built with [Foundry](https://getfoundry.sh) and Solidity 0.8. Tool versions are pinned in `mise.toml` (`mise install`).

## Develop

```bash
forge install --no-git foundry-rs/forge-std@v1.17.0   # once
forge build
forge test
```

## Deploy

```bash
anvil --chain-id 456719 &          # local dev chain
./scripts/deploy.sh                # deploys and prints the las2peer registry config
```

`scripts/deploy.sh` waits for the chain, funds the las2peer dev accounts when it talks to anvil, runs `script/Deploy.s.sol`, and writes `deployments/registry.properties` (copied to `$REGISTRY_CONFIG` if set). A las2peer node reads that file as `etc/i5.las2peer.registry.data.RegistryConfiguration.properties`.

Settings: `ETH_HOST`/`ETH_PORT` (RPC to deploy to), `ENDPOINT` (RPC URL as the node sees it), `DEPLOYER_KEY`.

The [las2peer](https://github.com/rwth-acis/las2peer) repository runs chain, deployment and node together with `docker compose up`.

## Known gap

`ReputationRegistry.createProfile` takes the profile owner as a parameter instead of using `msg.sender` (since 2020), so anyone can create a profile for any address. las2peer only calls it from the agent's own account. See `test/ReputationRegistry.t.sol`.
