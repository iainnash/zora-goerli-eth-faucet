// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IPartialERC721 {
  function balanceOf(address user) external view returns (uint256);
}