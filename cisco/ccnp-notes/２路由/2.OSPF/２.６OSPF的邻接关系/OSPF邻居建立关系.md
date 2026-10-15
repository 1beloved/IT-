# 一、OSPF 邻居及邻接关系建立过程

## 1. 邻接建立前的网络模型

### 【邻接建立分类】

核心依据：**网络类型**

主要分为：

- 点到点（Point-to-Point）
    
- 广播（Broadcast）
    
- NBMA
    
- Point-to-Multipoint
    

---

## 1.1 点到点网络

### 【核心特点】

- 不选举 DR/BDR
    
- 状态快速演进：
    

**Down → Init → 2-Way → ExStart → Exchange → Loading → Full**

- 邻居发现：通过组播地址 **224.0.0.5** 自动发现
    
- 建立邻接：不依赖 DR/BDR，直接尝试形成 Full
    
- 不产生 Type 2 Network LSA
    
- 适用场景：
    
    - 串行链路
        
    - Tunnel
        
    - 两台路由器直连的以太网
        

### 【常见配置】

```cisco
ip ospf network point-to-point
```

---

### 【实验模型】

#### R1

- Loopback0：1.1.1.1/32
    
- E0/0：192.168.1.1/24
    
- OSPF 1
    
- Router-ID：1.1.1.1
    
- Area 0
    
- 接口配置：
    

```cisco
ip ospf network point-to-point
```

#### R2

- Loopback0：2.2.2.2/32
    
- E0/0：192.168.1.2/24
    
- OSPF 1
    
- Router-ID：2.2.2.2
    
- Area 0
    
- 接口配置：
    

```cisco
ip ospf network point-to-point
```

### 【结果】

- 状态快速达到 **Full**
    
- `show ip ospf neighbor` 中没有 DR/BDR 字段
    
- DR/BDR 显示为 `-`
    

---

## 1.2 点到点网络的建邻核心特征

- 无 DR/BDR 选举
    
- Hello 报文中的 DR/BDR 字段为 `0.0.0.0`
    
- Active Neighbor 直接显示对端 Router-ID
    
- 无需等待 DR/BDR 选举
    
- 邻居可以直接进入后续的 ExStart → Exchange → Loading → Full
    

### 【考试重点】

点到点网络：

> **No DR/BDR election**

> **No Type 2 Network LSA**

---

# 2. 广播网络的建邻模型

## 2.1 为什么需要 DR/BDR？

假设广播网络中有 N 台路由器。

如果每台路由器都和其他所有路由器建立 Full 邻接：

N(N−1)2\frac{N(N-1)}{2}

例如：

- 4 台路由器 → 6 条 Full 邻接
    
- 5 台路由器 → 10 条 Full 邻接
    
- 10 台路由器 → 45 条 Full 邻接
    

随着路由器数量增加，邻接关系会快速增加。

### 【问题】

- 邻接关系数量增加
    
- DD/LSR/LSU/LSAck 交互增加
    
- LSA 泛洪开销增加
    
- LSDB 同步压力增加
    

---

## 2.2 DR/BDR 解决方案

OSPF 引入：

- **DR（Designated Router）**
    
- **BDR（Backup Designated Router）**
    
- **DROther**
    

### 【邻接关系】

|路由器角色|与 DR|与 BDR|与其他 DROther|
|---|---|---|---|
|DR|-|Full|Full|
|BDR|Full|-|Full|
|DROther|Full|Full|2-Way|

### 【核心思想】

- DR/BDR 与所有路由器建立 Full
    
- DROther 之间只保持 2-Way
    
- DROther 不需要彼此进行完整 LSDB 同步
    

这样可以大幅减少邻接关系和 LSA 泛洪开销。

---

# 3. DR/BDR 的工作机制

### DR

主要作用：

- 与所有 OSPF 路由器建立 Full 邻接
    
- 负责产生 **Type 2 Network LSA**
    
- 作为广播网络中的中心节点进行 LSA 泛洪
    

### BDR

主要作用：

- 与所有 OSPF 路由器建立 Full 邻接
    
- 监控 DR
    
- DR 失效后立即接替 DR
    
- 然后重新选举新的 BDR
    

### DROther

- 与 DR 建立 Full
    
- 与 BDR 建立 Full
    
- 与其他 DROther 保持 2-Way
    

---

# 4. OSPF 组播地址

## 224.0.0.5

**AllSPFRouters**

所有运行 OSPF 的路由器监听。

主要用于：

- Hello
    
- DR/BDR 向所有 OSPF 路由器发送 OSPF 报文
    

---

## 224.0.0.6

**AllDRouters**

只有 DR 和 BDR 监听。

主要用于：

- DROther → DR/BDR
    

例如：

> DROther 发现新的 LSA，需要发送给 DR/BDR 时，可以使用 224.0.0.6。

