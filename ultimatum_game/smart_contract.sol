// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.8.0 <0.9.0;

contract UltimatumGame {
    address payable public owner; // owner of contract
    uint public sessionSize; //max amount of participants
    uint public registrations; // current participants
    enum Network { POLYGON, MUMBAI } //POLYGON = 0, MUMBAI = 1 when deploying
    Network network;
    uint public ECU;
    uint public showUpFee;
    uint public amountToAllocateInECU; //amount available to allocate for each individual (in our experiment 10)

    constructor(uint _sessionSize, Network _network, uint _amountToAllocateInECU) {
        owner = payable(msg.sender);
        sessionSize = _sessionSize;
        network = _network;
        amountToAllocateInECU = _amountToAllocateInECU;
        
        if(network == Network.POLYGON) {
            ECU = 1e18;
        } else if(network == Network.MUMBAI) {
            ECU = 1e9;
        }

        showUpFee = ECU / 2;
    }

    //modifier for functions that only the owner is supossed to use
    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }

    enum Status { NONE, REGISTERED, COMPLETED, PAID, REFUSED }

    struct Data {
        Status status;
        uint encryptedDecisionDonate;
        uint encryptedDecisionMin;
        uint decisionDonate;
        uint decisionMin;
        uint key;
    }

    mapping(address => Data) public registry;

    // check status of address
    function isRegistered() external view returns(Status){
        return registry[msg.sender].status;
    }

    // check if there's room left to participate
    function hasFreeParticipantsSlots() external view returns(bool) {
        return registrations < sessionSize;
    }

    function registration() external {
        require(registry[msg.sender].status == Status.NONE, "Encumbered wallet address.");
        require(registrations <= sessionSize, "Maximum number of participants reached.");
        registry[msg.sender].status = Status.REGISTERED;
        registrations++;
    }

    //Saves the decision of the participant
    function recordDecision(uint _encryptedDecisionDonate, uint _encryptedDecisionMin) external {
        //Check if the user is registered
        require(registry[msg.sender].status != Status.NONE, "Wallet not yet registered");
        //Check that the user has not already submitted a decision
        require(registry[msg.sender].status != Status.COMPLETED, "Decision already recorded");
        //Check that the user has not been payed yet
        require(registry[msg.sender].status != Status.PAID, "Wallet already paid");
        //Check that the address is not refused   
        require(registry[msg.sender].status != Status.REFUSED, "Wallet refused");
        //Save the decision
        registry[msg.sender].encryptedDecisionDonate = _encryptedDecisionDonate;
        registry[msg.sender].encryptedDecisionMin = _encryptedDecisionMin;
        //mark them as registered and decision recorded
        registry[msg.sender].status = Status.COMPLETED;
    }

    //Returns the payout for each player based on their decisions
    //assume player1 is the proposer and player2 the respondent, who decides the minimum amount he accepts
    function getPayoff(uint decision1, uint decision2) public view returns(uint payoff1, uint payoff2) {
        if(decision1 >= decision2) {
            return(amountToAllocateInECU - decision1, decision1);
        } else {
            return(uint(0), uint(0));
        }
    }

    //Sends the funds to the participants
    function send_money(address payable player1, uint key1, address payable player2, uint key2) external payable onlyOwner {
        //Check that only participants that are registered, have made a decision and have not been paid yet get paid
        require(registry[player1].status == Status.COMPLETED && registry[player2].status == Status.COMPLETED, "participant not correctly registered or already payed");
        //get the decisions of the randomly matched participants
        registry[player1].decisionDonate = registry[player1].encryptedDecisionDonate - key1;
        registry[player1].decisionMin = registry[player1].encryptedDecisionMin - key1;
        registry[player2].decisionDonate = registry[player2].encryptedDecisionDonate - key2;
        registry[player2].decisionMin = registry[player2].encryptedDecisionMin - key2;
        //store the keys in the registry
        registry[player1].key = key1;
        registry[player2].key = key2;
        //get the payout for each participant
        (uint payoff1, uint payoff2) = getPayoff(registry[player1].decisionDonate, registry[player2].decisionMin);
        //send the funds
        player1.transfer(showUpFee + payoff1 * ECU);
        player2.transfer(showUpFee + payoff2 * ECU);
        //mark them as paid
        registry[player1].status = Status.PAID;
        registry[player2].status = Status.PAID;
    }

    // Accept any incoming amount
    receive () external payable {}

    //The following functions are only callable by the owner of the contract
    //collect all funds
    function endOfExperiment() external onlyOwner {
        selfdestruct(owner);
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
}