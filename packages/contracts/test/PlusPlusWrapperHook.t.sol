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
import {PlusPlusWrapperHook} from "../src/PlusPlusWrapperHook.sol";
import {MinimalRouter} from "./utils/MinimalRouter.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {PlusPlusToken} from "../src/PlusPlusToken.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract PlusPlusWrapperHookTest is Test, Fixtures {
  using EasyPosm for IPositionManager;
  using PoolIdLibrary for PoolKey;
  using CurrencyLibrary for Currency;
  using StateLibrary for IPoolManager;
  using CustomRevert for bytes4;
  using BalanceDeltaLibrary for BalanceDelta;

  uint24 constant FEE = 0;
  int24 constant TICK_SPACING = 1;

  MinimalRouter minimalRouter;
  PlusPlusWrapperHook hook;
  PoolId poolId;

  uint256 tokenId;
  int24 tickLower;
  int24 tickUpper;

  function setUp() public {
    // creates the pool manager, utility routers, and test tokens
    deployFreshManagerAndRouters();
    deployMintAndApprove2Currencies();
    deployMinimalRouterWithPermissions();
    deployPosm(manager);

    // Deploy the hook to an address with the correct flags
    address flags = address(
      uint160(Hooks.BEFORE_INITIALIZE_FLAG | Hooks.BEFORE_ADD_LIQUIDITY_FLAG) ^ (0x4444 << 144) // Namespace the hook to avoid collisions
    );

    bytes memory constructorArgs = abi.encode(manager); //Add all the necessary constructor arguments from the hook
    deployCodeTo("PlusPlusWrapperHook.sol:PlusPlusWrapperHook", constructorArgs, flags);
    hook = PlusPlusWrapperHook(flags);
  }

  function deployMinimalRouterWithPermissions() public {
    // Set up the minimal router
    minimalRouter = new MinimalRouter(manager);

    // Approving
    IERC20(Currency.unwrap(currency0)).approve(address(minimalRouter), Constants.MAX_UINT256);
    IERC20(Currency.unwrap(currency1)).approve(address(minimalRouter), Constants.MAX_UINT256);
  }

  function helper_makePlusPlusToken(address rawToken, address earnToken, uint16 targetRatio) public returns (address) {
    PlusPlusToken token = new PlusPlusToken();
    token.initialize(rawToken, earnToken, targetRatio);
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

  function test_beforeInitialize_unsupportedTokenPair(address token0, address token1) public {
    // Make sure that the tokens are in order and not the same
    vm.assume(token0 < token1);
    // Set currency0 to token0 and currency1 to token1
    currency0 = Currency.wrap(token0);
    currency1 = Currency.wrap(token1);

    // Attempt to create a pool with the wrong token pair
    key = PoolKey(currency0, currency1, FEE, TICK_SPACING, IHooks(hook));
    poolId = key.toId();
    vm.expectRevert(
      abi.encodeWithSelector(
        CustomRevert.WrappedError.selector,
        address(hook),
        IHooks.beforeInitialize.selector,
        abi.encodeWithSelector(PlusPlusWrapperHook.UnsupportedTokenPair.selector),
        abi.encodeWithSelector(Hooks.HookCallFailed.selector)
      )
    );
    manager.initialize(key, SQRT_PRICE_1_1);
  }

  function test_beforeInitialize_unsupportedFee(uint24 fee) public {
    // Make sure that the fee is wrong
    fee = uint24(bound(fee, 1, LPFeeLibrary.MAX_LP_FEE));

    // Attempt to create a pool with the correct token pair but wrong fee
    key = PoolKey(currency0, currency1, fee, TICK_SPACING, IHooks(hook));
    poolId = key.toId();
    vm.expectRevert(
      abi.encodeWithSelector(
        CustomRevert.WrappedError.selector,
        address(hook),
        IHooks.beforeInitialize.selector,
        abi.encodeWithSelector(PlusPlusWrapperHook.UnsupportedFee.selector),
        abi.encodeWithSelector(Hooks.HookCallFailed.selector)
      )
    );
    manager.initialize(key, SQRT_PRICE_1_1);
  }

  function test_beforeInitialize_unsupportedTickSpacing(int24 tickSpacing) public {
    // Make sure that the tick spacing is wrong
    tickSpacing = int24(bound(tickSpacing, 2, TickMath.MAX_TICK_SPACING));

    // Attempt to create a pool with the correct token pair
    key = PoolKey(currency0, currency1, FEE, tickSpacing, IHooks(hook));
    poolId = key.toId();
    vm.expectRevert(
      abi.encodeWithSelector(
        CustomRevert.WrappedError.selector,
        address(hook),
        IHooks.beforeInitialize.selector,
        abi.encodeWithSelector(PlusPlusWrapperHook.UnsupportedTickSpacing.selector),
        abi.encodeWithSelector(Hooks.HookCallFailed.selector)
      )
    );
    manager.initialize(key, SQRT_PRICE_1_1);
  }

  function test_beforeInitialize_correctCurrencyPair(bytes32 salt) public {
    // Creating a new raw token and plusplus token pair
    address rawToken = address(new ERC20Mock{salt: salt}());
    address plusPlusToken = helper_makePlusPlusToken(rawToken, address(new ERC20Mock()), 5000);
    currency0 = rawToken < plusPlusToken ? Currency.wrap(rawToken) : Currency.wrap(plusPlusToken);
    currency1 = rawToken < plusPlusToken ? Currency.wrap(plusPlusToken) : Currency.wrap(rawToken);

    // Attempt to create a pool with the correct token pair
    key = PoolKey(currency0, currency1, FEE, TICK_SPACING, IHooks(hook));
    poolId = key.toId();
    manager.initialize(key, SQRT_PRICE_1_1);

    // Assert that the pool was created successfully
    (uint160 sqrtPriceX96,,,) = manager.getSlot0(poolId);
    assertEq(sqrtPriceX96, SQRT_PRICE_1_1, "Pool was not created successfully");
  }

  function test_beforeAddLiquidity_revert(bytes32 salt, uint128 liquidityAmount) public {
    // Creating a new raw token and plusplus token pair
    address rawToken = address(new ERC20Mock{salt: salt}());
    address plusPlusToken = helper_makePlusPlusToken(rawToken, address(new ERC20Mock()), 5000);
    currency0 = rawToken < plusPlusToken ? Currency.wrap(rawToken) : Currency.wrap(plusPlusToken);
    currency1 = rawToken < plusPlusToken ? Currency.wrap(plusPlusToken) : Currency.wrap(rawToken);

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

    if (rawToken < plusPlusToken) {
      helper_dealRawAndPlusPlus(
        rawToken, amount0Expected + 1, address(this), plusPlusToken, amount1Expected + 1, address(this)
      );
    } else {
      helper_dealRawAndPlusPlus(
        rawToken, amount1Expected + 1, address(this), plusPlusToken, amount0Expected + 1, address(this)
      );
    }

    // Attempt to add liquidity to the pool (forcibly using an external call to the hook so that expectRevert catches it)
    vm.expectRevert(
      abi.encodeWithSelector(
        CustomRevert.WrappedError.selector,
        address(hook),
        IHooks.beforeAddLiquidity.selector,
        abi.encodeWithSelector(PlusPlusWrapperHook.UnsupportedLiquidityOperation.selector),
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
}