然后 DR 再负责向所有 OSPF 路由器泛洪。

---

# 5. DR/BDR 选举原则

## 5.1 第一优先级：接口 Priority

默认：

```text
Priority = 1
```

比较规则：

> **数值越大越优先**

例如：

```text
R1 = 1
R2 = 100
R3 = 50
```

那么：

```text
R2 > R3 > R1
```

### Priority = 0

如果：

```cisco
ip ospf priority 0
```

表示：

> **该接口不参与 DR/BDR 选举**

它只能成为 DROther。

---

## 5.2 第二优先级：Router ID

如果接口 Priority 相同：

> 比较 Router ID

**Router ID 越大越优先。**

例如：

```text
R1 Router-ID = 1.1.1.1
R2 Router-ID = 2.2.2.2
R3 Router-ID = 3.3.3.3
```

那么：

```text
R3 > R2 > R1
```

---

## 5.3 DR/BDR 选举顺序

考试中记住：

> **先选 BDR，再选 DR**

---

## 5.4 DR/BDR 没有抢占机制

这是非常重要的考试点。

例如：

当前：

```text
R1 = DR
R2 = BDR
R3 = DROther
```

此时把 R3 的 Priority 从：

```text
1 → 255
```

R3 **不会抢走现有 DR/BDR 的角色**。

原因：

> OSPF DR/BDR election is non-preemptive.

只有当 DR/BDR 发生故障并重新触发选举时，R3 才有机会成为 DR/BDR。

---

# 6. DR/BDR 故障后的角色变化

假设：

```text
R1 = DR
R2 = BDR
R3 = DROther
R4 = DROther
```

如果 R1 发生故障：

### 第一步

R2：

```text
BDR → DR
```

### 第二步

在剩余 DROther 中重新选举新的 BDR。

例如：

```text
R3 Priority = 100
R4 Priority = 50
```

那么：

```text
R3 → BDR
```

---

# 7. 修改 OSPF 接口 Priority

进入接口：

```cisco
interface e0/0
ip ospf priority 100
```

查看：

```cisco
show ip ospf interface
```

查看邻居：

```cisco
show ip ospf neighbor
```

---

# 8. 如何触发重新选举？

OSPF DR/BDR 不支持抢占。

实验中如果想让新的 Priority 立即生效，可以重置 OSPF 进程：

```cisco
clear ip ospf process
```

然后重新建立邻居并进行 DR/BDR 选举。

---

# 二、OSPF 邻居状态与邻接关系

## 1. 邻居 ≠ 邻接

这是 OSPF 中非常重要的概念。

### Neighbor

表示：

> 两台路由器通过 Hello 报文发现了彼此。

### Adjacency

表示：

> 两台路由器进一步完成 LSDB 同步，最终达到 Full。

所以：

> **所有邻接关系都是邻居关系，但所有邻居关系不一定都是 Full 邻接。**

最典型的就是：

```text
DROther ↔ DROther
```

状态保持：

```text
2-Way
```

---

# 2. OSPF 邻居状态机

完整过程：

```text
Down
 ↓
Init
 ↓
2-Way
 ↓
ExStart
 ↓
Exchange
 ↓
Loading
 ↓
Full
```

NBMA 还有特殊状态：

```text
Attempt
```

---

## 2.1 Down

初始状态。

表示：

> 没有收到对方的有效 Hello。

---

## 2.2 Init

收到对方 Hello。

但是：

> 对方的 Hello 中还没有看到自己的 Router-ID。

说明通信还是：

> 单向可见。

---

## 2.3 2-Way

双方 Hello 中都已经看到对方 Router-ID。

说明：

> 双向通信已经建立。

在广播网络中：

> **2-Way 阶段会进行 DR/BDR 选举以及邻接关系判断。**

---

# 3. 2-Way 后发生什么？

### 点到点网络

直接继续：

```text
2-Way
 ↓
ExStart
 ↓
Exchange
 ↓
Loading
 ↓
Full
```

最终形成 Full 邻接。

---

### 广播网络

首先判断双方角色。

如果：

```text
DR / BDR
```

则继续建立 Full。

如果：

```text
DROther ↔ DROther
```

则保持：

```text
2-Way
```

这是**正常状态**，不是故障。

---

# 4. ExStart

主要作用：

> **协商 DD 报文的主从关系以及 DD Sequence Number。**

涉及：

- Master
    
- Slave
    
- DD Sequence Number
    
- I bit
    
- M bit
    
- MS bit
    

---

# 5. Exchange

主要作用：

> **交换 LSDB 的摘要信息。**

通过：

**DD（Database Description）**

报文交换 LSA 摘要。

注意：

> DD 中主要是 LSA 的摘要信息，不是完整 LSA。

---

# 6. Loading

