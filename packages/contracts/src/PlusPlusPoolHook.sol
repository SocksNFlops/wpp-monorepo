// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {console} from "forge-std/console.sol";
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
import {IUnlockCallback} from "v4-core/src/interfaces/callback/IUnlockCallback.sol";
import {LiquidityAmounts} from "v4-core/test/utils/LiquidityAmounts.sol";
import {TickMath} from "v4-core/src/libraries/TickMath.sol";
import {StateLibrary} from "v4-core/src/libraries/StateLibrary.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract PlusPlusPoolHook is BaseHook, IUnlockCallback {
  using PoolIdLibrary for PoolKey;
  using CurrencySettler for Currency;
  using BeforeSwapDeltaLibrary for BeforeSwapDelta;
  using StateLibrary for IPoolManager;
  using SafeERC20 for IERC20;

  struct CallbackData {
    address to;
    PoolKey key;
    uint256 amount0Expected;
    uint256 amount1Expected;
    IPoolManager.ModifyLiquidityParams params;
  }

  error UnsupportedTokenPair();
  error UnsupportedLiquidityOperation();

  mapping(Currency => bool) public isPlusPlusToken;

  constructor(IPoolManager _poolManager) BaseHook(_poolManager) {}

  function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
    return Hooks.Permissions({
      beforeInitialize: true, // Need to disable invalid pairs from being created
      afterInitialize: false,
      beforeAddLiquidity: true, // Need to disable adding liquidity in the standard way
      afterAddLiquidity: false,
      beforeRemoveLiquidity: true, // Need to disable removing liquidity in the standard way
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

  function _beforeAddLiquidity(address, PoolKey calldata, IPoolManager.ModifyLiquidityParams calldata, bytes calldata)
    internal
    pure
    override
    returns (bytes4)
  {
    revert UnsupportedLiquidityOperation();
  }

  function _beforeRemoveLiquidity(
    address,
    PoolKey calldata,
    IPoolManager.ModifyLiquidityParams calldata,
    bytes calldata
  ) internal pure override returns (bytes4) {
    revert UnsupportedLiquidityOperation();
  }

  function addLiquidity(PoolKey calldata key, IPoolManager.ModifyLiquidityParams calldata params) external {
    // Fetch the current sqrtPriceX96 of the pool
    (uint160 sqrtPriceX96,,,) = poolManager.getSlot0(key.toId());

    // Calculate the expected amount of tokens to be transferred
    if (params.liquidityDelta > 0) {
      (uint256 amount0Expected, uint256 amount1Expected) = LiquidityAmounts.getAmountsForLiquidity(
        sqrtPriceX96,
        TickMath.getSqrtPriceAtTick(params.tickLower),
        TickMath.getSqrtPriceAtTick(params.tickUpper),
        uint128(uint256(params.liquidityDelta))
      );

      console.log("Transfering from sender to the hook", msg.sender, address(this));

      // Transfer the tokens to the pool
      IERC20(Currency.unwrap(key.currency0)).safeTransferFrom(msg.sender, address(this), amount0Expected);
      // IERC20(Currency.unwrap(key.currency0)).approve(address(poolManager), amount0Expected);
      IERC20(Currency.unwrap(key.currency1)).safeTransferFrom(msg.sender, address(this), amount1Expected);
      // IERC20(Currency.unwrap(key.currency1)).approve(address(poolManager), amount1Expected);

      poolManager.unlock(
        abi.encode(CallbackData({to: msg.sender, key: key, amount0Expected: amount0Expected, amount1Expected: amount1Expected, params: params}))
      );
    }
  }

  function unlockCallback(bytes calldata data) external returns (bytes memory) {
    CallbackData memory callbackData = abi.decode(data, (CallbackData));
    address to = callbackData.to;
    PoolKey memory key = callbackData.key;
    uint256 amount0Expected = callbackData.amount0Expected;
    uint256 amount1Expected = callbackData.amount1Expected;
    IPoolManager.ModifyLiquidityParams memory params = callbackData.params;

    console.log("amount0Expected", amount0Expected);
    console.log("amount1Expected", amount1Expected);

    key.currency0.settle(poolManager, address(this), amount0Expected, false);

    console.log("Finished settling currency0");

    key.currency1.settle(poolManager, address(this), amount1Expected, false);

    console.log("Finished settling currency1");

    poolManager.modifyLiquidity(key, params, "");

    console.log("Done with unlockCallback");
  }
}
