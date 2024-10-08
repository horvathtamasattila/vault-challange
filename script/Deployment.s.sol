// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "forge-std/Script.sol";
import "../src/MyNFT.sol";

contract DeployMyNFT is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("8c87bdb9ef563c4e780ae3e4b7f3c3e87eff6f60cb9fb565b57788c34efd0ab1");
        vm.startBroadcast(deployerPrivateKey);

        MyNFT myNft = new MyNFT();

        vm.stopBroadcast();
    }
}
