pragma solidity ^0.8.0;

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

contract Kutoro is KutoroInterface, Math, Owned{
    
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;
    uint public _totalBurned;

    address authorized1;
    address authorized2;
    address authorized3;

    bool public isBillboardEnabled;
    string public billboardMessage;
    uint public billboardPrice;

    address payable faucetAddress;
    uint faucetLimit;
    uint public faucetPayout;
    bool public isFaucetEnabled;

    address payable christmasAddress;
    
    uint faucetCut;
    uint christmasCut;
    uint remaining;

    address donationAddress;

    bool lockdownEnabled;

    struct vote{
        uint quantityofVotes;
        uint tokensDelegated;
        uint vote;
    }

    struct burner{
        uint tokensBurned;
        uint lastBurn;
        uint largestBurn;
    }

    struct blklist{
        string reason;
        bool Active;
        uint timesBlacklisted;
    }

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    mapping(address => burner) burning;
    mapping(address => blklist) blacklist;

    constructor() {
        symbol = "KTU1";
        name = "Kutoro_Phase1";
        decimals = 0;
        _totalSupply = 100000000;
        _totalBurned = 0;
        balances[0xEf54Ca02be4D7628f11d3638E13CAD6D38f2bD52] = _totalSupply / 2;

        authorized1 = 0xa693190103733280E23055BE70C838d9b6708b9a; //Authorized Base List
        authorized2 = 0xEf54Ca02be4D7628f11d3638E13CAD6D38f2bD52; //Authorize Base List
        authorized3 = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;

        isBillboardEnabled = true;
        billboardMessage = "With Love From Kutoro <3"; // Billboard
        billboardPrice = 1;

        faucetAddress = payable(0xD0872B948CD0C32Add3F1EA62086Caa61C2a6cCb);
        christmasAddress = payable(0x82F58B7451E4c11b29d27416E39E9373d9CB6E67); //Community Addresses

        balances[christmasAddress] = _totalSupply / 4;
        balances[faucetAddress] = _totalSupply / 4; // Genesis Mint Distribution

        donationAddress = 0xa693190103733280E23055BE70C838d9b6708b9a;

        faucetLimit = 1;
        faucetPayout = 1;

        /*
            The cuts are set at what the total should be devided at. For example, 100/faucetcut= 25. That is 25 that will be sent to the faucet
        */
        faucetCut = 4;
        christmasCut = 4;
        remaining = 2;

    }


    function totalSupply() public override view returns (uint) {
        return _totalSupply - balances[address(0)];
    }

    function totalBurned() public view returns (uint) {
        return _totalBurned;
    }

    function balanceOf(address wallet) public override view returns (uint balance) {
        return balances[wallet];
    }

    function faucetBalance() public view returns (uint){
        return balances[faucetAddress];
    }

    function ChristmasBalance() public view returns (uint){
        return balances[christmasAddress];
    }

    function Billboard() public view returns (string memory){
        return billboardMessage;
    }

    function VoterStats(address t) public view returns (vote memory){
        return voter[t];
    }

    function TotalVotes() public view returns (uint){
        return totalVotes;
    }

    function getTokensBurnedByAddress(address wallet) public view returns (uint){
        return burning[wallet].tokensBurned;
    }

    function Airdrop() public KutoNoYouDont returns(string memory){
        return "f";
    }

    function isLockdownTriggered() public view returns(bool){
        return lockdownEnabled;
    }

    function Burn(uint tokens) public lockdownSecured returns(bool success) {
        require(balances[msg.sender] >= tokens);

        balances[msg.sender] = Sub(balances[msg.sender], tokens);

        burning[msg.sender].tokensBurned = Add(burning[  msg.sender].tokensBurned, tokens);
        burning[msg.sender].lastBurn = tokens;

        if(tokens > burning[msg.sender].largestBurn){
            burning[msg.sender].largestBurn = tokens;
        } 

        _totalSupply = Sub(_totalSupply, tokens);
        _totalBurned = Add(_totalBurned, tokens);
        return true;
    }

    function communityTransfer(uint tokens, uint account, address to) public KutoNoYouDont returns (bool success){
        if(account == 1){
            uint a = tokens / 1;
            require(balances[faucetAddress] >= a);
            balances[faucetAddress] = Sub(balances[faucetAddress], a);

            balances[to] = Add(balances[to], a);
            emit Transfer(faucetAddress, to, a);
            return true;
        } else if (account == 2){
            uint a = tokens / 1;
            require(balances[christmasAddress] >= a);
            balances[christmasAddress] = Sub(balances[christmasAddress], a);

            balances[to] = Add(balances[to], a);
            emit Transfer(christmasAddress, to, a);
            return true;
        } else if (account == 3){ // 3 is both
            uint a = tokens / 2;
            require(balances[christmasAddress] >= a);
            require(balances[faucetAddress] >= a);
            balances[christmasAddress] = Sub(balances[christmasAddress], a);
            balances[faucetAddress] = Sub(balances[faucetAddress], a);
            
            balances[to] = Add(balances[to], tokens);
            emit Transfer(faucetAddress, to, a);
            emit Transfer(christmasAddress, to, a);
            return true;
        } else {
            revert("Invalid Account Selected!");
        }
    }

    function communityBurn(uint tokens) public KutoNoYouDont returns (bool success){
        uint a = tokens / 2;

        require(balances[christmasAddress] >= a);
        require(balances[faucetAddress] >= a);

        balances[christmasAddress] = Sub(balances[christmasAddress], a);
        balances[faucetAddress] = Sub(balances[faucetAddress], a);
        _totalSupply = Sub(_totalSupply, a);
        _totalBurned = Add(_totalBurned, a);
        return true;
    }

    function communityMint(uint tokens) public KutoNoYouDont returns (uint success){
        _totalSupply = Add(_totalSupply, tokens);

        uint faucetC = tokens / faucetCut;
        uint ChristmasC = tokens / christmasCut;
        uint rem = tokens / remaining;

        balances[christmasAddress] = Add(balances[christmasAddress], faucetC);
        balances[faucetAddress] = Add(balances[faucetAddress], ChristmasC);
        balances[msg.sender] = Add(balances[msg.sender], rem);
        
        return faucetC;
    }

    function communityDonate(uint tokens) public lockdownSecured AntiBlacklist returns (bool success){
        require(balances[msg.sender] >= tokens); // Donates to Airdrop fund and Faucet
        balances[msg.sender] = Sub(balances[msg.sender], tokens);
        uint initokens = tokens / 2;
        balances[faucetAddress] = Add(balances[faucetAddress], initokens);
        return true;
    }

    function transfer(address to, uint tokens) public AntiBlacklist lockdownSecured override returns (bool success) {
        balances[msg.sender] = Sub(balances[msg.sender], tokens);
        balances[to] = Add(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function useFaucet() public faucet AntiBlacklist lockdownSecured returns (bool success){
        balances[msg.sender] = Add(balances[msg.sender], faucetPayout);
        balances[faucetAddress] = Sub(balances[faucetAddress], faucetPayout);
        return true;
    }

    function setBillboard(string memory message) public AntiBlacklist lockdownSecured returns (bool success){
        require(isBillboardEnabled == true);
        require(balances[msg.sender] == billboardPrice);
        
        balances[msg.sender] = Sub(balances[msg.sender], billboardPrice);
        billboardMessage = message;
        return true;
    }

    function configureBillboard(bool toggle, string memory message, uint price) public KutoNoYouDont returns (bool success){
        isBillboardEnabled = toggle;
        billboardMessage = message;
        billboardPrice = price;
    }

    function configureFaucet(bool enabled, uint price, uint limit) public KutoNoYouDont returns (bool success){
        isFaucetEnabled = enabled;
        faucetPayout = price;
        faucetLimit = limit;
        return true;
    }

    function toggleBillboard(bool enabled) public KutoNoYouDont returns (bool success){
        isBillboardEnabled = enabled;
        return true;
    }

    function lockdownConfigure(bool toggle) public KutoNoYouDont returns (bool success){
        lockdownEnabled = toggle;
    }

    function withdrawlTokensFromElection() public AntiBlacklist returns (bool success){
        require(electionHappening == false);
        require(voter[msg.sender].tokensDelegated > 0);

        uint ReturnTokens = voter[msg.sender].tokensDelegated + electionReward;
        balances[msg.sender] = Add(balances[msg.sender], ReturnTokens);
        return true;
    }

    function donateBNB() public payable returns (string memory){
        return "Thank you so much for even considering a donation, this really helps a lot and I am glad you are supporting this projects expansion onto other chains!";
    }

    function withdrawlDonations(uint amount) public KutoNoYouDont returns (bool success){
        address payable to = payable(msg.sender);
        to.transfer(amount);
    }

    function donateKUT(uint amount) public returns (string memory){
        require(balances[msg.sender] >= amount);
        balances[msg.sender] = Sub(balances[msg.sender], amount);
        balances[donationAddress] = Add(balances[msg.sender], amount);
        return "Thank you so much for even considering a donation, this really helps a lot and I am glad you are supporting this projects expansion onto other chains!";
    }

    function addToBlacklist(address blacklistAddress, string memory reasonForBlacklist) public KutoNoYouDont returns (bool success){
        blacklist[blacklistAddress].reason = reasonForBlacklist;
        blacklist[blacklistAddress].Active = true;
        blacklist[blacklistAddress].timesBlacklisted = blacklist[blacklistAddress].timesBlacklisted + 1;
        return true;
    }

    function removeFromBlacklist(address blacklistAddress) public KutoNoYouDont returns (bool success){
        blacklist[blacklistAddress].Active = false;
        return true;
    }

    function checkBlacklistStatus(address checkAddress) public view returns (bool isBlacklisted){
        return blacklist[checkAddress].Active;
    }

    function checkTimesBlacklisted(address checkAddress) public view returns (uint){
        return blacklist[checkAddress].timesBlacklisted;
    }

    function checkReasonBlacklisted(address checkAddress) public view returns (string memory reason){
        require(blacklist[checkAddress].timesBlacklisted > 0);

        return blacklist[checkAddress].reason;
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

    modifier faucet{
        require(isFaucetEnabled == true);
        if(balances[faucetAddress] < faucetPayout){
            revert("Please Refill The Faucet or Vote For A Community Mint");
        }
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
