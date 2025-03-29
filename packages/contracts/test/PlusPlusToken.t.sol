// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {PlusPlusToken} from "../src/PlusPlusToken.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PlusPlusTokenTest is Test {
  PlusPlusToken public plusplusToken;
  IERC20 public rawToken;
  IERC20 public earnToken;
  uint16 public targetRatio = 5_000;
  address public admin = makeAddr("admin");

  function setUp() public {
    // Set up raw and earning tokens
    rawToken = new ERC20Mock();
    earnToken = new ERC20Mock();

    // Initialize plusplus token
    plusplusToken = new PlusPlusToken();
    plusplusToken.initialize(address(rawToken), address(earnToken), targetRatio, admin);

    // Whitelist this contract as a recipient
    vm.prank(admin);
    plusplusToken.updateWhitelist(address(this), true);
  }

  function test_initialize() public view {
    assertEq(plusplusToken.rawToken(), address(rawToken));
    assertEq(plusplusToken.earnToken(), address(earnToken));
    assertEq(plusplusToken.targetRatio(), targetRatio);
    assertTrue(plusplusToken.hasRole(plusplusToken.DEFAULT_ADMIN_ROLE(), admin));
  }

  function test_rawDeposit(address account, uint128 depositAmount) public {
    // Ensure that the account is not the zero address
    vm.assume(account != address(0));

    // Add account to whitelist for this test
    vm.prank(admin);
    plusplusToken.updateWhitelist(account, true);

    // Deal tokens to account
    deal(address(rawToken), account, depositAmount);

    // Grant allowance to the plusplus token
    vm.prank(account);
    rawToken.approve(address(plusplusToken), depositAmount);

    // Raw-deposit
    vm.prank(account);
    plusplusToken.rawDeposit(depositAmount);

    // Assertions
    assertEq(plusplusToken.balanceOf(account), depositAmount, "Balance of account should be the deposit amount");
    assertEq(rawToken.balanceOf(address(this)), 0, "Raw token balance of this should be 0");
  }

  function test_rawWithdraw(address account, uint128 depositAmount, uint128 withdrawAmount, uint32 timeElapsed) public {
    // Ensure that the account is not the zero address
    vm.assume(account != address(0));

    // Add account to whitelist for this test
    vm.prank(admin);
    plusplusToken.updateWhitelist(account, true);

    // Ensure that the withdraw amount is less than the deposit amount
    // Ensure that the withdraw amount is less than the deposit amount
    depositAmount = uint128(bound(depositAmount, 1, type(uint128).max));
    withdrawAmount = uint128(bound(withdrawAmount, 0, depositAmount));

    // Deal tokens to account
    deal(address(rawToken), account, depositAmount);

    // Grant allowance to the plusplus token
    vm.prank(account);
    rawToken.approve(address(plusplusToken), depositAmount);

    // Raw-deposit
    vm.prank(account);
    plusplusToken.rawDeposit(depositAmount);

    // Advance time
    skip(timeElapsed);

    // Raw-withdraw
    vm.prank(account);
    plusplusToken.rawWithdraw(withdrawAmount);

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
  }

  function test_earnDeposit(address account, uint128 depositAmount) public {
    // Ensure that the account is not the zero address
    vm.assume(account != address(0));

    // Add account to whitelist for this test
    vm.prank(admin);
    plusplusToken.updateWhitelist(account, true);

    // Deal tokens to test
    deal(address(earnToken), account, depositAmount);

    // Grant allowance to the plusplus token
    vm.prank(account);
    earnToken.approve(address(plusplusToken), depositAmount);

    // Raw-deposit
    vm.prank(account);
    plusplusToken.earnDeposit(depositAmount);

    // Assertions
    assertEq(plusplusToken.balanceOf(account), depositAmount, "Balance of account should be the deposit amount");
    assertEq(earnToken.balanceOf(address(this)), 0, "Earn token balance of this should be 0");
  }

  function test_earnWithdraw(address account, uint128 depositAmount, uint128 withdrawAmount, uint32 timeElapsed) public {
    // Ensure that the account is not the zero address
    vm.assume(account != address(0));

    // Add account to whitelist for this test
    vm.prank(admin);
    plusplusToken.updateWhitelist(account, true);

    // Ensure that the withdraw amount is less than the deposit amount
    // Ensure that the withdraw amount is less than the deposit amount
    depositAmount = uint128(bound(depositAmount, 1, type(uint128).max));
    withdrawAmount = uint128(bound(withdrawAmount, 0, depositAmount));

    // Deal tokens to account
    deal(address(earnToken), account, depositAmount);

    // Grant allowance to the plusplus token
    vm.prank(account);
    earnToken.approve(address(plusplusToken), depositAmount);

    // Raw-deposit
    vm.prank(account);
    plusplusToken.earnDeposit(depositAmount);

    // Advance time
    skip(timeElapsed);

    // Raw-withdraw
    vm.prank(account);
    plusplusToken.earnWithdraw(withdrawAmount);

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
  }
}
