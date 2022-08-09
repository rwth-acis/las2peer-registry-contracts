//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.5.0;

contract DataProcessingPurposes {
    struct Purpose {
        uint8 id;
        string title;
        string description;
        uint16 version;
    }
        
    mapping (uint8 => Purpose) public purposeList;
    uint8[] public purposeIDs;
/*     
    function getAllPurposes() public view returns(
        	uint8[] memory,
        	string[] memory,
        	string[] memory,
        	uint16[] memory
    ) {
        uint8[] memory ids = new uint8[](purposeIDs.length);
        string[] memory titles = new string[](purposeIDs.length);
        string[] memory descs = new string[](purposeIDs.length);
        uint16[] memory vers = new uint16[](purposeIDs.length);
        
        for (uint i = 0; i < purposeIDs.length; i++) {
           ids[i] = purposeList[purposeIDs[i]].id;
           titles[i] = purposeList[purposeIDs[i]].title;
           descs[i] = purposeList[purposeIDs[i]].description;
           vers[i] = purposeList[purposeIDs[i]].version;
        }
        
        return (ids, titles, descs, vers);
    }
   */ 
    function getPurpose(uint8 purposeID) public view returns(
        string memory, string memory, uint16
    ) {
        Purpose memory tmp = purposeList[purposeID];
        return(tmp.title, tmp.description, tmp.version);
    }
    
    function getAllPurposeIDs() public view returns(
        uint8[] memory
    ) {
        return purposeIDs;
    }
    
    function createOrModifyPurpose(
        uint8 id,
        string memory title,
        string memory description
    ) public returns(uint16) {
        uint8 index;
        for (index = 0; index < purposeIDs.length; index++) {
            if(purposeIDs[index] == id) {
                break;
            }
        }
        if (index == purposeIDs.length) {
        	purposeIDs.push(id);    
        }
        
        Purpose memory purpose = purposeList[id];
        purpose.id = id; //this is if it doesn't yet exist
        purpose.title = title;
        purpose.description = description;
        purpose.version += 1;
        purposeList[id] = purpose;  
        return purpose.version;        
    }
}
