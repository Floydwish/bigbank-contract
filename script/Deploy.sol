// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Script, console} from "forge-std/Script.sol";
import {Bigbank, Admin} from "../src/Bigbank.sol";

/**
 * @title 部署脚本
 * @dev 部署 BigBank 和 Admin 合约的脚本
 * @notice 这个脚本用于在本地或测试网络上部署合约
 * 
 * 使用步骤：
 * 1. 设置环境变量 PRIVATE_KEY
 * 2. 运行: forge script script/Deploy.sol --rpc-url <RPC_URL> --broadcast
 */
contract Deploy is Script {
    function run() public {
        // 从环境变量获取部署者私钥
        // 环境变量中的 PRIVATE_KEY 来自 anvil 的 1 号账户
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log(unicode"=========== 开始部署合约 ===========");
        console.log(unicode"部署者地址:", deployer);
        console.log(unicode"部署者余额:", deployer.balance / 1e18, "ETH");
        
        // 开始广播交易
        vm.startBroadcast(deployerPrivateKey);
        
        // 步骤1：部署 BigBank 合约
        // BigBank 继承自 Bank，具有存款、取款、管理员转移等功能
        console.log(unicode"正在部署 BigBank 合约...");
        Bigbank bigbank = new Bigbank();
        console.log(unicode"BigBank 部署成功，地址:", address(bigbank));
        
        // 步骤2：部署 Admin 合约
        // Admin 合约用于管理 BigBank 的资金提取
        console.log(unicode"正在部署 Admin 合约...");
        Admin adminContract = new Admin();
        console.log(unicode"Admin 部署成功，地址:", address(adminContract));
        
        // 停止广播交易
        vm.stopBroadcast();
        
        // 输出部署结果和初始状态
        console.log(unicode"=== 部署完成 ===");
        console.log(unicode"BigBank 合约地址:", address(bigbank));
        console.log(unicode"Admin 合约地址:", address(adminContract));
        console.log(unicode"BigBank 初始管理员:", bigbank.getAdmin());
        console.log(unicode"Admin 合约初始余额:", address(adminContract).balance / 1e18, "ETH");
        
        // 下一步操作
        console.log(unicode"=== 下一步操作 ===");
        console.log(unicode"1. 将合约地址保存到 .env 文件中");
        console.log(unicode"2. 运行测试流程脚本");
        console.log(unicode"3. 或使用 cast 工具进行交互");
    }
}