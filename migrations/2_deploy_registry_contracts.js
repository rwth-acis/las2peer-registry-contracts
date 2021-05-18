const Delegation = artifacts.require('Delegation')
const UserRegistryContract = artifacts.require('UserRegistry')
const GroupRegistryContract = artifacts.require('GroupRegistry')
const ServiceRegistryContract = artifacts.require('ServiceRegistry')
const ReputationRegistryContract = artifacts.require('ReputationRegistry')
const CommunityTagIndexContract = artifacts.require('CommunityTagIndex')

// no idea which of these returns are necessary, the entire thing is pretty unclear
module.exports = function (deployer) {
    deployer.deploy(CommunityTagIndexContract)

    return deployer.deploy(Delegation).then(function () {
        deployer.link(Delegation, UserRegistryContract)
        deployer.link(Delegation, ServiceRegistryContract)
        deployer.link(Delegation, ReputationRegistryContract)
        deployer.link(Delegation, GroupRegistryContract)
    }).then(function() {
        // dependent deploy exactly like the example here:
        // https://truffleframework.com/docs/truffle/getting-started/running-migrations#deployer
        return deployer.deploy(UserRegistryContract).then( function () {
            return deployer.deploy(ReputationRegistryContract, UserRegistryContract.address)
        });
    }).then(function() {
        return deployer.deploy(UserRegistryContract, {overwrite: false}).then( function () {
            return deployer.deploy(ServiceRegistryContract, UserRegistryContract.address)
        }).then(function() {
            return deployer.deploy(GroupRegistryContract, {overwrite: false}).then( function () {
                return deployer.deploy(ServiceRegistryContract, GroupRegistryContract.address)
            });;
    });
}
