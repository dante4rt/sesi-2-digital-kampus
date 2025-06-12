// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {ERC20Pausable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title CampusCredit
 * @dev ERC-20 token untuk transaksi dalam kampus
 * Use cases:
 * - Pembayaran di kafetaria
 * - Biaya printing dan fotokopi
 * - Laundry service
 * - Peminjaman equipment
 */
contract CampusCredit is ERC20, ERC20Burnable, ERC20Pausable, AccessControl {
    // TODO: Define role constants
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // Additional features untuk kampus
    mapping(address => uint256) public dailySpendingLimit;
    mapping(address => uint256) public spentToday;
    mapping(address => uint256) public lastSpendingReset;

    // Merchant whitelist
    mapping(address => bool) public isMerchant;
    mapping(address => string) public merchantName;

    // Events
    event TransferWithCashback(
        address indexed from,
        address indexed merchant,
        uint256 amount,
        uint256 cashback
    );

    constructor() ERC20("Campus Credit", "CREDIT") {
        // TODO: Setup roles
        // Hint:
        // 1. Grant DEFAULT_ADMIN_ROLE ke msg.sender
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        // 2. Grant PAUSER_ROLE ke msg.sender
        _grantRole(PAUSER_ROLE, msg.sender);
        // 3. Grant MINTER_ROLE ke msg.sender
        _grantRole(MINTER_ROLE, msg.sender);
        // 4. Consider initial mint untuk treasury
        _mint(msg.sender, 1_000_000 * 10 ** decimals());
    }

    /**
     * @dev Pause all token transfers
     * Use case: Emergency atau maintenance
     */
    function pause() public {
        // TODO: Implement dengan role check
        // Only PAUSER_ROLE can pause
        require(hasRole(PAUSER_ROLE, msg.sender), "Caller is not a paus00r");
        _pause();
    }

    function unpause() public {
        // TODO: Implement unpause
        require(hasRole(PAUSER_ROLE, msg.sender), "Caller is not a paus00r");
        _unpause();
    }

    /**
     * @dev Mint new tokens
     * Use case: Top-up saldo mahasiswa
     */
    function mint(address to, uint256 amount) public {
        // TODO: Implement dengan role check
        // Only MINTER_ROLE can mint
        // Consider adding minting limits
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");
        require(amount > 0, "Amount must be greater than zero");
        require(to != address(0), "Cannot mint to zero address");
        require(
            balanceOf(to) + amount <= 1_000_000 * 10 ** decimals(),
            "Minting limit exceeded"
        );

        _mint(to, amount);
    }

    /**
     * @dev Register merchant
     * Use case: Kafetaria, toko buku, laundry
     */
    function registerMerchant(
        address merchant,
        string memory name
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        // TODO: Register merchant untuk accept payments
        require(merchant != address(0), "Invalid merchant address");
        require(bytes(name).length > 0, "Merchant name cannot be empty");
        require(!isMerchant[merchant], "Merchant already registered");

        isMerchant[merchant] = true;
        merchantName[merchant] = name;
    }

    /**
     * @dev Set daily spending limit untuk mahasiswa
     * Use case: Parental control atau self-control
     */
    function setDailyLimit(
        address student,
        uint256 limit
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        // TODO: Set spending limit
        require(student != address(0), "Invalid student address");
        require(limit > 0, "Limit must be greater than zero");

        dailySpendingLimit[student] = limit;
        lastSpendingReset[student] = block.timestamp;
        spentToday[student] = 0;
    }

    /**
     * @dev Transfer dengan spending limit check
     */
    function transferWithLimit(address to, uint256 amount) public {
        // TODO: Check daily limit before transfer
        // Reset limit if new day
        // Update spent amount
        // Then do normal transfer
        require(to != address(0), "Cannot transfer to zero address");
        require(amount > 0, "Amount must be greater than zero");
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");

        require(dailySpendingLimit[msg.sender] > 0, "Daily limit not set");

        if (block.timestamp - lastSpendingReset[msg.sender] >= 1 days) {
            spentToday[msg.sender] = 0;
            lastSpendingReset[msg.sender] = block.timestamp;
        }

        require(
            spentToday[msg.sender] + amount <= dailySpendingLimit[msg.sender],
            "Daily spending limit exceeded"
        );

        spentToday[msg.sender] += amount;
        _transfer(msg.sender, to, amount);
    }

    /**
     * @dev Override _beforeTokenTransfer untuk add pause functionality
     */
    /**
        function _beforeTokenTransfer(
            address from,
            address to,
            uint256 amount
        ) internal override(ERC20) {
            // TODO: Add pause check
            super._beforeTokenTransfer(from, to, amount);
            require(!paused(), "Token transfers paused");
        }
      */
    function _update(
        address from,
        address to,
        uint256 value
    ) internal override(ERC20, ERC20Pausable) {
        require(!paused(), "Token transfers paused");

        super._update(from, to, value);
    }

    /**
     * @dev Cashback mechanism untuk encourage usage
     */
    uint256 public cashbackPercentage = 2; // 2%

    function transferWithCashback(address merchant, uint256 amount) public {
        // TODO: Transfer to merchant dengan cashback ke sender
        // Calculate cashback
        // Transfer main amount
        // Mint cashback to sender
        require(isMerchant[merchant], "Not a registered merchant");
        require(amount > 0, "Amount must be greater than zero");
        require(
            balanceOf(msg.sender) >= amount,
            "Insufficient Campus Credit balance"
        );
        require(
            dailySpendingLimit[msg.sender] > 0,
            "Daily limit not set for sender"
        );

        if (block.timestamp - lastSpendingReset[msg.sender] >= 1 days) {
            spentToday[msg.sender] = 0;
            lastSpendingReset[msg.sender] = block.timestamp;
        }

        require(
            spentToday[msg.sender] + amount <= dailySpendingLimit[msg.sender],
            "Daily spending limit exceeded"
        );

        spentToday[msg.sender] += amount;
        _transfer(msg.sender, merchant, amount);

        uint256 cashback = (amount * cashbackPercentage) / 100;
        _mint(msg.sender, cashback);

        emit TransferWithCashback(msg.sender, merchant, amount, cashback);
    }
}
