const UserRegistryContract = artifacts.require('UserRegistry')
const ServiceRegistryContract = artifacts.require('ServiceRegistry')
const CommunityTagIndexContract = artifacts.require('CommunityTagIndex')

module.exports = function (deployer) {
    // dependent deploy exactly like the example here:
    // https://truffleframework.com/docs/truffle/getting-started/running-migrations#deployer
    deployer.deploy(UserRegistryContract).then(function () {
        return deployer.deploy(ServiceRegistryContract, UserRegistryContract.address)
    })
    deployer.deploy(CommunityTagIndexContract)
}
