# CCNP OSPFv2 LSA 完整整理版

# 一、OSPF 五种报文

[[OSPF]] 一共有 **5 种报文**：

| 报文    | 全称                        | 主要作用         |
| ----- | ------------------------- | ------------ |
| Hello | Hello Packet              | 发现、建立、维护邻居   |
| DD    | Database Description      | 交换 LSDB 摘要   |
| LSR   | Link State Request        | 请求缺失或过期的 LSA |
| LSU   | Link State Update         | 携带并发送完整 LSA  |
| LSAck | Link State Acknowledgment | 确认收到 LSA     |

| 路由标记            | 含义           | 来源       |
| --------------- | ------------ | -------- |
| `O`             | OSPF区域内      | Type 1/2 |
| `O IA`          | OSPF区域间      | Type 3   |
| `O E1`          | OSPF外部类型1    | Type 5   |
| `O E2`          | OSPF外部类型2    | Type 5   |
| `O N1`          | NSSA外部类型1    | Type 7   |
| `O N2`          | NSSA外部类型2    | Type 7   |
| `O*IA`          | OSPF区域间默认路由  | ABR产生    |
| `O*N1` / `O*N2` | NSSA相关默认路由场景 | 取决于具体实现  |
### 建邻过程

```text
Hello
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

### Full 阶段涉及的核心报文

```text
DD
 ↓
交换 LSA 摘要

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

# 二、OSPF 邻居状态与邻接关系

## 1. 邻居状态

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

### Down

没有收到对方有效的 Hello。

### Init

收到对方 Hello，但是：

> 对方 Hello 中还没有看到自己的 Router-ID。

说明目前还是单向可见。

### 2-Way

双方 Hello 中都已经看到对方 Router-ID。

表示：

> 双向通信已经建立。

---

## 2. 广播网络中的 DR/BDR

如果网络类型是 Broadcast：

- 需要选举 DR/BDR
    
- Priority 越大越优
    
- Priority = 0 不参与选举
    
- Router ID 作为 Priority 相同时的第二比较条件
    
- DR/BDR **没有抢占机制**
    

### 邻接关系

```text
DR ↔ BDR       Full
DR ↔ DROther   Full
BDR ↔ DROther  Full
DROther ↔ DROther   2-Way
```

所以：

> **DROther 之间保持 2-Way 是正常现象。**

---

# 三、OSPF 网络类型

## 1. Broadcast

典型：

> Ethernet

特点：

- 自动发现邻居
    
- 选举 DR/BDR
    
- 使用 224.0.0.5
    
- DR/BDR 使用 224.0.0.6 与 DROther 通信
    
- 默认 Hello：10 秒
    
- 默认 Dead：40 秒
    

---

## 2. Point-to-Point

特点：

- 不选举 DR/BDR
    
- 自动发现邻居
    
- 不产生 Type 2 Network LSA
    
- 双方直接建立 Full 邻接
    

常见配置：

```cisco
interface e0/0
 ip ospf network point-to-point
```

---

## 3. NBMA

特点：

- Non-Broadcast Multi-Access
    
- 不使用广播/组播自动发现邻居
    
- 通常需要手动指定 Neighbor
    
- 默认 Hello：30 秒
    
- 默认 Dead：120 秒
    

---

## 4. Point-to-Multipoint

特点：

- 一个接口连接多个邻居
    
- 不需要 DR/BDR
    
- 可以自动发现邻居
    
- 默认 Hello：30 秒
    
- 默认 Dead：120 秒
    

---

# 四、OSPFv2 LSA

LSA：

> **Link-State Advertisement**

即：

> 链路状态通告。

LSA 是 OSPF 用来描述网络拓扑和路由信息的核心数据。

常见类型：

```text
Type 1
Type 2
Type 3
Type 4
Type 5
Type 7
```

Type 6：

> MOSPF 使用，已经废弃，实际网络基本不使用。

