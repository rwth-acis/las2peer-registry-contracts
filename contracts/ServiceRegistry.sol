pragma solidity ^0.4.24;

import "./UserRegistry.sol";


/**
 * Service registry
 */
contract ServiceRegistry {
    UserRegistry userRegistry;

    event ServiceCreated(
        bytes32 indexed name,
        bytes32 indexed author
    );

    event ServiceReleased(
        bytes32 indexed name,
        uint versionMajor,
        uint versionMinor,
        uint versionPatch
    );

    //mapping (bytes32 => bytes32)

    constructor(address userRegistryAddress) public {
        userRegistry = UserRegistry(userRegistryAddress);
    }

    // DEBUG: yay, this works
    function _test() public view returns(uint) {
        return userRegistry._addOne(23);
    }
}
