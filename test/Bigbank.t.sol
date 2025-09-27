// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Test, console} from "forge-std/Test.sol";
import {Bigbank, Admin, Bank} from "../src/Bigbank.sol";

contract BigbankTest is Test {
    Bigbank public bigbank;
    Admin public adminContract;
    Bank public bank;

    address public admin = makeAddr("admin");
    address public user1 = makeAddr("user1");
    address public user2 = makeAddr("user2");
    address public user3 = makeAddr("user3");


    function setUp() public {

        // admin 作为 msg.sender
        // 部署后，管理员为 admin
        vm.prank(admin);
        bigbank = new Bigbank();

        // user3 作为 msg.sender
        // adminContract 部署后，所有者为user3
        vm.prank(user3);
        adminContract = new Admin();

        // 设置用户余额
        vm.deal(admin, 0 ether);
        vm.deal(user1, 1 ether);
        vm.deal(user2, 2 ether);
        vm.deal(user3, 3 ether);
        
    }

    // 测试存款成功
    function test_deposit_success() public {
        vm.prank(user1);
        bigbank.deposit{value: 1 ether}();
        assertEq(address(user1).balance, 0 ether);
        assertEq(address(bigbank).balance, 1 ether);
    }

    // 测试存款失败：存款金额小于 0.001 ether
    function test_deposit_failed_less_than_0_001_ether() public {
        vm.prank(user1);
        vm.expectRevert("Deposit amount must greater than 0.001 ether");
        bigbank.deposit{value: 0.0005 ether}();
    }

    // 测试存款失败：存款金额为 0
    function test_deposit_failed_zero_amount() public {
        vm.prank(user1);
        vm.expectRevert("Deposit amount must greater than 0.001 ether");
        bigbank.deposit{value: 0 ether}();
    }

    // 测试转移管理员成功
    function test_transfer_admin_success() public {
        // admin 作为 msg.sender
        vm.prank(admin); 

        // 将管理员从 admin 转移到 user1
        bigbank.transferAdmin(user1);

        // 检查管理员是否转移成功
        assertEq(user1, bigbank.getAdmin());
    }

    // 测试转移管理员失败：管理员地址为 0 地址
    function test_transfer_admin_failed_invalid_admin() public {
        vm.prank(admin);
        vm.expectRevert("Invalid admin");
        bigbank.transferAdmin(address(0));
    }

    // 测试转移管理员失败：不是管理员发起的
    function test_transfer_admin_failed_not_admin() public {
        vm.prank(user1);
        vm.expectRevert("You are not the owner");
        bigbank.transferAdmin(user2);
    }

    // 测试转移管理员后取款成功
    
    function test_transfer_admin_withdraw_success() public {
        console.log("-----user1 address:", user1);
        console.log("-----user3 address:", user3);
        console.log("-----admin address:", admin);

        // 转移管理员(将 Admin 合约的所有者 设置为 Bigbank 的管理员)
        vm.prank(admin);
        bigbank.transferAdmin(address(adminContract));
        console.log("bigbank.getAdmin()", bigbank.getAdmin());

        console.log("1-----user1 address:", user1);

        // user1 存款
        vm.prank(user1);
        bigbank.deposit{value: 1 ether}();

        console.log("2-----user1 address:", user1);

        // user3 取款（user3 此时为 Bigbank 的管理员）
        console.log("bigbank.getAdmin()", bigbank.getAdmin());
        vm.prank(user3);
        adminContract.adminWithdraw(bigbank);

        console.log("3-----user1 address:", user1);

        // 检查 Bigbank 余额
        assertEq(address(bigbank).balance, 0 ether);

        assertEq(address(adminContract).balance, 1 ether);
        

    }
    
}