---

# 五、LSA 的基本结构

LSA 可以理解为：

```text
LSA
├── LSA Header
└── LSA Body
```

其中：

> **LSA Header 固定为 20 字节。**

所有类型的 LSA 都拥有公共 Header。

不同类型 LSA 的主要区别在于：

> **LSA Body 不同。**

---

# 六、LSA Header

LSA Header 中的重要字段：

| 字段                 | 作用                     |
| ------------------ | ---------------------- |
| LS Age             | LSA 已存在的时间             |
| Options            | OSPF 能力信息              |
| LS Type            | LSA 类型                 |
| Link State ID      | LSA 所描述对象的标识           |
| Advertising Router | 产生/通告该 LSA 的 Router-ID |
| LS Sequence Number | 判断 LSA 新旧              |
| LS Checksum        | 检查 LSA 完整性             |
| Length             | 整个 LSA 的长度             |

---

# 七、Link State ID

这是 LSA 中非常容易混淆的字段。

**LS ID 的含义取决于 LSA Type。**

| LSA Type | Link State ID       |
| -------- | ------------------- |
| Type 1   | 产生该 LSA 的 Router-ID |
| Type 2   | DR 的接口 IP 地址        |
| Type 3   | 被通告的网络前缀            |
| Type 4   | ASBR 的 Router-ID    |
| Type 5   | 外部网络前缀              |
| Type 7   | 外部网络前缀              |

注意：

> **不能简单地认为 Link State ID 永远等于 Router-ID。**

只有 Type 1 比较典型地是：

```text
LS ID = Advertising Router
```

---

# 八、LSA 新旧判断与老化

## 1. Sequence Number

主要用来：

> 判断两个相同 LSA 哪一个更新。

通常：

> **Sequence Number 越大 → LSA 越新**

---

## 2. Checksum

作用：

> 检查 LSA 内容是否损坏。

---

## 3. LS Age

LS Age 表示：

> LSA 已经存在多久。

最大年龄：

```text
3600 seconds
```

即：

> **1 小时**

如果 LSA 达到 MaxAge：

> LSA 会被认为已经过期，并从 LSDB 中删除。

---

# 九、六类主要 LSA 总览

| Type | 名称                | 产生者         | 主要作用            |
| ---- | ----------------- | ----------- | --------------- |
| 1    | Router LSA        | 每台 OSPF 路由器 | 描述区域内部自身链路      |
| 2    | Network LSA       | DR          | 描述广播网络          |
| 3    | Summary LSA       | ABR         | 通告区域间网络         |
| 4    | ASBR Summary LSA  | ABR         | 告诉其他区域如何到达 ASBR |
| 5    | AS External LSA   | ASBR        | 通告外部路由          |
| 7    | NSSA External LSA | NSSA 内 ASBR | 在 NSSA 中通告外部路由  |

最重要的一张图：

```text
             OSPF
              │
 ┌────────────┼────────────┐
 │            │            │
内部拓扑     区域间       外部路由
 │            │            │
Type 1/2     Type 3/4     Type 5/7
```

---

# 十、Type 1 Router LSA

## 1. 基本信息

名称：

> **Router LSA**

产生者：

> **每台 OSPF 路由器**

范围：

> **Area 内**

每台路由器都会针对自己参与的每个 Area 产生 Type 1 LSA。

---

## 2. 描述内容

Type 1 主要描述：

> **该路由器在本区域内的链路状态。**

包括：

- 链路
    
- 链路类型
    
- 链路 Cost
    
- 邻居
    
- 接口相关信息
    
- Router 是否为 ABR
    
- Router 是否为 ASBR
    

---

## 3. Type 1 与 SPF

Type 1：

> 参与 SPF 计算。

Type 2：

> 也参与 SPF 计算。

因此：

> **Type 1 + Type 2 → 构建区域内部拓扑。**

---

## 4. Router LSA 与网络类型

