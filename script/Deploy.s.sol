// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {CommunityTagIndex} from "../contracts/CommunityTagIndex.sol";
import {UserRegistry} from "../contracts/UserRegistry.sol";
import {GroupRegistry} from "../contracts/GroupRegistry.sol";
import {ServiceRegistry} from "../contracts/ServiceRegistry.sol";
import {ReputationRegistry} from "../contracts/ReputationRegistry.sol";
import {PrivacyConsentRegistry} from "../contracts/PrivacyConsentRegistry.sol";
import {DataProcessingPurposes} from "../contracts/DataProcessingPurposes.sol";
import {xAPIVerificationRegistry} from "../contracts/xAPIVerificationRegistry.sol";

/// Deploys the las2peer registry and writes deployments/registry.properties, the
/// i5.las2peer.registry.data.RegistryConfiguration file a node reads from etc/.
///   forge script script/Deploy.s.sol --rpc-url $RPC --private-key $KEY --broadcast
/// ENDPOINT (required): the RPC URL as seen by the las2peer node.
contract Deploy is Script {
    function run() external {
        vm.startBroadcast();
        CommunityTagIndex tags = new CommunityTagIndex();
        UserRegistry users = new UserRegistry();
        ReputationRegistry reputation = new ReputationRegistry(address(users));
        ServiceRegistry services = new ServiceRegistry(address(users));
        GroupRegistry groups = new GroupRegistry();
        // used by MobSOS privacy services, not by the node itself
        new PrivacyConsentRegistry();
        new DataProcessingPurposes();
        new xAPIVerificationRegistry();
        vm.stopBroadcast();

        string memory endpoint = vm.envString("ENDPOINT");
        string memory config = string.concat(
            "endpoint = ", endpoint, "\n",
            "gasPrice = ", vm.envOr("GAS_PRICE", string("20000000000")), "\n",
            "gasLimit = ", vm.envOr("GAS_LIMIT", string("6721975")), "\n",
            "communityTagIndexAddress = ", vm.toString(address(tags)), "\n",
            "userRegistryAddress = ", vm.toString(address(users)), "\n",
            "groupRegistryAddress = ", vm.toString(address(groups)), "\n",
            "serviceRegistryAddress = ", vm.toString(address(services)), "\n",
            "reputationRegistryAddress = ", vm.toString(address(reputation)), "\n"
        );
        vm.writeFile("deployments/registry.properties", config);
        console.log(config);
    }
}
