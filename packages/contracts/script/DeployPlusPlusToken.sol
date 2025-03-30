// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {PlusPlusToken} from "../src/PlusPlusToken.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {WETH9} from "../src/mocks/WETH9.sol";

contract DeployPlusPlusToken is Script {
    address public stETH;
    address public weth;
    address public poolManager = 0x00b036b58a818b1bc34d502d3fe730db729e62ac;
    address public admin = 0xc4E2761B76A5963687d8Be95ee8EC3feB4407A05;

    function setUp() public {
        stETH = address(new ERC20Mock("stETH", "stETH", 18));
        weth = address(new WETH9());
    }

    function run() public returns (PlusPlusToken plusPlusToken) {
        vm.startBroadcast();
        address broadcaster = tx.origin;

        address implementation = address(new PlusPlusToken());
        bytes memory initializerData =
            abi.encodeCall(PlusPlusToken.initialize, (weth, stETH, 5000, broadcaster));
        address proxy = address(new ERC1967Proxy(address(implementation), initializerData));
        plusPlusToken = PlusPlusToken(payable(proxy));

        // Granting all the roles to the admin
        plusPlusToken.grantRole(plusPlusToken.DEFAULT_ADMIN_ROLE(), admin);

        // Revoking the admin role from the script
        plusPlusToken.revokeRole(plusPlusToken.DEFAULT_ADMIN_ROLE(), address(broadcaster));

        vm.stopBroadcast();
    }
}
