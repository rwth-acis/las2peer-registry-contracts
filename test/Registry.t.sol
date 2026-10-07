// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {UserRegistry} from "../contracts/UserRegistry.sol";
import {GroupRegistry} from "../contracts/GroupRegistry.sol";
import {ServiceRegistry} from "../contracts/ServiceRegistry.sol";
import {CommunityTagIndex} from "../contracts/CommunityTagIndex.sol";

/// Shared fixtures and the eth_sign-style consent signatures las2peer nodes create for delegated calls.
abstract contract RegistryTest is Test {
    bytes32 constant ALICE = "Alice";
    bytes constant AGENT_ID = hex"1c4421af4d723edc834463c015a5b76ddce4cd679227e963c14941fcef2ee716";
    bytes constant PUBLIC_KEY = "MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCqGKukO1De7zhZj6";

    uint256 alicePk = 0xA11CE;
    address alice = vm.addr(alicePk);
    address relayer = makeAddr("node operator");

    /// Signature as produced by las2peer's SignatureUtils: eth_sign(keccak256(methodId ++ abi.encode(args)))
    function consent(uint256 pk, bytes4 methodId, bytes memory args) internal pure returns (bytes memory) {
        bytes32 dataHash = keccak256(abi.encodePacked(methodId, args));
        bytes32 digest = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", dataHash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(pk, digest);
        return abi.encodePacked(r, s, v);
    }
}

contract UserRegistryTest is RegistryTest {
    UserRegistry users;

    function setUp() public {
        users = new UserRegistry();
    }

    function test_nameValidity() public view {
        assertFalse(users.nameIsValid(bytes32(0)));
        assertTrue(users.nameIsValid(ALICE));
        assertFalse(users.nameIsTaken(ALICE));
    }

    function test_register_emitsEventAndTakesName() public {
        vm.expectEmit(false, false, false, true);
        emit UserRegistry.UserRegistered(ALICE, block.timestamp);
        vm.prank(alice);
        users.register(ALICE, AGENT_ID, PUBLIC_KEY);

        assertTrue(users.nameIsTaken(ALICE));
        assertFalse(users.nameIsAvailable(ALICE));
        assertTrue(users.isOwner(alice, ALICE));
    }

    function test_register_duplicateReverts() public {
        users.register(ALICE, AGENT_ID, PUBLIC_KEY);
        vm.expectRevert();
        users.register(ALICE, AGENT_ID, PUBLIC_KEY);
    }

    function test_transfer() public {
        vm.prank(alice);
        users.register(ALICE, AGENT_ID, PUBLIC_KEY);
        vm.expectEmit(false, false, false, true);
        emit UserRegistry.UserTransferred(ALICE);
        vm.prank(alice);
        users.transfer(ALICE, relayer);
        assertTrue(users.isOwner(relayer, ALICE));
    }

    function test_transfer_onlyOwner() public {
        vm.prank(alice);
        users.register(ALICE, AGENT_ID, PUBLIC_KEY);
        vm.expectRevert();
        vm.prank(relayer);
        users.transfer(ALICE, relayer);
    }

    function test_delegatedRegister_withConsent() public {
        bytes memory sig = consent(alicePk, bytes4(keccak256("register(bytes32,bytes,bytes)")), abi.encode(ALICE, AGENT_ID, PUBLIC_KEY));
        vm.prank(relayer); // the node pays the gas, alice owns the name
        users.delegatedRegister(ALICE, AGENT_ID, PUBLIC_KEY, alice, sig);
        assertTrue(users.isOwner(alice, ALICE));
        assertFalse(users.isOwner(relayer, ALICE));
    }

    function test_delegatedRegister_rejectsWrongSigner() public {
        bytes memory sig = consent(0xB0B, bytes4(keccak256("register(bytes32,bytes,bytes)")), abi.encode(ALICE, AGENT_ID, PUBLIC_KEY));
        vm.expectRevert("Signature does not match claimed signer.");
        users.delegatedRegister(ALICE, AGENT_ID, PUBLIC_KEY, alice, sig);
    }

    function test_delegatedRegister_rejectsTamperedArgs() public {
        bytes memory sig = consent(alicePk, bytes4(keccak256("register(bytes32,bytes,bytes)")), abi.encode(ALICE, AGENT_ID, PUBLIC_KEY));
        vm.expectRevert("Signature does not match claimed signer.");
        users.delegatedRegister(bytes32("Mallory"), AGENT_ID, PUBLIC_KEY, alice, sig);
    }
}

