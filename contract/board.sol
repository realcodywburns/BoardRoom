pragma solidity ^0.4.11;

contract owned{
  function owned () {owner = msg.sender;}
  address owner;
  modifier onlyOwner {
          if (msg.sender != owner)
              throw;
          _;
          }
  function setOwner(address newOwner) onlyOwner{owner = newOwner;}
  }

contract SafeMath {
      uint256 constant public MAX_UINT256 =
      0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

      function safeAdd(uint256 x, uint256 y) constant internal returns (uint256 z) {
          if (x > MAX_UINT256 - y) throw;
          return x + y;
      }

      function safeSub(uint256 x, uint256 y) constant internal returns (uint256 z) {
          if (x < y) throw;
          return x - y;
      }

      function safeMul(uint256 x, uint256 y) constant internal returns (uint256 z) {
          if (y == 0) return 0;
          if (x > MAX_UINT256 / y) throw;
          return x * y;
      }
  }


contract Board is owned, SafeMath {

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
        if (memberId[msg.sender] == 0)
        throw;
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
    function Board(
        uint16 minimumQuorumForProposals,
        uint32 minutesForDebate,
        uint16 marginOfVotesForMajority,
        address boardLeader
    ) onlyOwner{
        changeVotingRules(minimumQuorumForProposals, minutesForDebate, marginOfVotesForMajority);
        if (boardLeader != 0) owner = boardLeader;
        addMember(owner, 'President');
    }

// only Owner Functions
    /*make someone a member, no bots allowed */
    function addMember(address targetMember, string memberName) onlyOwner noBot(targetMember){
        uint id;
        if (memberId[targetMember] == 0) {
           memberId[targetMember] = 1;
           id = members.length++;
           Member n = members[id];
           n.member=targetMember;
           n.memberSince= now;
           n.name= memberName;
        } else {
            //just change info
            id= memberId[targetMember];
            Member m = members[id];
            m.member = targetMember;
            m.memberSince= now;
            m.name= memberName;
        }


        MembershipChanged(targetMember, true);
    }

    /*remove a member*/
    function removeMember(address targetMember) onlyOwner {
        if (memberId[targetMember] == 0) throw;

        for (uint i = memberId[targetMember]; i< members.length-1; i++){
            members[i] = members[i+1];
        }
        delete members[members.length-1];
        members.length = safeSub(members.length, 1);
    }

    /*change rules*/
    function changeVotingRules(
        uint16 minimumQuorumForProposals,
        uint32 minutesForDebate,
        uint16 marginOfVotesForMajority
    ) onlyOwner {
        minimumQuorum = minimumQuorumForProposals;
        debatingPeriodInMinutes = minutesForDebate;
        majorityMargin = marginOfVotesForMajority;

        ChangeOfRules(minimumQuorum, debatingPeriodInMinutes, majorityMargin);
    }

// onlyMember Functions
    /* Function to create a new proposal */
    function newProposal(
        address beneficiary,
        uint etherAmount,
        string JobDescription,
        bytes transactionBytecode
    )
        onlyMembers
        returns (uint proposalID)
    {
        proposalID = proposals.length++;
        Proposal p = proposals[proposalID];
        p.recipient = beneficiary;
        p.amount = etherAmount;
        p.description = JobDescription;
        p.proposalHash = sha3(beneficiary, etherAmount, transactionBytecode);
        p.votingDeadline = safeAdd(now,safeMul(debatingPeriodInMinutes, 1 minutes));
        p.executed = false;
        p.proposalPassed = false;
        p.numberOfVotes = 0;
        ProposalAdded(proposalID, beneficiary, etherAmount, JobDescription);
        numProposals = proposalID++;

        return proposalID;
    }

    function vote(
        uint proposalNumber,
        bool supportsProposal,
        string justificationText
    )
        onlyMembers
        returns (uint voteID)
    {
        Proposal p = proposals[proposalNumber];         // Get the proposal
        if (p.voted[msg.sender] == true) throw;         // If has already voted, cancel
        p.voted[msg.sender] = true;                     // Set this voter as having voted
        p.numberOfVotes++;                              // Increase the number of votes
        if (supportsProposal) {                         // If they support the proposal
            p.currentResult++;                 // Increase score
        } else {                                        // If they don't
            p.currentResult--;                          // Decrease the score
        }
        // Create a log of this event
        Voted(proposalNumber,  supportsProposal, msg.sender, justificationText);
        return p.numberOfVotes;
    }

//public
  /* default function allow anyone to send funds */
    function() payable{}

    /* function to check if a proposal code matches */
    function checkProposalCode(
        uint proposalNumber,
        address beneficiary,
        uint etherAmount,
        bytes transactionBytecode
    )
        constant
        returns (bool codeChecksOut)
    {
        Proposal p = proposals[proposalNumber];
        return p.proposalHash == sha3(beneficiary, etherAmount, transactionBytecode);
    }

    function executeProposal(uint proposalNumber, bytes transactionBytecode) {
        Proposal p = proposals[proposalNumber];
        /* Check if the proposal can be executed:
           - Has the voting deadline arrived?
           - Has it been already executed or is it being executed?
           - Does the transaction code match the proposal?
           - Has a minimum quorum?
        */

        if (now < p.votingDeadline
            || p.executed
            || p.proposalHash != sha3(p.recipient, p.amount, transactionBytecode)
            || p.numberOfVotes < minimumQuorum)
            throw;

        /* execute result */
        /* If difference between support and opposition is larger than margin */
        if (p.currentResult > majorityMargin) {
            // Avoid recursive calling

            p.executed = true;
            if (!p.recipient.call.value(p.amount)(transactionBytecode)) {
                throw;
            }

            p.proposalPassed = true;
        } else {
            p.proposalPassed = false;
        }
        // Fire Events
        ProposalTallied(proposalNumber, p.currentResult, p.numberOfVotes, p.proposalPassed);
    }

//safety switches consider removing for production
//clean up after contract is no longer needed

    function kill() public onlyOwner {selfdestruct(owner);}

    }
