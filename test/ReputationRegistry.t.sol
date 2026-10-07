// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {UserRegistry} from "../contracts/UserRegistry.sol";
import {ReputationRegistry} from "../contracts/ReputationRegistry.sol";

contract ReputationRegistryTest is Test {
    UserRegistry users;
    ReputationRegistry reputation;
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    address carol = makeAddr("carol");
    uint256 constant TIMESTAMP = 1_600_000_000;

    function setUp() public {
        users = new UserRegistry();
        reputation = new ReputationRegistry(address(users));
    }

    function enroll() internal {
        vm.prank(alice);
        reputation.createProfile(alice, "Alice");
        vm.prank(bob);
        reputation.createProfile(bob, "Bob");
    }

    function test_createProfile() public {
        vm.expectEmit(true, false, false, true);
        emit ReputationRegistry.UserProfileCreated("Alice", alice);
        vm.prank(alice);
        reputation.createProfile(alice, "Alice");

        assertTrue(reputation.hasProfile(alice));
        assertEq(reputation.getCumulativeScore(alice), 0);
        assertEq(reputation.getNoTransactionsSent(alice), 0);
        assertEq(reputation.getNoTransactionsReceived(alice), 0);
    }

    function test_createProfile_twiceReverts() public {
        reputation.createProfile(alice, "Alice");
        vm.expectRevert("profile already exists");
        reputation.createProfile(alice, "Alice");
    }

    /// Known gap since cb267ed (2020): the owner is a parameter, not msg.sender, so anyone can
    /// create a profile for any address. las2peer only sends it from the agent's own account.
    function test_createProfile_forSomeoneElse_isNotPrevented() public {
        vm.prank(carol);
        reputation.createProfile(alice, "Alice");
        assertTrue(reputation.hasProfile(alice));
    }

    function test_rating_updatesScoresAndCounters() public {
        enroll();
        vm.expectEmit(true, true, true, true);
        emit ReputationRegistry.TransactionAdded(alice, bob, TIMESTAMP, 3, 3);
        vm.prank(alice);
        reputation.addTransaction(bob, 3, TIMESTAMP);

        assertEq(reputation.getCumulativeScore(alice), 0);
        assertEq(reputation.getCumulativeScore(bob), 3);
        assertEq(reputation.getNoTransactionsSent(alice), 1);
        assertEq(reputation.getNoTransactionsReceived(bob), 1);

        vm.prank(alice);
        reputation.addTransaction(bob, 0, TIMESTAMP + 1);
        assertEq(reputation.getCumulativeScore(bob), 3);
        assertEq(reputation.getNoTransactionsReceived(bob), 2);
    }

    function test_rating_rejectsSelf() public {
        enroll();
        vm.expectRevert("Cannot rate yourself");
        vm.prank(alice);
        reputation.addTransaction(alice, 3, TIMESTAMP);
    }

    function test_rating_requiresProfiles() public {
        vm.prank(bob);
        reputation.createProfile(bob, "Bob");
        vm.expectRevert("sender profile unknown");
        vm.prank(carol);
        reputation.addTransaction(bob, 3, TIMESTAMP);
    }

    function testFuzz_rating_outsideRangeReverts(int256 amount) public {
        vm.assume(amount < 0 || amount > 5);
        enroll();
        vm.expectRevert("Rating must be an int between __amountMin and __amountMax");
        vm.prank(alice);
        reputation.addTransaction(bob, amount, TIMESTAMP);
    }
}
