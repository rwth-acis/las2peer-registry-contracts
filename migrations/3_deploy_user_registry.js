var UserRegistryContract = artifacts.require('UserRegistry')

module.exports = function (deployer) {
    deployer.deploy(UserRegistryContract)
}
