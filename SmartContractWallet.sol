//SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

contract SmartContractWallet {
    address payable owner;
    mapping(address => uint) public allowance;
    mapping(address => bool) public isAllowedToSend;
    address[] public guardians;

    mapping(address => uint) public newOwnerVoteTracker;
    mapping(address => bool) public guardianAlreadyVoted;
    uint public constant confirmationsFromGuardiansForReset = 3;

    constructor() {
        owner = payable(msg.sender);
    }

    function proposeNewOwner(address payable _newOwner) public {
        require(isGuardian(msg.sender), "You are not a guardian, you can't vote. Aborting");
        require(guardians.length > 3, "Less than three guardians. We don't have a quorum. Aborting");
        require(guardianAlreadyVoted[msg.sender] == false, "You already voted. Aborting");

        newOwnerVoteTracker[_newOwner] += 1;
        guardianAlreadyVoted[msg.sender] = true;

        if (newOwnerVoteTracker[_newOwner] >= confirmationsFromGuardiansForReset) {
            owner = _newOwner;
            resetGuardianVote();
        }

        bool reset_vote = false;
        for (uint i = 0; i < guardians.length; i++) {
            reset_vote = guardianAlreadyVoted[guardians[i]];
        }
        if (reset_vote == true) {
            resetGuardianVote();
        }
    }

    function addGuardian(address _guardian) public {
        require(msg.sender == owner, "You are not the owner so you can't add guardian. Aborting");
        require(guardians.length <= 5, "There can be at most 5 guardians. Pleae remove one before adding");
        if (isGuardian(_guardian) != true) {
            guardians.push(_guardian);
        }
    }

    function removeGuardian(address _guardian) public {
        require(msg.sender == owner, "You are not the owner so you can't remove guardian. Aborting");
        for (uint i = 0; i < guardians.length; i++) {
            if (_guardian == guardians[i]) {
                guardians[i] = guardians[guardians.length - 1];
                guardians.pop();
            }
        }
    }

    function listGuardians() public view returns (address[] memory) {
        return guardians;
    }

    function isGuardian(address _caller) private view returns (bool) {
        bool is_guardian = false;
        for (uint i = 0; i < guardians.length; i++) {
            if (_caller == guardians[i]) {
                is_guardian = true;
            }
        }
        return is_guardian;
    }

    function resetGuardianVote() private {
        for (uint i = 0; i < guardians.length; i++){
            guardianAlreadyVoted[guardians[i]] = false;
        }
    }

    function setAllowance(address _for, uint _amount) public {
        require(msg.sender == owner, "You are not the owner so you can't set allowance. Aborting");
        allowance[_for] = _amount;
        if (_amount > 0) {
            isAllowedToSend[_for] = true;
        } else {
            isAllowedToSend[_for] = false;
        }
    }

    function transfer(address payable _to, uint _amount, bytes memory _payload) public returns (bytes memory){
        if (msg.sender != owner) {
            require(isAllowedToSend[msg.sender], "You are not allowed to send anything. Aborting");
            require(allowance[msg.sender] >= _amount, "You are trying to send more than you can. Aborting");
            allowance[msg.sender] -= _amount;
        }
        (bool success, bytes memory returnData) = _to.call{value: _amount}(_payload);
        require(success, "Aborting, call was not successful");
        return returnData;
    }

    receive() external payable {}
}