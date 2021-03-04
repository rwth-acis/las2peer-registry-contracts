pragma solidity ^0.5.0;

import "./UserRegistry.sol";


/**
 * Service registry
 */
contract ServiceRegistry {
    UserRegistry public userRegistry;

    event ServiceCreated(
        bytes32 indexed nameHash,
        bytes32 indexed author,
        uint256 timestamp
    );

    event ServiceReleased(
        bytes32 indexed nameHash,
        uint versionMajor,
        uint versionMinor,
        uint versionPatch,
        bytes hash,
        uint256 timestamp
    );

    event ServiceDeployment(
        bytes32 indexed nameHash,
        string className,
        uint versionMajor,
        uint versionMinor,
        uint versionPatch,
        string nodeId,
        uint timestamp
    );

    event ClusterServiceDeployment(
        bytes32 indexed nameHash,
        uint versionMajor,
        uint versionMinor,
        uint versionPatch,
        bytes hash,
        uint timestamp
    );

    event ClusterServiceDeploymentEnd(
        bytes32 indexed nameHash,
        uint versionMajor,
        uint versionMinor,
        uint versionPatch,
        bytes hash,
        uint timestamp
    );

    event ServiceDeploymentEnd(
        bytes32 indexed nameHash,
        string className,
        uint versionMajor,
        uint versionMinor,
        uint versionPatch,
        string nodeId,
        uint256 timestamp
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

    modifier onlyRegisteredService(string memory serviceName) {
        require(services[stringHash(serviceName)].author != 0, "Service must be registered.");
        _;
    }

    modifier nonZero(bytes32 something) {
        require(something != 0, "Whatever this is, it must be non-zero.");
        _;
    }

    modifier nonZeroString(string memory something) {
        require(stringHash(something) != stringHash(""), "String must be non-zero.");
        _;
    }

    constructor(address userRegistryAddress) public {
        userRegistry = UserRegistry(userRegistryAddress);
    }

    function stringHash(string memory name) public pure returns(bytes32) {
        return keccak256(abi.encodePacked(name));
    }

    function nameIsAvailable(string memory serviceName) public view returns(bool) {
        return services[stringHash(serviceName)].author == 0;
    }

    function hashToName(bytes32 hashOfName) public view returns(string memory) {
        return services[hashOfName].name;
    }

    function register(string memory serviceName, bytes32 authorName) public {
        require(userRegistry.isOwner(msg.sender, authorName), "Sender must own author name to register service.");
        _register(serviceName, authorName);
    }

    function delegatedRegister(string memory serviceName, bytes32 authorName, address consentee, bytes memory consentSignature) public {
        // first 8 chars of keccak("register(string,bytes32)")
        bytes memory methodId = hex"656afdee";
        bytes memory args = abi.encode(serviceName, authorName);
        Delegation.checkConsent(methodId, args, consentee, consentSignature);

        require(userRegistry.isOwner(consentee, authorName), "Signer must own author name to register service.");
        _register(serviceName, authorName);
    }

    function release(
        string memory serviceName,
        bytes32 authorName,
        uint versionMajor,
        uint versionMinor,
        uint versionPatch,
        bytes memory hash
    )
        public
    {
        require(userRegistry.isOwner(msg.sender, authorName), "Sender must own author name to release.");
        _release(serviceName, authorName, versionMajor, versionMinor, versionPatch, hash);
    }

    function delegatedRelease(
        string memory serviceName,
        bytes32 authorName,
        uint versionMajor,
        uint versionMinor,
        uint versionPatch,
        bytes memory hash,
        address consentee,
        bytes memory consentSignature
    )
        public
    {
        // first 8 chars of keccak("release(string,bytes32,uint256,uint256,uint256,bytes)")
        bytes memory methodId = hex"e1930700";
        bytes memory args = abi.encode(serviceName, authorName, versionMajor, versionMinor, versionPatch, hash);
        Delegation.checkConsent(methodId, args, consentee, consentSignature);

        require(userRegistry.isOwner(consentee, authorName), "Signer must own author name to release.");
        _release(serviceName, authorName, versionMajor, versionMinor, versionPatch, hash);
    }

    function announceDeployment(
        string memory serviceName,
        string memory className,
        uint versionMajor,
        uint versionMinor,
        uint versionPatch,
        string memory nodeId
    )
        public
        onlyRegisteredService(serviceName)
    {
        bytes32 nameHash = stringHash(serviceName);
        emit ServiceDeployment(nameHash, className, versionMajor, versionMinor, versionPatch, nodeId, now);
    }

    function announceClusterDeployment(
        string memory serviceName,
        uint versionMajor,
        uint versionMinor,
        uint versionPatch,
        bytes memory hash
    )
        public
        onlyRegisteredService(serviceName)
    {
        bytes32 nameHash = stringHash(serviceName);
        emit ClusterServiceDeployment(nameHash, versionMajor, versionMinor, versionPatch, hash, now);
    }

    function announceClusterDeploymentEnd(
        string memory serviceName,
        uint versionMajor,
        uint versionMinor,
        uint versionPatch,
        bytes memory hash
    )
        public
        onlyRegisteredService(serviceName)
    {
        bytes32 nameHash = stringHash(serviceName);
        emit ClusterServiceDeploymentEnd(nameHash, versionMajor, versionMinor, versionPatch, hash, now);
    }

    function announceDeploymentEnd(
        string memory serviceName,
        string memory className,
        uint versionMajor,
        uint versionMinor,
        uint versionPatch,
        string memory nodeId
    )
        public
        onlyRegisteredService(serviceName)
    {
        bytes32 nameHash = stringHash(serviceName);
        emit ServiceDeploymentEnd(nameHash, className, versionMajor, versionMinor, versionPatch, nodeId, now);
    }

    function _register(
        string memory serviceName,
        bytes32 authorName
    )
    private
    nonZeroString(serviceName)
    nonZero(authorName)
    {
        require(nameIsAvailable(serviceName), "Service name already taken.");
        bytes32 hash = stringHash(serviceName);
        services[hash] = Service(serviceName, authorName);
        emit ServiceCreated(hash, authorName, now);
    }

    function _release(
        string memory serviceName,
        bytes32 authorName,
        uint versionMajor,
        uint versionMinor,
        uint versionPatch,
        bytes memory hash
    )
    private
    nonZeroString(serviceName)
    nonZero(authorName)
    {
        bytes32 nameHash = stringHash(serviceName);
        require(services[nameHash].author == authorName, "Passed author does not own service.");

        serviceVersions[nameHash].push(Version(versionMajor, versionMinor, versionPatch));
        emit ServiceReleased(nameHash, versionMajor, versionMinor, versionPatch, hash, now);
    }
}
