// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

contract WethPlusPlus is ERC20Upgradeable {
  function initialize() public initializer {
    __ERC20_init("WethPlusPlus", "WPP");
  }
}
