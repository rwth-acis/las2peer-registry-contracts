pragma solidity ^0.4.24;

import "./UserRegistry.sol";


/**
 * Service registry
 */
contract ServiceRegistry {
    UserRegistry public userRegistry;

    event ServiceCreated(
        bytes32 indexed nameHash,
        bytes32 indexed author
    );

    event ServiceReleased(
        bytes32 indexed nameHash,
        uint versionMajor,
        uint versionMinor,
        uint versionPatch,
        bytes hash
    );

    event ServiceDeployment(
        bytes32 indexed nameHash,
        string className,
        uint versionMajor,
        uint versionMinor,
        uint versionPatch,
        uint timestamp,
        string nodeId
    );

    event ServiceDeploymentEnd(
        bytes32 indexed nameHash,
        string className,
        uint versionMajor,
        uint versionMinor,
        uint versionPatch,
        string nodeId
    );

    struct Version {
        uint versionMajor;
        uint versionMinor;
        uint versionPatch;
    }

    struct Service {
        string name;
        bytes32 author;
    }

    mapping (bytes32 => Service) public services;
    mapping (bytes32 => Version[]) public serviceVersions;

    modifier onlyRegisteredService(string serviceName) {
        require(services[stringHash(serviceName)].author != 0, "Service must be registered.");
        _;
    }

    modifier nonZero(bytes32 something) {
        require(something != 0, "Whatever this is, it must be non-zero.");
        _;
    }

    modifier nonZeroString(string something) {
        require(stringHash(something) != stringHash(""), "String must be non-zero.");
        _;
    }

    constructor(address userRegistryAddress) public {
        userRegistry = UserRegistry(userRegistryAddress);
    }

    function stringHash(string name) public pure returns(bytes32) {
        return keccak256(abi.encodePacked(name));
    }

    function nameIsAvailable(string serviceName) public view returns(bool) {
        return services[stringHash(serviceName)].author == 0;
    }

    function hashToName(bytes32 hashOfName) public view returns(string) {
        return services[hashOfName].name;
    }

    function register(string serviceName, bytes32 authorName) public {
        require(userRegistry.isOwner(msg.sender, authorName), "Sender must own author name to register service.");
        _register(serviceName, authorName);
    }

    function delegatedRegister(string serviceName, bytes32 authorName, bytes consentSignature) public {
        // first 8 chars of keccak("register(string,bytes32)")
        bytes memory methodId = hex"656afdee";
        bytes memory args = abi.encode(serviceName, authorName);
        address signer = Delegation.checkConsent(methodId, args, consentSignature);

        require(userRegistry.isOwner(signer, authorName), "Signer must own author name to register service.");
        _register(serviceName, authorName);
    }

    function release(
        string serviceName,
        bytes32 authorName,
        uint versionMajor,
        uint versionMinor,
        uint versionPatch,
        bytes hash
    )
        public
    {
        require(userRegistry.isOwner(msg.sender, authorName), "Sender must own author name to release.");
        _release(serviceName, authorName, versionMajor, versionMinor, versionPatch, hash);
    }

    function delegatedRelease(
        string serviceName,
        bytes32 authorName,
        uint versionMajor,
        uint versionMinor,
        uint versionPatch,
        bytes hash,
        bytes consentSignature
    )
        public
    {
        // first 8 chars of keccak("release(string,bytes32,uint,uint,uint,bytes)")
        bytes memory methodId = hex"626efb2d";
        bytes memory args = abi.encode(serviceName, authorName, versionMajor, versionMinor, versionPatch);
        address signer = Delegation.checkConsent(methodId, args, consentSignature);

        require(userRegistry.isOwner(signer, authorName), "Signer must own author name to release.");
        _release(serviceName, authorName, versionMajor, versionMinor, versionPatch, hash);
    }

    function announceDeployment(
        string serviceName,
        string className,
        uint versionMajor,
        uint versionMinor,
        uint versionPatch,
        uint timestamp,
        string nodeId
    )
        public
        onlyRegisteredService(serviceName)
    {
        byte32 nameHash = stringHash(serviceName);
        emit ServiceDeployment(nameHash, className, versionMajor, versionMinor, versionPatch, timestamp, nodeId);
    }

    function announceDeploymentEnd(
        string serviceName,
        string className,
        uint versionMajor,
        uint versionMinor,
        uint versionPatch,
        string nodeId
    )
        public
        onlyRegisteredService(serviceName)
    {
        byte32 nameHash = stringHash(serviceName);
        emit ServiceDeploymentEnd(nameHash, className, versionMajor, versionMinor, versionPatch, nodeId);
    }

    function _register(
        string serviceName,
        bytes32 authorName
    )
    private
    nonZeroString(serviceName)
    nonZero(authorName)
    {
        require(nameIsAvailable(serviceName), "Service name already taken.");
        bytes32 hash = stringHash(serviceName);
        services[hash] = Service(serviceName, authorName);
        emit ServiceCreated(hash, authorName);
    }

    function _release(
        string serviceName,
        bytes32 authorName,
        uint versionMajor,
        uint versionMinor,
        uint versionPatch,
        bytes hash
    )
    private
    nonZeroString(serviceName)
    nonZero(authorName)
    {
        bytes32 nameHash = stringHash(serviceName);
        require(services[nameHash].author == authorName, "Passed author does not own service.");

        serviceVersions[nameHash].push(Version(versionMajor, versionMinor, versionPatch));
        emit ServiceReleased(nameHash, versionMajor, versionMinor, versionPatch, hash);
    }
}