contract GroupRegistryTest is RegistryTest {
    GroupRegistry groups;
    bytes32 constant GROUP = "thesis-group";

    function setUp() public {
        groups = new GroupRegistry();
    }

    function test_register() public {
        vm.prank(alice);
        groups.register(GROUP, AGENT_ID, PUBLIC_KEY);
        assertTrue(groups.nameIsTaken(GROUP));
        assertTrue(groups.isOwner(alice, GROUP));
    }

    function test_delegatedRegister_withConsent() public {
        bytes memory sig = consent(alicePk, bytes4(keccak256("register(bytes32,bytes,bytes)")), abi.encode(GROUP, AGENT_ID, PUBLIC_KEY));
        vm.prank(relayer);
        groups.delegatedRegister(GROUP, AGENT_ID, PUBLIC_KEY, alice, sig);
        assertTrue(groups.isOwner(alice, GROUP));
    }
}

contract CommunityTagIndexTest is Test {
    CommunityTagIndex tags;
    bytes32 constant TAG = "some-tag";

    function setUp() public {
        tags = new CommunityTagIndex();
    }

    function test_createTag() public {
        assertTrue(tags.isAvailable(TAG));
        vm.expectEmit(false, false, false, true);
        emit CommunityTagIndex.CommunityTagCreated(TAG);
        tags.create(TAG, "lorem ipsum dolor sit amet");
        assertFalse(tags.isAvailable(TAG));
        assertEq(tags.viewDescription(TAG), "lorem ipsum dolor sit amet");
    }
}

contract ServiceRegistryTest is RegistryTest {
    UserRegistry users;
    ServiceRegistry services;
    string constant SERVICE = "com.example.services.exampleService";
    bytes constant HASH = hex"50047cbf35f98cb1c7e46c24afa32078";

    function setUp() public {
        users = new UserRegistry();
        services = new ServiceRegistry(address(users));
        vm.prank(alice);
        users.register(ALICE, AGENT_ID, PUBLIC_KEY);
    }

    function test_register_requiresKnownAuthor() public {
        assertTrue(services.nameIsAvailable(SERVICE));
        vm.expectRevert();
        vm.prank(alice);
        services.register(SERVICE, bytes32("nobody"));

        vm.expectEmit(true, false, false, true);
        emit ServiceRegistry.ServiceCreated(keccak256(bytes(SERVICE)), ALICE, block.timestamp);
        vm.prank(alice);
        services.register(SERVICE, ALICE);
        assertFalse(services.nameIsAvailable(SERVICE));
        assertEq(services.hashToName(keccak256(bytes(SERVICE))), SERVICE);
    }

    function test_release_onlyByAuthorOwner() public {
        vm.prank(alice);
        services.register(SERVICE, ALICE);

        vm.expectRevert("Sender must own author name to release.");
        vm.prank(relayer);
        services.release(SERVICE, ALICE, 1, 2, 3, HASH);

        vm.expectEmit(true, false, false, true);
        emit ServiceRegistry.ServiceReleased(keccak256(bytes(SERVICE)), 1, 2, 3, HASH, block.timestamp);
        vm.prank(alice);
        services.release(SERVICE, ALICE, 1, 2, 3, HASH);
    }

    function test_delegatedRegisterAndRelease() public {
        bytes memory regSig = consent(alicePk, bytes4(keccak256("register(string,bytes32)")), abi.encode(SERVICE, ALICE));
        vm.prank(relayer);
        services.delegatedRegister(SERVICE, ALICE, alice, regSig);

        bytes memory relSig = consent(
            alicePk, bytes4(keccak256("release(string,bytes32,uint256,uint256,uint256,bytes)")), abi.encode(SERVICE, ALICE, 1, 0, 0, HASH)
        );
        vm.prank(relayer);
        services.delegatedRelease(SERVICE, ALICE, 1, 0, 0, HASH, alice, relSig);
    }

    function test_announceDeployment() public {
        vm.prank(alice);
        services.register(SERVICE, ALICE);
        bytes32 nameHash = keccak256(bytes(SERVICE));

        vm.expectEmit(true, false, false, true);
        emit ServiceRegistry.ServiceDeployment(nameHash, "ExampleService", 1, 2, 3, "D48D3823", block.timestamp);
        services.announceDeployment(SERVICE, "ExampleService", 1, 2, 3, "D48D3823");

        vm.expectEmit(true, false, false, true);
        emit ServiceRegistry.ServiceDeploymentEnd(nameHash, "ExampleService", 1, 2, 3, "D48D3823", block.timestamp);
        services.announceDeploymentEnd(SERVICE, "ExampleService", 1, 2, 3, "D48D3823");
    }

    function test_announceDeployment_unknownServiceReverts() public {
        vm.expectRevert();
        services.announceDeployment("unknown", "X", 1, 0, 0, "node");
    }
}
