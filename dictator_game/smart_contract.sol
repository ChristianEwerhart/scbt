// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.8.0 <0.9.0;

contract Contract {
    //the base unit of the experiment (in Wei)
    uint unitInWei;
    uint showUpFeeInWei;
    address payable owner; // owner of contract
    uint public max_participants; //max amount of participants
    uint public participant_count = 0; // current participants

    //max units per experiment 
    uint maxUnitsPerResponse = 2000;

    //Address of the charity
    address payable charity = payable(0x530DD50cf1fAB292DEe6D91e11FC1d3F4Ba26141);

    constructor(uint _max_participants, bool _testnet) payable {
        max_participants = _max_participants;
        owner = payable(msg.sender);

        if(_testnet) {
            showUpFeeInWei = 500e12;
            unitInWei = 1e12; 
        } else {
            showUpFeeInWei = 500e15;
            unitInWei = 1e15;
        }
        
        require(max_participants * (maxUnitsPerResponse * unitInWei + showUpFeeInWei) <= msg.value, "needs more funds");
    }
    // 0: not registered
    // 1: registered but not payed
    // 2: registered and payed
    mapping(address => int8) public registered;

    // check status of address
    function isRegistered() external view returns(int){
        return registered[msg.sender];
    }

    // check if there's room left to participate
    function hasFreeParticipantsSlots() external view returns(bool) {
        return participant_count < max_participants;
    }
    
    function registration() external {
        require(registered[msg.sender] == 0, "Already registered or ended the experiment.");
        require(participant_count <= max_participants, "Maximum number of participants reached.");
        registered[msg.sender] = 1;
        participant_count++;
        payable(msg.sender).transfer(showUpFeeInWei);
    }

    function send_money(uint _units) external {
        require(registered[msg.sender] == 1, "Not registered or ended the experiment.");
        ///Check if the contract has enough funds (otherwise the experiment has ended)
        require(address(this).balance >= maxUnitsPerResponse * unitInWei, "Experiment has ended!");
        require(_units <= maxUnitsPerResponse,"Invalid value");
        //Send the chosen amount to chatiry
        charity.transfer(_units * unitInWei);
        //Send the rest of the funds to the person that took the survey
        payable(msg.sender).transfer((maxUnitsPerResponse - _units) * unitInWei);
        // set address registration to 2
        registered[msg.sender] = 2;
    }
    //collect all funds
    function endOfExperiment() external  {
        require(msg.sender == owner, "only owner");
        selfdestruct(owner);
        //owner.transfer(address(this).balance);
    }
    // Accept any incoming amount
    receive () external payable {}


}


