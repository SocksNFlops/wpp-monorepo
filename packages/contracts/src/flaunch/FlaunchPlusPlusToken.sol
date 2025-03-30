// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {EIP712Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {PlusPlusToken} from "../PlusPlusToken.sol";

contract FlaunchPlusPlusToken is PlusPlusToken {
  using SafeERC20 for IERC20;

  // Access control roles
  bytes32 public constant YIELD_SKIMMER_ROLE = keccak256("YIELD_SKIMMER_ROLE");

  bytes32 private constant PlusPlusTokenStorageLocation =
    0x916815e707b896d4cbd2bb2f2391cdf5114a0642fcf78c9c686b8bc97694bf00;

  function _getPlusPlusTokenStorage2() private pure returns (PlusPlusTokenStorage storage $) {
    assembly {
      $.slot := PlusPlusTokenStorageLocation
    }
  }

  function skimYield() external onlyRole(YIELD_SKIMMER_ROLE) returns (uint256 rawAmount) {
    // Fetch storage
    PlusPlusTokenStorage storage $ = _getPlusPlusTokenStorage2();

    uint256 totalSupply = this.totalSupply();
    uint256 rawTokenBalance = IERC20($._rawToken).balanceOf(address(this));
    uint256 earnTokenBalance = IERC20($._earnToken).balanceOf(address(this));

    // Calculate yield (rawAmount that is getting skimmed)
    rawAmount = rawTokenBalance + earnTokenBalance - totalSupply;

    // Transfer raw tokens from this contract to sender
    IERC20($._rawToken).safeTransfer(msg.sender, rawAmount);
  }
}
