pragma solidity ^0.4.24;

import "./UserRegistry.sol";


/**
 * Service registry
 */
contract ServiceRegistry {
    UserRegistry userRegistry;

    event Debug(bool);

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
        //debug();
    }

    function _debug() public returns(uint) {
        bool b = userRegistry.debug();
        emit Debug(b);
        if (b) {
            return 42;
        } else {
            return 23;
        }
    }
}
