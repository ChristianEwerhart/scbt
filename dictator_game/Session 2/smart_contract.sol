// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.8.0 <0.9.0;

// Dictator Game With Oracle Functionality
// Smart Contracts Lab, University of Zurich, May 2023

import "https://github.com/BlockchainPresence/Receiver-Tools/blob/main/BCP_informed.sol";

contract PDwithOracle is BCP_informed {

//************************** Declarations ************************

    // Polygon address of the registered UK charity "Last Night a DJ saved my life"
    address payable charity = payable(0x530DD50cf1fAB292DEe6D91e11FC1d3F4Ba26141);
    // oracle address on Mumbai only!
    address payable constant bcpAddress =
        payable(0xD200F64cEcc8bBc1292c0187F5ee6cD7bDf1eeac); 
    // store wallet addresses of completed submissions
    address[] public submissions;

    uint public registrations; // current number of registrations
    uint public lowestUnpaid; // lowest index of unpaid participant
    uint40 constant gasForMailbox = 210000; // must be raised for more complex applications
    uint public transactionCosts;
    
    enum Status { NONE, REGISTERED, COMPLETED, PAID, REFUSED }

    struct participantData {
        Status status;
        bytes32 submissionID;
        uint key;
        uint decision;
    }
    
    // store participant data for each wallet address
    mapping(address => participantData) public registry;
    mapping(uint => address) public participantFromOrderID;

    
//************************** Constructor Module ************************

    enum Network { POLYGON, MUMBAI } //POLYGON = 0, MUMBAI = 1 when deploying
    Network network;  

    address payable public owner; 
    uint public ECU;
    uint public showUpFee;
    int64 commitmentID;
    uint public sessionSize; // max number of participants (including refused)
    uint64 gasPriceInGwei; 
    
    constructor(Network _network) payable BCP_informed(bcpAddress) {
        owner = payable(msg.sender);
        require((_network == Network.POLYGON) || (_network == Network.MUMBAI));
        if(_network == Network.POLYGON) { 
            ECU = 1e17;  // 0.1 MATIC
        } else if (_network == Network.MUMBAI) { 
            ECU = 1e9; // 1 Gwei
        }
        showUpFee = 5*ECU;  // Adjust as appropriate in the mainnet
        commitmentID = 2; // Change to match oracle 
        sessionSize = 20; 
        gasPriceInGwei = 200; // Check gas prices 
    }
      
//************************** Qualtrics Module ************************

    function hasFreeParticipantsSlots() external view returns(bool) {
        return (registrations < sessionSize);
    }
    
    function registration() external {
        require(registry[msg.sender].status == Status.NONE, "Encumbered wallet address.");
        require(registrations <= sessionSize, "Maximum number of participants reached.");
        registry[msg.sender].status = Status.REGISTERED;
        registrations++;
    }

    function isRegistered() external view returns(Status){
        return registry[msg.sender].status;
    }

    function recordDecision(bytes32 _submissionID) external {
        //Check if the user is registered
        require(registry[msg.sender].status != Status.NONE, "Wallet not yet registered");
        //Check that the user has not already submitted a decision
        require(registry[msg.sender].status != Status.COMPLETED, "Decision already recorded");
        //Check that the user has not been payed yet
        require(registry[msg.sender].status != Status.PAID, "Wallet already paid");
        //Check that the address is not refused   
        require(registry[msg.sender].status != Status.REFUSED, "Wallet refused");
        //Save the decision
        registry[msg.sender].submissionID = _submissionID;
        //mark them as registered and decision recorded
        registry[msg.sender].status = Status.COMPLETED;
    }

//************************** Experimenter's Module ************************
      
    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }
    
    function increaseSessionSizeBy(uint n) external onlyOwner {
        sessionSize += n;
    }

    function changeGas(uint64 _gasPriceInGwei) external onlyOwner {
        gasPriceInGwei = _gasPriceInGwei;
    }

    function refuseParticipant(address _participant) external onlyOwner {
        registry[_participant].status = Status.REFUSED;
        sessionSize += 1;
    }

    fallback() override external payable {}

    receive () override external payable {}

    // make payments for the next m submissions
    function send_money(uint _m) external payable onlyOwner {
        transactionCosts = BCP.GetTransactionCosts( // calculate costs of a single order
            commitmentID,
            gasForMailbox,
            uint256(gasPriceInGwei)
            );
        uint counter = 0;
        while (counter <= _m) {
            if (lowestUnpaid + counter <= submissions.length) {
                address participant = submissions[lowestUnpaid + counter];
                if (registry[participant].status == Status.COMPLETED) {                    
                    // ask the oracle to send the data of the submission to the mailbox
                    BCP.Order{value: transactionCosts}( 
                        commitmentID,
                        string(abi.encodePacked(registry[participant].submissionID)),
                        uint32(block.timestamp),
                        gasForMailbox,
                        gasPriceInGwei
                    );
                    counter += 1;
                }
            }
            lowestUnpaid += _m;
        }
    }

    // this function is called by the oracle to implement the payment
    function Mailbox(
        uint32 _orderID,
        int88 _data,
        bool _statusFlag
    ) external payable override onlyBCP {
        require (_statusFlag == true); // oracle data is fine
        address participant = participantFromOrderID[_orderID];
        // encrypted data on blockchain consistent with payment data set prepared by experimenter?
        require(registry[participant].submissionID == keccak256(abi.encodePacked(participant, _data)));
        registry[participant].key = uint88(_data) / 0x1000;
        uint decision = uint88(_data) % 0x1000;
        registry[participant].decision = decision;
        uint payoffPlayer = decision * ECU;
        uint payoffCharity = (50 - decision) * ECU;
        payable(participant).transfer(showUpFee + payoffPlayer);
        charity.transfer(payoffCharity); 
        //mark as paid
        registry[participant].status = Status.PAID;
    }   
    
    function endOfExperiment() external onlyOwner {
        selfdestruct(owner);
    }
}