Broadcast：

```text
Type 1 + Type 2
```

Point-to-Point：

```text
Type 1
```

因为 Point-to-Point 没有 DR，也就不产生 Type 2 Network LSA。

---

# 十一、Type 2 Network LSA

名称：

> **Network LSA**

产生者：

> **DR**

产生条件：

> 多路访问网络中存在 DR，例如 Broadcast 网络。

---

## 1. 作用

描述：

> **一个广播/多路访问网络，以及连接到该网络的 OSPF 路由器。**

主要字段：

- Network Mask
    
- Attached Routers
    

---

## 2. Link State ID

Type 2 的：

> **LS ID = DR 接口的 IP 地址**

例如：

```text
R1 = DR
R1 E0/0 = 192.168.1.1
```

那么：

```text
Type 2 LSA
LS ID = 192.168.1.1
```

---

## 3. Attached Routers

Type 2 中会列出：

> 连接到该网络的 OSPF Router-ID。

例如：

```text
192.168.1.0/24

Attached Routers:
1.1.1.1
2.2.2.2
3.3.3.3
```

表示这些 OSPF 路由器连接到这个 Transit Network。

---

# 十二、Type 3 Summary LSA

名称：

> **Summary LSA**

产生者：

> **ABR**

作用：

> **在不同 Area 之间通告网络前缀。**

例如：

```text
Area 1
192.168.10.0/24
       ↓
      ABR
       ↓
Type 3
       ↓
Area 0
```

Area 0 就可以知道：

```text
192.168.10.0/24
```

位于 Area 1。

---

## 1. Type 3 的核心

记住：

> **Type 3 = Network**

也就是：

> 告诉其他 Area：

**“某个网络在哪。”**

---

# 十三、Type 4 ASBR Summary LSA

名称：

> **ASBR Summary LSA**

产生者：

> **ABR**

作用：

> **告诉其他 Area：ASBR 在哪里，以及如何到达 ASBR。**

---

## 1. 为什么需要 Type 4？

假设：

```text
Area 0
   |
  ABR
   |
Area 1
   |
  ASBR
   |
External Network
```

ASBR 在 Area 1。

其他 Area 如果想使用 ASBR 发布的外部路由，就必须知道：

> **如何到达这个 ASBR。**

因此 ABR 产生 Type 4 LSA。

---

## 2. Type 4 的 Link State ID

Type 4：

> **LS ID = ASBR 的 Router-ID**

例如：

```text
ASBR Router-ID = 5.5.5.5
```

那么：

```text
Type 4
LS ID = 5.5.5.5
```

---

# 十四、Type 3 vs Type 4

这是非常重要的考试点。

||Type 3|Type 4|
|---|---|---|
|名称|Summary LSA|ASBR Summary LSA|
|产生者|ABR|ABR|
|作用|告诉别人“网络在哪”|告诉别人“ASBR 在哪”|
|LS ID|网络前缀|ASBR Router-ID|
|主要服务|区域间网络|到 ASBR 的路径|

可以简单记：

> **Type 3 找 Network**

> **Type 4 找 ASBR**

---

# 十五、ASBR 是什么？

ASBR：

> **Autonomous System Boundary Router**

自治系统边界路由器。

判断标准非常简单：

> **只要一台 OSPF 路由器向 OSPF 中引入外部路由，它就是 ASBR。**

例如：

```cisco
router ospf 1
 redistribute connected
```

或者：

```cisco
router ospf 1
 redistribute static
```

这台路由器就成为：

> **ASBR**

---

# 十六、Type 5 AS External LSA

名称：

> **AS External LSA**

产生者：

> **ASBR**

作用：

> **向 OSPF 通告外部路由。**

例如：

```text
外部网络
10.10.10.0/24
      ↓
     ASBR
      ↓
Type 5
      ↓
OSPF
```

---

## 1. 什么叫外部路由？

例如：

