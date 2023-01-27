// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Solidex.sol";
import "../src/Solids.sol";
import "forge-std/console.sol";


contract SolidexTest is Test {
    Solids public solids;
    Solidex public solidex;

    function setUp() public {
        solids = new Solids();
        solidex = new Solidex(address(solids));
        solids.approve(address(solidex), 100 ether);
    }

    function init() public {
        solidex.init{value: 5 ether}(5 ether);
    }

    function test() public {
    uint totalLiquidity = solidex.totalLiquidity();

    console.log(totalLiquidity);
}
}





// // Approving DEX to take Solids from main account
// await solids.approve(solidex.address, ethers.utils.parseEther("100"));
// console.log("INIT exchange...");
// await solidex.init(ethers.utils.parseEther("0.01"), {
//   value: ethers.utils.parseEther("0.01"),
//   gasLimit: 200000,
// });

// const totalLiquidity = solidex.totalLiquidity();
// console.log("totalLiquidity", totalLiquidity);