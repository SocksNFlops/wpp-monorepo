// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {BaseHook} from "v4-periphery/src/utils/BaseHook.sol";

import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "v4-core/src/types/PoolId.sol";
import {BalanceDelta} from "v4-core/src/types/BalanceDelta.sol";
import {BeforeSwapDelta, toBeforeSwapDelta, BeforeSwapDeltaLibrary} from "v4-core/src/types/BeforeSwapDelta.sol";
import {Currency} from "v4-core/src/types/Currency.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {CurrencySettler} from "@uniswap/v4-core/test/utils/CurrencySettler.sol";
import {IPlusPlusToken} from "./interface/IPlusPlusToken.sol";

contract PlusPlusPoolHook is BaseHook {
  using PoolIdLibrary for PoolKey;
  using CurrencySettler for Currency;
  using BeforeSwapDeltaLibrary for BeforeSwapDelta;

  error UnsupportedTokenPair();

  mapping(Currency => bool) public isPlusPlusToken;

  constructor(IPoolManager _poolManager) BaseHook(_poolManager) {}

  function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
    return Hooks.Permissions({
      beforeInitialize: true, // Need to disable invalid pairs from being created
      afterInitialize: false,
      beforeAddLiquidity: false, // Need to disable adding liquidity in the standard way
      afterAddLiquidity: false, // Need to disable adding liquidity in the standard way
      beforeRemoveLiquidity: false,
      afterRemoveLiquidity: false,
      beforeSwap: false,
      afterSwap: false,
      beforeDonate: false,
      afterDonate: false,
      beforeSwapReturnDelta: false,
      afterSwapReturnDelta: false,
      afterAddLiquidityReturnDelta: false,
      afterRemoveLiquidityReturnDelta: false
    });
  }

  function _beforeInitialize(address, PoolKey calldata key, uint160) internal virtual override returns (bytes4) {
    // Check if either token is a PlusPlusToken
    bool currency0IsPlusPlus = false;
    bool currency1IsPlusPlus = false;

    // Check if currency0 is a PlusPlusToken
    (bool success, bytes memory data) =
      Currency.unwrap(key.currency0).staticcall(abi.encodeWithSelector(IPlusPlusToken.rawToken.selector));

    if (success && data.length >= 32) {
      currency0IsPlusPlus = true;
      isPlusPlusToken[key.currency0] = true;

      // Store raw token relationship if available
      address rawTokenAddress = abi.decode(data, (address));
      if (Currency.unwrap(key.currency1) == rawTokenAddress) {
        IERC20(rawTokenAddress).approve(Currency.unwrap(key.currency0), type(uint256).max);
      }
    }
    // Check if currency1 is a PlusPlusToken
    (success, data) =
      Currency.unwrap(key.currency1).staticcall(abi.encodeWithSelector(IPlusPlusToken.rawToken.selector));

    if (success && data.length >= 32) {
      currency1IsPlusPlus = true;
      isPlusPlusToken[key.currency1] = true;

      // Store raw token relationship if available
      address rawTokenAddress = abi.decode(data, (address));
      if (Currency.unwrap(key.currency0) == rawTokenAddress) {
        IERC20(rawTokenAddress).approve(Currency.unwrap(key.currency1), type(uint256).max);
      }
    }

    // If neither token is a PlusPlusToken, revert
    if (!currency0IsPlusPlus && !currency1IsPlusPlus) {
      revert UnsupportedTokenPair();
    }
    return BaseHook.beforeInitialize.selector;
  }
}
