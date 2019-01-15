const Delegation = artifacts.require('Delegation')
const DelegationExample = artifacts.require('DelegationExample')

module.exports = function (deployer) {
    return deployer.deploy(Delegation).then(function () {
        deployer.link(Delegation, DelegationExample)
        return deployer.deploy(DelegationExample)
    })
}
