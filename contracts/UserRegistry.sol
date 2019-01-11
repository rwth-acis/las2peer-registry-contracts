pragma solidity ^0.4.24;


/**
 * User name registry
 *
 * Names are available for free, on a first come first served basis.
 * Names are bytes32 rather than strings, since dynamic-sized keys in
 * mappings aren't supported.
 */
contract UserRegistry {
    event UserRegistered(bytes32 name);
    event UserTransferred(bytes32 name);
    //event UserDeleted(bytes32);

    struct User {
        bytes32 name;
        bytes agentId; // 64 bytes?
        address owner;
    }

    mapping (bytes32 => User) public users;

    modifier onlyOwnName(bytes32 name) {
        require(name != 0, "Empty name is not owned by anyone.");
        require(users[name].owner == msg.sender, "Sender does not own name.");
        // TODO: wait a second, I thought accessing a struct's field from a mapping like that isn't possible!?
        // why does this (seem to) work?
        _;
    }

    function nameIsValid(bytes32 name) public pure returns(bool) {
        return name != 0;
    }

    function nameIsTaken(bytes32 name) public view returns(bool) {
        User storage maybeEmpty = users[name];
        return maybeEmpty.owner != 0;
    }

    // eh, this should have a better name to indicate that available =/= !taken
    function nameIsAvailable(bytes32 name) public view returns(bool) {
        return (nameIsValid(name) && !nameIsTaken(name));
    }

    function register(bytes32 name, bytes agentId) public {
        _register(User(name, agentId, msg.sender, ""));
        emit UserRegistered(name);
    }

    function transfer(bytes32 name, address newOwner) public onlyOwnName(name) {
        users[name].owner = newOwner;
        emit UserTransferred(name);
    }

    function _register(User user) internal {
        require(user.name != 0, "Name must be non-zero.");
        require(user.owner != 0, "Owner address must be non-zero.");

        require(nameIsAvailable(user.name), "Name already taken or invalid.");

        users[user.name] = user;
    }
}
