# 本地部署及测试指南

本指南详细说明如何使用 Foundry 在本地部署和测试 BigBank 合约系统。

## 项目结构

```
2.2/
├── src/
│   └── Bigbank.sol          # 合约源码
├── script/
│   ├── Deploy.sol           # 部署脚本
│   ├── TestFlow.sol         # 测试流程脚本
│   └── Interactive.sol      # 交互式测试脚本
├── test/
│   └── Bigbank.t.sol        # 单元测试
├── env.example              # 环境变量示例
└── README_DEPLOY.md         # 本文件
```

## 环境准备

### 1. 安装 Foundry

```bash
# 安装 Foundry
curl -L https://foundry.paradigm.xyz | bash
foundryup

# 验证安装
forge --version
cast --version
anvil --version
```

### 2. 配置环境变量

```bash
# 复制环境变量示例文件
cp env.example .env

# 编辑 .env 文件，填入你的私钥
# 注意：请使用测试私钥，不要使用主网私钥
```

## 部署流程

### 步骤1：启动本地网络

```bash
# 启动 Anvil（本地测试网络）
anvil

# 输出示例：
# Available Accounts
# ==================
# (0) 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 (10000.0 ETH)
# (1) 0x70997970C51812dc3A010C7d01b50e0d17dc79C8 (10000.0 ETH)
# ...

# 复制第一个账户的私钥到 .env 文件
```

### 步骤2：部署合约

```bash
# 部署到本地网络
forge script script/Deploy.sol --rpc-url http://localhost:8545 --broadcast

# 输出示例：
# === 开始部署合约 ===
# 部署者地址: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
# 部署者余额: 10000 ETH
# 正在部署 BigBank 合约...
# BigBank 部署成功，地址: 0x5FbDB2315678afecb367f032d93F642f64180aa3
# 正在部署 Admin 合约...
# Admin 部署成功，地址: 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
# === 部署完成 ===
```

### 步骤3：更新环境变量

将部署输出的合约地址添加到 `.env` 文件中：

```bash
BIGBANK_ADDRESS=0x5FbDB2315678afecb367f032d93F642f64180aa3
ADMIN_ADDRESS=0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
```

## 测试流程

### 方法1：运行完整测试流程

```bash
# 运行测试流程脚本
forge script script/TestFlow.sol --rpc-url http://localhost:8545 --broadcast

# 输出示例：
# === 开始测试流程 ===
# 步骤1：转移管理员
# 正在将 BigBank 管理员转移给 Admin 合约...
# 管理员转移完成
# 新管理员地址: 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
# 步骤2：用户存款
# 用户存款 1 ETH（满足 > 0.001 ETH 的要求）...
# 存款完成
# BigBank 当前余额: 1 ETH
# 步骤3：Admin 合约取款
# Admin 合约的 Owner 调用 adminWithdraw...
# 取款完成
# 取款后 BigBank 余额: 0 ETH
# 取款后 Admin 合约余额: 1 ETH
# === 结果验证 ===
# 测试是否通过: true
```

### 方法2：运行交互式测试

```bash
# 运行交互式测试脚本
forge script script/Interactive.sol --rpc-url http://localhost:8545 --broadcast
```

### 方法3：使用 cast 工具

```bash
# 查看 BigBank 管理员
cast call $BIGBANK_ADDRESS "getAdmin()" --rpc-url http://localhost:8545

# 查看 BigBank 余额
cast balance $BIGBANK_ADDRESS --rpc-url http://localhost:8545

# 查看 Admin 合约余额
cast balance $ADMIN_ADDRESS --rpc-url http://localhost:8545

# 发送存款交易
cast send $BIGBANK_ADDRESS "deposit()" --value 1ether --private-key $PRIVATE_KEY --rpc-url http://localhost:8545
```

## 单元测试

```bash
# 运行所有单元测试
forge test

# 运行特定测试
forge test --match-test test_transfer_admin_withdraw_success

# 显示详细输出
forge test -vvv

# 显示 gas 报告
forge test --gas-report
```

## 部署到测试网络

### 部署到 Sepolia 测试网

```bash
# 1. 获取测试 ETH
# 访问 https://sepoliafaucet.com/ 获取测试 ETH

# 2. 更新 .env 文件
RPC_URL=https://sepolia.infura.io/v3/YOUR_PROJECT_ID
ETHERSCAN_API_KEY=YOUR_ETHERSCAN_API_KEY

# 3. 部署合约
forge script script/Deploy.sol --rpc-url $RPC_URL --broadcast --verify

# 4. 运行测试流程
forge script script/TestFlow.sol --rpc-url $RPC_URL --broadcast
```

## 故障排除

### 常见问题

1. **私钥错误**
   ```
   错误: Invalid private key
   解决: 检查 .env 文件中的 PRIVATE_KEY 格式
   ```

2. **余额不足**
   ```
   错误: Insufficient funds
   解决: 确保账户有足够的 ETH 支付 gas 费用
   ```

3. **合约地址错误**
   ```
   错误: Contract not found
   解决: 检查 .env 文件中的合约地址是否正确
   ```

4. **网络连接问题**
   ```
   错误: Connection refused
   解决: 确保 Anvil 正在运行，或检查 RPC_URL 是否正确
   ```

### 调试技巧

1. **使用详细输出**
   ```bash
   forge script script/Deploy.sol --rpc-url http://localhost:8545 --broadcast -vvv
   ```

2. **检查交易状态**
   ```bash
   cast tx <TX_HASH> --rpc-url http://localhost:8545
   ```

3. **查看合约状态**
   ```bash
   cast call <CONTRACT_ADDRESS> "functionName()" --rpc-url http://localhost:8545
   ```

## 安全注意事项

1. **私钥安全**
   - 永远不要将私钥提交到版本控制系统
   - 使用测试私钥，不要使用主网私钥
   - 考虑使用硬件钱包或密钥管理服务

2. **网络安全**
   - 在生产环境中使用 HTTPS RPC 端点
   - 验证合约地址的正确性
   - 使用多重签名钱包进行重要操作

3. **代码审计**
   - 在生产部署前进行代码审计
   - 使用形式化验证工具
   - 进行充分的测试

## 总结

通过以上步骤，你可以成功在本地部署和测试 BigBank 合约系统。这个流程涵盖了：

1. ✅ 合约部署
2. ✅ 管理员转移
3. ✅ 用户存款
4. ✅ Admin 合约取款
5. ✅ 资金流向验证

所有功能都符合要求，可以正常运行。
