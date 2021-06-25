// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.1.0/contracts/access/Ownable.sol";

contract TSVoteManager is Ownable {
    
    /////////////////
    // Domain objects
    /////////////////
    
    // Represents a user/voter. Linked to a single wallet address.
    struct Voter {
        address voterAddress;
        bytes32[] labelsVoteKeys;
    }
    
    mapping(address => Voter) public addresstoVoterStruct;
    address[] public voterList;
    
    // Represents a user's votes on a single image.
    // Each label is given confidence score between 0 and 100 where
    // 0 = certainty label should not be applied,
    // 100 = certainty label should be applied,
    // 50 = unsure / too subjective
    struct LabelsVote {
        bytes32 key; // keccak256 hash of (voter address, cid)
        address voter;
        bytes32 cid;
        uint8 adult;
        uint8 suggestive;
        uint8 violence;
        uint8 disturbing;
        uint8 hate;
    }
    
    mapping(bytes32 => LabelsVote) public keyTolabelsVoteStruct;
    mapping(bytes32 => uint) public cidLabelsVotesCount; 
    bytes32[] public labelsVoteList;
    
    struct LabelsVoteInput {
        bytes32 cid;
        uint8 adult;
        uint8 suggestive;
        uint8 violence;
        uint8 disturbing;
        uint8 hate;
    }
        
    /////////////////
    // Events
    /////////////////
    
    event NewVoter(address sender);
    event NewLabelsVote(address sender, bytes32 labelsVoteKey);
    event UpdatedLabelsVote(address sender, bytes32 labelsVoteKey);
    
    /////////////////
    // Public view functions
    /////////////////
    
    function getVoterCount() external view returns(uint voterCount) {
        return voterList.length;
    }
    
    function getLabelsVoteCount() external view returns(uint labelsVoteCount) {
        return labelsVoteList.length;
    }
    
    function isVoter(address _voterAddress) public view returns(bool) {
        return _voterAddress != address(0) && addresstoVoterStruct[_voterAddress].voterAddress == _voterAddress;
    }
    
    function isLabelsVote(bytes32 _key) public view returns(bool) {
        if (keyTolabelsVoteStruct[_key].key == 0) {
            return false;
        }
        return keyTolabelsVoteStruct[_key].key == _key;
    }
    
    function getVoterLabelsVoteCount (address _voterAddress) external view returns(uint labelsVoteCount, bool error) {        
        if (addresstoVoterStruct[_voterAddress].voterAddress == address(0)) {
            return (0, true);
        }
        return (addresstoVoterStruct[_voterAddress].labelsVoteKeys.length, false);
    }
    
    function getVotersLabelsVoteAtIndex (address _voterAddress, uint _row) external view returns(bytes32 key) {
        if (addresstoVoterStruct[_voterAddress].voterAddress == address(0)) {
            return 0;
        }
        return addresstoVoterStruct[_voterAddress].labelsVoteKeys[_row];
    }

    function getLabelsVoteKeys (bytes32 _cid) external view returns(bytes32[] memory keys) {
        bytes32[] memory labelsVoteKeys = new bytes32[](cidLabelsVotesCount[_cid]);
        uint counter = 0;
        for (uint i = 0; i < labelsVoteList.length; i++) {
            if (keyTolabelsVoteStruct[labelsVoteList[i]].cid == _cid) {
                labelsVoteKeys[counter] = labelsVoteList[counter];
                counter++;
            }
        }
        return labelsVoteKeys;
    }
    
    /////////////////
    // State changing functions
    /////////////////
        
    function createVoter() external returns(bool success) {
        require(!isVoter(msg.sender), "Voter already exists");
        addresstoVoterStruct[msg.sender].voterAddress = msg.sender;
        voterList.push(msg.sender);
        emit NewVoter(msg.sender);
        return true;
    }
    
    function createLabelsVotes(LabelsVoteInput[] memory _labelsVoteInputs) external returns(bool success) {
        require (isVoter(msg.sender), "No voter exists for this address");
        for (uint i = 0; i < _labelsVoteInputs.length; i++) {
            bytes32 key = keccak256(abi.encodePacked(msg.sender, _labelsVoteInputs[i].cid));
            bool isExistingVote = isLabelsVote(key);
            keyTolabelsVoteStruct[key] = LabelsVote({
                    key: key,
                    voter: msg.sender,
                    cid: _labelsVoteInputs[i].cid,
                    adult: _labelsVoteInputs[i].adult,
                    suggestive: _labelsVoteInputs[i].suggestive,
                    violence: _labelsVoteInputs[i].violence,
                    disturbing: _labelsVoteInputs[i].disturbing,
                    hate: _labelsVoteInputs[i].hate
                });
            if (!isExistingVote) {
                labelsVoteList.push(key);
                cidLabelsVotesCount[_labelsVoteInputs[i].cid]++;
                addresstoVoterStruct[msg.sender].labelsVoteKeys.push(key);
                emit NewLabelsVote(msg.sender, key);
            }
            else {
                emit UpdatedLabelsVote(msg.sender, key);
            }
        }
        return true;
    }
}
