// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPlusPlusToken is IERC20 {
  // Errors
  /**
   * @notice The error raised when the renouncement of a role is attempted
   */
  error RoleRenouncementDisabled();

  /**
   * @notice The error raised when a non-whitelisted recipient attempts to hold PlusPlus tokens
   * @param recipient The address of the recipient that is not whitelisted
   */
  error NotWhitelisted(address recipient);

  /**
   * @notice The error raised when an exchange is attempted but is disabled
   */
  error ExchangeDisabled();

  // Events
  /**
   * @notice The event emitted when the whitelist is updated
   * @param recipient The address of the recipient that is being updated
   * @param status The new status of the recipient
   */
  event WhitelistUpdated(address indexed recipient, bool status);

  // Functions
  /**
   * @dev Initializes the contract
   * @param rawToken_ The address of the raw token
   * @param earningToken_ The address of the earning token
   * @param targetRatio_ The target ratio of raw token to earning token principle (in basis points)
   * @param admin_ The address of the admin
   */
  function initialize(address rawToken_, address earningToken_, uint16 targetRatio_, address admin_) external;

  /**
   * @return The address of the raw token
   */
  function rawToken() external view returns (address);

  /**
   * @return The address of the earning token
   */
  function earnToken() external view returns (address);

  /**
   * @return The address of the raw token and earning token
   */
  function rawAndEarnToken() external view returns (address, address);

  /**
   * @return The target ratio of raw token / totalSupply (in basis points)
   */
  function targetRatio() external view returns (uint16);

  /**
   * @return The current ratio of raw token / totalSupply (in basis points)
   */
  function currentRatio() external view returns (uint16);

  /**
   * @notice Deposits raw token into the contract
   * @param rawAmount The amount of raw token to deposit
   * @return amount The amount of plusplus token received
   */
  function rawDeposit(uint256 rawAmount) external returns (uint256 amount);

  /**
   * @notice Withdraws raw token from the contract
   * @param rawAmount The amount of raw token to withdraw
   * @return amount The amount of plusplus token consumed
   */
  function rawWithdraw(uint256 rawAmount) external returns (uint256 amount);

  /**
   * @notice Deposits earning token into the contract
   * @param earnAmount The amount of earning token to deposit
   * @return amount The amount of plusplus token received
   */
  function earnDeposit(uint256 earnAmount) external returns (uint256 amount);

  /**
   * @notice Withdraws earning token from the contract
   * @param earnAmount The amount of earning token to withdraw
   * @return amount The amount of plusplus token consumed
   */
  function earnWithdraw(uint256 earnAmount) external returns (uint256 amount);

  /**
   * @notice Burns plusplus tokens and returns the amount of raw and earning tokens. Split is proportional to total balances of raw and earning tokens
   * @param amount The amount of plusplus tokens to burn
   * @return rawAmount The amount of raw tokens burned
   * @return earnAmount The amount of earning tokens burned
   */
  function burn(uint256 amount) external returns (uint256 rawAmount, uint256 earnAmount);

  /**
   * @notice Updates the whitelist of recipients allowed to hold PlusPlus tokens
   * @param recipient The address of the recipient to update
   * @param status Whether the recipient is whitelisted
   */
  function updateWhitelist(address recipient, bool status) external;

  /**
   * @notice Returns whether a recipient is whitelisted to hold PlusPlus tokens
   * @param recipient The address of the recipient to check
   * @return isWhitelisted Whether the recipient is whitelisted
   */
  function isWhitelisted(address recipient) external view returns (bool isWhitelisted);

  /**
   * @notice Updates the deposit and withdraw switches
   * @param rawDepositOn Whether raw deposits are enabled
   * @param rawWithdrawOn Whether raw withdrawals are enabled
   * @param earnDepositOn Whether earn deposits are enabled
   * @param earnWithdrawOn Whether earn withdrawals are enabled
   */
  function updateDepositWithdrawSwitches(bool rawDepositOn, bool rawWithdrawOn, bool earnDepositOn, bool earnWithdrawOn)
    external;
}
