// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/hacks/Reentrancy.sol";

contract ReentrancyTest is Test {
    FaultyVault vault;
    Attack attack;

    function setUp() public {
        vault = new FaultyVault();
        attack = new Attack(address(vault));
    }

    function testReentrancy() public {
        // Fund the Vault with some Ether
        vm.deal(address(vault), 10 ether);

        // Perform attack
        attack.attack{value: 1 ether}();

        // Check final balances
        assertGt(address(attack).balance, 1 ether, "Attack failed");
        assertEq(address(vault).balance, 0, "Vault was drained");
    }
}