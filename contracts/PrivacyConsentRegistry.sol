// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.5.0;

contract PrivacyConsentRegistry {
    struct Consent {
        bytes32 userID;
        bytes32 serviceID;
        bytes32 courseID;
        uint8[] purposes;
        uint8[] purposeVersions;
        uint256 timestamp;
    }
    
    // Mapping UserID -> ServiceID -> CourseID
    mapping(bytes32 => mapping(bytes32 => mapping(bytes32 => Consent))) public consentDatabase;
    
    
    function getConsentInfo(bytes32 userID, bytes32 serviceID, bytes32 courseID)
    	public view returns(uint8[] memory, uint8[] memory, uint256) {
        Consent memory tmp = consentDatabase[userID][serviceID][courseID];
        return (tmp.purposes, tmp.purposeVersions, tmp.timestamp);
    }
    
    function storeConsent(bytes32 userID, bytes32 serviceID, bytes32 courseID,
        uint8[] memory purposes, uint8[] memory purposeVersions
    ) public {
        consentDatabase[userID][serviceID][courseID] = Consent(userID, serviceID, courseID, purposes, purposeVersions, now);
    }
    
}