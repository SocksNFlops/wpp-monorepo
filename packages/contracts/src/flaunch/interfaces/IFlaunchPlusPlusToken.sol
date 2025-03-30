// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {IPlusPlusToken} from "../../PlusPlusToken.sol";

interface IFlaunchPlusPlusToken is IPlusPlusToken {
  /**
   * @notice Skims yield from the token and sends it to the buyback address. Only callable by the YIELD_SKIMMER_ROLE.
   * @return rawAmount The amount of raw tokens that were skimmed
   */
  function skimYield() external returns (uint256 rawAmount);
}