如果发现：

> 自己缺少某些 LSA。

就通过：

### LSR

**Link State Request**

请求缺失的 LSA。

然后对方通过：

### LSU

**Link State Update**

发送完整的 LSA。

最后通过：

### LSAck

**Link State Acknowledgment**

确认收到 LSA。

所以：

```text
LSR  → 请求
LSU  → 发送
LSAck → 确认
```

---

# 7. Full

表示：

> 双方 LSDB 已经完成同步。

此时：

```text
Neighbor State = FULL
```

说明：

> 邻接关系已经建立。

之后主要通过 Hello 报文维持邻居关系，并在发生拓扑变化时进行 LSA 更新。

---

# 三、点到点网络完整建邻过程

假设：

```text
R1 ---------------- R2
      Point-to-Point
```

---

## 第一步：Hello

R1 和 R2 都向：

```text
224.0.0.5
```

发送 Hello。

---

## 第二步：发现邻居

R1 收到 R2 的 Hello。

R2 收到 R1 的 Hello。

进入：

```text
Init
```

然后确认双方都看到了对方。

进入：

```text
2-Way
```

---

## 第三步：跳过 DR/BDR

因为是：

```text
Point-to-Point
```

所以：

> 不进行 DR/BDR 选举。

直接进入：

```text
ExStart
```

---

## 第四步：ExStart

通过 DD 报文：

- 协商 Master/Slave
    
- 协商 DD Sequence Number
    

---

## 第五步：Exchange

双方使用 DD：

> 交换 LSA 摘要。

---

## 第六步：Loading

如果发现缺少 LSA：

```text
LSR
 ↓
LSU
 ↓
LSAck
```

完成 LSA 同步。

---

## 第七步：Full

最终：

```text
R1 ←→ R2
      Full
```

LSDB 同步完成。

---

# 四、广播网络完整建邻过程

假设：

```text
        R1
       /  \
      /    \
    R2------R3
```

这是一个广播网络。

---

## 第一步：Hello

所有路由器向：

```text
224.0.0.5
```

发送 Hello。

Hello 中包含：

- Router ID
    
- Hello Interval
    
- Dead Interval
    
- Area ID
    
- Authentication
    
- DR
    
- BDR
    
- Priority
    
- Neighbor List
    

---

## 第二步：Init

收到其他路由器的 Hello。

进入：

```text
Init
```

---

## 第三步：2-Way

双方 Hello 中都出现了对方 Router-ID。

进入：

```text
2-Way
```

---

## 第四步：DR/BDR 选举

根据：

### 第一比较项

```text
OSPF Priority
```

越大越优。

### 第二比较项

```text
Router ID
```

越大越优。

---

## 第五步：判断是否建立 Full

### DR ↔ DROther

```text
Full
```

### BDR ↔ DROther

```text
Full
```

### DR ↔ BDR

```text
Full
```

### DROther ↔ DROther

```text
2-Way
```

---

# 五、OSPF 广播网络中的 LSA 泛洪

典型过程：

```text
DROther
   |
   | LSU
   ↓
224.0.0.6
   |
   ↓
DR / BDR
   |
   | LSU
   ↓
224.0.0.5
   |
   ↓
所有 OSPF 路由器
```

### 关键点

**224.0.0.5**

> AllSPFRouters

**224.0.0.6**

> AllDRouters

---

# 六、Type 2 Network LSA

在广播网络中：

> **DR 负责产生 Type 2 Network LSA。**

Type 2 LSA：

> **Network LSA**

主要描述：

> 一个多路访问网络以及连接到该网络的 OSPF 路由器。

### 重要对比

|网络类型|DR/BDR|Type 2 LSA|
|---|---|---|
|Broadcast|有|有|
|Point-to-Point|无|无|

---

# 七、OSPF 网络类型

常见 OSPF 网络类型：

1. Broadcast
    
2. Point-to-Point
    
3. NBMA
    
4. Point-to-Multipoint
    

---

## 1. Broadcast

特点：

- 自动发现邻居
    
- 使用组播
    
- 选举 DR/BDR
    
- 默认 Hello：10 秒
    
- 默认 Dead：40 秒
    

典型：

> Ethernet

---

## 2. Point-to-Point

特点：

- 不选举 DR/BDR
    
- 自动发现邻居
    
- 不产生 Type 2 Network LSA
    
- 默认 Hello：10 秒
    
- 默认 Dead：40 秒
    

常见配置：

```cisco
ip ospf network point-to-point
```

---

## 3. NBMA

特点：

- Non-Broadcast Multi-Access
    
- 默认不使用广播/组播自动发现邻居
    
- 通常需要手动指定 Neighbor
    
- 默认 Hello：30 秒
    
- 默认 Dead：120 秒
    

---

## 4. Point-to-Multipoint

