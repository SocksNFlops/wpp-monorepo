// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface IFlaunch {
  function approve(address spender, uint256 amount) external returns (bool);

  function tokenId(address memecoin) external returns (uint256);
}
