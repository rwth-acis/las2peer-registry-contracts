pragma solidity ^0.5.0;

import { Delegation } from "./Delegation.sol";

contract ConsentRegistry {
    struct Consent {
        address owner;
        uint256 timestamp;
        bytes32 userId;
        uint8[] consentLevels;
    }

    // Mapping from user's ID to user's consent
    mapping(bytes32 => Consent) userConsent;

    function hasStoredConsent(bytes32 userId) public view returns(bool){
        Consent storage potentialConsent = userConsent[userId];
        return potentialConsent.owner != address(0);
    }

    function storeConsent(bytes32 userId, uint8[] memory consentLevels) public {
        if (!hasStoredConsent(userId)) {
            _createConsent(Consent(msg.sender, now, userId, consentLevels));
        }
    }

    function _createConsent(Consent memory consent) private {
        userConsent[consent.userId] = consent;
    }

    function getUserConsentLevels(bytes32 userId) public view returns(uint8[] memory) {
        return userConsent[userId].consentLevels;
    }

    function getConsent(bytes32 userId) public view returns(address, uint256, bytes32, uint8[] memory) {
        Consent memory consent = userConsent[userId];
        return (consent.owner, consent.timestamp, consent.userId, consent.consentLevels);
    }

    function delegatedStoreConsent(
        bytes32 userId,
        uint8[] memory consentLevels,
        address consentee,
        bytes memory signature
    )
    public {
        // first 8 chars of keccak("setConsent(bytes32,uint8[])")
        bytes memory methodId = hex"c73c4234";
        bytes memory args = abi.encode(userId, consentLevels);
        Delegation.checkConsent(methodId, args, consentee, signature);

        if (!hasStoredConsent(userId)) {
            _createConsent(Consent(consentee, now, userId, consentLevels));
        }
    }
}
