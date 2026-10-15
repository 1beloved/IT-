# OSPF Type 1 LSA + SPF 完整笔记

## 一、OSPF LSA 基础

LSA = **Link-State Advertisement**

可以理解成：

> **OSPF 路由器向其他 OSPF 路由器描述“我知道的网络状态”。**

LSA 被存储在：

> **LSDB（Link-State Database）**

然后 OSPF 根据 LSDB 运行 SPF 算法，计算最优路径。

基本流程：

```
OSPF邻居建立
      ↓
交换LSA
      ↓
形成LSDB
      ↓
运行SPF
      ↓
生成最短路径树
      ↓
计算最优路由
      ↓
写入RIB
      ↓
最终安装到FIB
```

---

# 二、Type 1 Router LSA

## 1. 基本信息

|项目|Type 1 Router LSA|
|---|---|
|名称|Router LSA|
|Type|1|
|产生者|每台 OSPF Router|
|Link State ID|Router ID|
|Advertising Router|Router ID|
|传播范围|**本 Area 内**|
|是否跨 Area|❌|

最重要的一句话：

> **Type 1 LSA 描述“一个路由器在某个 OSPF Area 内的链路状态”。**

例如：

```
        Area 0

   R1              R2
RID 1.1.1.1      RID 2.2.2.2
    │                │
    └──── Ethernet ──┘
```

那么 Area 0 中至少有：

```
Type 1
LSID = 1.1.1.1
Advertising Router = 1.1.1.1

Type 1
LSID = 2.2.2.2
Advertising Router = 2.2.2.2
```

---

# 三、Type 1 LSA 的三个核心字段

这个非常适合考试。

### Type

表示 LSA 类型：

```
Type 1 = Router LSA
```

### Link State ID

Type 1 中：

> **Link State ID = Router ID**

例如：

```
R1 Router ID = 1.1.1.1
```

那么：

```
Link State ID = 1.1.1.1
```

### Advertising Router

表示：

> **是谁产生/通告了这个 LSA**

Type 1 中：

```
Link State ID
        =
Advertising Router
        =
Router ID
```

所以 R1：

```
Type              = 1
Link State ID     = 1.1.1.1
Advertising Router= 1.1.1.1
```

### ⭐考试记忆

> **Type 1：LSID 和 Advertising Router 都是 Router ID。**

---

# 四、Type 1 LSA 的传播范围

这是非常重要的考点：

> **Type 1 LSA 只在本 Area 内泛洪。**

例如：

```
Area 0
R1 ─ R2 ─ R3
```

R1 产生：

```
Type 1
LSID = 1.1.1.1
```

它可以在：

```
R1 → R2 → R3
```

传播。

但是如果：

```
Area 0          Area 1

R1 ─ R2 ─ R3
```

R1 的 Type 1 **不会直接进入 Area 1**。

Area 1 中的路由器需要通过其他类型的 LSA 获得跨区域路由信息。

---

# 五、Type 1 LSA 到底描述什么？

可以把 Router LSA 理解成：

> **“我是 R1，我有哪些 OSPF 链路，这些链路连接到哪里，每条链路的 Cost 是多少。”**

例如：

```
             R2
             │
            10
             │
             R1
           /    \
         1/      \1
        LAN      Loopback
```

R1 的 Router LSA 可以描述：

```
R1
│
├── 到R2的链路
│     Cost = 10
│
├── LAN前缀
│     Cost = 1
│
└── Loopback
      Cost = 1
```

因此 Type 1 LSA 是 OSPF **拓扑数据库的重要组成部分**。

---

# 六、Type 1 中常见的 Link Type

Cisco Router LSA 中常见：

```
1. Point-to-Point
2. Transit Network
3. Stub Network
4. Virtual Link
```

注意：

> 这里的 Link Type 是 **Router LSA 内部描述链路的类型**，不要和 OSPF 接口的 Network Type 完全混为一谈。

---

# 七、Transit Network

这是你原笔记里最需要修改的地方。

在 Ethernet 等多路访问网络中：

```
          R1
           │
           │
           ├──── LAN ────┤
           │             │
          R2             R3
```

