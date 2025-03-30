// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IFlaunch} from "./IFlaunch.sol";

interface IRevenueManager {
  struct FlaunchToken {
    IFlaunch flaunch;
    uint256 tokenId;
  }

  /**
   * Parameters passed during manager initialization.
   *
   * @member creator The end-owner creator of the ERC721
   * @member protocolRecipient The recipient of protocol fees
   * @member protocolFee The fee that the external protocol will take (2dp)
   */
  struct InitializeParams {
    address payable creator;
    address payable protocolRecipient;
    uint256 protocolFee;
  }

  function initialize(FlaunchToken calldata _flaunchToken, address _owner, bytes calldata _data) external;

  function claim() external returns (uint256 creatorAmount_, uint256 protocolAmount_);
}
