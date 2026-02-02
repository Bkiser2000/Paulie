// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/// @title Paulie - The Yield-Bearing Meme Coin
/// @notice ERC20 token with 90/10 JitoSOL reward mechanism on Solana
/// Supply: 420B tokens
/// Tax: 1.15% on buy/sell, 0% on transfers
/// Rewards: 90% → JitoSOL to holders, 10% → Dev/Operations (CompFi Umbrella)
contract Paulie is Initializable, 
    ERC20Upgradeable, 
    OwnableUpgradeable, 
    PausableUpgradeable, 
    ERC20PermitUpgradeable,
    UUPSUpgradeable 
{
    // === TOKENOMICS CONSTANTS ===
    uint256 public constant MAX_SUPPLY = 420_000_000_000 * 10**18; // 420B tokens
    uint256 public constant INITIAL_SUPPLY = 420_000_000_000 * 10**18;
    
    // === TAX STRUCTURE (in basis points: 1 bp = 0.01%) ===
    uint256 public constant TOTAL_TAX = 115; // 1.15% total tax
    uint256 public constant REWARDS_TAX = 103; // 1.035% → JitoSOL rewards (90%)
    uint256 public constant DEV_TAX = 12; // 0.115% → Dev/Ops (10%)
    uint256 public constant BPS_DIVISOR = 10000; // basis points divisor
    
    // === ADDRESSES ===
    address public jitosolAddress; // JitoSOL token address
    address public devWallet; // CompFi Umbrella wallet for dev/marketing/ops
    address public rewardsVault; // Vault for distributing JitoSOL rewards
    
    // === TRACKING ===
    mapping(address => bool) public excludedFromTax;
    mapping(address => bool) public isAMM;
    
    // === EVENTS ===
    event TaxCollected(uint256 rewardsAmount, uint256 devAmount);
    event RewardsDistributed(uint256 jitosolAmount);
    event JitoSOLSwapped(uint256 paulieAmount, uint256 jitosolReceived);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _jitosolAddress,
        address _devWallet,
        address _rewardsVault
    ) public initializer {
        __ERC20_init("Paulie", "PAULIE");
        __Ownable_init();
        __Pausable_init();
        __ERC20Permit_init("Paulie");
        
        jitosolAddress = _jitosolAddress;
        devWallet = _devWallet;
        rewardsVault = _rewardsVault;
        
        // Exclude core addresses from tax
        excludedFromTax[msg.sender] = true;
        excludedFromTax[_rewardsVault] = true;
        excludedFromTax[_devWallet] = true;
        
        // Mint initial supply to owner
        _mint(msg.sender, INITIAL_SUPPLY);
    }

    // === TAX MECHANISM ===
    
    /// @notice Calculate tax on transfer amount
    /// @param amount Transfer amount
    /// @return taxAmount Total tax amount (1.15%)
    function calculateTax(uint256 amount) public pure returns (uint256) {
        return (amount * TOTAL_TAX) / BPS_DIVISOR;
    }

    /// @notice Split tax between rewards (90%) and dev (10%)
    /// @param taxAmount Total tax collected
    /// @return rewardsAmount Amount for JitoSOL rewards
    /// @return devAmount Amount for dev/ops
    function splitTax(uint256 taxAmount) public pure returns (uint256, uint256) {
        uint256 rewardsAmount = (taxAmount * REWARDS_TAX) / TOTAL_TAX;
        uint256 devAmount = taxAmount - rewardsAmount;
        return (rewardsAmount, devAmount);
    }

    /// @notice Transfer with tax applied (for buy/sell transactions)
    /// @dev Applies 1.15% tax on swaps, 0% on transfers
    function _transferWithTax(
        address from,
        address to,
        uint256 amount,
        bool isTaxable
    ) internal {
        if (!isTaxable || excludedFromTax[from] || excludedFromTax[to]) {
            // No tax: transfers, or excluded addresses
            super._transfer(from, to, amount);
        } else {
            // Apply tax on buy/sell
            uint256 taxAmount = calculateTax(amount);
            uint256 transferAmount = amount - taxAmount;
            
            (uint256 rewardsAmount, uint256 devAmount) = splitTax(taxAmount);
            
            // Transfer net amount to recipient
            super._transfer(from, to, transferAmount);
            
            // Send rewards portion to rewards vault
            super._transfer(from, rewardsVault, rewardsAmount);
            
            // Send dev portion to dev wallet
            super._transfer(from, devWallet, devAmount);
            
            emit TaxCollected(rewardsAmount, devAmount);
        }
    }

    // === CORE OVERRIDES ===

    /// @notice Override transfer to apply tax on swaps
    function transfer(address to, uint256 amount) 
        public 
        override 
        returns (bool) 
    {
        _transferWithTax(msg.sender, to, amount, false); // 0% tax on transfers
        return true;
    }

    /// @notice Override transferFrom to apply tax on swaps
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) 
        public 
        override 
        returns (bool) 
    {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transferWithTax(from, to, amount, isAMM[to] || isAMM[from]); // Tax on AMM trades
        return true;
    }

    // === ADMIN FUNCTIONS ===

    /// @notice Set JitoSOL token address
    function setJitoSOLAddress(address _jitosolAddress) external onlyOwner {
        jitosolAddress = _jitosolAddress;
    }

    /// @notice Set dev wallet address
    function setDevWallet(address _devWallet) external onlyOwner {
        devWallet = _devWallet;
    }

    /// @notice Set rewards vault address
    function setRewardsVault(address _rewardsVault) external onlyOwner {
        rewardsVault = _rewardsVault;
    }

    /// @notice Exclude address from tax
    function excludeFromTax(address account, bool excluded) external onlyOwner {
        excludedFromTax[account] = excluded;
    }

    /// @notice Mark address as AMM pair (applies tax)
    function setAMM(address account, bool _isAMM) external onlyOwner {
        isAMM[account] = _isAMM;
    }

    /// @notice Pause contract (only owner)
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpause contract (only owner)
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Authorize upgrade (only owner)
    function _authorizeUpgrade(address newImplementation) internal onlyOwner override {}

    // === REQUIRED OVERRIDES ===

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    )
        internal
        override(ERC20Upgradeable)
        whenNotPaused
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}
