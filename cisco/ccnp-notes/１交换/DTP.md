## 一、Cisco 二层控制协议承载机制

### 1. Cisco 私有二层控制协议概述

常见 Cisco 私有二层协议：

- **CDP**：Cisco Discovery Protocol
    
- **VTP**：VLAN Trunking Protocol
    
- **DTP**：Dynamic Trunking Protocol
    
- **PAgP**：Port Aggregation Protocol
    

特点：

- 不运行在 IP / TCP / UDP 之上
    
- 直接封装在二层以太帧中
    
- 排障时若问题与这些协议相关，通常与上层 IP / TCP / UDP / 应用层无关
    

### 2. 二层以太网帧承载协议原理

以太帧类型字段有两种常见形式：

|类型|字段|说明|
|---|---|---|
|Ethernet II|EtherType ≥ 0x0600|直接标识上层协议|
|IEEE 802.3|Length < 1500|后续为 802.2 LLC|

常见 EtherType：

- IPv4：0x0800
    
- IPv6：0x86DD
    
- ARP：0x0806
    

IEEE 802.3 + LLC：

- LLC 字段：DSAP、SSAP、Ctrl
    
- STP BPDU：LLC = 0x42 42 03
    
- SNAP：LLC = 0xAA AA 03
    
- Cisco 私有协议：通过 **LLC/SNAP** 承载
    

### 3. Cisco LLC/SNAP 报文骨架

结构：

text

DMAC + SMAC
Length（非 Type）
802.2 LLC：DSAP、SSAP、Ctrl（常见 0xAA AA 03）
SNAP：OUI + PID
Payload

关键字段：

- **OUI**：组织唯一标识符，Cisco 为 `00-00-0C`
    
- **PID**：协议标识符
    
    - 0x2004：DTP
        
    - 0x2003：VTP
        
    - 0x2000：CDP
        
    - 0x010B：PAgP
        

目的 MAC：

- Cisco 常见组播地址：`01-00-0C-CC-CC-CC`
    
- CDP、VTP、DTP、PAgP 均发往该地址
    

---

## 二、DTP 协议详解

### 1. DTP 基本概念

- 全称：**Dynamic Trunking Protocol**
    
- 属性：Cisco 私有协议
    
- 功能：相邻交换机之间自动协商是否形成 Trunk
    
- 设计初衷：简化配置，通过报文协商接口模式
    
- 协商目标：判断双方是否愿意形成 Trunk
    
- 风险：生产环境若开启自动协商，存在安全风险
    

### 2. DTP 工作前提

- 接口必须为二层接口
    
- Trunk 封装若兼容，采用 **802.1Q**
    
- 需处于相同 VTP 域内
    
- 接口需支持 DTP 模式
    
- 关闭命令：`switchport nonegotiate`
    

> 注意：不能同时处于 Dynamic 状态与 Nonegotiate 状态，需先指定端口模式。

### 3. DTP 报文格式

DTP 无 IETF/RFC 公开标准，可通过 Wireshark 解析。

整体结构：

text

Version
TLV List

TLV = Type-Length-Value，类似字典或 JSON 结构。

常见 TLV：

|TLV|含义|
|---|---|
|0x0001|Domain|
|0x0002|Trunk Status|
|0x0003|Trunk Type|
|0x0004|Sender ID|

### 4. Trunk Status 拆解

Trunk Status 包含：

- 当前状态
    
- 协商意图
    

Administrative Status 取值：

|值|含义|
|---|---|
|On|静态 Trunk，意图为 Trunk|
|Off|非 Trunk，意图不为 Trunk|
|Desirable|主动协商，要求对方配为 Trunk|
|Auto|被动协商，不主动要求对方|

Operating vs Administrative 组合示例：

|Operating|Administrative|含义|
|---|---|---|
|0|3|当前非 Trunk，但意图为 Trunk|
|1|3|当前 Trunk，管理意图 Desirable|
|1|4|当前 Trunk，管理意图 Auto|
|1|1|当前 Trunk，管理意图 On|

