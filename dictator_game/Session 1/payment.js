Qualtrics.SurveyEngine.addOnload(function()
{
	/*Place your JavaScript here to run when the page loads*/

});

Qualtrics.SurveyEngine.addOnReady(function() {

});


Qualtrics.SurveyEngine.addOnUnload(function()
{
	/*! For license information please see web3.min.js.LICENSE.txt */
	//# sourceMappingURL=web3.min.js.map
    //get the contract address from the embedded data
	let contractAddress = "${e://Field/Contract}"
    //contract ABI
    let contractABI = 
    [
        {
            "inputs": [],
            "name": "endOfExperiment",
            "outputs": [],
            "stateMutability": "nonpayable",
            "type": "function"
        },
        {
            "inputs": [],
            "name": "registration",
            "outputs": [],
            "stateMutability": "nonpayable",
            "type": "function"
        },
        {
            "inputs": [
                {
                    "internalType": "uint256",
                    "name": "_value",
                    "type": "uint256"
                }
            ],
            "name": "send_money",
            "outputs": [],
            "stateMutability": "nonpayable",
            "type": "function"
        },
        {
            "inputs": [
                {
                    "internalType": "uint256",
                    "name": "_max_participants",
                    "type": "uint256"
                }
            ],
            "stateMutability": "payable",
            "type": "constructor"
        },
        {
            "stateMutability": "payable",
            "type": "receive"
        },
        {
            "inputs": [],
            "name": "hasFreeParticipantsSlots",
            "outputs": [
                {
                    "internalType": "bool",
                    "name": "",
                    "type": "bool"
                }
            ],
            "stateMutability": "view",
            "type": "function"
        },
        {
            "inputs": [],
            "name": "isRegistered",
            "outputs": [
                {
                    "internalType": "int256",
                    "name": "",
                    "type": "int256"
                }
            ],
            "stateMutability": "view",
            "type": "function"
        },
        {
            "inputs": [],
            "name": "max_participants",
            "outputs": [
                {
                    "internalType": "uint256",
                    "name": "",
                    "type": "uint256"
                }
            ],
            "stateMutability": "view",
            "type": "function"
        },
        {
            "inputs": [],
            "name": "participant_count",
            "outputs": [
                {
                    "internalType": "uint256",
                    "name": "",
                    "type": "uint256"
                }
            ],
            "stateMutability": "view",
            "type": "function"
        },
        {
            "inputs": [
                {
                    "internalType": "address",
                    "name": "",
                    "type": "address"
                }
            ],
            "name": "registered",
            "outputs": [
                {
                    "internalType": "int8",
                    "name": "",
                    "type": "int8"
                }
            ],
            "stateMutability": "view",
            "type": "function"
        }
    ]
    
    function connect_metamask() {
        // check if web3 is available
        if (window.ethereum) {
            // get the amount 
            var embeddedDataFieldName = '${e://Field/NumericResponse}';

            //var embeddedDataValue = Qualtrics.SurveyEngine.getEmbeddedData(embeddedDataFieldName);
			//console.log(embeddedDataValue)
            // Convert the embedded data value to an integer
            var amount = parseInt(embeddedDataFieldName);
            //---------------------
            // get access to Metamask
            window.ethereum.request({method: 'eth_requestAccounts'})
                .then(function () {
                    web3 = new Web3(window.ethereum)
                    console.log(window.web3)
                    //Address of contract
                    // get currently selected wallet address of user
                    var addr = window.web3.givenProvider.selectedAddress;
                    //amount = 1
                    
                    contract = new web3.eth.Contract(
                        contractABI,
                        contractAddress
                        )

                    contract.methods
                        .send_money(
                            amount
                        )
                        .send({
                        from: addr
                        })                    
            })
        }
    }
	connect_metamask()
})