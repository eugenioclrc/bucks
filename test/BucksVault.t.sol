// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/BucksVault.sol";
import "solady/tokens/ERC20.sol";
import "../src/mocks/DataFeed.sol";
import {MockBtc} from "../src/mocks/WBTC.sol";


contract BucksVaultTest is Test {
    BucksVault public bucksVault;
    mockOracle oracle = new mockOracle();
    ERC20 wbtc = ERC20(address(new MockBtc()));

    uint256 constant ONE_BTC = 1e8;


    function setUp() public {
        bucksVault = new BucksVault(address(wbtc), address(oracle));
    }

    function testMockWbtcPrice() public {
        assertEq(bucksVault.WBTC_PRICE(), 28964_00000000);
    }

    function testCreateVault() public {
         assertEq(bucksVault.totalSupply(), 0, "Total supply should be 0");
        uint256 vaultId = bucksVault.createVault();
        assertEq(vaultId, 1, "vaultId should be 1");
        assertEq(bucksVault.totalSupply(), 1, "Total supply should be 1");

        wbtc.approve(address(bucksVault), type(uint256).max);

        bucksVault.deposit(vaultId, ONE_BTC);
        assertEq(bucksVault.vaultsValue(vaultId), ONE_BTC, "Vault value have 1 BTC");
    }

    function testMaxMint() public {
        uint256 vaultId = bucksVault.createVault();

        wbtc.approve(address(bucksVault), type(uint256).max);

        bucksVault.deposit(vaultId, ONE_BTC);
        assertEq(bucksVault.vaultsValue(vaultId), ONE_BTC, "Vault value have 1 BTC");

        // this should revert, im depositing more than i have
        vm.expectRevert();
        bucksVault.deposit(vaultId, 100 ether);

        uint256 maxMint = bucksVault.maxMint(vaultId);
        uint256 expectedMaxMint = 28964 ether * 80 / 100;
        assertEq(maxMint, expectedMaxMint, "Max mint should be 80% of 28964");

        uint256 vaultValue = bucksVault.vaultCollateralValue(vaultId);
        assertEq(vaultValue, 28964 ether, "Vault value should be 28964 in 1e18 decimals");
    }

    function testDepositWithdrawSimple() public {
        uint256 vaultId = bucksVault.createVault();
        wbtc.approve(address(bucksVault), type(uint256).max);

        bucksVault.deposit(vaultId, 1 ether);
        assertEq(bucksVault.vaultsValue(vaultId), 1 ether, "Vault value have 1 BTC");

        bucksVault.widthdraw(vaultId, 0.5 ether);
        assertEq(bucksVault.vaultsValue(vaultId), 0.5 ether, "Vault value have 0.5 BTC");
        assertEq(wbtc.balanceOf(address(bucksVault)), 0.5 ether, "Vault value have 0.5 BTC");        
        assertEq(wbtc.balanceOf(address(this)), 99.5 ether, "user value have 99.5 BTC");     

        vm.expectRevert();
        bucksVault.widthdraw(vaultId, 1.5 ether);

        wbtc.transfer(address(bucksVault), 1 ether);

        vm.expectRevert();
        bucksVault.widthdraw(vaultId, 1 ether);

        bucksVault.widthdraw(vaultId, 0.5 ether);
    }

    function testDepositAndMint() public {
        uint256 vaultId = bucksVault.createVault();
        wbtc.approve(address(bucksVault), type(uint256).max);

        bucksVault.deposit(vaultId, ONE_BTC);
        assertEq(bucksVault.vaultsValue(vaultId), ONE_BTC, "Vault value have 1 BTC");

        uint256 maxMintPrev = bucksVault.maxMint(vaultId);
        assertEq(maxMintPrev, 23171_200000000000000000 , "Max mint should be 80% of 28964");
        // yoo 50cents??
        bucksVault.mintDebt(vaultId, 0.5 ether);
        assertEq(bucksVault.BUCKS().balanceOf(address(this)), 0.5 ether, "User should have 0.5 bucks");

        assertLt(bucksVault.maxMint(vaultId), maxMintPrev);
    }

    function testLiquidate() public {
        uint256 vaultId = bucksVault.createVault();
        wbtc.approve(address(bucksVault), type(uint256).max);

        bucksVault.deposit(vaultId, ONE_BTC);
       
        bucksVault.mintDebt(vaultId, bucksVault.maxMint(vaultId));
        assertEq(bucksVault.BUCKS().balanceOf(address(this)), 23171_200000000000000000, "User should have 23171.20 bucks");

        address liquidator = makeAddr("liquidator");
        vm.startPrank(liquidator);
        vm.expectRevert("not liquidatable");
        bucksVault.liquidate(vaultId);

    }
}
