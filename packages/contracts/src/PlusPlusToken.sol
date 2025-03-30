// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {EIP712Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IPlusPlusToken} from "./interface/IPlusPlusToken.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

contract PlusPlusToken is
  ERC20Upgradeable,
  EIP712Upgradeable,
  UUPSUpgradeable,
  AccessControlUpgradeable,
  IPlusPlusToken
{
  using SafeERC20 for IERC20;

  /**
   * @custom:storage-location erc7201:plusplus.storage.plusplus
   * @param _rawToken The address of the raw token
   * @param _earnToken The address of the earn token
   * @param _targetRatio The target ratio of raw token to earning token principle
   */
  struct PlusPlusTokenStorage {
    address _rawToken;
    address _earnToken;
    uint16 _targetRatio;
    mapping(address => bool) _whitelist;
    bool _rawDepositOn;
    bool _rawWithdrawOn;
    bool _earnDepositOn;
    bool _earnWithdrawOn;
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

  function __PlusPlusToken_init_unchained(address rawToken_, address earnToken_, uint16 targetRatio_)
    internal
    onlyInitializing
  {
    PlusPlusTokenStorage storage $ = _getPlusPlusTokenStorage();
    $._rawToken = rawToken_;
    $._earnToken = earnToken_;
    $._targetRatio = targetRatio_;
    $._rawDepositOn = true;
    $._rawWithdrawOn = true;
    $._earnDepositOn = true;
    $._earnWithdrawOn = true;
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
  function earnToken() external view returns (address) {
    return _getPlusPlusTokenStorage()._earnToken;
  }

  /**
   * @inheritdoc IPlusPlusToken
   */
  function rawAndEarnToken() external view returns (address, address) {
    return (_getPlusPlusTokenStorage()._rawToken, _getPlusPlusTokenStorage()._earnToken);
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
  function currentRatio() external view returns (uint16) {
    // Fetch storage
    PlusPlusTokenStorage storage $ = _getPlusPlusTokenStorage();

    // Return the current ratio
    uint256 rawTokenBalance = IERC20($._rawToken).balanceOf(address(this));

    return uint16((rawTokenBalance * 1e4) / totalSupply());
  }

  /**
   * @inheritdoc IPlusPlusToken
   */
  function rawDeposit(uint256 rawAmount) external returns (uint256 amount) {
    // Fetch storage
    PlusPlusTokenStorage storage $ = _getPlusPlusTokenStorage();

    // Revert if raw deposits are disabled
    if (!$._rawDepositOn) {
      revert ExchangeDisabled();
    }

    // Mint plusplus tokens
    _mint(msg.sender, rawAmount);

    // Transfer raw tokens from sender to this contract
    IERC20($._rawToken).safeTransferFrom(msg.sender, address(this), rawAmount);

    // Return amount of plusplus tokens minted
    amount = rawAmount;
  }

  /**
   * @inheritdoc IPlusPlusToken
   */
  function rawWithdraw(uint256 rawAmount) external returns (uint256 amount) {
    // Fetch storage
    PlusPlusTokenStorage storage $ = _getPlusPlusTokenStorage();

    // Revert if raw withdrawals are disabled
    if (!$._rawWithdrawOn) {
      revert ExchangeDisabled();
    }

    // Burn plusplus tokens
    _burn(msg.sender, rawAmount);

    // Transfer raw tokens from this contract to sender
    IERC20($._rawToken).safeTransfer(msg.sender, rawAmount);

    // Return amount of plusplus tokens burned
    amount = rawAmount;
  }

  /**
   * @inheritdoc IPlusPlusToken
   */
  function earnDeposit(uint256 earnAmount) external returns (uint256 amount) {
    // Fetch storage
    PlusPlusTokenStorage storage $ = _getPlusPlusTokenStorage();

    // Revert if earn deposits are disabled
    if (!$._earnDepositOn) {
      revert ExchangeDisabled();
    }

    // Mint plusplus tokens
    _mint(msg.sender, earnAmount);

    // Transfer earning tokens from sender to this contract
    IERC20($._earnToken).safeTransferFrom(msg.sender, address(this), earnAmount);

    // Return amount of plusplus tokens minted
    amount = earnAmount;
  }

  /**
   * @inheritdoc IPlusPlusToken
   */
  function earnWithdraw(uint256 earnAmount) external returns (uint256 amount) {
    // Fetch storage
    PlusPlusTokenStorage storage $ = _getPlusPlusTokenStorage();

    // Revert if earn withdrawals are disabled
    if (!$._earnWithdrawOn) {
      revert ExchangeDisabled();
    }

    // Burn plusplus tokens
    _burn(msg.sender, earnAmount);

    // Transfer earning tokens from this contract to sender
    IERC20($._earnToken).safeTransfer(msg.sender, earnAmount);

    // Return amount of plusplus tokens burned
    amount = earnAmount;
  }

  function burn(uint256 amount) external returns (uint256 rawAmount, uint256 earnAmount) {
    // Fetch storage
    PlusPlusTokenStorage storage $ = _getPlusPlusTokenStorage();

    uint256 totalSupply = this.totalSupply();
    uint256 rawTokenBalance = IERC20($._rawToken).balanceOf(address(this));
    uint256 earnTokenBalance = IERC20($._earnToken).balanceOf(address(this));

    rawAmount = Math.mulDiv(amount, rawTokenBalance, totalSupply);
    earnAmount = Math.mulDiv(amount, earnTokenBalance, totalSupply);

    // Burn plusplus tokens
    _burn(msg.sender, amount);

    // Transfer raw tokens from this contract to sender
    IERC20($._rawToken).safeTransfer(msg.sender, rawAmount);

    // Transfer earning tokens from this contract to sender
    IERC20($._earnToken).safeTransfer(msg.sender, earnAmount);
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
    // Revert if the recipient is not whitelisted
    if (to != address(0) && !this.isWhitelisted(to)) {
      revert NotWhitelisted(to);
    }

    // Update the balance
    super._update(from, to, value);
  }

  /**
   * @inheritdoc IPlusPlusToken
   */
  function updateDepositWithdrawSwitches(bool rawDepositOn, bool rawWithdrawOn, bool earnDepositOn, bool earnWithdrawOn)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    // Fetch storage
    PlusPlusTokenStorage storage $ = _getPlusPlusTokenStorage();

    // Update the deposit and withdraw switches
    $._rawDepositOn = rawDepositOn;
    $._rawWithdrawOn = rawWithdrawOn;
    $._earnDepositOn = earnDepositOn;
    $._earnWithdrawOn = earnWithdrawOn;
  }
}
