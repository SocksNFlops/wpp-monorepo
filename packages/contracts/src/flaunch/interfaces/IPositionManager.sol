// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IFlaunch} from "./IFlaunch.sol";

interface IPositionManager {
  /**
   * Parameters required when flaunching a new token.
   *
   * @member name Name of the token
   * @member symbol Symbol of the token
   * @member tokenUri The generated ERC721 token URI
   * @member initialTokenFairLaunch The amount of tokens to add as single sided fair launch liquidity
   * @member premineAmount The amount of tokens that the creator will buy themselves
   * @member creator The address that will receive the ERC721 ownership and premined ERC20 tokens
   * @member creatorFeeAllocation The percentage of fees the creators wants to take from the BidWall
   * @member flaunchAt The timestamp at which the token will launch
   * @member initialPriceParams The encoded parameters for the Initial Price logic
   * @member feeCalculatorParams The encoded parameters for the fee calculator
   */
  struct FlaunchParams {
    string name;
    string symbol;
    string tokenUri;
    uint256 initialTokenFairLaunch;
    uint256 premineAmount;
    address creator;
    uint24 creatorFeeAllocation;
    uint256 flaunchAt;
    bytes initialPriceParams;
    bytes feeCalculatorParams;
  }

  function flaunchContract() external returns (IFlaunch _flaunch);

  function flaunch(FlaunchParams calldata _params) external payable returns (address memecoin_);
}