如果这个网络存在多个 OSPF 路由器，OSPF 通常会选举：

```
DR
BDR
```

然后 Router LSA 不需要让每台路由器分别描述所有邻居之间的关系，而是使用：

```
Transit Network
```

描述：

> **“我连接到了这个由 DR 所代表的 Transit Network。”**

---

# 八、Transit Network 中最重要的两个字段

## Link ID

对于 Transit Network：

> **Link ID = DR 的接口 IP 地址**

例如：

```
DR
G0/0 = 192.168.1.254
```

那么：

```
Link ID = 192.168.1.254
```

## Link Data

通常：

> **Link Data = 本路由器连接该网络的接口 IP**

例如：

```
R1 G0/0 = 192.168.1.1
```

那么：

```
Link ID   = 192.168.1.254
Link Data = 192.168.1.1
```

---

# 九、为什么要有 DR？

假设没有 DR：

```
R1 ── R2
│ ╲  ╱ │
│  ╲╱  │
R3 ─── R4
```

广播网络中大量路由器需要互相描述拓扑，LSA 泛洪关系会非常复杂。

DR 出现以后：

```
          R1
           │
R2 ─────── DR ─────── R3
           │
          R4
```

逻辑上把这个广播网络抽象成：

```
Router
   ↓
Transit Network
   ↓
DR
```

这样可以减少 LSA 泛洪和邻接关系的规模。

### 但注意

**DR 不是一个额外的虚拟路由器。**

DR 是：

> **真实存在的一台 OSPF 路由器，只是在广播网络中承担特殊角色。**

---

# 十、Stub Network

Router LSA 中另一种常见描述：

```
Stub Network
```

它主要用于描述：

> **某个非 Transit 的网络/前缀。**

例如：

```
R1
 │
 └──── 10.1.1.0/24
```

如果这个网段没有形成 OSPF Transit Network，那么 Router LSA 可以把它作为：

```
Stub Network
```

进行描述。

典型信息：

```
Link ID   = Network ID
Link Data = Subnet Mask
Metric    = Cost
```

例如：

```
10.1.1.0/24
```

可能看到：

```
Link ID   = 10.1.1.0
Link Data = 255.255.255.0
Metric    = 1
```

---

# 十一、Loopback 为什么经常看到 Stub Network？

这是 CCNP 很容易遇到的实验现象。

例如：

```
interface Loopback0
 ip address 1.1.1.1 255.255.255.255
```

OSPF 通常会把它作为：

```
Stub Network
```

来描述。

你在：

```
show ip ospf database router
```

中可能看到：

```
Link connected to: a Stub Network
(Link ID) Network/subnet number: 1.1.1.1
(Link Data) Network Mask: 255.255.255.255
```

所以：

> **Loopback 在 Router LSA 中经常表现为 Stub Network。**

---

# 十二、查看 Type 1 LSA

最重要的两个命令：

```
show ip ospf database
```

查看整个 OSPF 数据库。

更精确：

```
show ip ospf database router
```

或者：

```
show ip ospf database router 1.1.1.1
```

可以看到：

```
Router Link States (Area 0)

Link ID         ADV Router
1.1.1.1         1.1.1.1
2.2.2.2         2.2.2.2
```

这里：

```
Link ID = Router ID
ADV Router = Router ID
```

就是 Type 1。

---

# 十三、SPF 是怎么利用这些 LSA 的？

这是整章最重要的部分。

假设：

```
        10
R1 ───────── R2
│             │
│10           │10
│             │
R3 ───────── R4
        10
```

R1 收集到：

```
R1的Router LSA
R2的Router LSA
R3的Router LSA
R4的Router LSA
```

形成：

```
LSDB
```

然后 R1：

> **以自己 R1 为 SPF 根节点。**

开始计算：

```
R1 → R2 = 10
R1 → R3 = 10

R1 → R2 → R4 = 20
R1 → R3 → R4 = 20
```

最终得到最短路径树。

---

# 十四、OSPF Cost 怎么计算？

基本公式：

> **Cost = Reference Bandwidth / Interface Bandwidth**

Cisco 默认：

```
Reference Bandwidth = 100 Mbps
```

例如：

