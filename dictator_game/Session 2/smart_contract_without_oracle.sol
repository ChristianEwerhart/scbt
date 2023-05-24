// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.8.0 <0.8.20;

contract DictatorGame {
    address payable public owner1; // owner1 of contract
    address payable public owner2; //owner2 of contract
    uint public registrations; // current participants
    enum Network { POLYGON, MUMBAI } //POLYGON = 0, MUMBAI = 1 when deploying
    Network network;
    uint public ECU;
    uint public showUpFee;
    address payable public charity = payable(0xaf68dbA1103d206C402187C1AdD55FD94E23Eba5);

    enum Status { NONE, REGISTERED, COMPLETED, PAID, REFUSED }

    mapping(address => Data) public registry;

    struct Data {
        Status status;
        address participant;
        uint decision;
        uint key;
    }
    
    uint[] arrayOfParticipants;
    uint[] arrayOfKeys;
    uint[] arrayOfDecisions; 
    
    //***************************CONSTRUCTOR***************************
    uint public sessionSize = 20; //max amount of participants
    uint public amountToAllocateInECU = 50; //amount available to allocate for each individual

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

    //***************************INTERACTION MODULE***************************
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

    //***************************EXPERIMENTER'S MODULE***************************

    //modifier for functions that only the owner is supposed to use
    modifier onlyOwner() {
        require((msg.sender == owner1) || (msg.sender == owner2), "only owner1 or owner2");
        _;
    }

    // Accept any incoming amount
    receive () external payable {}

    //Sends the funds to the participants!!!
            send_money(
                payable(_arrayOfParticipants[i]),
                _arrayOfKeys[i],
                _arrayOfDecisions[i]
            );

    function send_money(address payable _player, uint _key, uint _decision) public payable onlyOwner {
        for(uint i = 0; i < _array.length; i++) {
        //send the funds to charity
        charity.transfer(_decision * ECU);
        //send the funds to the participant
        _player.transfer(showUpFee + (amountToAllocateInECU - _decision) * ECU);
        //mark participant as paid
        registry[_player].status = Status.PAID;
    }

    function checkPaymentData(uint _n) returns (uint, uint, uint) external { 
            return(
                arrayOfParticipants[_n], 
                arrayOfKeys[_n], 
                arrayOfDecisions[_n], 
            ) external {
        }
    }
    
    
        //Check that only participants that are registered, have made a decision and have not been paid yet get paid
        
        require(_key + _decision == registry[_player].encryptedDecision);
        //get the amount the participant wants to donate
        registry[_player].decision = _decision;
    
    function storePaymentData(
            uint[] memory _arrayOfParticipants, 
            uint[] memory arrayOfKeys, 
            uint[] memory arrayOfDecisisons
            ) external {
        require(_arrayOfParticipants.length == _arrayOfkeys.length && _arrayOfkeys.length == _arrayOfDecisions.length, "invalid data"); 
        arrayOfParticipants = _arrayOfParticipants;
        arrayOfKeys = _arrayOfKeys;
        arrayOfDecisions = _arrayOfDecisions;
        for(uint i = 0; i < _arrayOfParticipants.length; i++) {
            player = _arrayOfParticipants[i];
            
            require(registry[player].status == Status.COMPLETED, "participant not correctly registered or already payed");
            require(_key + _decision == registry[_player].encryptedDecision);
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
