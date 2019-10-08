pragma solidity ^0.5.0;

contract owned{
    address owner;
    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        assert(msg.sender == owner);
        _;
    }

    function setOwner(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}

contract Board is owned {

    /* Contract Variables and events */
    uint16 public minimumQuorum;
    uint32 public debatingPeriodInMinutes;
    uint16 public majorityMargin;
    Proposal[] public proposals;
    uint public numProposals;
    Member[] public members;

//structures

    struct Proposal {
        address recipient;
        uint amount;
        string description;
        uint votingDeadline;
        bool executed;
        bool proposalPassed;
        uint16 numberOfVotes;
        uint16 currentResult;
        bytes32 proposalHash;
        Vote[] votes;
        mapping (address => bool) voted;
    }

    struct Member {
        address member;
        string name;
        uint memberSince;
    }

    struct Vote {
        bool inSupport;
        address voter;
        string justification;
    }

//mapping
    mapping (address => uint) public memberId;

//events
    event ProposalAdded(uint proposalID, address recipient, uint amount, string description);
    event Voted(uint proposalID, bool position, address voter, string justification);
    event ProposalTallied(uint proposalID, uint result, uint quorum, bool active);
    event MembershipChanged(address member, bool isMember);
    event ChangeOfRules(uint16 minimumQuorum, uint32 debatingPeriodInMinutes, uint16 majorityMargin);

//modifiers
    /* modifier that allows only shareholders to vote and create new proposals */
    modifier onlyMembers {
        require(memberId[msg.sender] != 0, 'User called member function as non-member');
        _;
    }

    modifier noBot(address _addr){
        uint length;
        assembly {length := extcodesize(_addr) }
        require(length <= 0);
        _;
      }

// functions
    /* First time setup */
    constructor(
        uint16 minimumQuorumForProposals,
        uint32 minutesForDebate,
        uint16 marginOfVotesForMajority,
        address boardLeader
    )
        public
        onlyOwner
    {
        changeVotingRules(minimumQuorumForProposals, minutesForDebate, marginOfVotesForMajority);
        owner = boardLeader;
        addMember(owner, 'President');
    }

// only Owner Functions
    /*make someone a member, no bots allowed */
    function addMember(
        address targetMember,
        string memory memberName
    )
        public
        onlyOwner
        noBot(targetMember)
    {
        uint id;
        if (memberId[targetMember] == 0) {
           memberId[targetMember] = 1;
           id = members.length++;
           Member storage n = members[id];
           n.member=targetMember;
           n.memberSince= now;
           n.name= memberName;
        } else {
            //just change info
            id= memberId[targetMember];
            Member storage m = members[id];
            m.member = targetMember;
            m.memberSince= now;
            m.name= memberName;
        }
        emit MembershipChanged(targetMember, true);
    }

    /*remove a member*/
    function removeMember(
        address targetMember
    )
        public
        onlyOwner
    {
        require(memberId[targetMember] != 0);
        for (uint i = memberId[targetMember]; i < members.length-1; i++){
            members[i] = members[i+1];
        }
        delete members[members.length - 1];
    }

    /*change rules*/
    function changeVotingRules(
        uint16 minimumQuorumForProposals,
        uint32 minutesForDebate,
        uint16 marginOfVotesForMajority
    )
        public
        onlyOwner
    {
        minimumQuorum = minimumQuorumForProposals;
        debatingPeriodInMinutes = minutesForDebate;
        majorityMargin = marginOfVotesForMajority;
        emit ChangeOfRules(minimumQuorum, debatingPeriodInMinutes, majorityMargin);
    }

// onlyMember Functions
    /* Function to create a new proposal */
    function newProposal(
        address beneficiary,
        uint etherAmount,
        string memory JobDescription,
        bytes memory transactionBytecode
    )
        public
        onlyMembers
        returns (uint proposalID)
    {
        proposalID = proposals.length++;
        Proposal storage p = proposals[proposalID];
        p.recipient = beneficiary;
        p.amount = etherAmount;
        p.description = JobDescription;
        p.proposalHash = keccak256(abi.encodePacked(beneficiary, etherAmount, transactionBytecode));
        p.votingDeadline = now + (debatingPeriodInMinutes * 1 minutes);
        p.executed = false;
        p.proposalPassed = false;
        p.numberOfVotes = 0;
        emit ProposalAdded(proposalID, beneficiary, etherAmount, JobDescription);
        numProposals = proposalID++;
        return proposalID;
    }

    function vote(
        uint proposalNumber,
        bool supportsProposal,
        string memory justificationText
    )
        public
        onlyMembers
        returns (uint voteID)
    {
        Proposal storage p = proposals[proposalNumber];         // Get the proposal
        require(p.voted[msg.sender] != true);           // If has already voted, cancel
        p.voted[msg.sender] = true;                     // Set this voter as having voted
        p.numberOfVotes++;                              // Increase the number of votes
        if (supportsProposal) {                         // If they support the proposal
            p.currentResult++;                       // Increase score
        } else {                                        // If they don't
            p.currentResult--;                          // Decrease the score
        }
        // Create a log of this event
        emit Voted(proposalNumber,  supportsProposal, msg.sender, justificationText);
        return p.numberOfVotes;
    }

//public
  /* default function allow anyone to send funds */
    function() external payable {}

    /* function to check if a proposal code matches */
    function checkProposalCode(
        uint proposalNumber,
        address beneficiary,
        uint etherAmount,
        bytes memory transactionBytecode
    )
        public
        view
        returns (bool codeChecksOut)
    {
        Proposal storage p = proposals[proposalNumber];
        return p.proposalHash == keccak256(abi.encodePacked(beneficiary, etherAmount, transactionBytecode));
    }

    function executeProposal(
        uint proposalNumber,
        bytes memory transactionBytecode
    )
        public
    {
        Proposal storage p = proposals[proposalNumber];
        /* Check if the proposal can be executed:
           - Has the voting deadline arrived?
           - Has it been already executed or is it being executed?
           - Does the transaction code match the proposal?
           - Has a minimum quorum?
        */

        require(
            now > p.votingDeadline ||
            !p.executed ||
            p.proposalHash == keccak256(abi.encodePacked(p.recipient, p.amount, transactionBytecode)) ||
            p.numberOfVotes >= minimumQuorum
            ,'Proposal requirements not met'
            );

        /* execute result */
        /* If difference between support and opposition is larger than margin */
        if (p.currentResult > majorityMargin) {
            // Avoid recursive calling
            p.executed = true;
            p.recipient.call.value(p.amount)(transactionBytecode);
            p.proposalPassed = true;
        } else {
            p.proposalPassed = false;
        }
        // Fire Events
        emit ProposalTallied(proposalNumber, p.currentResult, p.numberOfVotes, p.proposalPassed);
    }

}