```
100 Mbps / 100 Mbps = 1
```

```
100 Mbps / 10 Mbps = 10
```

所以：

```
100M接口 → Cost 1
10M接口  → Cost 10
```

### ⚠️ 注意

现代网络中经常有：

```
1G
10G
40G
100G
```

默认参考带宽 100 Mbps 已经不适合区分高速接口。

因此实际网络可能配置：

```
router ospf 1
 auto-cost reference-bandwidth 10000
```

例如把参考带宽改成：

```
10,000 Mbps
```

---

# 十五、路径 Cost 是累加的

例如：

```
R1 --10-- R2 --10-- R3
```

那么：

```
R1 → R3
Cost = 10 + 10
     = 20
```

如果：

```
R1 ─10─ R2
│
20
│
R3
```

那么：

```
R1 → R2 = 10
R1 → R3 = 20
```

SPF 会选择 Cost 更低的路径。

---

# 十六、每台路由器都要自己跑 SPF

这个非常重要。

不是：

> “网络里有一个中央 OSPF 服务器负责计算。”

而是：

```
        LSDB
          │
 ┌────────┼────────┐
 ↓        ↓        ↓
 R1       R2       R3
 SPF      SPF      SPF
```

每台路由器：

> **以自己为根运行 SPF。**

所以：

```
R1看到的最优路径
```

和：

```
R2看到的最优路径
```

理论上可能不同，因为它们的 SPF Root 不同。

---

# 十七、把 Type 1 和 Type 2 联系起来

这个非常重要，因为你马上会继续学 Type 2。

广播网络：

```
        R1
         │
         │
R2 ───── DR ───── R3
```

Router LSA：

```
Type 1
R1 → Transit Network
R2 → Transit Network
R3 → Transit Network
```

DR 再产生：

```
Type 2 Network LSA
```

描述：

> **这个 Transit Network 上有哪些 OSPF 路由器。**

所以可以先这样记：

```
Type 1
Router LSA
↓
“我是谁，我有哪些链路”

Type 2
Network LSA
↓
“这个广播网络上有哪些路由器”
```

这个关系非常重要。

---

# 十八、CCNP考试记忆表

|LSA|名称|LSID|作用|范围|
|---|---|---|---|---|
|**Type 1**|Router LSA|Router ID|描述路由器链路|Area内|
|**Type 2**|Network LSA|DR接口IP|描述Transit Network|Area内|
|**Type 3**|Summary LSA|目标网络|跨Area传递网络信息|跨Area|
|**Type 4**|ASBR Summary|ASBR RID|告诉其他Area如何到ASBR|跨Area|
|**Type 5**|AS External|外部网络|描述外部路由|AS范围|
|**Type 7**|NSSA External|外部网络|NSSA区域外部路由|NSSA|

---

# 十九、你现在最应该背下来的 8 个点

如果准备 CCNP，我建议你先把下面这张“脑图”吃透：

```
                 OSPF
                   │
                  LSA
                   │
             ┌─────┴─────┐
             │   Type 1  │
             │ Router LSA│
             └─────┬─────┘
                   │
          ┌────────┼────────┐
          ↓        ↓        ↓
        Type=1   LSID     ADV Router
                   │          │
                   └────┬─────┘
                        ↓
                   Router ID
                        
传播范围：
Area内
                        
描述：
本路由器的链路状态
                        
Link Type：
P2P
Transit
Stub
Virtual Link
                        
Transit：
Link ID = DR接口IP
Link Data = 本机接口IP
                        
Stub：
Link ID = 网络地址
Link Data = 子网掩码
                        
最终：
LSDB
 ↓
SPF
 ↓
最短路径树
 ↓
RIB
 ↓
FIB
```

### 最后纠正你原笔记里最容易形成错误记忆的一句话：

你原来写：

> **“Transit = 有邻居，Subnet = 无邻居。”**

**不要这样背。**

更准确地记：

> **Transit Network 是 Router LSA 中对一个多路访问 Transit Network 的拓扑描述；Stub Network 是 Router LSA 中对非 Transit 网络/前缀的描述。**

尤其是 CCNP 题目会故意利用“有没有邻居”这种过度简化来干扰你。