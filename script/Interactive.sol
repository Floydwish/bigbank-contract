// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Script, console} from "forge-std/Script.sol";
import {Bigbank, Admin} from "../src/Bigbank.sol";

/**
 * @title 交互式脚本
 * @dev 交互式测试脚本，用于单独测试各子功能
 * @notice 该脚本提供了交互式的合约操作功能
 
    // 使用示例：
    // 添加条件执行
    bool testDeposit = vm.envOr("TEST_DEPOSIT", true);
    bool testAdminTransfer = vm.envOr("TEST_ADMIN_TRANSFER", true);
    bool testWithdraw = vm.envOr("TEST_WITHDRAW", true);
    
    if (testDeposit) {
        // 测试存款
    }
    
    if (testAdminTransfer) {
        // 测试管理员转移
    }
    
    if (testWithdraw) {
        // 测试取款
    }
 * 
 * 使用步骤：
 * 1. 先运行 Deploy.sol 部署合约
 * 2. 设置环境变量 BIGBANK_ADDRESS 和 ADMIN_ADDRESS
 * 3. 运行: forge script script/Interactive.sol --rpc-url <RPC_URL> --broadcast
 */
contract InteractiveScript is Script {
    function run() external {
        // 从环境变量获取部署者私钥
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        // 从环境变量读取已部署的合约地址
        address payable bigbankAddress = payable(vm.envAddress("BIGBANK_ADDRESS"));
        address payable adminAddress = payable(vm.envAddress("ADMIN_ADDRESS"));
        
        // 创建合约实例
        Bigbank bigbank = Bigbank(bigbankAddress);
        Admin adminContract = Admin(adminAddress);
        
        console.log(unicode"=== 交互式测试工具 ===");
        console.log(unicode"部署者地址:", deployer);
        console.log(unicode"BigBank 合约地址:", address(bigbank));
        console.log(unicode"Admin 合约地址:", address(adminContract));
        
        // 显示当前状态
        console.log(unicode"=== 当前状态 ===");
        console.log(unicode"BigBank 管理员:", bigbank.getAdmin());
        console.log(unicode"BigBank 余额:", address(bigbank).balance / 1e18, "ETH");
        console.log(unicode"Admin 合约余额:", address(adminContract).balance / 1e18, "ETH");
        console.log(unicode"部署者余额:", deployer.balance / 1e18, "ETH");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // 功能1：测试存款功能
        console.log(unicode"=== 功能1：测试存款 ===");
        console.log(unicode"测试存款 0.5 ETH...");
        bigbank.deposit{value: 0.5 ether}();
        console.log(unicode"存款后 BigBank 余额:", address(bigbank).balance / 1e18, "ETH");
        
        // 功能2：测试管理员转移
        console.log(unicode"=== 功能2：测试管理员转移 ===");
        console.log(unicode"当前管理员:", bigbank.getAdmin());
        console.log(unicode"转移管理员给 Admin 合约...");
        bigbank.transferAdmin(address(adminContract));
        console.log(unicode"转移后管理员:", bigbank.getAdmin());
        
        // 功能3：测试 Admin 合约取款
        console.log(unicode"=== 功能3：测试 Admin 合约取款 ===");
        console.log(unicode"取款前状态:");
        console.log(unicode"  BigBank 余额:", address(bigbank).balance / 1e18, "ETH");
        console.log(unicode"  Admin 合约余额:", address(adminContract).balance / 1e18, "ETH");
        
        console.log(unicode"执行 Admin 合约取款...");
        adminContract.adminWithdraw(bigbank);
        
        console.log(unicode"取款后状态:");
        console.log(unicode"  BigBank 余额:", address(bigbank).balance / 1e18, "ETH");
        console.log(unicode"  Admin 合约余额:", address(adminContract).balance / 1e18, "ETH");
        
        vm.stopBroadcast();
        
        // 功能验证
        console.log(unicode"=== 功能验证 ===");
        bool adminIsManager = bigbank.getAdmin() == address(adminContract);
        bool fundsTransferred = address(adminContract).balance > 0;
        
        console.log(unicode"Admin 合约是否为管理员:", adminIsManager);
        console.log(unicode"资金是否成功转移:", fundsTransferred);
        console.log(unicode"所有功能测试完成:", adminIsManager && fundsTransferred);
        
        console.log(unicode"=== 交互式测试完成 ===");
        console.log(unicode"提示：可以使用 cast 工具进行更多交互操作");
        console.log(unicode"例如：");
        console.log(unicode"  cast call <BIGBANK_ADDRESS> 'getAdmin()' --rpc-url <RPC_URL>");
        console.log(unicode"  cast balance <BIGBANK_ADDRESS> --rpc-url <RPC_URL>");
    }
}
