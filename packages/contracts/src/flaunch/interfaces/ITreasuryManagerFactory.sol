// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface ITreasuryManagerFactory {
  function deployManager(address _managerImplementation) external returns (address payable manager_);
}
