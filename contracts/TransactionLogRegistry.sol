pragma solidity ^0.5.0;

contract TransactionLogRegistry {
    struct LogEntry {
        uint256 timestamp;
        bytes32 userId;
        bytes32 source;
        bytes32 operation;
        bytes32 dataHash;
    }

    mapping(bytes32 => LogEntry[]) userToLogEntries;

    function createLogEntry(bytes32 userId, bytes32 source, bytes32 operation, bytes32 dataHash) public {
        _createLogEntry(LogEntry(now, userId, source, operation, dataHash));
    }

     function _createLogEntry(LogEntry memory logEntry) private {
         userToLogEntries[logEntry.userId].push(logEntry);
     }

    function getLogEntries(bytes32 userId) public view returns(uint[] memory) {
        uint[] memory timestamps = new uint[](userToLogEntries[userId].length);
        for (uint i = 0; i < userToLogEntries[userId].length; i++) {
            timestamps[i] = userToLogEntries[userId][i].timestamp;
        }
        return timestamps;
    }

    function getDataHashesForUser(bytes32 userId) public view returns (bytes32[] memory) {
        bytes32[] memory hashes = new bytes32[](userToLogEntries[userId].length);
        for (uint i = 0; i < userToLogEntries[userId].length; i++) {
            hashes[i] = userToLogEntries[userId][i].dataHash;
        }
        return hashes;
    }

}
