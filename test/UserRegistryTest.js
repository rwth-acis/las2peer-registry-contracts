require('./support/setup.js')

const UserRegistryContract = artifacts.require('HelloWorld')

contract('UserRegistryContract', accounts => {
    beforeEach(async () => {
        let instance = await UserRegistryContract.deployed()
        this.i = instance
    })
})
