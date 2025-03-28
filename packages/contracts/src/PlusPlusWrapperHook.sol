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

import {console} from "forge-std/console.sol";

contract PlusPlusWrapperHook is BaseHook {
  using PoolIdLibrary for PoolKey;
  using CurrencySettler for Currency;
  using BeforeSwapDeltaLibrary for BeforeSwapDelta;

  error UnsupportedFee();
  error UnsupportedTickSpacing();
  error UnsupportedTokenPair();

  constructor(IPoolManager _poolManager) BaseHook(_poolManager) {}

  function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
    return Hooks.Permissions({
      beforeInitialize: true, // Need to disable invalid pairs from being created
      afterInitialize: false,
      beforeAddLiquidity: false, // Need to disable adding liquidity
      afterAddLiquidity: false,
      beforeRemoveLiquidity: false,
      afterRemoveLiquidity: false,
      beforeSwap: false, // Need to override swap behavior
      afterSwap: false,
      beforeDonate: false,
      afterDonate: false,
      beforeSwapReturnDelta: false, // Need to allow beforeSwap to return a custom delta
      afterSwapReturnDelta: false,
      afterAddLiquidityReturnDelta: false,
      afterRemoveLiquidityReturnDelta: false
    });
  }

  function _beforeInitialize(address, PoolKey calldata key, uint160) internal virtual override returns (bytes4) {
    if (key.fee != 0) {
      revert UnsupportedFee();
    }
    if (key.tickSpacing != 1) {
      revert UnsupportedTickSpacing();
    }
    // Check if either token is a PlusPlusToken and the other is its raw token
    // Try currency0 as PlusPlusToken
    (bool success, bytes memory data) =
      Currency.unwrap(key.currency0).staticcall(abi.encodeWithSelector(IPlusPlusToken.rawToken.selector));

    if (success && data.length >= 32) {
      address rawTokenAddress = abi.decode(data, (address));
      if (Currency.unwrap(key.currency1) == rawTokenAddress) {
        return BaseHook.beforeInitialize.selector;
      }
    }
    // Try currency1 as PlusPlusToken
    (success, data) =
      Currency.unwrap(key.currency1).staticcall(abi.encodeWithSelector(IPlusPlusToken.rawToken.selector));

    if (success && data.length >= 32) {
      address rawTokenAddress = abi.decode(data, (address));
      if (Currency.unwrap(key.currency0) == rawTokenAddress) {
        return BaseHook.beforeInitialize.selector;
      }
    }
    // If neither token is a PlusPlusToken, revert
    revert UnsupportedTokenPair();
  }
}
