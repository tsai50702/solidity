pragma solidity ^0.4.18;

// This is Pig World Main contract
// Pig World is a Hybrid Decentralized Online Casino
// https://pig.world/


// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}



// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and an
// initial fixed supply
// ----------------------------------------------------------------------------
contract FixedSupplyToken is ERC20Interface {
    using SafeMath for uint;

    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;
    address public owner1;
    address public owner2;
    address public owner3;
    
    address public newOwner1;
    address public newOwner2;
    address public newOwner3;
    

    mapping(address => uint8) public gameContract;
    mapping(address => mapping(address => bool)) public onwerAgrees;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    event OwnershipTransferred(address, address);
    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    function FixedSupplyToken() public {
        owner1 = msg.sender;
        symbol = "PICO";
        name = "Pig World Coin";
        decimals = 18;
        _totalSupply = 2000000 * 10**uint(decimals);
        balances[owner1] = _totalSupply;
        Transfer(address(0), owner1, _totalSupply);
    }


    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public constant returns (uint) {
        return _totalSupply;
    }


    // ------------------------------------------------------------------------
    // Get the token balance for account `tokenOwner`
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from token owner's account to `to` account
    // - Owner's account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(msg.sender, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner's account
    //
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces 
    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Transfer `tokens` from the `from` account to the `to` account
    // 
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the `from` account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(from, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender's account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    
    
    // ------------------------------------------------------------------------
    // Don't accept ETH
    // ------------------------------------------------------------------------
    function () public payable {
        revert();
    }


    // ------------------------------------------------------------------------
    // Pig World burn some coin
    // ------------------------------------------------------------------------
    function burnCoins(uint pico) payable onlyOwner {
        balances[msg.sender] = balances[msg.sender].sub(pico);
        _totalSupply = _totalSupply.sub(pico);
    }
    
    
    // ------------------------------------------------------------------------
    // Pig World mint some coin
    // ------------------------------------------------------------------------
    function mintTokens(uint pico) payable onlyOwner {
        balances[msg.sender] = balances[msg.sender].add(pico);
        _totalSupply = _totalSupply.add(pico);
    }
    

    // ------------------------------------------------------------------------
    // Player need buy some ticket in game
    // Only game contract can use this function
    // ------------------------------------------------------------------------
    function payToPlay(address paidAddress,uint price) public {
        
        bool a = gameContract[msg.sender] >= 2;
        if(a)
            balances[paidAddress] = balances[paidAddress].sub(price);
    }


    // ------------------------------------------------------------------------
    // Player win the game
    // Only game contract can use this function
    // ------------------------------------------------------------------------
    function winTheGame(address winAddress,uint reward) public {
        
        bool a = gameContract[msg.sender] >= 2;
        if(a)
            balances[winAddress] = balances[winAddress].add(reward);
    }
    
    
    // ------------------------------------------------------------------------
    // Pig World team need to add new game contract in main contract
    // Only owner can use this contract
    // ------------------------------------------------------------------------
    function add_game_contract(address game_add) public onlyOwner {
        if(!onwerAgrees[msg.sender][game_add]){
            gameContract[game_add] ++;
            onwerAgrees[msg.sender][game_add] = true;
        }
        
    }
    
    
    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner1, tokens);
    }
    
    
    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent Ether
    // ------------------------------------------------------------------------
    function transferEther() public onlyOwner returns (bool success) {
        return owner1.send(this.balance);
    }
    
    
    modifier onlyOwner {
        require(msg.sender == owner1 || msg.sender == owner2 || msg.sender == owner3);
        _;
    }

    function transferOwner1ship(address _newOwner) public  {
        require(msg.sender == owner1);
        newOwner1 = _newOwner;
    }
    
    function transferOwner2ship(address _newOwner) public  {
        require(msg.sender == owner2);
        newOwner2 = _newOwner;
    }
    
    function transferOwner3ship(address _newOwner) public  {
        require(msg.sender == owner3);
        newOwner3 = _newOwner;
    }
    
    function acceptOwner1ship() public {
        require(msg.sender == newOwner1);
        OwnershipTransferred(owner1, newOwner1);
        owner1 = newOwner1;
        newOwner1 = address(0);
    }
    
    function acceptOwner2ship() public {
        require(msg.sender == newOwner2);
        OwnershipTransferred(owner2, newOwner2);
        owner2 = newOwner2;
        newOwner2 = address(0);
    }
    
    function acceptOwner3ship() public {
        require(msg.sender == newOwner3);
        OwnershipTransferred(owner3, newOwner3);
        owner3 = newOwner3;
        newOwner3 = address(0);
    }

}