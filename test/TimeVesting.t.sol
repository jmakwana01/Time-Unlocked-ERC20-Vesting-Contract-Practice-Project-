// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;


import "forge-std/Test.sol";
import "../src/TimeVesting.sol";
import "../src/TestToken.sol";


contract TimeVestingTest is Test {
TimeVesting vest;
TestToken token;
address payer = address(0xAA);
address beneficiary = address(0xBB);


function setUp() public {
token = new TestToken("Test", "TST");
vest = new TimeVesting();


// mint tokens to payer
token.mint(payer, 1_000 ether);
}


function testCreateAndWithdrawPartial() public {
vm.startPrank(payer);
uint256 total = 100 ether;
token.approve(address(vest), total);


uint256 start = block.timestamp + 1; // start in 1s
uint256 durationDays = 4; // unlock 1/4 every day


bytes32 id = vest.createScheduleAndDeposit(address(token), beneficiary, total, start, durationDays);
vm.stopPrank();


// before start => nothing vested
vm.expectRevert();
vm.prank(beneficiary);
vest.withdraw(id);


// move to after 1 full day
vm.warp(start + 86400 + 1);


// beneficiary can withdraw 1/4
vm.prank(beneficiary);
vest.withdraw(id);
assertEq(token.balanceOf(beneficiary), 25 ether);


// after 2 days => another 25 ether
vm.warp(start + 2 * 86400 + 2);
vm.prank(beneficiary);
vest.withdraw(id);
assertEq(token.balanceOf(beneficiary), 50 ether);


// after full duration => remaining
vm.warp(start + 4 * 86400 + 10);
vm.prank(beneficiary);
vest.withdraw(id);
assertEq(token.balanceOf(beneficiary), 100 ether);
}


function testPayerCancelRefundsUnvested() public {
vm.startPrank(payer);
uint256 total = 100 ether;
token.approve(address(vest), total);
uint256 start = block.timestamp;
uint256 durationDays = 10;
bytes32 id = vest.createScheduleAndDeposit(address(token), beneficiary, total, start, durationDays);
vm.stopPrank();


// after 3 days, 30% vested
vm.warp(start + 3 * 86400 + 1);


// payer cancels; beneficiary keeps vested (30), payer gets remainder (70)
vm.prank(payer);
vest.cancelSchedule(id);


assertEq(token.balanceOf(payer), 1_000 ether - 100 ether + 70 ether); // minted 1000, paid 100 then refunded 70
assertEq(token.balanceOf(beneficiary), 30 ether);
}
}