### 5. Trunk Type 拆解

Trunk Type 包含：

- Operating Type：当前封装类型
    
- Administratively Type：期望封装类型
    

封装类型值：

- 值 = 5：802.1Q
    
- 模拟器/老式设备默认：ISL
    
- 现代设备：已舍弃 ISL，仅支持 802.1Q
    

### 6. DTP 报文交互过程

前提：

- 接口 Up 后，默认不关闭协商
    
- 生产环境建议：`switchport nonegotiate`
    

流程：

1. 根据 Switch Port 模式生成 DTP 报文
    
2. TLV 构造：Domain、当前状态、管理意图、封装类型、Sender ID
    
3. 接收端解析意图（Desirable / Auto）
    
4. 协商结果：
    
    - 两端意图一致（如 Desirable-Desirable）→ Operational Mode = Trunk
        
    - 意图不一致 → 保持 No Trunk（Access / Nonegotiate）
        
    - Auto-Auto：通常不会形成 Trunk
        
    - Access 端口：不受影响，不会变化
        

### 7. 抓包中如何识别 DTP

过滤条件示例：

text

dtp.version == 1

- Version = 1：常见值
    
- Version = 2：已废弃
    

可扩展至其他协议，用于过滤特定字段信息。

---

## 三、DTP 协商结果表

|本端模式|对端模式|协商结果|说明|
|---|---|---|---|
|Access|Access|Access|两端均为 Access，无 Trunk|
|Access|Trunk|协商失败|一端 Access，一端 Trunk，无法协商|
|Access|Dynamic Auto|协商失败|Access 无法主动发起 Trunk 协商|
|Access|Dynamic Desirable|协商失败|Desirable 主动协商，但 Access 拒绝|
|Trunk|Trunk|Trunk|两端均为 Trunk，直接成功|
|Trunk|Dynamic Desirable|Trunk|一端 Trunk，一端 Desirable，成功|
|Trunk|Dynamic Auto|Trunk|一端 Trunk，一端 Auto，成功|
|Dynamic Desirable|Dynamic Desirable|Trunk|两端均主动协商，成功|
|Dynamic Desirable|Dynamic Auto|Trunk|Desirable 主动，Auto 被动，成功|
|Dynamic Auto|Dynamic Auto|Access|两端均被动，无主动方，协商失败|

---

## 四、VLAN Hopping 与 DTP 攻击

### 1. 攻击类型一：DTP 协商攻击

原理：

- 攻击者接入 Access 端口
    
- 发送 DTP Desirable 帧
    
- 强制交换机协商为 Trunk
    
- 攻击者可跳跃至其他 VLAN
    

后果：

- Trunk 默认 allow all VLANs
    
- 攻击者可构造特定 VLAN ID 报文进行横向移动
    
- 绕过 VLAN 隔离机制
    

### 2. 攻击类型二：双层标签攻击（Double Tagging）

利用点：

- Native VLAN 不打标签的特性
    

构造：

- 外层标签 = Native VLAN（如 99）
    
- 内层标签 = 目标 VLAN（如 10）
    

转发过程：

1. 交换机收到后，因外层标签为 Native VLAN，剥掉外层标签
    
2. 内层标签暴露
    
3. 报文被转发至目标 VLAN
    

前提：

- 外层 Native VLAN 在 Trunk 的 Allowed 列表中
    

危害：

- 可实现小型 DoS 攻击
    
- 可对网络进行内部探测
    
- 危险性存在，但并非极大
    

### 3. 攻击条件总结

- 接口未强制为 Access，处于 Dynamic Auto 状态
    
- 交换机仍接受 DTP 协商
    
- Trunk Allowed VLAN 范围过大
    
- Native VLAN / VLAN 1 使用不当
    

---

## 五、VLAN Hopping 防护

### 1. 防护措施

- 修改 Native VLAN：将 Native VLAN 从默认的 VLAN 1 修改为其他未使用的 VLAN ID
    