```text
Static
Connected
BGP
RIP
EIGRP
```

这些路由通过 Redistribution 引入 OSPF：

```cisco
redistribute connected
```

那么这些路由就属于：

> **External Route**

ASBR 会产生 Type 5 LSA。

---

# 十七、Type 5 的 Metric Type

Type 5 有两种常见 Metric Type：

## E1

```text
总 Cost
=
OSPF 内部 Cost
+
External Cost
```

因此：

> **E1 会考虑内部路径成本。**

适合：

> 多出口场景。

---

## E2

```text
总 Cost
≈
External Cost
```

默认：

> **E2**

适合：

> 外部路由的外部 Metric 已经足够决定路径的场景。

---

## 记忆

```text
E1 = Internal + External
E2 = External
```

---

# 十八、Type 5 的重要字段

常见：

- Network Mask
    
- Metric
    
- E1/E2
    
- Forwarding Address
    
- Route Tag
    

### Forwarding Address

用于告诉其他 OSPF 路由器：

> 到达这个外部网络时，实际可以把数据包转发给哪个地址。

默认情况下常见：

```text
0.0.0.0
```

具体值取决于 ASBR 的外部接口和配置。

---

# 十九、特殊区域与 Type 5

普通 Area：

```text
Type 5
   ↓
Area
```

但是特殊区域会限制 Type 5。

### Stub

```text
Type 5 ❌
```

### Totally Stubby

```text
Type 5 ❌
Type 3/4 也进一步限制
```

### NSSA

```text
Type 5 ❌进入 NSSA
```

但是 NSSA 内部可以产生：

```text
Type 7
```

---

# 二十、Type 7 NSSA External LSA

名称：

> **NSSA External LSA**

产生者：

> **NSSA 区域内部的 ASBR**

作用：

> **在 NSSA 内部通告外部路由。**

---

## 1. 为什么需要 Type 7？

因为：

> NSSA 不允许普通 Type 5 LSA 进入。

但是 NSSA 内部又允许存在 ASBR。

所以：

```text
External Route
      ↓
NSSA ASBR
      ↓
Type 7
      ↓
NSSA
```

---

# 二十一、Type 7 → Type 5

当 Type 7 到达 NSSA 的 ABR：

```text
NSSA ASBR
    ↓
Type 7
    ↓
NSSA ABR
    ↓
Type 5
    ↓
Area 0
    ↓
其他 Area
```

因此可以记：

> **Type 7 只在 NSSA 中使用。**

> **离开 NSSA 后，通常转换成 Type 5。**

---

# 二十二、Type 5 vs Type 7

||Type 5|Type 7|
|---|---|---|
|名称|AS External|NSSA External|
|产生者|ASBR|NSSA 内 ASBR|
|普通 Area|✅|❌|
|NSSA|❌进入|✅|
|外部路由|✅|✅|
|离开 NSSA|—|通常转换为 Type 5|

核心记忆：

> **Type 5 = 普通 OSPF 外部路由**

> **Type 7 = NSSA 外部路由**

---

# 二十三、Type 6 MOSPF

Type 6：

> **Group Membership LSA**

用于：

> MOSPF（Multicast OSPF）

现在已经基本被：

> **PIM（Protocol Independent Multicast）**

等组播技术取代。

所以 CCNP 中：

> 了解即可，不需要像 Type 1/2/3/4/5/7 一样重点掌握。

---

# 二十四、ABR 与 ASBR 的区别

这是 OSPF 非常容易混淆的地方。

## ABR

> **Area Border Router**

连接不同 Area。

例如：

```text
Area 0
  |
 ABR
  |
Area 1
```

---

## ASBR

> **Autonomous System Boundary Router**

向 OSPF 引入外部路由。

例如：

```text
External
   |
 ASBR
   |
 OSPF
```

---

### 两者可以是同一台路由器

例如：

```text
Area 0
   |
  R2
 /  \
A1  External
```

