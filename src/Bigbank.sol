// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/*
在 Bank 合约基础之上，编写 IBank 接口及 BigBank 合约，
使其满足 Bank 实现 IBank， BigBank 继承自 Bank ， 同时 BigBank 有附加要求：

1.要求存款金额 >0.001 ether（用modifier权限控制）

2.BigBank 合约支持转移管理员

3.编写一个 Admin 合约， Admin 合约有自己的 Owner ，同时有一个取款函数 adminWithdraw(IBank bank) , 
adminWithdraw 中会调用 IBank 接口的 withdraw 方法从而把 bank 合约内的资金转移到 Admin 合约地址。

4.BigBank 和 Admin 合约 部署后，把 BigBank 的管理员转移给 Admin 合约地址，模拟几个用户的存款，
然后Admin 合约的Owner地址调用 adminWithdraw(IBank bank) 把 BigBank 的资金转移到 Admin 地址。
*/

interface IBank{
    function withdraw(uint256 _amount) external;
}

contract Bank is IBank {
    address private owner;              // 合约所有者地址

    // 取消总存款金额的记录，原因：
    // 1.数据可能不准确（可能存在节点转入金额的情况，但不会被这个值记录，造成数据不一致）
    // 2.节省 gas (这个值可以通过 内置函数 balance 获取)
    // 3.增加了代码复杂性（代码中多处需要更新这个值）
    //uint256 public totalDeposits;       // 总存款金额

    bool private reentrant;             // 重入锁变量

    //mapping 类型变量，用于存储每个地址对应的余额
    mapping(address => uint256)  public balances;

    // 数组，用于记录存款金额的前3名用户
    address[3] public top3Depositors;

    // 函数修饰器：仅owner可以调用
    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner");
        _;
    }

    // 函数修饰器：防止重入攻击
    modifier reentrantGuard(){
        require(!reentrant, "Reentrant call detected");
        reentrant = true;
        _;
        reentrant = false;
    }

    // 构造函数，设置合约所有者
    constructor(){
        owner = msg.sender; // 设置合约所有者为部署者
    }

    // 内部存款函数，用于处理存款逻辑
    function _deposit() internal {
        require(msg.value > 0, "Deposit amount must greater than 0");

        // 将发送者地址和金额存入mapping
        balances[msg.sender] += msg.value;

        // 更新Top3 用户
        updateTop3Depositors();
    }

    // 存款函数，用于存储资金到 Bank 合约地址
    // payable 关键字，表示合约可以接收 ETH
    function deposit() public payable virtual{
        _deposit();
    }

    // 收款函数
    // payable 关键字，表示合约可以接收 ETH
    receive() external payable {
        _deposit(); 
    }

    // 取款函数，用于从合约地址提取资金
   /*
    1. 防重入的必要性
      a. 当前版本的 bank 合约从技术上不用防重入（只有 owner 可以调用，且有少量 gas 开销）
      b. 但是遵循最佳安全实践，任何涉及外部 ETH 发送的函数都应该有 防重入 保护。（因为：1.实际开发中后续可能添加功能，导致暴露在重入攻击下；2.代码审查友好；3.成本低）

    2. 重入攻击的原理
    // ❌ 有漏洞
    function withdraw() public {
        // 1. 检查余额
        require(balance[msg.sender] > 0);  

        // 2. 发送资金
        // 此时，恶意合约可以在 fallback 中再次调用 withdraw, 导致重入（第1步的余额还未更新）
        (bool success,) = msg.sender.call{value: balance[msg.sender]}("");
        require(success);

        // 3. 更新余额
        balance[msg.sender] = 0;
    }

    3. 防重入攻击的原理
    // ✅ 修复后
    // 机制：Check-Effects-Interactions 模式
    function withdraw() public {
        // 1. 检查余额
        require(balance[msg.sender] > 0);

        // 2. 更新余额
        balance[msg.sender] = 0;

        // 3. 发送资金
        // 此时，恶意合约无法在 fallback 中再次调用 withdraw, 因为第2步的余额已经更新(如果重入，将通不过第 1 步的检查)
        (bool success,) = msg.sender.call{value: amount}("");
        require(success);
    }

    4. 防重入的实际使用（同时使用 a, b 两种方式)
     a. 防护方法1：先更新状态，再转账 (机制：Check-Effects-Interactions 模式)
     b. 防护方法2：使用 ReentrancyGuard 修饰器（ OpenZeppelin 库中有）

    */  
    function withdraw(uint256 _amount) public virtual onlyOwner reentrantGuard{
        // 1. 检查合约总存款金额是否足够
        require(address(this).balance >= _amount, "Insufficient balance");

        // 2.将资金发送给所有者
        (bool success, ) = owner.call{value: _amount}("");
        require(success, "Withdraw failed");

    }

    // 更新Top3 用户
    function updateTop3Depositors() internal{
        // 1. 获取当前存款用户的地址和金额
        address currentUser = msg.sender;
        uint256 currentBalance = balances[currentUser]; // 这里不用msg.value, 因为这是本次的存款金额，实际可能累计多次

        // 2. 检查是否已经有空位，如果有直接放入
        for(uint i = 0; i < top3Depositors.length; i++){
            if(top3Depositors[i] == address(0)){
                top3Depositors[i] = currentUser;
                return;
            }
        }

        // 3. 如果没有空位，找到Top3 中余额最低用户及其index
        uint256 minBalance = balances[top3Depositors[0]];
        uint minIndex = 0;

        for(uint i = 1; i < top3Depositors.length; i++ ){
            if(balances[top3Depositors[i]] < minBalance){
                minBalance = balances[top3Depositors[i]];
                minIndex = i;
            }
        }

        // 4. 如果当前用户比 Top3 最低的要高，就替换
        if(currentBalance > minBalance){
            top3Depositors[minIndex] = currentUser; 
        }

        // 5. 按照从高到低排序
        for(uint i = 0; i < top3Depositors.length -1; i++){
            for(uint j = i + 1; j < top3Depositors.length; j++)
            {
                if(balances[top3Depositors[i]] < balances[top3Depositors[j]]){
                    address tmp = top3Depositors[i];
                    top3Depositors[i] = top3Depositors[j];
                    top3Depositors[j] = tmp;
                }
            }
        }

        /*
        要点：
        • 理解合约作为一个账号、也可以持有资产
        • msg.value / 如何传递 Value
        • 回调函数的理解(receive/fallback)
        • Payable 关键字理解
        • Mapping 、数组使用

        常见问题：
        • 不用保存 total balance
        • 不用同时保存 address[3] 和 uint[3] (复用mapping的数据)
        • 不需要保存所有的数组数据
        • 排序代码复用 (在 receive 及 deposit 中)
        • 排序代码放 View 函数可以么?
        */
    }

    function transferOwner(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }

}


