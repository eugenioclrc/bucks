// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Bucks.sol";

contract BucksTokenTest is Test {
    BucksToken public token;
    address user = makeAddr("user");

    function setUp() public {
        token = new BucksToken();
    }

    function testOwnership() public {
        assertEq(token.owner(), address(this));
        token.transferOwnership(address(0xdead));
        assertEq(token.owner(), address(0xdead));
        vm.expectRevert();
        token.transferOwnership(address(0xdead));
    }

    function testMint() public {
        token.mint(user, 1 ether);
        assertEq(token.balanceOf(user), 1 ether);

        token.transferOwnership(address(0xdead));

        vm.expectRevert();
        token.mint(user, 1 ether);

        vm.prank(address(0xdead));
        token.mint(user, 1 ether);

        assertEq(token.balanceOf(user), 2 ether);
    }

    function testBurn() public {
        token.mint(address(this), 10 ether);
        assertEq(token.balanceOf(address(this)), 10 ether, "minted 10 ether");

        token.burn(5 ether);
        assertEq(token.balanceOf(address(this)), 5 ether, "burned 5 ether");

        token.transfer(user, 5 ether);
        assertEq(token.balanceOf(address(this)), 0, "transferred 5 ether");

        vm.expectRevert();
        token.burn(user, 5 ether);

        vm.prank(user);
        token.burn(1 ether);
        assertEq(token.balanceOf(user), 4 ether, "burned 1 ether");

        vm.prank(user);
        token.approve(address(this), 3 ether);

        assertEq(token.allowance(user, address(this)), 3 ether, "approved 3 ether");

        token.burn(user, 1 ether);

        assertEq(token.allowance(user, address(this)), 2 ether, "approved 3 ether");
        assertEq(token.balanceOf(user), 3 ether, "burned 1 ether");
    }

}
