# BigBank 智能合约

一个基于 Solidity 的 bank 智能合约，支持存款、取款和管理员转移功能。

## 功能特性

- **存款功能**：支持 ETH 存款，最小金额 0.001 ETH
- **取款功能**：管理员权限控制，支持资金提取
- **管理员转移**：支持将管理员权限转移给其他地址
- **Top3 存款者**：自动记录存款金额前 3 名用户
- **重入攻击防护**：内置重入攻击保护机制

## 合约结构

- `Bank`：基础银行合约，实现 IBank 接口
- `Bigbank`：扩展银行合约，增加管理员功能
- `Admin`：管理员合约，用于管理资金提取

## 快速开始

### 环境要求

- Foundry
- Solidity ^0.8.17

### 安装依赖

```bash
git clone https://github.com/Floydwish/bigbank-contract.git
cd bigbank-contract
forge install
```

### 编译合约

```bash
forge build
```

### 运行测试

```bash
forge test
```

### 部署合约

```bash
# 启动本地节点
anvil

# 部署合约
forge script script/Deploy.sol --rpc-url http://127.0.0.1:8545 --broadcast
```

### 运行测试流程

```bash
# 设置环境变量
export BIGBANK_ADDRESS=<合约地址>
export ADMIN_ADDRESS=<管理员合约地址>
export PRIVATE_KEY=<私钥>

# 运行测试流程
forge script script/TestFlow.sol --rpc-url http://127.0.0.1:8545 --broadcast
```

## 使用说明

1. **部署合约**：使用 `Deploy.sol` 脚本部署 BigBank 和 Admin 合约
2. **转移管理员**：将 BigBank 的管理员权限转移给 Admin 合约
3. **用户存款**：用户可以向 BigBank 合约存款（> 0.001 ETH）
4. **管理员取款**：Admin 合约的拥有者可以提取 BigBank 中的资金

## 许可证

MIT
