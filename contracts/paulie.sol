// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/// @title Cannacoin - An ERC20 token with governance features (Upgradeable)
contract Paulie is Initializable, 
    ERC20Upgradeable, 
    OwnableUpgradeable, 
    PausableUpgradeable, 
    ERC20PermitUpgradeable,
    UUPSUpgradeable 
{
    uint256 public constant MAX_SUPPLY = 420_000_000_000 * 10**18;
    uint256 public constant INITIAL_SUPPLY = 420_000_000_000 * 10**18;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address splitAddress) public initializer {
        __ERC20_init("Paulie", "PAULIE");
        __Ownable_init();
        __Pausable_init();
        __ERC20Permit_init("Paulie");
        uint256 ownerAmount = (INITIAL_SUPPLY * 90) / 100;
        uint256 splitAmount = INITIAL_SUPPLY - ownerAmount;
        _mint(msg.sender, ownerAmount);
        _mint(splitAddress, splitAmount);
    }

    /// @notice Pause contract (only owner)
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpause contract (only owner)
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Mint tokens up to MAX_SUPPLY (only owner)
    /// @param to Address to mint tokens to
    /// @param amount Amount of tokens to mint
    function mint(address to, uint256 amount) external onlyOwner {
        require(totalSupply() + amount <= MAX_SUPPLY, "Exceeds max supply");
        _mint(to, amount);
    }

    /// @notice Authorize upgrade (only owner)
    /// @param newImplementation Address of new implementation
    function _authorizeUpgrade(address newImplementation) internal onlyOwner override {}

    // --- Required overrides for ERC20 and Pausable ---

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20Upgradeable)
        whenNotPaused
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}
