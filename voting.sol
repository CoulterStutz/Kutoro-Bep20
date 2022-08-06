pragma solidity ^0.8.0;
import "Kutoro.sol";


contract Math {
    function Add(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }

    function Sub (uint a, uint b) public pure returns (uint c) {
        c = a - b;
        require(b <= a);

    }

    function Mult (uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);

    }

    function Div (uint a, uint b) public pure returns (uint c) {
        c = a / b;
        require(b > 0);

    }

    function Precentage (uint a, uint b) public pure returns (uint d) {
        d = b / a;
        return d;
    }

    function calculateVotes (uint tokens,uint voteToTokenRate) public pure returns (uint d){
        d = tokens / voteToTokenRate;
    }
}

//
// Some interface borrowed from https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
//
abstract contract KutoroInterface{
    function totalSupply() virtual public view returns (uint);
    function balanceOf(address tokenOwner) virtual public view returns (uint balance);
    /// function allowance(address tokenOwner, address spender) virtual public view returns (uint remaining);
    function transfer(address to, uint tokens) virtual public returns (bool success);
    /// function approve(address spender, uint tokens) virtual public returns (bool success);
    /// function transferFrom(address from, address to, uint tokens) virtual public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
}



contract Owned{
    address public owner;
    address public newOwner;

    event OwnershipTransferred (address indexed _from, address indexed _to);

    // Rest ripped
    constructor(){
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract Voting is KutoroInterface, Math, Owned{

    bool public electionHappening;
    uint public electionVotePrice;
    string public electionTitle;
    uint voteToTokenRate;
    address public ElectionRunner;
    uint public electionReward;

    uint public option1Votes;
    uint public option2Votes;
    uint public totalVotes;
    

    struct vote{
        uint quantityofVotes;
        uint tokensDelegated;
        uint vote;
    }

    mapping(address => vote) voter;

    constructor() {

        authorized1 = 0xa693190103733280E23055BE70C838d9b6708b9a; //Authorized Base List
        authorized2 = 0xEf54Ca02be4D7628f11d3638E13CAD6D38f2bD52; //Authorize Base List
        authorized3 = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;

        electionHappening = false;
        electionVotePrice = 1;
        electionTitle = "Made With Love <3 Kutoro";
        voteToTokenRate = 1;

        option1Votes = 0;
        option2Votes = 0;
        totalVotes = 0;

        electionReward = 1;

    }

    function createElection(string memory title) public AntiBlacklist lockdownSecured KutoNoYouDont returns (bool success){
        require(electionHappening == false);
        electionTitle = title;
        electionHappening = true;
        ElectionRunner = msg.sender;
    }

    function Vote(uint choice, uint tokens) public AntiBlacklist lockdownSecured election returns (bool success){
        require(balances[msg.sender] >= tokens);
        require(choice <= 2);
        balances[msg.sender] = Sub(balances[msg.sender], tokens);
        uint votes = calculateVotes(tokens, voteToTokenRate);

        if(choice == 1){
            option1Votes = Add(option1Votes, votes);
        } else if(choice == 2){
            option2Votes = Add(option2Votes, votes);
        }
        totalVotes = Add(totalVotes, votes);

        voter[msg.sender].quantityofVotes = votes;
        voter[msg.sender].tokensDelegated = tokens;
        voter[msg.sender].vote = choice;
        
    }

    function endElection() public AntiBlacklist election returns(bool success){
        require(msg.sender == ElectionRunner);
        require(electionHappening == true);

        electionHappening = false;
        electionTitle = "";
        return true;
    }

    function withdrawlTokensFromElection() public AntiBlacklist returns (bool success){
        require(electionHappening == false);
        require(voter[msg.sender].tokensDelegated > 0);

        uint ReturnTokens = voter[msg.sender].tokensDelegated + electionReward;
        balances[msg.sender] = Add(balances[msg.sender], ReturnTokens);
        return true;
    }

    function setAuthorized(int slot, address address1) public KutoNoYouDont returns (bool success){
        require(slot <= 3);
        require(slot > 0);

        if(slot == 1){
            authorized1 = address1;
            return true;
        } else if(slot == 2){
            authorized2 = address1;
            return true;
        } else if(slot == 3){
            authorized3 = address1;
            return true;
        }
    }

    function setAllAuthorized(address address1, address address2, address address3) public KutoNoYouDont returns (bool success){
        authorized1 = address1;
        authorized2 = address2;
        authorized3 = address3;

        return true;
    }

    function transferAnyToken (address tokenAddress, uint tokens) public onlyOwner returns (bool success)  {
        transfer(owner, tokens);
        return KutoroInterface(tokenAddress).transfer(owner, tokens);
    }

    modifier election{
        require(electionHappening == true);
        require(voter[msg.sender].quantityofVotes <= 0);
        _;
    }

    modifier KutoNoYouDont{
        if(msg.sender == authorized1){
        } else if(msg.sender == authorized2){
        } else if(msg.sender == authorized3){
        } else{
            revert("Not Authorized");
        }
        _;
    }

    modifier AntiBlacklist{
        require(blacklist[msg.sender].Active == false, "You have been blacklisted, Appeal at ...");
        _;
    }

    modifier lockdownSecured{ // Used to stop ongoing token attacks if any happen
        require(lockdownEnabled == false);
        _;
    }
}
