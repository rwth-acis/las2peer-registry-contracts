pragma solidity ^0.4.24;

/**
 * User name registry
 *
 * Names are available for free, on a first come first served basis.
 * Names are bytes32 rather than strings, since dynamic-sized keys in
 * mappings aren't supported.
 */
contract UserRegistry {
    event UserRegistered(bytes32);
    event UserDeleted(bytes32);

    struct User {
        bytes32 name;
        bytes agentId; // 64 bytes?
        address account;
        bytes dhtSupplement;
    }

    mapping (bytes32 => User) public users;

    function __test() public {
        register("Tom", 2);
    }

    function nameIsAvailable(bytes32 name) public view returns(bool) {
        // return (users[name] == 0); // not possible since User is a struct
        User storage maybeEmpty = users[name];
        return (maybeEmpty.account == 0);
    }

    function register(bytes32 name, bytes agentId) public {
        _register(User(name, agentId, msg.sender, ""));
    }

    function _register(User user) internal {
        require(user.name != 0);
        require(user.account != 0);

        require(nameIsAvailable(user.name));

        users[user.name] = user;
    }
}
