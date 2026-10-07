#!/usr/bin/env node
// Writes the las2peer RegistryConfiguration properties file from truffle's build artifacts.
//
// Usage: node scripts/export-registry-config.js <networkId> <endpoint> [outFile]
//   e.g. node scripts/export-registry-config.js 456719 http://127.0.0.1:8545 ../las2peer/etc/i5.las2peer.registry.data.RegistryConfiguration.properties
// Without outFile the properties are printed to stdout.

const fs = require('fs')
const path = require('path')

const [networkId, endpoint, outFile] = process.argv.slice(2)
if (!networkId || !endpoint) {
    console.error('usage: export-registry-config.js <networkId> <endpoint> [outFile]')
    process.exit(1)
}

const contracts = {
    communityTagIndexAddress: 'CommunityTagIndex',
    userRegistryAddress: 'UserRegistry',
    groupRegistryAddress: 'GroupRegistry',
    serviceRegistryAddress: 'ServiceRegistry',
    reputationRegistryAddress: 'ReputationRegistry'
}

const lines = [
    `endpoint = ${endpoint}`,
    'gasPrice = 20000000000',
    'gasLimit = 6721975'
]

for (const [key, name] of Object.entries(contracts)) {
    const artifact = path.join(__dirname, '..', 'build', 'contracts', `${name}.json`)
    const deployment = JSON.parse(fs.readFileSync(artifact, 'utf8')).networks[networkId]
    if (!deployment) {
        console.error(`${name} is not deployed on network ${networkId}; run truffle migrate first`)
        process.exit(2)
    }
    lines.push(`${key} = ${deployment.address}`)
}

const output = lines.join('\n') + '\n'
if (outFile) {
    fs.writeFileSync(outFile, output)
    console.error(`wrote ${outFile}`)
} else {
    process.stdout.write(output)
}
