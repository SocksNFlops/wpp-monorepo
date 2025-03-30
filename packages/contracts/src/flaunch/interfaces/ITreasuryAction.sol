// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";

interface ITreasuryAction {
  event ActionExecuted(PoolKey _poolKey, int256 _token0, int256 _token1);

  function execute(PoolKey memory _poolKey, bytes memory _data) external;
}
