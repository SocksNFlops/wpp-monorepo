// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {IHooks} from "v4-core/src/interfaces/IHooks.sol";
import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {TickMath} from "v4-core/src/libraries/TickMath.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {BalanceDelta} from "v4-core/src/types/BalanceDelta.sol";
import {PoolId, PoolIdLibrary} from "v4-core/src/types/PoolId.sol";
import {CurrencyLibrary, Currency} from "v4-core/src/types/Currency.sol";
import {StateLibrary} from "v4-core/src/libraries/StateLibrary.sol";
import {CustomRevert} from "v4-core/src/libraries/CustomRevert.sol";

import {LiquidityAmounts} from "v4-core/test/utils/LiquidityAmounts.sol";
import {IPositionManager} from "v4-periphery/src/interfaces/IPositionManager.sol";
import {EasyPosm} from "./utils/EasyPosm.sol";
import {Fixtures} from "./utils/Fixtures.sol";
import {Constants} from "v4-core/test/utils/Constants.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {BalanceDeltaLibrary} from "v4-core/src/types/BalanceDelta.sol";
import {LPFeeLibrary} from "v4-core/src/libraries/LPFeeLibrary.sol";
import {PlusPlusPoolHook} from "../src/PlusPlusPoolHook.sol";
import {MinimalRouter} from "./utils/MinimalRouter.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {PlusPlusToken} from "../src/PlusPlusToken.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract PlusPlusPoolHookTest is Test, Fixtures {
  using EasyPosm for IPositionManager;
  using PoolIdLibrary for PoolKey;
  using CurrencyLibrary for Currency;
  using StateLibrary for IPoolManager;
  using CustomRevert for bytes4;
  using BalanceDeltaLibrary for BalanceDelta;

  uint24 constant FEE = 3000;
  int24 constant TICK_SPACING = 60;

  MinimalRouter minimalRouter;
  PlusPlusPoolHook hook;
  PoolId poolId;

  uint256 tokenId;
  int24 tickLower;
  int24 tickUpper;

  address plusPlusAdmin = makeAddr("plusPlusAdmin");

  function setUp() public {
    // creates the pool manager, utility routers, and test tokens
    deployFreshManagerAndRouters();
    deployMintAndApprove2Currencies();
    deployPosm(manager);

    // Deploy the hook to an address with the correct flags
    address flags = address(
      uint160(Hooks.BEFORE_INITIALIZE_FLAG | Hooks.BEFORE_ADD_LIQUIDITY_FLAG) ^ (0x4444 << 144) // Namespace the hook to avoid collisions
    );

    bytes memory constructorArgs = abi.encode(manager); //Add all the necessary constructor arguments from the hook
    deployCodeTo("PlusPlusPoolHook.sol:PlusPlusPoolHook", constructorArgs, flags);
    hook = PlusPlusPoolHook(flags);
  }

  function helper_makePlusPlusToken(address rawToken, address earnToken, uint16 targetRatio) public returns (address) {
    PlusPlusToken token = new PlusPlusToken();
    token.initialize(rawToken, earnToken, targetRatio, plusPlusAdmin);
    vm.startPrank(plusPlusAdmin);
    token.updateWhitelist(address(this), true);
    token.updateWhitelist(address(hook), true);
    token.updateWhitelist(address(manager), true);
    vm.stopPrank();
    return address(token);
  }

  function helper_dealRawAndPlusPlus(
    address rawToken,
    uint256 rawAmount,
    address rawRecipient,
    address plusPlusToken,
    uint256 plusPlusAmount,
    address plusPlusRecipient
  ) internal {
    if (rawAmount > 0) {
      ERC20Mock(rawToken).mint(rawRecipient, rawAmount);
    }
    if (plusPlusAmount > 0) {
      ERC20Mock(rawToken).mint(address(this), plusPlusAmount);
      ERC20Mock(rawToken).approve(address(plusPlusToken), plusPlusAmount);
      PlusPlusToken(plusPlusToken).deposit(plusPlusRecipient, plusPlusAmount);
    }
  }

  function helper_addLiquidity(
    PoolKey memory _poolKey,
    int24 _tickLower,
    int24 _tickUpper,
    uint256 _liquidity,
    uint256 _amount0Max,
    uint256 _amount1Max,
    address _recipient,
    uint256 _deadline,
    bytes memory _hookData
  ) external returns (uint256, BalanceDelta) {
    return posm.mint(
      _poolKey, _tickLower, _tickUpper, _liquidity, _amount0Max, _amount1Max, _recipient, _deadline, _hookData
    );
  }

  function helper_removeLiquidity(
    uint256 _tokenId,
    uint256 _amount0Min,
    uint256 _amount1Min,
    address _recipient,
    uint256 _deadline,
    bytes memory _hookData
  ) external returns (BalanceDelta delta) {
    return posm.burn(_tokenId, _amount0Min, _amount1Min, _recipient, _deadline, _hookData);
  }

  function helper_boundInt24(int24 value, int24 min, int24 max, int24 step) public returns (int24) {
    min /= step;
    max /= step;
    return step
      * int24(
        int256(
          bound(
            uint256(value + int256(uint256(type(uint24).max))),
            uint256(min + int256(uint256(type(uint24).max))),
            uint256(max + int256(uint256(type(uint24).max)))
          )
        ) - int256(uint256(type(uint24).max))
      );
  }

  function test_beforeInitialize_unsupportedTokenPair(bytes32 saltA, bytes32 saltB) public {
    // Ensure that the salts are not the same
    vm.assume(saltA != saltB);
    address tokenA = address(new ERC20Mock{salt: saltA}());
    address tokenB = address(new ERC20Mock{salt: saltB}());
    // Set currency0 to token0 and currency1 to token1
    currency0 = tokenA < tokenB ? Currency.wrap(tokenA) : Currency.wrap(tokenB);
    currency1 = tokenA < tokenB ? Currency.wrap(tokenB) : Currency.wrap(tokenA);

    // Attempt to create a pool with the wrong token pair
    key = PoolKey(currency0, currency1, FEE, TICK_SPACING, IHooks(hook));
    poolId = key.toId();
    vm.expectRevert(
      abi.encodeWithSelector(
        CustomRevert.WrappedError.selector,
        address(hook),
        IHooks.beforeInitialize.selector,
        abi.encodeWithSelector(PlusPlusPoolHook.UnsupportedTokenPair.selector),
        abi.encodeWithSelector(Hooks.HookCallFailed.selector)
      )
    );
    manager.initialize(key, SQRT_PRICE_1_1);
  }

  function test_beforeInitialize_eitherIsPlusPlusToken(bool isPlusPlusTokenA, bool isPlusPlusTokenB) public {
    // Ensure at least one token is a PlusPlusToken
    vm.assume(isPlusPlusTokenA || isPlusPlusTokenB);

    // Creating a new raw token and plusplus token pair
    address tokenA;
    if (isPlusPlusTokenA) {
      address rawToken = address(new ERC20Mock());
      tokenA = helper_makePlusPlusToken(rawToken, address(new ERC20Mock()), 5000);
    } else {
      tokenA = address(new ERC20Mock());
    }
    address tokenB;
    if (isPlusPlusTokenB) {
      address rawToken = address(new ERC20Mock());
      tokenB = helper_makePlusPlusToken(rawToken, address(new ERC20Mock()), 5000);
    } else {
      tokenB = address(new ERC20Mock());
    }

    currency0 = tokenA < tokenB ? Currency.wrap(tokenA) : Currency.wrap(tokenB);
    currency1 = tokenA < tokenB ? Currency.wrap(tokenB) : Currency.wrap(tokenA);

    // Attempt to create a pool with the correct token pair
    key = PoolKey(currency0, currency1, FEE, TICK_SPACING, IHooks(hook));
    poolId = key.toId();
    manager.initialize(key, SQRT_PRICE_1_1);

    // Assert that the pool was created successfully
    (uint160 sqrtPriceX96,,,) = manager.getSlot0(poolId);
    assertEq(sqrtPriceX96, SQRT_PRICE_1_1, "Pool was not created successfully");
  }

  function test_beforeAddLiquidity_revert(bytes32 saltA, bytes32 saltB, uint128 liquidityAmount) public {
    // Ensure that the salts are not the same
    vm.assume(saltA != saltB);
    // Create a regular token
    address tokenA = address(new ERC20Mock{salt: saltA}());
    // Creating a plusplus token pair
    address rawToken = address(new ERC20Mock{salt: saltB}());
    address tokenB = helper_makePlusPlusToken(rawToken, address(new ERC20Mock()), 5000);
    currency0 = tokenA < tokenB ? Currency.wrap(tokenA) : Currency.wrap(tokenB);
    currency1 = tokenA < tokenB ? Currency.wrap(tokenB) : Currency.wrap(tokenA);

    // Attempt to create a pool with the correct token pair
    key = PoolKey(currency0, currency1, FEE, TICK_SPACING, IHooks(hook));
    poolId = key.toId();
    manager.initialize(key, SQRT_PRICE_1_1);

    // // Attempt to add liquidity to the pool
    tickLower = TickMath.minUsableTick(key.tickSpacing);
    tickUpper = TickMath.maxUsableTick(key.tickSpacing);

    liquidityAmount = uint128(bound(liquidityAmount, 1, type(uint128).max));

    (uint256 amount0Expected, uint256 amount1Expected) = LiquidityAmounts.getAmountsForLiquidity(
      SQRT_PRICE_1_1, TickMath.getSqrtPriceAtTick(tickLower), TickMath.getSqrtPriceAtTick(tickUpper), liquidityAmount
    );

    if (tokenA < tokenB) {
      ERC20Mock(tokenA).mint(address(this), amount0Expected + 1);
      helper_dealRawAndPlusPlus(rawToken, 0, address(0), tokenB, amount1Expected + 1, address(this));
    } else {
      ERC20Mock(tokenA).mint(address(this), amount1Expected + 1);
      helper_dealRawAndPlusPlus(rawToken, 0, address(0), tokenB, amount0Expected + 1, address(this));
    }

    // Attempt to add liquidity to the pool (forcibly using an external call to the hook so that expectRevert catches it)
    vm.expectRevert(
      abi.encodeWithSelector(
        CustomRevert.WrappedError.selector,
        address(hook),
        IHooks.beforeAddLiquidity.selector,
        abi.encodeWithSelector(PlusPlusPoolHook.UnsupportedLiquidityOperation.selector),
        abi.encodeWithSelector(Hooks.HookCallFailed.selector)
      )
    );
    this.helper_addLiquidity(
      key,
      tickLower,
      tickUpper,
      liquidityAmount,
      amount0Expected + 1,
      amount1Expected + 1,
      address(this),
      block.timestamp,
      ZERO_BYTES
    );
  }

  function test_modifyLiquidity_add(bytes32 saltA, bytes32 saltB, uint64 liquidityAmount) public {
    // Ensure that the salts are not the same
    vm.assume(saltA != saltB);
    // Create a regular token
    address tokenA = address(new ERC20Mock{salt: saltA}());
    // Creating a plusplus token pair
    address rawToken = address(new ERC20Mock{salt: saltB}());
    address tokenB = helper_makePlusPlusToken(rawToken, address(new ERC20Mock()), 5000);
    currency0 = tokenA < tokenB ? Currency.wrap(tokenA) : Currency.wrap(tokenB);
    currency1 = tokenA < tokenB ? Currency.wrap(tokenB) : Currency.wrap(tokenA);

    // Attempt to create a pool with the correct token pair
    key = PoolKey(currency0, currency1, FEE, TICK_SPACING, IHooks(hook));
    poolId = key.toId();
    manager.initialize(key, SQRT_PRICE_1_1);

    // Determine the ticks to be used for the liquidity
    tickLower = helper_boundInt24(
      tickLower,
      TickMath.minUsableTick(key.tickSpacing),
      TickMath.maxUsableTick(key.tickSpacing) - key.tickSpacing,
      key.tickSpacing
    );
    tickUpper = helper_boundInt24(
      tickUpper, tickLower + key.tickSpacing, TickMath.maxUsableTick(key.tickSpacing), key.tickSpacing
    );

    // Ensure that the liquidity amount is not too large
    liquidityAmount = uint64(bound(liquidityAmount, 1, type(uint64).max));

    (uint256 amount0Expected, uint256 amount1Expected) = LiquidityAmounts.getAmountsForLiquidity(
      SQRT_PRICE_1_1, TickMath.getSqrtPriceAtTick(tickLower), TickMath.getSqrtPriceAtTick(tickUpper), liquidityAmount
    );

    // Mint and approve the tokens. Only mint and approve the rawTokens however, as the hook will wrap them into the PlusPlusToken
    if (tokenA < tokenB) {
      ERC20Mock(tokenA).mint(address(this), amount0Expected + 1);
      IERC20(tokenA).approve(address(hook), amount0Expected + 1);
      helper_dealRawAndPlusPlus(rawToken, amount1Expected + 1, address(this), tokenB, 0, address(0));
      IERC20(rawToken).approve(address(hook), amount1Expected + 1);
    } else {
      ERC20Mock(tokenA).mint(address(this), amount1Expected + 1);
      IERC20(tokenA).approve(address(hook), amount1Expected + 1);
      helper_dealRawAndPlusPlus(rawToken, amount0Expected + 1, address(this), tokenB, 0, address(0));
      IERC20(rawToken).approve(address(hook), amount0Expected + 1);
    }

    hook.modifyLiquidity(
      key,
      IPoolManager.ModifyLiquidityParams({
        tickLower: tickLower,
        tickUpper: tickUpper,
        liquidityDelta: int256(uint256(liquidityAmount)),
        salt: bytes32(0)
      })
    );

    // Confirm that the hook now owns the liquidity added to the pool manager
    (uint128 liquidity, uint256 feeGrowthInside0LastX128, uint256 feeGrowthInside1LastX128) =
      manager.getPositionInfo(poolId, address(hook), tickLower, tickUpper, "");
    assertEq(liquidity, liquidityAmount, "Hook should own the liquidityAmount added to the pool manager");
    assertEq(feeGrowthInside0LastX128, 0, "Fee growth inside0 should be 0 since no swaps have occurred");
    assertEq(feeGrowthInside1LastX128, 0, "Fee growth inside1 should be 0 since no swaps have occurred");

    // Confirm that we have minted the sender ERC6909 tokens for the liquidity added
    tokenId = hook.generateTokenId(key, tickLower, tickUpper, "");
    assertEq(
      hook.balanceOf(address(this), tokenId),
      liquidityAmount,
      "Hook should have minted the sender ERC6909 tokens for the liquidity added"
    );
  }
}
