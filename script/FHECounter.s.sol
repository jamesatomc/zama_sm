// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "../lib/forge-std/src/Script.sol";
import "src/FHECounter.sol";

contract FHECounterScript is Script {

    function run() external {
        vm.startBroadcast();

        // Deploy the FHECounter contract. It inherits SepoliaConfig which
        // sets up the FHE coprocessor addresses in its constructor, so there
        // are no constructor arguments required here.
        FHECounter counter = new FHECounter();

        // Print the deployed address to the console for convenience.
        console.log("FHECounter deployed at:", address(counter));

        vm.stopBroadcast();
    }
}