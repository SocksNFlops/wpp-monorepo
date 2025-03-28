// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {BaseHook} from "v4-periphery/src/utils/BaseHook.sol";
import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "v4-core/src/types/PoolId.sol";
import {BalanceDelta, BalanceDeltaLibrary} from "v4-core/src/types/BalanceDelta.sol";
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
import {SafeCast} from "v4-core/src/libraries/SafeCast.sol";
import {ERC6909} from "v4-core/src/ERC6909.sol";

contract PlusPlusPoolHook is BaseHook, IUnlockCallback, ERC6909 {
  using PoolIdLibrary for PoolKey;
  using CurrencySettler for Currency;
  using BeforeSwapDeltaLibrary for BeforeSwapDelta;
  using StateLibrary for IPoolManager;
  using SafeERC20 for IERC20;
  using BalanceDeltaLibrary for BalanceDelta;
  using SafeCast for *;

  struct CallbackData {
    address to;
    PoolKey key;
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

      // Pre-approve the raw token to get deposited into the PlusPlusToken
      address rawTokenAddress = abi.decode(data, (address));
      IERC20(rawTokenAddress).approve(Currency.unwrap(key.currency0), type(uint256).max);
    }
    // Check if currency1 is a PlusPlusToken
    (success, data) =
      Currency.unwrap(key.currency1).staticcall(abi.encodeWithSelector(IPlusPlusToken.rawToken.selector));

    if (success && data.length >= 32) {
      currency1IsPlusPlus = true;
      isPlusPlusToken[key.currency1] = true;

      // Pre-approve the raw token to get deposited into the PlusPlusToken
      address rawTokenAddress = abi.decode(data, (address));
      IERC20(rawTokenAddress).approve(Currency.unwrap(key.currency1), type(uint256).max);
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

  function modifyLiquidity(PoolKey calldata key, IPoolManager.ModifyLiquidityParams calldata params) external {
    poolManager.unlock(abi.encode(CallbackData({to: msg.sender, key: key, params: params})));
  }

  function unlockCallback(bytes calldata data) external returns (bytes memory) {
    CallbackData memory callbackData = abi.decode(data, (CallbackData));
    address to = callbackData.to;
    PoolKey memory key = callbackData.key;
    IPoolManager.ModifyLiquidityParams memory params = callbackData.params;

    (BalanceDelta callerDelta, BalanceDelta feesAccrued) = poolManager.modifyLiquidity(key, params, "");

    int128 amount0 = callerDelta.amount0() + feesAccrued.amount0();
    int128 amount1 = callerDelta.amount1() + feesAccrued.amount1();

    // Settle or take currency0
    if (amount0 < 0) {
      uint256 amount0ToAdd = (-amount0).toUint128();
      // If currency0 is a PlusPlusToken, we need to pull the rawToken and wrap it
      if (isPlusPlusToken[key.currency0]) {
        IERC20 rawToken = IERC20(IPlusPlusToken(Currency.unwrap(key.currency0)).rawToken());
        rawToken.safeTransferFrom(to, address(this), amount0ToAdd);
        IPlusPlusToken(Currency.unwrap(key.currency0)).deposit(address(this), amount0ToAdd);
      } else {
        IERC20(Currency.unwrap(key.currency0)).safeTransferFrom(to, address(this), amount0ToAdd);
      }
      key.currency0.settle(poolManager, address(this), amount0ToAdd, false);
    } else if (amount0 > 0) {
      uint256 amount0ToRemove = amount0.toUint128();
      // If currency0 is a PlusPlusToken, we need to take it and unwrap it into a rawToken
      key.currency0.take(poolManager, address(this), amount0ToRemove, false);
      if (isPlusPlusToken[key.currency0]) {
        IPlusPlusToken(Currency.unwrap(key.currency0)).withdraw(address(this), amount0ToRemove);
        IERC20 rawToken = IERC20(IPlusPlusToken(Currency.unwrap(key.currency0)).rawToken());
        rawToken.safeTransfer(to, amount0ToRemove);
      } else {
        IERC20(Currency.unwrap(key.currency0)).safeTransfer(to, amount0ToRemove);
      }
    }

    // Settle or take currency1
    if (amount1 < 0) {
      uint256 amount1ToAdd = (-amount1).toUint128();
      // If currency1 is a PlusPlusToken, we need to pull the rawToken and wrap it
      if (isPlusPlusToken[key.currency1]) {
        IERC20 rawToken = IERC20(IPlusPlusToken(Currency.unwrap(key.currency1)).rawToken());
        rawToken.safeTransferFrom(to, address(this), amount1ToAdd);
        IPlusPlusToken(Currency.unwrap(key.currency1)).deposit(address(this), amount1ToAdd);
      } else {
        IERC20(Currency.unwrap(key.currency1)).safeTransferFrom(to, address(this), amount1ToAdd);
      }
      key.currency1.settle(poolManager, address(this), amount1ToAdd, false);
    } else if (amount1 > 0) {
      uint256 amount1ToRemove = amount1.toUint128();
      // If currency0 is a PlusPlusToken, we need to take it and unwrap it into a rawToken
      key.currency1.take(poolManager, address(this), amount1ToRemove, false);
      if (isPlusPlusToken[key.currency1]) {
        IPlusPlusToken(Currency.unwrap(key.currency1)).withdraw(address(this), amount1ToRemove);
        IERC20 rawToken = IERC20(IPlusPlusToken(Currency.unwrap(key.currency1)).rawToken());
        rawToken.safeTransfer(to, amount1ToRemove);
      } else {
        IERC20(Currency.unwrap(key.currency1)).safeTransfer(to, amount1ToRemove);
      }
    }

    // Mint/Burn an ERC6909 liquidity claim to the caller
    uint256 tokenId = generateTokenId(key, params.tickLower, params.tickUpper, "");
    if (params.liquidityDelta > 0) {
      _mint(to, tokenId, uint256(params.liquidityDelta));
    } else {
      _burn(to, tokenId, uint256(-params.liquidityDelta));
    }
  }

  function generateTokenId(PoolKey memory key, int24 tickLower, int24 tickUpper, bytes32 salt)
    public
    pure
    returns (uint256)
  {
    return
      uint256(keccak256(abi.encode(key.currency0, key.currency1, key.fee, key.tickSpacing, tickLower, tickUpper, salt)));
  }
}
