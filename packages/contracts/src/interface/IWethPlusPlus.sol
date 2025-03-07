// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWethPlusPlus is IERC20 {

  /**
   * @dev Initializes the contract
   * @param weth_ The address of the WETH token
   * @param stakedEth_ The address of the staked ETH token
   * @param targetRatio_ The target ratio of WETH to staked ETH principle (in basis points)
   */
  function initialize(address weth_, address stakedEth_, uint16 targetRatio_) external;

  /**
   * @return The address of the WETH token
   */
  function weth() external view returns (address);

  /**
   * @return The address of the staked ETH token
   */
  function stakedEth() external view returns (address);

  /**
   * @return The target ratio of WETH to staked ETH principle (in basis points)
   */
  function targetRatio() external view returns (uint16);
}
