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
    uint refused;
    address payable public charity = payable(0xaf68dbA1103d206C402187C1AdD55FD94E23Eba5);

    enum Status { NONE, REGISTERED, COMPLETED, CLEARED, PAID, REFUSED }

    mapping(address => Data) public registry;

    struct Data {
        Status status;
        uint encryptedDecision;
        uint key;
        uint decision;
    }
    
    address[] submissions;
        
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
    receive() external payable {}

    function sendMoney(uint reallyDoIt) public payable onlyOwner {
        require(reallyDoIt == 2023, "rejected");
        for(uint i = 0; i < submissions.length; i++) {
            //send the funds to charity
            charity.transfer(registry[submissions[i]].decision * ECU);
            //send the funds to the participant
            payable(submissions[i]).transfer(showUpFee + (amountToAllocateInECU - registry[submissions[i]].decision) * ECU);
            //mark participant as paid
            registry[submissions[i]].status = Status.PAID;
        }
    }   

    function checkPaymentData(uint _n) external view returns (Data memory) { 
            return(registry[submissions[_n]]);
    }
    
    function storePaymentData(
            address[] memory _participants, 
            uint[] memory _keys, 
            uint[] memory _decisions
            ) external {
        require(_participants.length == sessionSize - refused, "length mismatch participants"); 
        require(_keys.length == sessionSize - refused, "length mismatch keys");
        require(_decisions.length == sessionSize - refused, "length mismatch decisions");
        submissions = _participants;
        for(uint i = 0; i < submissions.length; i++) {
            require(
                registry[submissions[i]].status == Status.COMPLETED, 
                "participant not correctly registered or already payed"
                );
            require(
                registry[submissions[i]].key + registry[submissions[i]].decision == registry[submissions[i]].encryptedDecision, 
                "inconsistent data"
                );
            registry[submissions[i]].decision = _decisions[i];
            registry[submissions[i]].key = _keys[i];
            registry[submissions[i]].status = Status.CLEARED;
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
        refused+=1;
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
