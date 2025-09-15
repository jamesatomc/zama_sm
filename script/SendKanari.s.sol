// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import "../src/Kanari.sol";

contract SendKanari is Script {
    // Recipient hardcoded as requested
    address constant RECIPIENT = 0xC88C539aa6f67daeDaeA7aff75FE1F8848d6CeC2;

    function run() external {
        // Optional: read an existing Kanari address from env using a safe low-level call
        address kanariAddr = address(0);
        {
            (bool okAddr, bytes memory resAddr) = address(vm).call(abi.encodeWithSignature("envAddress(string)", "KANARI_ADDRESS"));
            if (okAddr && resAddr.length >= 32) {
                kanariAddr = abi.decode(resAddr, (address));
            }
        }

        // Optional: AMOUNT in wei (ERC20 decimals); if not provided default to 100 KAN
        uint256 amount = 0;
        {
            (bool okUint, bytes memory resUint) = address(vm).call(abi.encodeWithSignature("envUint(string)", "AMOUNT"));
            if (okUint && resUint.length >= 32) {
                amount = abi.decode(resUint, (uint256));
            }
        }
        if (amount == 0) {
            amount = 100 * 10 ** 18; // default 100 KAN
        }

    // Start broadcast; the private key can be provided via CLI (--private-key)
    vm.startBroadcast();

        Kanari kanari;
        if (kanariAddr == address(0)) {
            // deploy a new Kanari with initialSupply = 0
            kanari = new Kanari(0);
            kanariAddr = address(kanari);
        } else {
            kanari = Kanari(kanariAddr);
        }

        // Prefer minting (owner-only). If mint reverts, try a standard transfer
        // Use low-level call to detect revert without bubbling.
        (bool ok, ) = address(kanari).call(abi.encodeWithSignature("mint(address,uint256)", RECIPIENT, amount));
        if (!ok) {
            // Mint failed (not owner or other). Try a transfer from the broadcast signer
            // This requires the signer to have a sufficient token balance.
            (bool ok2, bytes memory ret) = address(kanari).call(abi.encodeWithSignature("transfer(address,uint256)", RECIPIENT, amount));
            require(ok2, string(ret.length > 0 ? abi.decode(ret, (string)) : "mint and transfer both failed"));
        }

        vm.stopBroadcast();
    }
}