R2：

- 连接 Area 0 和 Area 1 → ABR
    
- 引入 External Route → ASBR
    

所以：

> **ABR 和 ASBR 是按照不同条件定义的，可以同时存在于同一台路由器上。**

---

# 二十五、六类主要 LSA 的完整逻辑

把整个 OSPF 体系串起来：

```text
                 OSPF
                   |
        ┌──────────┴──────────┐
        |                     |
     内部拓扑                外部路由
        |                     |
    Type 1 / 2             Type 5 / 7
        |
        ↓
    Area 内部 SPF
```

区域之间：

```text
Area 1
  |
  | Type 3
  ↓
Area 0
```

如果需要寻找外部 ASBR：

```text
Area 1
  |
  | Type 4
  ↓
ASBR
```

NSSA：

```text
External
   ↓
NSSA ASBR
   ↓
Type 7
   ↓
NSSA ABR
   ↓
Type 5
   ↓
Area 0
```

---

# 二十六、抓包分析

Wireshark 中可以使用：

```text
ospf.lsa
```

查看 OSPF LSA。

注意：

> **LSA 通常承载在 LSU 报文中。**

所以抓到：

```text
OSPF
  ↓
Link State Update
  ↓
LSA
```

可以进一步查看具体 LSA。

---

# 二十七、Wireshark 中常见 LSA 类型

可以根据 LSA 类型进行过滤和定位：

```text
Router LSA
Network LSA
Summary LSA
ASBR Summary LSA
AS External LSA
NSSA External LSA
```

重点关注：

```text
Type 1 → Router
Type 2 → Network
Type 3 → Summary
Type 4 → ASBR Summary
Type 5 → AS External
Type 7 → NSSA External
```

---

# 二十八、CCNP 必背表

这一张建议直接背下来：

|Type|名称|谁产生|描述什么|主要范围|
|---|---|---|---|---|
|1|Router|每台路由器|自己的链路|Area|
|2|Network|DR|广播网络|Area|
|3|Summary|ABR|网络前缀|Area 间|
|4|ASBR Summary|ABR|ASBR 位置|Area 间|
|5|AS External|ASBR|外部网络|OSPF AS|
|6|Group Membership|MOSPF|组播成员|已废弃|
|7|NSSA External|NSSA ASBR|NSSA 外部网络|NSSA|

---

# 二十九、最重要的考试口诀

### Type 1

> **Router → 路由器自己**

### Type 2

> **Network → DR描述广播网络**

### Type 3

> **Summary → ABR告诉其他区域“网络在哪”**

### Type 4

> **ASBR Summary → ABR告诉其他区域“ASBR在哪”**

### Type 5

> **AS External → ASBR告诉 OSPF“外部网络在哪”**

### Type 7

> **NSSA External → NSSA 内部 ASBR告诉 NSSA“外部网络在哪”**

---

# 三十、把所有 LSA 串成一张图

```text
                       OSPF
                         |
        ┌────────────────┼────────────────┐
        │                │                │
      Area内部          Area之间          外部路由
        │                │                │
     Type 1/2          Type 3/4          Type 5/7
        │                │                │
        │                │          ┌─────┴─────┐
        │                │          │           │
        │                │       普通Area      NSSA
        │                │          │           │
        │                │       Type 5       Type 7
        │                │                      │
        │                │                      ↓
        │                │                 NSSA ABR
        │                │                      │
        │                │                      ↓
        │                │                   Type 5
        │                │
        └────────────────┴──────────────────────┘
```

## 最终记忆框架

```text
Type 1 → Router
Type 2 → Network
Type 3 → Network between Areas
Type 4 → ASBR
Type 5 → External
Type 7 → NSSA External
```

再压缩成一句：

> **1 看 Router，2 看 Network，3 看 Area 间 Network，4 找 ASBR，5 是 External，7 是 NSSA External。**