contract Bigbank is Bank{
    address public admin;

    constructor() {
        admin = msg.sender;
    }

    modifier minDeposit() {
        require(msg.value > 0.001 ether, "Deposit amount must greater than 0.001 ether");
        _;
    }

    // 检查管理员地址是否有效
    modifier validAdmin(address _admin) {
        require(_admin != address(0), "Invalid admin");
        _;
    }

    // 仅管理员
    modifier onlyAdmin() {
        require(msg.sender == admin, "You are not the admin");
        _;
    }
    
    // 重写 bank 的 deposit 函数，添加最小存款金额限制
    function deposit() public payable override minDeposit{
        super.deposit(); // 调用父合约的 deposit
    }

    // 转移管理员
    // 检查：1.管理员地址有效；2.只有原管理员可以转移
    function transferAdmin(address _newAdmin) public validAdmin(_newAdmin) onlyOwner {
        admin = _newAdmin;
    }

    // 获取管理员地址
    function getAdmin() public view returns (address) {
        return admin;
    }

    // 重写 bank 的 withdraw 函数，添加管理员权限限制
    function withdraw(uint256 _amount) public override onlyAdmin 
    {
        // 1. 检查合约总存款金额是否足够
        require(address(this).balance >= _amount, "Insufficient balance");

        // 2.将资金发送给所有者
        (bool success, ) = admin.call{value: _amount}("");
        require(success, "Withdraw failed");
    }


}

contract Admin {
    address private owner;

    constructor() {
        owner = msg.sender;
    }

    function adminWithdraw(IBank bank) external {
        bank.withdraw(address(bank).balance);
    }

    receive() external payable {}
}

