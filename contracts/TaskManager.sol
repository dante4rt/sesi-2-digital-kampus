// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract TaskManager {
    // State Variables & Scope
    address public owner; // public: bisa dibaca siapa saja
    uint256 public taskCount; // counter tasks
    bool private isActive; // private: hanya contract ini

    // Mapping: alamat -> jumlah task user
    mapping(address => uint256) public userTaskCount;

    // Functions dengan berbagai visibility
    constructor() {
        owner = msg.sender; // yang deploy = owner
        isActive = true;
        taskCount = 0;
    }

    // View function: baca data, no gas (kecuali dipanggil dari contract)
    function getOwner() public view returns (address) {
        return owner;
    }

    // Pure function: no read/write state, hanya komputasi
    function calculateFee(uint256 amount) public pure returns (uint256) {
        return (amount * 2) / 100; // 2% fee
    }

    // Public function: bisa dipanggil dari mana saja
    function addTask() public {
        require(isActive, "Contract not active");
        taskCount++;
        userTaskCount[msg.sender]++;
    }

    // Private function: hanya dari dalam contract
    function _updateStatus() private {
        isActive = taskCount < 1000;
    }
}
