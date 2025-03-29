// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {console} from "forge-std/console.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {EIP712Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IPlusPlusToken} from "./interface/IPlusPlusToken.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

// ToDo: Rewrite points to use shares rather than raw deposit amounts
// ToDo: Separate tokenHolder and points-earner
contract PlusPlusToken is
  ERC20Upgradeable,
  EIP712Upgradeable,
  UUPSUpgradeable,
  AccessControlUpgradeable,
  IPlusPlusToken
{
  using SafeERC20 for IERC20;

  uint256 public constant POINTS_PRECISION = 1e6;

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
    mapping(address => bool) _whitelist;
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
   * @dev Authorizes the upgrade of the contract. Only the admin can authorize the upgrade.
   * @param newImplementation The address of the new implementation.
   */
  function _authorizeUpgrade(address newImplementation) internal virtual override onlyRole(DEFAULT_ADMIN_ROLE) {}

  /**
   * @dev This function is disabled to prevent the renouncement of roles
   */
  function renounceRole(bytes32, address) public virtual override {
    revert RoleRenouncementDisabled();
  }

  /**
   * /**
   * @dev Sets the values for {name} and {symbol}.
   *
   * All two of these values are immutable: they can only be set once during
   * construction.
   */
  function __PlusPlusToken_init(address rawToken_, address earningToken_, uint16 targetRatio_, address admin_)
    internal
    onlyInitializing
  {
    string memory name = string.concat(IERC20Metadata(rawToken_).name(), " - PlusPlus");
    string memory symbol = string.concat(IERC20Metadata(rawToken_).symbol(), "++");
    __ERC20_init(name, symbol);
    __EIP712_init("PlusPlusToken", "1");
    __AccessControl_init();
    __PlusPlusToken_init_unchained(rawToken_, earningToken_, targetRatio_);
    _grantRole(DEFAULT_ADMIN_ROLE, admin_);
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
   * @inheritdoc IPlusPlusToken
   */
  function initialize(address rawToken_, address earningToken_, uint16 targetRatio_, address admin_) public initializer {
    __PlusPlusToken_init(rawToken_, earningToken_, targetRatio_, admin_);
  }

  /**
   * @inheritdoc IERC20Metadata
   */
  function decimals() public view override returns (uint8) {
    return IERC20Metadata(_getPlusPlusTokenStorage()._rawToken).decimals();
  }

  /**
   * @inheritdoc IPlusPlusToken
   */
  function rawToken() external view returns (address) {
    return _getPlusPlusTokenStorage()._rawToken;
  }

  /**
   * @inheritdoc IPlusPlusToken
   */
  function earningToken() external view returns (address) {
    return _getPlusPlusTokenStorage()._earningToken;
  }

  /**
   * @inheritdoc IPlusPlusToken
   */
  function targetRatio() external view returns (uint16) {
    return _getPlusPlusTokenStorage()._targetRatio;
  }

  /**
   * @inheritdoc IPlusPlusToken
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
    tokenStake.accruedPoints += (uint256(block.timestamp) - tokenStake.timestamp) * tokenStake.shares;
    // Update timestamp to now
    tokenStake.timestamp = uint128(block.timestamp);
  }

  function _updateTotalPoints() internal {
    // Fetch storage
    PlusPlusTokenStorage storage $ = _getPlusPlusTokenStorage();
    // Get the last total stake
    TokenStake storage _lastTotalStake = $._lastTotalStake;
    // Update total points and last timestamp
    _lastTotalStake.accruedPoints += (uint256(block.timestamp) - _lastTotalStake.timestamp) * _lastTotalStake.shares;
    _lastTotalStake.timestamp = uint128(block.timestamp);
  }

  function calculateShares(uint256 depositAmount) internal view returns (uint256) {
    // Fetch storage
    PlusPlusTokenStorage storage $ = _getPlusPlusTokenStorage();
    TokenStake storage _lastTotalStake = $._lastTotalStake;
    if (_lastTotalStake.shares == 0) {
      return depositAmount * POINTS_PRECISION;
    } else {
      return Math.mulDiv(depositAmount, _lastTotalStake.shares, totalSupply());
    }
  }

  /**
   * @inheritdoc IPlusPlusToken
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
   * @inheritdoc IPlusPlusToken
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

  function points(address account) public view returns (uint256 points) {
    // Fetch storage
    PlusPlusTokenStorage storage $ = _getPlusPlusTokenStorage();

    // Get the token stake
    TokenStake storage tokenStake = $._tokenStakes[account];

    // Calculate pending points and add them to accrued points
    points = tokenStake.accruedPoints + (uint256(block.timestamp) - tokenStake.timestamp) * tokenStake.shares;
  }

  function totalPoints() public view returns (uint256) {
    // Fetch storage
    PlusPlusTokenStorage storage $ = _getPlusPlusTokenStorage();

    // Calculate total points
    return $._lastTotalStake.accruedPoints + (uint256(block.timestamp) - $._lastTotalStake.timestamp) * $._lastTotalStake.shares;
  }

  /**
   * @inheritdoc IPlusPlusToken
   */
  function updateWhitelist(address recipient, bool status) external onlyRole(DEFAULT_ADMIN_ROLE) {
    // Fetch storage
    PlusPlusTokenStorage storage $ = _getPlusPlusTokenStorage();

    // Update the whitelist
    $._whitelist[recipient] = status;

    // Emit the whitelist updated event
    emit WhitelistUpdated(recipient, status);
  }

  /**
   * @inheritdoc IPlusPlusToken
   */
  function isWhitelisted(address recipient) external view returns (bool) {
    // Fetch storage
    PlusPlusTokenStorage storage $ = _getPlusPlusTokenStorage();

    // Return the whitelist
    return $._whitelist[recipient];
  }

  /**
   * @dev Overrides the ERC20Upgradeable `_update` function to revert if the recipient is not whitelisted
   * @inheritdoc ERC20Upgradeable
   */
  function _update(address from, address to, uint256 value) internal override {
    // Fetch storage
    PlusPlusTokenStorage storage $ = _getPlusPlusTokenStorage();

    // Revert if the recipient is not whitelisted
    if (to != address(0) && !this.isWhitelisted(to)) {
      revert NotWhitelisted(to);
    }

    // Update shares
    uint256 shares = calculateShares(value);
    if (from != address(0)) {
      $._tokenStakes[from].shares -= shares;
      $._lastTotalStake.shares -= shares;
    }
    if (to != address(0)) {
      $._tokenStakes[to].shares += shares;
      $._lastTotalStake.shares += shares;
    }

    // Update the balance
    super._update(from, to, value);
  }
}
