var Delegation = artifacts.require('Delegation')
var UserRegistryContract = artifacts.require('UserRegistry')
var ServiceRegistryContract = artifacts.require('ServiceRegistry')
var CommunityTagIndexContract = artifacts.require('CommunityTagIndex')

module.exports = function (deployer) {
    deployer.deploy(Delegation).then(function () {
        deployer.link(Delegation, UserRegistryContract)
        deployer.link(Delegation, ServiceRegistryContract)
        // dependent deploy exactly like the example here:
        // https://truffleframework.com/docs/truffle/getting-started/running-migrations#deployer
        deployer.deploy(UserRegistryContract).then(function () {
            return deployer.deploy(ServiceRegistryContract, UserRegistryContract.address)
        })
        deployer.deploy(CommunityTagIndexContract)
    })
}
