// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {PlusPlusToken} from "../src/PlusPlusToken.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PlusPlusTokenTest is Test {
  PlusPlusToken public plusplusToken;
  IERC20 public rawToken;
  IERC20 public earningToken;
  uint16 public targetRatio = 5_000;

  function setUp() public {
    // Set up raw and earning tokens
    rawToken = new ERC20Mock();
    earningToken = new ERC20Mock();

    // Initialize plusplus token
    plusplusToken = new PlusPlusToken();
    plusplusToken.initialize(address(rawToken), address(earningToken), targetRatio);
  }

  function test_Initialize() public {
    assertEq(plusplusToken.rawToken(), address(rawToken));
    assertEq(plusplusToken.earningToken(), address(earningToken));
    assertEq(plusplusToken.targetRatio(), targetRatio);
    assertEq(plusplusToken.lastTotalStake().accruedPoints, 0);
    assertEq(plusplusToken.lastTotalStake().timestamp, 0);
  }

  function test_deposit(address account, uint128 depositAmount) public {
    // Ensure that the account is not the zero address
    vm.assume(account != address(0));

    // Deal tokens to test
    deal(address(rawToken), address(this), depositAmount);

    // Grant allowance to the plusplus token
    rawToken.approve(address(plusplusToken), depositAmount);

    // Deposit
    plusplusToken.deposit(account, depositAmount);

    // Assertions
    assertEq(plusplusToken.balanceOf(account), depositAmount, "Balance of account should be the deposit amount");
    assertEq(rawToken.balanceOf(address(this)), 0, "Raw token balance of this should be 0");
    assertEq(plusplusToken.points(account), 0, "Points of account should be 0");
  }

  function test_points(address account, uint128 depositAmount, uint32 timeElapsed) public {
    // Ensure that the account is not the zero address
    vm.assume(account != address(0));

    // Deal tokens to test
    deal(address(rawToken), address(this), depositAmount);

    // Grant allowance to the plusplus token
    rawToken.approve(address(plusplusToken), depositAmount);

    // Deposit
    plusplusToken.deposit(account, depositAmount);

    // Validate that the points are 0
    assertEq(plusplusToken.points(account), 0, "Points of account should be 0");
    assertEq(plusplusToken.totalPoints(), 0, "Total points should be 0");

    // Advance time
    skip(timeElapsed);

    // Validate that the points are correct
    assertEq(plusplusToken.points(account), uint256(timeElapsed) * depositAmount, "Points of account are not correct");
    assertEq(plusplusToken.totalPoints(), uint256(timeElapsed) * depositAmount, "Total points are not correct");
  }

  function test_withdraw(address account, uint128 depositAmount, uint128 withdrawAmount, uint32 timeElapsed) public {
    // Ensure that the account is not the zero address
    vm.assume(account != address(0));

    // Ensure that the withdraw amount is less than the deposit amount
    depositAmount = uint128(bound(depositAmount, 1, type(uint128).max));
    withdrawAmount = uint128(bound(withdrawAmount, 0, depositAmount));

    // Deal tokens to test
    deal(address(rawToken), address(this), depositAmount);

    // Grant allowance to the plusplus token
    rawToken.approve(address(plusplusToken), depositAmount);

    // Deposit
    plusplusToken.deposit(account, depositAmount);

    // Validate that the points are 0
    assertEq(plusplusToken.points(account), 0, "Points of account should be 0");
    assertEq(plusplusToken.totalPoints(), 0, "Total points should be 0");

    // Advance time
    skip(timeElapsed);

    // Withdraw the tokens
    plusplusToken.withdraw(account, withdrawAmount);

    // Validate the balance of the account and total supply
    assertEq(
      plusplusToken.balanceOf(account),
      depositAmount - withdrawAmount,
      "Balance of account should be the deposit amount minus the withdraw amount"
    );
    assertEq(
      plusplusToken.totalSupply(),
      depositAmount - withdrawAmount,
      "Total supply should be the deposit amount minus the withdraw amount"
    );

    // Validate that the points are correct
    assertEq(plusplusToken.points(account), uint256(timeElapsed) * (depositAmount), "Points of account are not correct");
    assertEq(plusplusToken.totalPoints(), uint256(timeElapsed) * (depositAmount), "Total points are not correct");
  }
}