特点：

- 一个接口连接多个邻居
    
- 通常不需要 DR/BDR
    
- 可以自动发现邻居
    
- 默认 Hello：30 秒
    
- 默认 Dead：120 秒
    

---

# 八、OSPF 网络类型不匹配

网络两端的 OSPF 网络类型不匹配可能导致邻居建立异常。

例如：

```text
R1                     R2
Broadcast     ←→      Point-to-Point
```

两端对 DR/BDR 的理解不同，可能导致：

- 邻居建立异常
    
- 卡在 2-Way
    
- 卡在 ExStart
    
- LSDB 无法正常同步
    

---

## 常见检查项目

### 1. 查看 OSPF 接口

```cisco
show ip ospf interface
```

检查：

- Network Type
    
- Hello
    
- Dead
    
- Priority
    
- DR
    
- BDR
    

---

### 2. 查看 OSPF 邻居

```cisco
show ip ospf neighbor
```

检查：

- Neighbor ID
    
- State
    
- Priority
    
- DR
    
- BDR
    
- Interface
    

---

### 3. 常见邻居故障

#### 卡在 Init

重点检查：

> Hello 是否能够双向到达。

---

#### 卡在 2-Way

如果是：

```text
DROther ↔ DROther
```

那么：

> **正常。**

如果本来应该建立 Full 却一直 2-Way，则检查 DR/BDR 和网络类型。

---

#### 卡在 ExStart

重点检查：

- MTU
    
- DD 协商
    
- 主从关系
    
- 网络类型
    
- 二层连通性
    

---

#### 邻居完全无法建立

重点检查：

- Area ID
    
- Hello Interval
    
- Dead Interval
    
- Authentication
    
- Network Type
    
- Router ID
    
- IP 连通性
    
- ACL
    
- MTU
    
- OSPF 是否启用
    

---

# 九、CCNP 必背总结

## DR/BDR

```text
Priority 越大越优
        ↓
Priority 相同
        ↓
Router ID 越大越优
```

```text
Priority 0
    ↓
不参加选举
```

```text
DR/BDR
    ↓
无抢占
```

```text
DR 故障
    ↓
BDR → DR
    ↓
重新选举 BDR
```

---

## 邻居状态

```text
Down
 ↓
Init
 ↓
2-Way
 ↓
ExStart
 ↓
Exchange
 ↓
Loading
 ↓
Full
```

### 每个阶段一句话

|状态|核心作用|
|---|---|
|Down|没收到 Hello|
|Init|收到 Hello，但没看到自己的 Router-ID|
|2-Way|双向通信建立|
|ExStart|协商 Master/Slave 和 DD 序列号|
|Exchange|交换 LSA 摘要|
|Loading|LSR/LSU/LSAck 同步缺失 LSA|
|Full|LSDB 同步完成|

---

## OSPF 4 个重要报文

```text
Hello
 ↓
发现/维护邻居

DD
 ↓
交换 LSDB 摘要

LSR
 ↓
请求缺失 LSA

LSU
 ↓
发送完整 LSA

LSAck
 ↓
确认收到 LSA
```

---

## 两个重要组播地址

```text
224.0.0.5
AllSPFRouters
所有 OSPF 路由器
```

```text
224.0.0.6
AllDRouters
DR/BDR
```

---

## Broadcast vs Point-to-Point

|特征|Broadcast|Point-to-Point|
|---|---|---|
|DR/BDR|有|无|
|Type 2 LSA|有|无|
|邻居发现|自动|自动|
|Ethernet 默认|是|否|
|Full 邻接|DR/BDR 与其他路由器|双方直接 Full|
|DROther ↔ DROther|2-Way|不存在此角色关系|
|默认 Hello|10s|10s|
|默认 Dead|40s|40s|

---

# 十、最终理解框架

学习 OSPF 建邻时，可以始终按照下面这条线理解：

```text
① 网络类型
      ↓
② 是否需要 DR/BDR
      ↓
③ Hello 发现邻居
      ↓
④ Init
      ↓
⑤ 2-Way
      ↓
⑥ 判断是否需要建立邻接
      ↓
⑦ ExStart
      ↓
⑧ Exchange
      ↓
⑨ Loading
      ↓
⑩ Full
      ↓
⑪ LSDB 同步完成
```

其中最容易考的几个判断：

```text
Broadcast
    ↓
DR/BDR
    ↓
DROther ↔ DROther = 2-Way
```

```text
Point-to-Point
    ↓
无 DR/BDR
    ↓
直接建立 Full
```

```text
ExStart
    ↓
Master / Slave
    ↓
DD Sequence Number
```

```text
Exchange
    ↓
DD
    ↓
LSA 摘要
```

```text
Loading
    ↓
LSR → LSU → LSAck
    ↓
Full
```