# las2peer Service Registry Smart Contracts 

This repo contains Solidity smart contracts for an Ethereum-based service registry for [las2peer](https://github.com/rwth-acis/las2peer).

## Development Status

The contracts are very much a work in progress and not ready for production use.
However, you can try out the development environment and play around with the contracts in an IDE like [Remix](https://remix.ethereum.org/) or on the command line. 

## Installation & Dependencies

This project is distributed as an [npm](https://www.npmjs.com/) package and uses the [truffle](https://truffleframework.com/truffle) Ethereum development framework as a build and deployment tool.

### Installation

* If you haven’t already, install [Node.js with npm](https://docs.npmjs.com/getting-started/installing-node#install-npm--manage-npm-versions).
* Clone this repo and run `npm install` in the root folder. This will install truffle and other dependencies.

### Ethereum client setup

You are free to use any blockchain and [JSON-RPC](https://github.com/ethereum/wiki/wiki/JSON-RPC)-enabled Ethereum client (adjust `truffle.js` accordingly), but the simplest way is to use [ganache-cli](https://github.com/trufflesuite/ganache-cli), which is included as a developer dependency. It should suffice to run:

```sh
npm run start-ganache
```

And later:

```sh
npm run stop-ganache
```

That’s it — the default configuration is fine. This sets up a local blockchain for development purposes and serves its API on port 8545. Don’t worry, with these settings, mining blocks does not fry your CPU. By default, the blockchain data is not persisted, i.e., restarting ganache will give you a blank slate. 

If you actually want to see what’s going on, run `./node_modules/.bin/ganache-cli` directly, or even install and run the [Ganache GUI](https://truffleframework.com/ganache) for a pretty visual interface.

<details>
<summary>
Optional: set up convenient shortcuts for the truffle and ganache-cli executables.
</summary>

Truffle, ganache-cli, and other developer dependencies’ binaries can be found in `./node_modules/.bin/`. If you find this inconvenient and would prefer to access them simply by their name, you have several options.

1. Install them globally with npm, e.g., `npm install --global truffle`. This makes sense if you want to use a tool in other projects too.
2. Set up an alias for each tool you want to use, e.g., `alias truffle="$(realpath ./node_modules/.bin/truffle)"`. 
3. Modify your `PATH`, e.g., `export PATH="$(realpath ./node_modules/.bin):PATH"`, if you want to make all tools from the `.bin` directory available. 

To make the alias or PATH persistent, put the commands with the absolute path [in your shell configuration script](https://wiki.archlinux.org/index.php/Bash#Aliases).
</details>

## Deploying contracts and running tests

The compilation of the contracts, deployment of the bytecode contracts to the blockchain, and running tests is all handled by truffle.


Compilation and deployment can be run manually via truffle’s `compile` and `migrate` commands, but simply running the tests will also trigger these steps if necessary. Thus, simply try: 

```sh
npm run test
```

This requires a running Ethereum client as described above.

<!--
DOCUMENTATION TODO

* describe how to set up Remix to try the contracts
* explain all the stuff that took me a long time to figure out, e.g., the tests and accessing contract functions via the truffle JS wrapper 
-->
