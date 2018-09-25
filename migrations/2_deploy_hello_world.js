const HelloWorldContract = artifacts.require('HelloWorld')

module.exports = function (deployer) {
    deployer.deploy(HelloWorldContract)
}
