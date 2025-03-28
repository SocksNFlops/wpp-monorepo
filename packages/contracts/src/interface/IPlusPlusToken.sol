// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPlusPlusToken is IERC20 {
  /**
   * @notice The token stake for a given account
   * @param accruedPoints The amount of accrued points
   * @param timestamp The last timestamp when points were updated
   */
  struct TokenStake {
    uint256 accruedPoints;
    uint128 timestamp;
  }

  /**
   * @dev Initializes the contract
   * @param rawToken_ The address of the raw token
   * @param earningToken_ The address of the earning token
   * @param targetRatio_ The target ratio of raw token to earning token principle (in basis points)
   */
  function initialize(address rawToken_, address earningToken_, uint16 targetRatio_) external;

  /**
   * @return The address of the raw token
   */
  function rawToken() external view returns (address);

  /**
   * @return The address of the earning token
   */
  function earningToken() external view returns (address);

  /**
   * @return The target ratio of raw token to earning token principle (in basis points)
   */
  function targetRatio() external view returns (uint16);

  /**
   * @return The last total stake
   */
  function lastTotalStake() external view returns (TokenStake memory);

  /**
   * @notice Deposits raw token into the contract
   * @param account The address of the account to deposit for
   * @param rawAmount The amount of raw token to deposit
   * @return amount The amount of plusplus token received
   */
  function deposit(address account, uint256 rawAmount) external returns (uint256 amount);

  /**
   * @notice Withdraws raw token from the contract
   * @param account The address of the account to withdraw for
   * @param rawAmount The amount of raw token to withdraw
   * @return amount The amount of plusplus token consumed
   */
  function withdraw(address account, uint256 rawAmount) external returns (uint256 amount);

  /**
   * @notice Returns the points for a given account
   * @param account The address of the account to check
   * @return points The amount of points
   */
  function points(address account) external view returns (uint256 points);

  /**
   * @notice Returns the total points
   * @return totalPoints The amount of total points
   */
  function totalPoints() external view returns (uint256 totalPoints);
}
