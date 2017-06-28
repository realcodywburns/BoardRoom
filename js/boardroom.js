// basic information about the dapp
var uri = 'https://mewapi.epool.io';
//var uri = 'http://127.0.0.1'
var web3 = new Web3(new Web3.providers.HttpProvider(uri));
var abiArray = [{"constant":true,"inputs":[{"name":"","type":"uint256"}],"name":"proposals","outputs":[{"name":"recipient","type":"address"},{"name":"amount","type":"uint256"},{"name":"description","type":"string"},{"name":"votingDeadline","type":"uint256"},{"name":"executed","type":"bool"},{"name":"proposalPassed","type":"bool"},{"name":"numberOfVotes","type":"uint16"},{"name":"currentResult","type":"uint16"},{"name":"proposalHash","type":"bytes32"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"targetMember","type":"address"}],"name":"removeMember","outputs":[],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"newOwner","type":"address"}],"name":"setOwner","outputs":[],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"proposalNumber","type":"uint256"},{"name":"transactionBytecode","type":"bytes"}],"name":"executeProposal","outputs":[],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"MAX_UINT256","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":true,"inputs":[{"name":"","type":"address"}],"name":"memberId","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"numProposals","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":false,"inputs":[],"name":"kill","outputs":[],"payable":false,"type":"function"},{"constant":true,"inputs":[{"name":"","type":"uint256"}],"name":"members","outputs":[{"name":"member","type":"address"},{"name":"name","type":"string"},{"name":"memberSince","type":"uint256"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"debatingPeriodInMinutes","outputs":[{"name":"","type":"uint32"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"minimumQuorumForProposals","type":"uint16"},{"name":"minutesForDebate","type":"uint32"},{"name":"marginOfVotesForMajority","type":"uint16"}],"name":"changeVotingRules","outputs":[],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"minimumQuorum","outputs":[{"name":"","type":"uint16"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"majorityMargin","outputs":[{"name":"","type":"uint16"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"beneficiary","type":"address"},{"name":"etherAmount","type":"uint256"},{"name":"JobDescription","type":"string"},{"name":"transactionBytecode","type":"bytes"}],"name":"newProposal","outputs":[{"name":"proposalID","type":"uint256"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"targetMember","type":"address"},{"name":"memberName","type":"string"}],"name":"addMember","outputs":[],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"proposalNumber","type":"uint256"},{"name":"supportsProposal","type":"bool"},{"name":"justificationText","type":"string"}],"name":"vote","outputs":[{"name":"voteID","type":"uint256"}],"payable":false,"type":"function"},{"constant":true,"inputs":[{"name":"proposalNumber","type":"uint256"},{"name":"beneficiary","type":"address"},{"name":"etherAmount","type":"uint256"},{"name":"transactionBytecode","type":"bytes"}],"name":"checkProposalCode","outputs":[{"name":"codeChecksOut","type":"bool"}],"payable":false,"type":"function"},{"inputs":[{"name":"minimumQuorumForProposals","type":"uint16"},{"name":"minutesForDebate","type":"uint32"},{"name":"marginOfVotesForMajority","type":"uint16"},{"name":"boardLeader","type":"address"}],"payable":false,"type":"constructor"},{"payable":true,"type":"fallback"},{"anonymous":false,"inputs":[{"indexed":false,"name":"proposalID","type":"uint256"},{"indexed":false,"name":"recipient","type":"address"},{"indexed":false,"name":"amount","type":"uint256"},{"indexed":false,"name":"description","type":"string"}],"name":"ProposalAdded","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"name":"proposalID","type":"uint256"},{"indexed":false,"name":"position","type":"bool"},{"indexed":false,"name":"voter","type":"address"},{"indexed":false,"name":"justification","type":"string"}],"name":"Voted","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"name":"proposalID","type":"uint256"},{"indexed":false,"name":"result","type":"uint256"},{"indexed":false,"name":"quorum","type":"uint256"},{"indexed":false,"name":"active","type":"bool"}],"name":"ProposalTallied","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"name":"member","type":"address"},{"indexed":false,"name":"isMember","type":"bool"}],"name":"MembershipChanged","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"name":"minimumQuorum","type":"uint16"},{"indexed":false,"name":"debatingPeriodInMinutes","type":"uint32"},{"indexed":false,"name":"majorityMargin","type":"uint16"}],"name":"ChangeOfRules","type":"event"}];
var contractAddress = "0x08CE0b196877917f32ECFF98B727dDf04A58aC7B";
var contract = web3.eth.contract(abiArray).at(contractAddress);


window.onload = function() {
	//fill the table with proposals
	// Date proposal expires
		var deadline = contract.proposals(0)[7].c["0"];
		console.log(deadline);

		//fill the table with proposals

		var table = document.getElementById("proposalTable");
		for (i = 0; i < 1; i++){
			var deadline = contract.proposals(i)[3].c["0"];
			if(deadline == 0){break};
			var about = "<button type='button' class='btn btn-link' data-toggle='modal' data-target='#propModal'>" + contract.proposals(i)[2]+"</button>";
			var row = table.insertRow(i-1);
			var cell1 = row.insertCell(0);
			var cell2 = row.insertCell(1);
			var cell3 = row.insertCell(2);
			cell1.innerHTML = i;
			cell2.innerHTML = about;
			cell3.innerHTML = new Date(deadline*1000);

			$('#propModalHead').html(contract.proposals(i)[2]);
			$('#propVoteCount').html(contract.proposals(i)[6].c["0"]);
			var propNay = contract.proposals(i)[6].c["0"] - contract.proposals(i)[7].c["0"] / contract.proposals(i)[6].c["0"];
			var propYea = contract.proposals(i)[6].c["0"] - propNay / contract.proposals(i)[6].c["0"];
			console.log("yea" + propYea);
			console.log("nay" + propNay);
			$('#propProgress').html("<div class='progress-bar progress-bar-success' style='width:"+ propYea * 100 +"%'></div><div class='progress-bar progress-bar-danger' style='width:"+ propNay* 100 +"%'></div>");


		}


	};
