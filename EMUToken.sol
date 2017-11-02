pragma solidity ^0.4.11;

import "https://github.com/OpenZeppelin/zeppelin-solidity/contracts/token/BurnableToken.sol";

contract EMUToken is BurnableToken
{
    string public constant name = "EMU";
    string public constant symbol = "EMU";
    uint8 public constant decimals = 18;
    
    function EDToken() public 
    {
        totalSupply = 250000000 * 10 ** uint256(decimals);
        balances[msg.sender] = totalSupply;
        Transfer(0x0, msg.sender, totalSupply);
    }
}