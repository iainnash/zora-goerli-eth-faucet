// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {ERC721} from "solmate/tokens/ERC721.sol";
import {Owned} from "solmate/auth/Owned.sol";

/// @author Iain Nash @iainnash
/// @notice Contract for distributing testnet funds in a given time period for each distribution
contract Faucet is Owned {
    event Received(address indexed from, uint256 value, uint256 balance);
    event SettingsUpdated(address indexed from, ERC721 nft, uint256 max);

    ERC721 public targetNFT;
    uint256 public claimMax = 1 ether;
    mapping(address => mapping(uint256 => uint256)) internal claims;
    error UserNFTBalanceTooLow();
    error ClaimedMoreThanAllowed(uint256 attemptClaimed, uint256 max);
    error TransferFailed();

    modifier onlyNFTOwner() {
        if (targetNFT.balanceOf(msg.sender) < 1) {
            revert UserNFTBalanceTooLow();
        }

        _;
    }

    constructor(address _owner) Owned(_owner) {

    }

    function updateSettings(ERC721 _targetNFT, uint256 _claimMax)
        external
        onlyOwner
    {
        targetNFT = _targetNFT;
        claimMax = _claimMax;

        emit SettingsUpdated(msg.sender, _targetNFT, _claimMax);
    }

    function claimAmount(uint256 amount) public onlyNFTOwner {
        uint256 claimAmountOverTime = claims[msg.sender][
            block.timestamp / 1 days
        ] + amount;
        if (claimAmountOverTime > claimMax) {
            revert ClaimedMoreThanAllowed(claimAmountOverTime, claimMax);
        }

        claims[msg.sender][block.timestamp / 1 days] = claimAmountOverTime;

        // transfer
        (bool success, ) = payable(msg.sender).call{
            value: amount,
            gas: 300_000
        }("");
        if (!success) {
            revert TransferFailed();
        }
    }

    function claimAllAvailable() external {
        claimAmount(claimMax);
    }

    function ownerWithdraw(uint256 amount) external onlyOwner {
        if (amount == 0) {
            amount = address(this).balance;
        }
        (bool success, ) = address(msg.sender).call{value: amount}("");
        if (!success) {
            revert TransferFailed();
        }
    }

    receive() payable external {
        emit Received(msg.sender, msg.value, address(this).balance);
    }
}
