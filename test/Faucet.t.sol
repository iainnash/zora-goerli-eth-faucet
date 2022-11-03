// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Faucet.sol";

contract MockToken {
    uint256 balance;

    function balanceOf(address) public returns (uint256) {
        return balance;
    }

    function setBalance(uint256 _balance) public {
        balance = _balance;
    }
}

contract FaucetTest is Test {
    address admin = address(0x99);
    Faucet public faucet;
    MockToken public mockToken;

    function setUp() public {
        faucet = new Faucet(admin);
        mockToken = new MockToken();
    }

    function testPayout() public {
        vm.prank(admin);
        faucet.updateSettings(ERC721(address(mockToken)), 1 ether);
        vm.startPrank(address(0x123));
        assertEq(address(faucet).balance, 0);
        mockToken.setBalance(0);
        vm.expectRevert(Faucet.UserNFTBalanceTooLow.selector);
        faucet.claimAllAvailable();
        mockToken.setBalance(1);
        vm.expectRevert(Faucet.TransferFailed.selector);
        faucet.claimAllAvailable();
        vm.deal(address(faucet), 1 ether);
        faucet.claimAllAvailable();
        assertEq(address(faucet).balance, 0 ether);
    }

    function testAdminClaim() public {
        vm.deal(address(faucet), 1 ether);
        assertEq(admin.balance, 0 ether);
        vm.prank(admin);
        faucet.ownerWithdraw(0);
        assertEq(admin.balance, 1 ether);
    }
}
