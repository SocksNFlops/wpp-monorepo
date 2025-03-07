// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IWethPlusPlus} from "./interface/IWethPlusPlus.sol";

contract WethPlusPlus is ERC20Upgradeable, IWethPlusPlus{
  /**
   * @custom:storage-location erc7201:wethplusplus.storage.wethplusplus
   * @param _weth The address of the WETH token
   * @param _stakedEth The address of the staked ETH token
   * @param _targetRatio The target ratio of WETH to staked ETH principle
   */
  struct WethPlusPlusStorage {
    address _weth;
    address _stakedEth;
    uint16 _targetRatio;
  }

  // ToDo: Validate this hash
  // keccak256(abi.encode(uint256(keccak256("wethplusplus.storage.wethplusplus")) - 1)) & ~bytes32(uint256(0xff))
  bytes32 private constant WethPlusPlusStorageLocation =
    0x4047422df835e2e32e4d8c22e919c252412cd34f26c0503fc6e21dfee8341300;

  function _getWethPlusPlusStorage() private pure returns (WethPlusPlusStorage storage $) {
    assembly {
      $.slot := WethPlusPlusStorageLocation
    }
  }

  /**
   * @dev Sets the values for {name} and {symbol}.
   *
   * All two of these values are immutable: they can only be set once during
   * construction.
   */
  function __WethPlusPlus_init(address weth_, address stakedEth_, uint16 targetRatio_) internal onlyInitializing {
    __ERC20_init("WethPlusPlus", "WPP");
    __WethPlusPlus_init_unchained(weth_, stakedEth_, targetRatio_);
  }

  function __WethPlusPlus_init_unchained(address weth_, address stakedEth_, uint16 targetRatio_) internal onlyInitializing {
    WethPlusPlusStorage storage $ = _getWethPlusPlusStorage();
    $._weth = weth_;
    $._stakedEth = stakedEth_;
    $._targetRatio = targetRatio_;
  }

  /**
   * @inheritdoc IWethPlusPlus
   */
  function initialize(address weth_, address stakedEth_, uint16 targetRatio_) public initializer {
    __WethPlusPlus_init(weth_, stakedEth_, targetRatio_);
  }

  /**
   * @inheritdoc IWethPlusPlus
   */
  function weth() external view returns (address) {
    return _getWethPlusPlusStorage()._weth;
  }

  /**
   * @inheritdoc IWethPlusPlus
   */
  function stakedEth() external view returns (address) {
    return _getWethPlusPlusStorage()._stakedEth;
  }

  /**
   * @inheritdoc IWethPlusPlus
   */
  function targetRatio() external view returns (uint16) {
    return _getWethPlusPlusStorage()._targetRatio;
  }
}
