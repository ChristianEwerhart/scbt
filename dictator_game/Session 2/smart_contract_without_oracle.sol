// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.8.0 <0.9.0;

contract DictatorGame {
    address payable public owner1; // owner1 of contract
    address payable public owner2; //owner2 of contract
    uint public registrations; // current participants
    enum Network { POLYGON, MUMBAI } //POLYGON = 0, MUMBAI = 1 when deploying
    Network network;
    uint public ECU;
    uint public showUpFee;
    address payable public charity = payable(0xaf68dbA1103d206C402187C1AdD55FD94E23Eba5);

    uint public sessionSize = 20; //max amount of participants
    uint public amountToAllocateInECU = 50; //amount available to allocate for each individual

    enum Status { NONE, REGISTERED, COMPLETED, PAID, REFUSED }

    struct Data {
        Status status;
        uint decision;
        uint encryptedDecision;
    }

    mapping(address => Data) public registry;

    struct PaymentData {
        address participant;
        uint decision;
        uint key;
    }

    constructor(Network _network, address _owner2) {
        require(msg.sender != _owner2, "owner1 must differ from owner2");
        require((_network == Network.POLYGON) || (_network == Network.MUMBAI));
        owner1 = payable(msg.sender);
        owner2 = payable(_owner2);
        network = _network;
        
        if(network == Network.POLYGON) {
            ECU = 1e17;
        } else if(network == Network.MUMBAI) {
            ECU = 1e9;
        }

        showUpFee = ECU / 2;
    }

    //INTERACTION MODULE
    function registration() external {
        require(registry[msg.sender].status == Status.NONE, "Encumbered wallet address.");
        require(registrations <= sessionSize, "Maximum number of participants reached.");
        registry[msg.sender].status = Status.REGISTERED;
        registrations++;
    }

    //Saves the decision of the participant
    function recordDecision(uint _encryptedDecision) payable external {
        //Check if the user is registered
        require(registry[msg.sender].status != Status.NONE, "Wallet not yet registered");
        //Check that the user has not already submitted a decision
        require(registry[msg.sender].status != Status.COMPLETED, "Decision already recorded");
        //Check that the user has not been payed yet
        require(registry[msg.sender].status != Status.PAID, "Wallet already paid");
        //Check that the address is not refused   
        require(registry[msg.sender].status != Status.REFUSED, "Wallet refused");
        //Save the decision
        require(msg.value == _encryptedDecision, "value must not be modified");
        registry[msg.sender].encryptedDecision = _encryptedDecision;
        //mark them as registered and decision recorded
        registry[msg.sender].status = Status.COMPLETED;
    }

    // check status of address
    function isRegistered() external view returns(Status){
        return registry[msg.sender].status;
    }

    // check if there's room left to participate
    function hasFreeParticipantsSlots() external view returns(bool) {
        return registrations < sessionSize;
    }

    //EXPERIMENTER'S MODULE

    //modifier for functions that only the owner is supossed to use
    modifier onlyOwner() {
        require((msg.sender == owner1) || (msg.sender == owner2), "only owner1 or owner2");
        _;
    }

    // Accept any incoming amount
    receive () external payable {}

    //Sends the funds to the participants
    function send_money(address payable _player, uint _key, uint _decision) public payable onlyOwner {
        //Check that only participants that are registered, have made a decision and have not been paid yet get paid
        require(registry[_player].status == Status.COMPLETED, "participant not correctly registered or already payed");
        require(_key + _decision == registry[_player].encryptedDecision);
        //get the amount the participant wants to donate
        registry[_player].decision = _decision;
        //send the funds to charity
        charity.transfer(_decision * ECU);
        //send the funds to the participant
        _player.transfer(showUpFee + (amountToAllocateInECU - _decision) * ECU);
        //mark participant as paid
        registry[_player].status = Status.PAID;
    }

    function sendMoneyForN(PaymentData[] calldata _array) external {
        for(uint i = 0; i < _array.length; i++) {
            send_money(
                payable(_array[i].participant),
                _array[i].key,
                _array[i].decision
            );
        }
    }

    //function to increase the session size
    function increaseSessionSizeBy(uint n) external onlyOwner {
        sessionSize += n;
    }

    function refuseParticipant(address _participant) external onlyOwner {
        registry[_participant].status = Status.REFUSED;
        //increase the session size by 1
        sessionSize += 1;
    }

    //Change the owner
    function changeOwner(address _newOwner) external onlyOwner {
        if(msg.sender == owner1) {
            owner2 = payable(_newOwner);
        } else if(msg.sender == owner2) {
            owner1 = payable(_newOwner);
        }
    }

    function endOfExperiment() external onlyOwner {
        selfdestruct(payable(msg.sender));
    }
}