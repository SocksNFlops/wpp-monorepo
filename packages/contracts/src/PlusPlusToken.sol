// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {console} from "forge-std/console.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IPlusPlus} from "./interface/IPlusPlus.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract PlusPlusToken is ERC20Upgradeable, IPlusPlus {
  using SafeERC20 for IERC20;

  /**
   * @custom:storage-location erc7201:plusplus.storage.plusplus
   * @param _rawToken The address of the raw token
   * @param _earningToken The address of the earning token
   * @param _targetRatio The target ratio of raw token to earning token principle
   * @param _lastTotalStake The last total stake
   */
  struct PlusPlusTokenStorage {
    address _rawToken;
    address _earningToken;
    uint16 _targetRatio;
    TokenStake _lastTotalStake;
    mapping(address => TokenStake) _tokenStakes;
  }

  // ToDo: Validate this hash
  // keccak256(abi.encode(uint256(keccak256("plusplus.storage.plusplus")) - 1)) & ~bytes32(uint256(0xff))
  bytes32 private constant PlusPlusTokenStorageLocation =
    0x916815e707b896d4cbd2bb2f2391cdf5114a0642fcf78c9c686b8bc97694bf00;

  function _getPlusPlusTokenStorage() private pure returns (PlusPlusTokenStorage storage $) {
    assembly {
      $.slot := PlusPlusTokenStorageLocation
    }
  }

  /**
   * @dev Sets the values for {name} and {symbol}.
   *
   * All two of these values are immutable: they can only be set once during
   * construction.
   */
  function __PlusPlusToken_init(address rawToken_, address earningToken_, uint16 targetRatio_)
    internal
    onlyInitializing
  {
    __ERC20_init("PlusPlusToken", "PP");
    __PlusPlusToken_init_unchained(rawToken_, earningToken_, targetRatio_);
  }

  function __PlusPlusToken_init_unchained(address rawToken_, address earningToken_, uint16 targetRatio_)
    internal
    onlyInitializing
  {
    PlusPlusTokenStorage storage $ = _getPlusPlusTokenStorage();
    $._rawToken = rawToken_;
    $._earningToken = earningToken_;
    $._targetRatio = targetRatio_;
  }

  /**
   * @inheritdoc IPlusPlus
   */
  function initialize(address rawToken_, address earningToken_, uint16 targetRatio_) public initializer {
    __PlusPlusToken_init(rawToken_, earningToken_, targetRatio_);
  }

  /**
   * @inheritdoc IPlusPlus
   */
  function rawToken() external view returns (address) {
    return _getPlusPlusTokenStorage()._rawToken;
  }

  /**
   * @inheritdoc IPlusPlus
   */
  function earningToken() external view returns (address) {
    return _getPlusPlusTokenStorage()._earningToken;
  }

  /**
   * @inheritdoc IPlusPlus
   */
  function targetRatio() external view returns (uint16) {
    return _getPlusPlusTokenStorage()._targetRatio;
  }

  /**
   * @inheritdoc IPlusPlus
   */ 
  function lastTotalStake() external view returns (TokenStake memory) {
    return _getPlusPlusTokenStorage()._lastTotalStake;
  }

  

  function _convertPoints(address account) internal {
    // Fetch storage
    PlusPlusTokenStorage storage $ = _getPlusPlusTokenStorage();

    // Get the token stake
    TokenStake storage tokenStake = $._tokenStakes[account];
    // Increment the accrued points
    tokenStake.accruedPoints += (uint256(block.timestamp) - tokenStake.timestamp) * balanceOf(account);
    // Update timestamp to now
    tokenStake.timestamp = uint128(block.timestamp);
  }

  function _updateTotalPoints() internal {
    // Fetch storage
    PlusPlusTokenStorage storage $ = _getPlusPlusTokenStorage();
    // Get the last total stake
    TokenStake storage lastTotalStake = $._lastTotalStake;
    // Update total points and last timestamp
    $._lastTotalStake.accruedPoints += (uint256(block.timestamp) - lastTotalStake.timestamp) * totalSupply();
    $._lastTotalStake.timestamp = uint128(block.timestamp);
  }

  /**
   * @inheritdoc IPlusPlus
   */
  function deposit(address account, uint256 rawAmount) external returns (uint256 amount) {
    // Fetch storage
    PlusPlusTokenStorage storage $ = _getPlusPlusTokenStorage();
    
    // Update existing token stake
    _convertPoints(account);

    // Update total points
    _updateTotalPoints();

    // Mint plusplus tokens
    _mint(account, rawAmount);

    // Transfer raw tokens from sender to this contract
    IERC20($._rawToken).safeTransferFrom(msg.sender, address(this), rawAmount);

    // Return amount of plusplus tokens minted
    amount = rawAmount;
  }

  /**
   * @inheritdoc IPlusPlus
   */
  function withdraw(address account, uint256 rawAmount) external returns (uint256 amount) {
    // Fetch storage
    PlusPlusTokenStorage storage $ = _getPlusPlusTokenStorage();

    // Update existing token stake
    _convertPoints(account);

    // Update total points
    _updateTotalPoints();

    // Burn plusplus tokens
    _burn(account, rawAmount);

    // Transfer raw tokens from this contract to sender
    IERC20($._rawToken).safeTransfer(account, rawAmount);

    // Return amount of plusplus tokens burned
    amount = rawAmount;
  }

  function points(address account) public view returns (uint256 pendingPoints) {
    // Fetch storage
    PlusPlusTokenStorage storage $ = _getPlusPlusTokenStorage();

    // Get the token stake
    TokenStake storage tokenStake = $._tokenStakes[account];

    console.log("tokenStake.accruedPoints", tokenStake.accruedPoints);
    console.log("tokenStake.timestamp", tokenStake.timestamp);
    console.log("balanceOf(account)", balanceOf(account));
    console.log("block.timestamp", block.timestamp);
    console.log("--------------------------------");
    console.log("(uint256(block.timestamp) - tokenStake.timestamp)", (uint256(block.timestamp) - tokenStake.timestamp));
    console.log("(uint256(block.timestamp) - tokenStake.timestamp) * balanceOf(account)", (uint256(block.timestamp) - tokenStake.timestamp) * balanceOf(account));
    console.log("tokenStake.accruedPoints + (uint256(block.timestamp) - tokenStake.timestamp) * balanceOf(account)", tokenStake.accruedPoints + (uint256(block.timestamp) - tokenStake.timestamp) * balanceOf(account));
    console.log("--------------------------------");

    // Calculate pending points
    pendingPoints = tokenStake.accruedPoints + (uint256(block.timestamp) - tokenStake.timestamp) * balanceOf(account);
  }

  function totalPoints() public view returns (uint256) {
    // Fetch storage
    PlusPlusTokenStorage storage $ = _getPlusPlusTokenStorage();
    
    // Calculate total points
    return $._lastTotalStake.accruedPoints + (uint256(block.timestamp) - $._lastTotalStake.timestamp) * totalSupply();
  }
}
