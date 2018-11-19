module.exports = {
    networks: {
        development: {
            host: '127.0.0.1',
            port: 8545,
            network_id: '*'
        },
        cluster: {
            host: '127.0.0.1',
            port: 8545,
            network_id: '456719',
            gas: 5000000
        },
        gethdev: {
            host: '127.0.0.1',
            port: 8545,
            network_id: '1337',
            gas: 2000000
        },
        docker_boot: {
            host: 'eth-bootstrap',
            port: 8545,
            network_id: '456719',
            gas: 5000000
        }
    }
}
