// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract TSVoteManager {
    
    bytes32[] imageCids;
    
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
    bytes32[] public labelsVoteList;
    
    /////////////////
    // Events
    /////////////////
    
    event NewVoter(address sender);
    event NewLabelsVote(address sender, bytes32 labelsVoteKey);
    
    /////////////////
    // Public view functions
    /////////////////
    
    function getVoterCount() public view returns(uint voterCount) {
        return voterList.length;
    }
    
    function getLabelsVoteCount() public view returns(uint labelsVoteCount) {
        return labelsVoteList.length;
    }
    
    function isVoter(address _voterAddress) public view returns(bool) {
        if (voterList.length == 0) return false;
        return addresstoVoterStruct[_voterAddress].voterAddress == _voterAddress;
    }
    
    function isLabelsVote(bytes32 _key) public view returns(bool) {
        if (labelsVoteList.length == 0) return false;
        return keyTolabelsVoteStruct[_key].key == _key;
    }
    
    function getVoterLabelVotesCount (address _voterAddress) public view returns(uint labelsVoteCount) {
        require (isVoter(_voterAddress), "No voter exists for this address");
        return addresstoVoterStruct[_voterAddress].labelsVoteKeys.length;
    }
    
    function getVotersLabelsVoteAtIndex (address _voterAddress, uint _row) public view returns(bytes32 key) {
        require (isVoter(_voterAddress), "No voter exists for this address");
        return addresstoVoterStruct[_voterAddress].labelsVoteKeys[_row];
    }
    
    /////////////////
    // State changing functions
    /////////////////
    
    function createVoter() public returns(bool success) {
        require(!isVoter(msg.sender), "Voter already exists");
        addresstoVoterStruct[msg.sender].voterAddress = msg.sender;
        voterList.push(msg.sender);
        emit NewVoter(msg.sender);
        return true;
    }
    
    function createLabelsVote(bytes32 _cid, uint8 _adult, uint8 _suggestive, uint8 _violence, uint8 _disturbing, uint8 _hate) public returns(bool success) {
        require (isVoter(msg.sender), "No voter exists for this address");
        bytes32 key = keccak256(abi.encodePacked(msg.sender, _cid));
        require (!isLabelsVote(key), "Vote already exists for this address");
        keyTolabelsVoteStruct[key] = LabelsVote({
            key: key,
            voter: msg.sender,
            cid: _cid,
            adult: _adult,
            suggestive: _suggestive,
            violence: _violence,
            disturbing: _disturbing,
            hate: _hate
        });
        labelsVoteList.push(key);
        addresstoVoterStruct[msg.sender].labelsVoteKeys.push(key);
        emit NewLabelsVote(msg.sender, key);
        return true;
    }
    
    // TODO - add way to update a vote
}
