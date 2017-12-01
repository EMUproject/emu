pragma solidity ^0.4.18;


import "https://github.com/OpenZeppelin/zeppelin-solidity/contracts/ownership/Ownable.sol";
import "browser/EMUToken.sol";

contract Crowdsale is Ownable
{
    using SafeMath for uint256;
    
    uint256 public constant preIcoStart = 1512136800;
    uint256 public constant preIcoEnd = preIcoStart + 30 days;
    
    uint256 public constant icoStart = 1517493600;
    uint256 public constant icoEnd = icoStart + 45 days;
    
    enum States { NotStarted, PreICO, ICO, Finished }
    States public state;
    
    EMUToken public token;
    address public wallet;
    uint256 public constant rate = 9000;
    uint256 public constant softCap = 600 ether;
    uint256 public balance;
    
    mapping(address => uint256) internal balances;
    
    function Crowdsale(address _token, address _wallet) public
    {
        token = EMUToken(_token);
        wallet = _wallet;
        state = States.NotStarted;
    }
    
    function nextState() onlyOwner public
    {
        require(state == States.NotStarted || state == States.PreICO || state == States.ICO);
        
        if(state == States.NotStarted)
        {
            state = States.PreICO;
        }
        else if(state == States.PreICO)
        {
            state = States.ICO;
        }
        else if(state == States.ICO)
        {
            state = States.Finished;
            
            if(balance >= softCap)
            {
                address contractAddress = this;
                wallet.transfer(contractAddress.balance);
                uint256 tokens = token.balanceOf(contractAddress);
                token.burn(tokens);
            }
        }
    }
    
    function getBonus(uint256 tokens) internal constant returns (uint256) 
    {
        uint256 bonus = 0;
        if(state == States.PreICO)
        {
            if(now >= preIcoStart && now <= (preIcoStart + 1 days))
            {
                bonus = tokens.mul(15).div(100);
            }
            else if(now >= (preIcoStart + 1 days) && now <= (preIcoStart + 2 days))
            {
                bonus = tokens.mul(10).div(100);
            }
            else if(now >= (preIcoStart + 2 days) && now <= preIcoEnd)
            {
                bonus = tokens.mul(5).div(100);
            }
        }
        else if(state == States.ICO)
        {
            if(now >= icoStart && now <= (icoStart + 10 days))
            {
                bonus = tokens.mul(5).div(100);
            }
        }
        
        return bonus;
    }
    
    function refund() public returns (bool)
    {
        require(state == States.Finished);
        require(balance < softCap);
        uint256 value = balances[msg.sender];
        require(value > 0);
        balances[msg.sender] = 0;
        token.burn(token.balanceOf(msg.sender));
        msg.sender.transfer(value);
        return true;
    }
    
    function buyTokens() internal
    {
        uint256 weiAmount = msg.value;
        uint256 tokens = weiAmount.mul(rate);
        uint256 bonus = getBonus(tokens);
        tokens = tokens.add(bonus);
        bool success = token.transfer(msg.sender, tokens);
        require(success);
        if(state == States.PreICO)
        {
            wallet.transfer(msg.value);
        }
        saveFunds();
    }
    
    function saveFunds() internal
    {
       balance = balance.add(msg.value);
       if(state == States.ICO)
       {
           balances[msg.sender] = balances[msg.sender].add(msg.value);
       }
    }
    
    function isValidPeriod() internal constant returns (bool)
    {
        if(state == States.PreICO)
        {
            if(now >= preIcoStart && now <= preIcoEnd) return true;
        }
        else if(state == States.ICO)
        {
            if(now >= icoStart && now <= icoEnd) return true;
        }
        
        return false;
    }
    
    function () public payable 
    {
        require(msg.sender != address(0));
        require(msg.value > 0);
        require(isValidPeriod());
        
        buyTokens();
    }
    
    function manualTransfer(address to, uint256 weiAmount) onlyOwner public returns (bool)
    {
        require(to != address(0));
        require(weiAmount > 0);
        require(isValidPeriod());
        
        uint256 tokens = weiAmount.mul(rate);
        uint256 bonus = getBonus(tokens);
        tokens = tokens.add(bonus);
        bool success = token.transfer(to, tokens);
        if(success)
        {
            balance = balance.add(weiAmount);
        }
        return success;
    }

}