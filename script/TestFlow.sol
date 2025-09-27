// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Script, console} from "forge-std/Script.sol";
import {Bigbank, Admin} from "../src/Bigbank.sol";

/**
 * @title 测试流程脚本
 * @dev 测试完整流程的脚本
 * @notice 演示完整的业务流程：
 * 1. 转移管理员给 Admin 合约
 * 2. 用户存款
 * 3. Admin 合约取款
 * 
 * 使用步骤：
 * 1. 先运行 Deploy.sol 部署合约
 * 2. 设置环境变量 BIGBANK_ADDRESS 和 ADMIN_ADDRESS
 * 3. 运行: forge script script/TestFlow.sol --rpc-url <RPC_URL> --broadcast
 */
contract TestFlowScript is Script {
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
        
        console.log(unicode"=== 开始测试流程 ===");
        console.log(unicode"部署者地址:", deployer);
        console.log(unicode"BigBank 合约地址:", address(bigbank));
        console.log(unicode"Admin 合约地址:", address(adminContract));
        
        // 显示初始状态
        console.log(unicode"=== 初始状态 ===");
        console.log(unicode"BigBank 当前管理员:", bigbank.getAdmin());
        console.log(unicode"BigBank 当前余额:", address(bigbank).balance / 1e18, "ETH");
        console.log(unicode"Admin 合约当前余额:", address(adminContract).balance / 1e18, "ETH");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // 步骤1：转移管理员给 Admin 合约地址
        console.log(unicode"=== 步骤1：转移管理员 ===");
        console.log(unicode"正在将 BigBank 管理员转移给 Admin 合约...");
        bigbank.transferAdmin(address(adminContract));
        console.log(unicode"管理员转移完成");
        console.log(unicode"新管理员地址:", bigbank.getAdmin());
        console.log(unicode"验证：管理员是否为 Admin 合约地址:", bigbank.getAdmin() == address(adminContract));
        
        // 步骤2：模拟用户存款
        // 测试存款金额限制（> 0.001 ether）
        console.log(unicode"=== 步骤2：用户存款 ===");
        console.log(unicode"用户存款 1 ETH（满足 > 0.001 ETH 的要求）...");
        bigbank.deposit{value: 1 ether}();
        console.log(unicode"存款完成");
        console.log(unicode"BigBank 当前余额:", address(bigbank).balance / 1e18, "ETH");

        // 步骤2.1：测试存款失败（跳过，因为脚本中无法使用 vm.expectRevert）
        console.log(unicode"=== 步骤2.1：存款失败测试 ===");
        console.log(unicode"注意：存款失败测试需要在测试文件中进行，脚本中无法使用 vm.expectRevert");
        
        
        // 步骤3：Admin 合约取款
        console.log(unicode"=== 步骤3：Admin 合约取款 ===");
        console.log(unicode"Admin 合约的 Owner 调用 adminWithdraw...");
        console.log(unicode"取款前 BigBank 余额:", address(bigbank).balance / 1e18, "ETH");
        console.log(unicode"取款前 Admin 合约余额:", address(adminContract).balance / 1e18, "ETH");
        
        // 调用 Admin 合约的取款函数
        adminContract.adminWithdraw(bigbank);
        
        console.log(unicode"取款完成");
        console.log(unicode"取款后 BigBank 余额:", address(bigbank).balance / 1e18, "ETH");
        console.log(unicode"取款后 Admin 合约余额:", address(adminContract).balance / 1e18, "ETH");
        
        vm.stopBroadcast();
        
        // 验证结果
        console.log(unicode"=== 结果验证 ===");
        bool bigbankBalanceZero = address(bigbank).balance == 0;
        bool adminReceivedFunds = address(adminContract).balance == 1 ether;
        
        console.log(unicode"BigBank 余额是否为 0:", bigbankBalanceZero);
        console.log(unicode"Admin 合约是否收到 1 ETH:", adminReceivedFunds);
        console.log(unicode"测试是否通过:", bigbankBalanceZero && adminReceivedFunds);
        
        console.log(unicode"=== 测试流程完成 ===");
        console.log(unicode"所有步骤执行成功！");
    }
}
