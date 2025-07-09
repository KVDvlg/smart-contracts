// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ERC20Ballot {
    struct Voter {
        uint weight;        // Вес голоса (кол-во токенов)
        bool voted;         // Голосовал ли уже
        address delegate;   // Кому делегирован голос
        uint vote;          // Индекс предложения
    }

    struct Proposal {
        bytes32 name;       // Название предложения
        uint voteCount;     // Кол-во голосов (весов)
    }

    IERC20 public token;
    address public chairperson;
    mapping(address => Voter) public voters;
    Proposal[] public proposals;

    // 📢 События
    event RightGranted(address voter, uint weight);
    event Delegated(address from, address to);
    event Voted(address voter, uint proposal, uint weight);
    event Winner(bytes32 name, uint totalVotes);

    constructor(address _token, bytes32[] memory proposalNames) {
        token = IERC20(_token);
        chairperson = msg.sender;

        for (uint i = 0; i < proposalNames.length; i++) {
            proposals.push(Proposal({
                name: proposalNames[i],
                voteCount: 0
            }));
        }
    }

    /// Предоставить право голосовать (по балансу ERC20)
    function giveRightToVote(address voter) external {
        require(msg.sender == chairperson, "Only chairperson");
        require(!voters[voter].voted, "Already voted");
        require(voters[voter].weight == 0, "Already granted");

        uint balance = token.balanceOf(voter);
        require(balance > 0, "No token balance");

        voters[voter].weight = balance;
        emit RightGranted(voter, balance);
    }

    /// Делегировать голос
    function delegate(address to) external {
        Voter storage sender = voters[msg.sender];
        require(sender.weight > 0, "No voting power");
        require(!sender.voted, "Already voted");
        require(to != msg.sender, "Self-delegation not allowed");

        while (voters[to].delegate != address(0)) {
            to = voters[to].delegate;
            require(to != msg.sender, "Circular delegation");
        }

        Voter storage delegate_ = voters[to];
        require(delegate_.weight > 0, "Delegate has no voting power");

        sender.voted = true;
        sender.delegate = to;

        if (delegate_.voted) {
            proposals[delegate_.vote].voteCount += sender.weight;
        } else {
            delegate_.weight += sender.weight;
        }

        emit Delegated(msg.sender, to);
    }

    /// Проголосовать за предложение
    function vote(uint proposalIndex) external {
        Voter storage sender = voters[msg.sender];
        require(sender.weight > 0, "No voting power");
        require(!sender.voted, "Already voted");
        require(proposalIndex < proposals.length, "Invalid proposal");

        sender.voted = true;
        sender.vote = proposalIndex;
        proposals[proposalIndex].voteCount += sender.weight;

        emit Voted(msg.sender, proposalIndex, sender.weight);
    }

    /// Получить индекс победителя
    function winningProposal() public view returns (uint winningProposal_) {
        uint highestVotes = 0;
        for (uint i = 0; i < proposals.length; i++) {
            if (proposals[i].voteCount > highestVotes) {
                highestVotes = proposals[i].voteCount;
                winningProposal_ = i;
            }
        }
    }

    /// Получить имя победителя
    function winnerName() external view returns (bytes32 winnerName_) {
        uint index = winningProposal();
        winnerName_ = proposals[index].name;
    }

    /// Объявить победителя через событие
    function announceWinner() external {
        uint index = winningProposal();
        emit Winner(proposals[index].name, proposals[index].voteCount);
    }
}
