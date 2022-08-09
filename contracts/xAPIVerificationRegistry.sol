pragma solidity ^0.5.0;

contract xAPIVerificationRegistry {
    struct LogEntry{
        bytes32 userID;
        bytes32 dataHash;
        uint8 purposeCode;
        uint8 purposeVersion;
        uint256 timestamp;
    }
    
    
    mapping(bytes32 => LogEntry[]) public userToEntries;
    
    function enterLogEntry(
        bytes32 userID,
        bytes32 dataHash,
        uint8 purposeCode,
        uint8 purposeVersion
    ) public {
        LogEntry memory tmp = LogEntry(
            userID, dataHash, purposeCode, purposeVersion, now
        );
        userToEntries[userID].push(tmp);
    }
    
    function enterLogEntries(
        bytes32[] memory userIDs,
        bytes32[] memory dataHashes,
        uint8[] memory purposeCodes,
        uint8[] memory purposeVersions
    ) public {
        for(uint i = 0; i < userIDs.length; i++) {
            LogEntry memory tmp = LogEntry(
                userIDs[i],
                dataHashes[i],
                purposeCodes[i],
                purposeVersions[i],
                now
            );
            userToEntries[userIDs[i]].push(tmp);
        }
    }
    
    function getLogEntries(bytes32 userID) public view
    	returns(bytes32[] memory, uint8[] memory, uint8[] memory, uint[] memory) {
    	    
        uint length = userToEntries[userID].length;
        bytes32[] memory hashes = new bytes32[](length);
        uint8[] memory pCodes = new uint8[](length);
        uint8[] memory pVersions = new uint8[](length); 
       	uint[] memory times = new uint[](length);
       	
        for(uint i = 0; i < length; i++) {
        	hashes[i] = userToEntries[userID][i].dataHash;
        	pCodes[i] = userToEntries[userID][i].purposeCode;
        	pVersions[i] = userToEntries[userID][i].purposeVersion;
        	times[i] = userToEntries[userID][i].timestamp;
        }
        
        return(hashes, pCodes, pVersions, times);
    }
}