- 关闭 DTP 协商：在接口上明确配置 Trunk 或 Access 模式，并禁用 DTP
    
- 在接入用户端口配置：`switchport nonegotiate`
    
- 确定接口模式后，必须关闭 DTP，并确保对端也进行相应配置
    

### 2. 配置示例

bash

interface e0/0
 switchport trunk encapsulation dot1q
 switchport mode trunk
 switchport trunk native vlan [ID]
 switchport nonegotiate

验证：

bash

show run interface e0/0

### 3. 排障验证

查看接口状态：

bash

show interface e0/0

确认 MAC 地址及 DTP 协商状态。

DTP 报文分析：

- 源 MAC 地址：如 ABC-04
    
- Value 值：0x0xA5 表示对端尝试协商为 802.1Q Trunk
    

防护效果：

- 若本端已关闭 DTP 协商，对端发起的协商请求将被忽略
    
- 从而阻断 VLAN Hopping 攻击
    

---

## 六、为什么生产环境通常关闭 DTP

安全风险：

- 若开启 DTP，攻击者可通过发送 DTP 帧，协商对端接口变为 Trunk 模式
    
- 从而实施 VLAN Hopping 攻击
    

生产环境建议：

- 必须关闭 DTP
    
- 手动指定接口模式（Access 或 Trunk）
    
- 杜绝协商带来的安全隐患
    

最佳实践：

- 两端均配置 DTP 关闭
    
- 明确指定 Trunk 或 Access 模式
    
- 避免因协商不一致导致安全风险
    

---

## 七、排障命令汇总

|命令|作用|
|---|---|
|`show interface trunk`|查看当前所有 Trunk 链路及状态|
|`show interface [接口] switchport`|查看接口模式、Native VLAN 等配置|
|`show interface [接口] counters`|查看 DTP 等协议报文收发数量|
|`show run interface [接口]`|确认接口配置生效|
|`show interface [接口]`|查看接口状态、MAC 地址、DTP 协商状态|

抓包过滤：

text

dtp
dtp.version == 1

---

## 八、CCNP 考点速记

1. **DTP 是 Cisco 私有协议**，用于动态协商 Trunk。
    
2. **DTP 封装在 LLC/SNAP 中**，OUI = `00-00-0C`，PID = `0x2004`。
    
3. **目的 MAC = `01-00-0C-CC-CC-CC`**。
    
4. **DTP 报文结构 = Version + TLV**。
    
5. **Trunk Status = 当前状态 + 管理意图**。
    
6. **Administrative Status：On / Off / Desirable / Auto**。
    
7. **Auto-Auto 不会形成 Trunk**。
    
8. **Desirable-Desirable 形成 Trunk**。
    
9. **Trunk-Auto / Trunk-Desirable 形成 Trunk**。
    
10. **Access 与任何模式都不会形成 Trunk**。
    
11. **生产环境建议关闭 DTP：`switchport nonegotiate`**。
    
12. **VLAN Hopping 两种方式：DTP 协商攻击、双层标签攻击**。
    
13. **防护：修改 Native VLAN、关闭 DTP、明确接口模式、限制 Allowed VLAN**。
    
14. **不能同时处于 Dynamic 状态与 Nonegotiate 状态**。
    
15. **排障常用：`show interface trunk`、`show interface switchport`、`show interface counters`**。
    

---

## 九、建议补充的 CCNP 相关知识点

1. **Native VLAN 安全**：Native VLAN 应改为未使用 VLAN，且两端一致。
    
2. **Allowed VLAN 限制**：Trunk 上只允许必要的 VLAN。
    
3. **VLAN 1 安全**：避免将业务 VLAN 放在 VLAN 1。
    
4. **BPDU Guard / Root Guard**：与二层安全结合复习。
    
5. **Port Security**：接入端口安全加固。
    
6. **802.1Q 封装**：现代设备只支持 dot1q，ISL 已淘汰。
    
7. **VTP 风险**：VTP 域和模式配置不当可能导致 VLAN 数据库被篡改。