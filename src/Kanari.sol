// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {FHE, euint64, externalEuint64} from "lib/zama-lib/src/FHE.sol";
import {SepoliaConfig} from "lib/zama-lib/src/ZamaConfig.sol";

/// @title Kanari ERC20 token with FHE integration example
/// @notice Simple ERC20 token that also stores an encrypted balance mapping (euint64)
contract Kanari is ERC20, Ownable, SepoliaConfig {
    mapping(address => euint64) private encryptedBalances;

    // Max supply: 11,000,000 tokens with 18 decimals
    uint256 public constant MAX_SUPPLY = 11_000_000 * 10 ** 18;

    constructor(uint256 initialSupply) ERC20("Kanari", "KAN") Ownable(msg.sender) SepoliaConfig() {
        require(initialSupply <= MAX_SUPPLY, "initial supply exceeds max");
        _mint(msg.sender, initialSupply);
    }

    /// @notice Example: accept an encrypted deposit (external handle + proof) and add to the encrypted balance
    /// @dev This doesn't affect the clear ERC20 balance, it's an example of storing and updating encrypted data via FHE.
    function depositEncrypted(externalEuint64 inputHandle, bytes memory inputProof) public {
        euint64 incoming = FHE.fromExternal(inputHandle, inputProof);
        // If sender has no prior encrypted balance the library handles initialization
        encryptedBalances[msg.sender] = FHE.add(encryptedBalances[msg.sender], incoming);
        // Allow this contract to use the updated handles
        FHE.allowThis(encryptedBalances[msg.sender]);
    }

    /// @notice Get the encrypted handle as bytes32 for off-chain decryption requests
    function encryptedBalanceHandle(address who) public view returns (bytes32) {
        return FHE.toBytes32(encryptedBalances[who]);
    }

    /// @notice Owner can mint clear tokens up to MAX_SUPPLY
    function mint(address to, uint256 amount) public onlyOwner {
        require(totalSupply() + amount <= MAX_SUPPLY, "mint would exceed max supply");
        _mint(to, amount);
    }

    /// @notice Burn tokens from caller
    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }

    /// @notice Burn tokens from `account` using allowance
    function burnFrom(address account, uint256 amount) public {
        uint256 currentAllowance = allowance(account, _msgSender());
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }
}
