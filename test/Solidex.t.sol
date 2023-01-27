// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Solidex.sol";
import "../src/Solids.sol";
import "forge-std/console.sol";


contract SolidexTest is Test {
    Solids public solids;
    Solidex public solidex;
    address matteo = address(100);


    function setUp() public {
        solids = new Solids();
        solidex = new Solidex(address(solids));
        // need approval to swap LSD and call deposit function
        solids.approve(address(solidex), 100 ether);
        vm.deal(matteo, 50 ether);

    }


    function test() public {
    uint initEthAmount = 5 ether;
    // verso tutti gli $SLD che possiedo
    uint initSldAmount = 5 ether;

    solidex.init{value: initEthAmount}(initSldAmount);
    uint totalLiquidity = solidex.totalLiquidity();

    assertEq(solidex.totalLiquidity(), initEthAmount);
    assertEq(address(solidex).balance, initEthAmount);
    assertEq(solids.balanceOf(address(solidex)), initSldAmount);

    vm.startPrank(matteo);
    // APPROVAL
    solids.approve(address(solidex), 100 ether);
    emit log_named_decimal_uint("matteo $ETH initial balance: ", address(matteo).balance, 18);

    // SWAP
    solidex.ethToToken{value: 10 ether}();
    emit log_named_decimal_uint("matteo $ETH balance after eth swap: ", address(matteo).balance, 18);
    emit log_named_decimal_uint("matteo $SLD balance after eth swap: ", solids.balanceOf(address(matteo)), 18);

    solidex.tokenToEth(1 ether);
    emit log_named_decimal_uint("matteo $ETH balance after token swap: ", address(matteo).balance, 18);
    emit log_named_decimal_uint("matteo $SLD balance after token swap: ", solids.balanceOf(address(matteo)), 18);

    // when we try to swap $SLD tokens we don't have: [FAIL. Reason: ERC20: transfer amount exceeds balance]
    // if we don't approve, error [FAIL. Reason: ERC20: insufficient allowance] test() (gas: 155695)

    // LIQUIDITY
    solidex.deposit{value: 1 ether}();
    emit log_named_decimal_uint("matteo $ETH balance after deposit: ", address(matteo).balance, 18);
    emit log_named_decimal_uint("matteo $SLD balance after deposit: ", solids.balanceOf(address(matteo)), 18);

    solidex.withdraw(0.5 ether);
    emit log_named_decimal_uint("matteo $ETH balance after withdraw: ", address(matteo).balance, 18);
    emit log_named_decimal_uint("matteo $SLD balance after withdrawal: ", solids.balanceOf(address(matteo)), 18);

}
}