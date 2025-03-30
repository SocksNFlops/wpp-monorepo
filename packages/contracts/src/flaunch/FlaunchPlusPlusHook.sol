// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {BeforeSwapDelta} from "@uniswap/v4-core/src/types/BeforeSwapDelta.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {Hooks, IHooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";

import {BalanceDelta, PlusPlusPoolHook} from "../PlusPlusPoolHook.sol";
import {IFlaunchPlusPlusToken} from "./interfaces/IFlaunchPlusPlusToken.sol";
import {IPositionManager} from "./interfaces/IPositionManager.sol";
import {IRevenueManager} from "./interfaces/IRevenueManager.sol";
import {ITreasuryManagerFactory} from "./interfaces/ITreasuryManagerFactory.sol";
import {PlusPlusBuyBackAction} from "./PlusPlusBuyBackAction.sol";

contract FlaunchPlusPlusHook is PlusPlusPoolHook {
  struct FlaunchToken {
    address memecoin;
    uint256 tokenId;
    address payable manager;
  }

  address public immutable managerImplementation;

  IPositionManager public immutable positionManager;
  ITreasuryManagerFactory public immutable treasuryManagerFactory;
  PlusPlusBuyBackAction public immutable plusPlusBuyBackAction;

  mapping(PoolId _poolId => FlaunchToken _flaunchToken) public flaunchTokens;

  constructor(
    IPoolManager _poolManager,
    address _positionManager,
    address _treasuryManagerFactory,
    address _managerImplementation,
    address _plusPlusBuyBackAction
  ) PlusPlusPoolHook(_poolManager) {
    positionManager = IPositionManager(_positionManager);
    treasuryManagerFactory = ITreasuryManagerFactory(_treasuryManagerFactory);
    managerImplementation = _managerImplementation;
    plusPlusBuyBackAction = PlusPlusBuyBackAction(_plusPlusBuyBackAction);
  }

  function getHookPermissions() public pure virtual override returns (Hooks.Permissions memory) {
    return Hooks.Permissions({
      beforeInitialize: true, // Need from PlusPlusPoolHook
      afterInitialize: true, // Need to flaunch a token
      beforeAddLiquidity: true, // Need from PlusPlusPoolHook
      afterAddLiquidity: false,
      beforeRemoveLiquidity: false,
      afterRemoveLiquidity: false,
      beforeSwap: false,
      afterSwap: true, // Need to skim yield from the FPP and send to the buyback action
      beforeDonate: false,
      afterDonate: false,
      beforeSwapReturnDelta: false,
      afterSwapReturnDelta: false,
      afterAddLiquidityReturnDelta: false,
      afterRemoveLiquidityReturnDelta: false
    });
  }

  function _afterInitialize(address, PoolKey calldata _key, uint160, int24) internal override returns (bytes4) {
    // We can only flaunch a token if the pair is ETH
    if (Currency.unwrap(_key.currency0) != address(0)) {
      return IHooks.afterInitialize.selector;
    }

    // Flaunch our token
    address memecoin = positionManager.flaunch(
      IPositionManager.FlaunchParams({
        name: "Flaunch++",
        symbol: "FLP++",
        tokenUri: "https://wethplusplus.xyz/",
        initialTokenFairLaunch: 50e27,
        premineAmount: 0,
        creator: address(this),
        creatorFeeAllocation: 10_00, // 10% fees
        flaunchAt: 0,
        initialPriceParams: abi.encode(""),
        feeCalculatorParams: abi.encode(1_000)
      })
    );

    // Get the flaunched tokenId
    uint256 tokenId = positionManager.flaunchContract().tokenId(memecoin);

    // Deploy our token to a fresh RevenueManager
    address payable manager = treasuryManagerFactory.deployManager(managerImplementation);

    // Initialize our manager with the token
    positionManager.flaunchContract().approve(manager, tokenId);
    IRevenueManager(manager).initialize(
      IRevenueManager.FlaunchToken(positionManager.flaunchContract(), tokenId),
      address(this),
      abi.encode(IRevenueManager.InitializeParams(payable(address(this)), payable(address(this)), 100_00))
    );

    flaunchTokens[_key.toId()] = FlaunchToken({memecoin: memecoin, tokenId: tokenId, manager: manager});

    return IHooks.afterInitialize.selector;
  }

  function _afterSwap(address, PoolKey calldata key, IPoolManager.SwapParams calldata, BalanceDelta, bytes calldata)
    internal
    override
    returns (bytes4, int128)
  {
    _skimYieldAndSendToBuyBack(key);
  }

  function _skimYieldAndSendToBuyBack(PoolKey calldata key) internal {
    // Check if Currency0 is a plusplusToken with a raw native token
    if (
      isPlusPlusToken[key.currency0]
        && IFlaunchPlusPlusToken(Currency.unwrap(key.currency0)).rawToken()
          == Currency.unwrap(plusPlusBuyBackAction.nativeToken())
    ) {
      // Currency1 is the memecoin
      address memecoin = Currency.unwrap(key.currency1);
      // Skim yield from the FPP
      uint256 rawAmount = _skimYieldFromFPP(IFlaunchPlusPlusToken(Currency.unwrap(key.currency0)));
      // Send to the FlaunchBuyBackAction
      plusPlusBuyBackAction.increaseBuyBackBudget(Currency.wrap(memecoin), rawAmount);
    }

    // Check if Currency1 is a plusplusToken with a raw native token
    if (
      isPlusPlusToken[key.currency1]
        && IFlaunchPlusPlusToken(Currency.unwrap(key.currency1)).rawToken()
          == Currency.unwrap(plusPlusBuyBackAction.nativeToken())
    ) {
      // Currency0 is the memecoin
      address memecoin = Currency.unwrap(key.currency0);
      // Skim yield from the FPP
      uint256 rawAmount = _skimYieldFromFPP(IFlaunchPlusPlusToken(Currency.unwrap(key.currency1)));
      // Send to the FlaunchBuyBackAction
      plusPlusBuyBackAction.increaseBuyBackBudget(Currency.wrap(memecoin), rawAmount);
    }

  }

  function _skimYieldFromFPP(IFlaunchPlusPlusToken plusplusToken) internal returns (uint256 rawAmount) {
    rawAmount = plusplusToken.skimYield();
  }
}
