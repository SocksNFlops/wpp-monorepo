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

contract PlusPlusRawHook is BaseHook {
  using PoolIdLibrary for PoolKey;
  using CurrencySettler for Currency;
  using BeforeSwapDeltaLibrary for BeforeSwapDelta;

  error UnsupportedFee();
  error UnsupportedTickSpacing();
  error UnsupportedTokenPair();
  error UnsupportedLiquidityOperation();

  mapping(Currency => mapping(Currency => bool)) public rawTokenIsZeroMap;

  constructor(IPoolManager _poolManager) BaseHook(_poolManager) {}

  function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
    return Hooks.Permissions({
      beforeInitialize: true, // Need to disable invalid pairs from being created
      afterInitialize: false,
      beforeAddLiquidity: true, // Need to disable adding liquidity
      afterAddLiquidity: false,
      beforeRemoveLiquidity: false,
      afterRemoveLiquidity: false,
      beforeSwap: true, // Need to override swap behavior
      afterSwap: false,
      beforeDonate: false,
      afterDonate: false,
      beforeSwapReturnDelta: true, // Need to allow beforeSwap to return a custom delta
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
        // rawTokenIsZeroMap[key.currency0][key.currency1] = false; // Can omit this
        IERC20(rawTokenAddress).approve(Currency.unwrap(key.currency0), type(uint256).max);
        return BaseHook.beforeInitialize.selector;
      }
    }
    // Try currency1 as PlusPlusToken
    (success, data) =
      Currency.unwrap(key.currency1).staticcall(abi.encodeWithSelector(IPlusPlusToken.rawToken.selector));

    if (success && data.length >= 32) {
      address rawTokenAddress = abi.decode(data, (address));
      if (Currency.unwrap(key.currency0) == rawTokenAddress) {
        rawTokenIsZeroMap[key.currency0][key.currency1] = true;
        IERC20(rawTokenAddress).approve(Currency.unwrap(key.currency1), type(uint256).max);
        return BaseHook.beforeInitialize.selector;
      }
    }
    // If neither token is a PlusPlusToken, revert
    revert UnsupportedTokenPair();
  }

  function _beforeAddLiquidity(address, PoolKey calldata, IPoolManager.ModifyLiquidityParams calldata, bytes calldata)
    internal
    pure
    override
    returns (bytes4)
  {
    revert UnsupportedLiquidityOperation();
  }

  // ToDo: Figure out how to simplify the input/output currency selection
  // ToDo: Figure out how to simplify calculating input/output amounts
  function _beforeSwap(address, PoolKey calldata key, IPoolManager.SwapParams calldata params, bytes calldata)
    internal
    override
    returns (bytes4, BeforeSwapDelta, uint24)
  {
    // XOR( Curr0 == RawToken, zeroForOne ) == 0 && (amountSpecified < 0)
    bool rawTokenIsZero = rawTokenIsZeroMap[key.currency0][key.currency1];
    bool exactIn = params.amountSpecified < 0;

    uint256 inputAmount;
    uint256 outputAmount;
    // Case 1: ExactIn (RawToken) -> PlusPlusToken
    if ((rawTokenIsZero == params.zeroForOne) && exactIn) {
      Currency input = rawTokenIsZero ? key.currency0 : key.currency1;
      Currency output = rawTokenIsZero ? key.currency1 : key.currency0;
      inputAmount = uint256(-params.amountSpecified);

      // Take the RawToken input
      input.take(poolManager, address(this), inputAmount, false);

      // Deposit the RawToken input to generate PlusPlusToken output amount
      outputAmount = IPlusPlusToken(Currency.unwrap(output)).rawDeposit(inputAmount);

      // Tell pool manager to take PlusPlusToken from the hook
      output.settle(poolManager, address(this), outputAmount, false);
      return
        (BaseHook.beforeSwap.selector, toBeforeSwapDelta(int128(int256(inputAmount)), int128(-int256(outputAmount))), 0);
      // Case 2: ExactOut (RawToken) -> PlusPlusToken
    } else if ((rawTokenIsZero == params.zeroForOne) && !exactIn) {
      Currency input = rawTokenIsZero ? key.currency0 : key.currency1;
      Currency output = rawTokenIsZero ? key.currency1 : key.currency0;
      outputAmount = uint256(params.amountSpecified);
      inputAmount = outputAmount;

      // Take the RawToken input
      input.take(poolManager, address(this), inputAmount, false);

      // Mint the PlusPlusToken output
      IPlusPlusToken(Currency.unwrap(output)).rawDeposit(inputAmount);

      // Tell pool manager to take PlusPlusToken from the hook
      output.settle(poolManager, address(this), outputAmount, false);

      return
        (BaseHook.beforeSwap.selector, toBeforeSwapDelta(int128(-int256(outputAmount)), int128(int256(inputAmount))), 0);

      // Case 3: ExactIn (PlusPlusToken) -> RawToken
    } else if ((rawTokenIsZero != params.zeroForOne) && exactIn) {
      Currency input = rawTokenIsZero ? key.currency1 : key.currency0;
      Currency output = rawTokenIsZero ? key.currency0 : key.currency1;
      inputAmount = uint256(-params.amountSpecified);

      // Take the PlusPlusToken input
      input.take(poolManager, address(this), inputAmount, false);

      // Burn the PlusPlusToken input to generate RawToken
      outputAmount = IPlusPlusToken(Currency.unwrap(input)).rawWithdraw(inputAmount);

      // Tell pool manager to take RawToken from the hook
      output.settle(poolManager, address(this), outputAmount, false);

      return
        (BaseHook.beforeSwap.selector, toBeforeSwapDelta(int128(int256(inputAmount)), int128(-int256(outputAmount))), 0);

      // Case 4: ExactOut (PlusPlusToken) -> RawToken
    } else if ((rawTokenIsZero != params.zeroForOne) && !exactIn) {
      Currency input = rawTokenIsZero ? key.currency1 : key.currency0;
      Currency output = rawTokenIsZero ? key.currency0 : key.currency1;
      outputAmount = uint256(params.amountSpecified);
      inputAmount = outputAmount;

      // Take the PlusPlusToken input
      input.take(poolManager, address(this), inputAmount, false);

      // Burn the PlusPlusToken input to generate RawToken
      outputAmount = IPlusPlusToken(Currency.unwrap(input)).rawWithdraw(outputAmount);

      // Tell pool manager to take RawToken from the hook
      output.settle(poolManager, address(this), outputAmount, false);

      return
        (BaseHook.beforeSwap.selector, toBeforeSwapDelta(int128(-int256(outputAmount)), int128(int256(inputAmount))), 0);
    }
  }
}
