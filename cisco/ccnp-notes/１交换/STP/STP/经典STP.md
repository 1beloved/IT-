把 **经典 STP（IEEE 802.1D）** 理解成三个层次：

> **① STP 为什么存在 → ② STP 怎么选路 → ③ BPDU 在网络里怎么传播、交换机到底发生了什么。**

尤其是你问的“**数据包格式发生什么变化**”，这个非常关键：**STP 本身并不是修改正常业务数据包，而是交换机之间额外交换 BPDU 控制报文。**

---
  
# 一、STP 是干什么的？

STP 全称：

**Spanning Tree Protocol**

标准：

**IEEE 802.1D**

它解决的问题是：

> **二层网络存在冗余链路时，防止产生 Layer 2 环路。**

例如没有 STP：

```text
        SW1
       /   \
      /     \
    SW2 ─── SW3
```

如果 SW1 发一个广播：

```text
Broadcast
   ↓
SW1
 ↙  ↘
SW2  SW3
 ↘  ↙
  又收到
```

广播可能不断循环。

因为二层 Ethernet 帧：

> **没有 TTL。**

路由器的 IP 包有 TTL：

```text
TTL 64
 ↓
经过路由器
 ↓
TTL 63
```

最终 TTL=0 就丢弃。

但是普通 Ethernet 帧没有类似机制：

```text
MAC → MAC
```

所以二层环路非常危险。

---

# 二、STP 的核心思想

STP 并不是把冗余链路删除。

而是：

> **逻辑上阻塞一部分链路，形成一棵无环的树。**

例如：

```text
        SW1
       /   \
      /     \
    SW2     SW3
      \     /
       \   /
        X
```

假设：

```text
SW2 ─── SW3
```

这条链路被 STP 阻塞。

于是逻辑拓扑变成：

```text
        SW1
       /   \
      /     \
    SW2     SW3
```

但是物理链路仍然存在。

如果以后：

```text
SW1 ─ SW3
```

断了，STP 可以重新计算，让原来阻塞的链路恢复转发。

所以：

> **STP = 物理冗余 + 逻辑无环。**

---

# 三、经典 STP 是怎么工作的？

整个过程可以概括为：

```text
交换机启动
   ↓
交换 BPDU
   ↓
选 Root Bridge
   ↓
每台交换机计算到 Root 的最佳路径
   ↓
选 Root Port
   ↓
每条链路选 Designated Port
   ↓
剩余端口阻塞
   ↓
形成 Spanning Tree
```

其中最重要的是：

**Root Bridge → Root Port → Designated Port → Blocking**

---

# 四、第一步：选 Root Bridge

STP 首先要选一个“树根”。

这个设备叫：

> **Root Bridge**

选举依据：

> **最低 Bridge ID**

Bridge ID 主要由：

```text
Bridge ID
=
Bridge Priority
+
MAC Address
```

例如：

```text
SW1
Priority = 32768
MAC = 0000.1111.1111

SW2
Priority = 32768
MAC = 0000.2222.2222

SW3
Priority = 32768
MAC = 0000.3333.3333
```

因为：

```text
0000.1111.1111
<
0000.2222.2222
<
0000.3333.3333
```

所以：

```text
SW1 = Root Bridge
```

---

# 五、Root Bridge 有什么特殊？

Root Bridge 上：

> **所有活跃端口通常都是 Designated Port。**

例如：

```text
        SW1
       ROOT
      /    \
     /      \
   SW2      SW3
```

SW1：

```text
G0/1 → Designated Port
G0/2 → Designated Port
```

因为 SW1 本身就是 Root。

---

# 六、第二步：每台非 Root 交换机选 Root Port

例如：

```text
             SW1
             ROOT
            /    \
           /      \
         SW2 ───── SW3
```

SW2 要问：

> “我通过哪条路径到 Root SW1 最好？”

SW3 也要问同样的问题。

于是每台非 Root Switch：

> **选择一个 Root Port。**

Root Port 的定义：

> **非 Root Bridge 上，到达 Root Bridge 的最佳端口。**

注意：

**Root Bridge 本身没有 Root Port。**

---

# 七、STP 怎么判断“最佳路径”？以及RP跟DP的区别

经典 STP 使用：

> **Root Path Cost**

例如：

```text
SW1
 │
 │ 100M
 │
SW2
```

Fast Ethernet 的 STP cost 通常比 Gigabit Ethernet 大。

例如常见 Cisco short path cost：

| 链路       | Cost |
| -------- | ---: |
| 10 Mbps  |  100 |
| 100 Mbps |   19 |
| 1 Gbps   |    4 |
| 10 Gbps  |    2 |

所以：

```text
SW2 ──100M── SW1
```

成本：

```text
19
```

如果：

```text
SW2 ──1G── SW3 ──1G── SW1
```

成本：

```text
4 + 4 = 8
```

那么：

```text
直接走 SW2 → SW1 = 19

绕 SW3：
SW2 → SW3 → SW1 = 8
```

STP 会选择：

```text
8
```

## ① RP：主要比较「到 Root 的路径」

每台**非 Root Switch**选择 RP 时，核心第一比较项就是：

> **Root Path Cost（RPC）谁最小，谁更优。**

例如：

```
        S1 ROOT
       /      \
    cost 4   cost 10
     /          \
   S2            S3
```

S2 收到 BPDU 后计算自己到 Root 的 RPC：

```
S2 → S1
RPC = 4
```

如果 S2 有两条路：

```
S2 → S1       RPC = 4
S2 → S3 → S1  RPC = 8
```

那么：

```
4 < 8
```

所以去 S1 的端口成为 **RP**。

---

# ② DP：也是先比较 RPC，但比较的是「两台交换机谁离 Root 更近」

这是你现在最容易混淆的地方。

假设：

```
             S1
            ROOT
           /    \
          /      \
        S2--------S3
```

假设：

```
S2 到 Root 的 RPC = 4
S3 到 Root 的 RPC = 10
```

现在看 **S2-S3 这个网段**。

STP 要决定：

> “这个网段谁的端口当 DP？”

比较：

```
S2 RPC = 4
S3 RPC = 10
```

因为：

```
4 < 10
```

所以：

```
S2 = DP
S3 = 非DP
```

如果 S3 的这个端口没有其他更优用途，它就会进入 Blocking。

---

# ③ 所以你可以这样记

### 选 RP

问：

> **“我这台交换机，哪个端口能让我最快到 Root？”**

比较的是**自己从不同端口到 Root 的 RPC**。

```
RPC 最小
  ↓
RP
```

---

### 选 DP

问：

> **“这个网段两边，哪台交换机离 Root 更近？”**

比较的是**两台交换机各自的 RPC**。

```
RPC 更小的一方
      ↓
DP
```

---

## ④ 但 RPC 相同怎么办？

这才是 CCNP 真正需要掌握的地方。

如果：

```
S2 RPC = 4
S3 RPC = 4
```

RPC 平手，就继续比较 **Bridge ID**。

大致选举顺序：

```
① 最低 Root Bridge ID
② 最低 Root Path Cost
③ 最低 Sender Bridge ID
④ 最低 Sender Port ID
```

对于 RP/DP，具体比较场景略有不同，但你现在先抓住这个核心：

> **RPC 是非常重要的第一比较条件，但不是唯一条件。**

### 最重要的一张图

```
                 S1
              ★ ROOT
             /      \
          RPC 4    RPC 10
           /          \
         S2------------S3
        DP              ?
```

S2 和 S3 比：

```
4 vs 10
↓
S2 更接近 Root
↓
S2 这一侧 = DP
```

而对 S3 来说，它自己通往 Root 的最佳端口可能是：

```
S3 → S1
```

所以：

```
S3 → S1 = RP
```

**一句话：**

> **RP：在“我自己的端口”之间比较谁到 Root 的 RPC 最小。**
> 
> **DP：在“同一个网段的两端”比较谁的 RPC 更小。**
---

# 八、第三步：选 Designated Port(是在每条链路上选取)

这个概念特别容易和 Root Port 混。

假设：

```text
             SW1
             ROOT
            /    \
           /      \
         SW2 ───── SW3
```

对于：

```text
SW2 ───── SW3
```

这一条链路，两边都要竞争：

> “谁负责这个网段的转发？”

最终会选出：

> **Designated Port**

另一边如果没有成为 RP/DP，就会进入阻塞状态。

所以每个网络 Segment（**每条链路**）：

> **至少要有一个 Designated Port。**

---

# 九、STP 最终形成什么？

最终可能变成：

```text
              SW1
              ROOT
             /    \
            /      \
          SW2      SW3
            \      /
             \    /
              X
```

端口角色：

```text
SW1:
G0/1 = DP
G0/2 = DP

SW2:
G0/1 = RP
G0/2 = Blocking

SW3:
G0/1 = RP
G0/2 = Blocking
```

于是：

```text
        SW1
       /   \
      /     \
    SW2     SW3
```

就是 Spanning Tree。

---

# 十、那么 STP 到底交换什么“数据包”？

这就是你问的重点。

STP **不会给正常业务 Ethernet 数据包增加一个 STP 字段。**

而是交换机之间额外发送：

> **BPDU**

全称：

**Bridge Protocol Data Unit**

也就是说：

```text
正常业务：

PC
 ↓
Ethernet Frame
 ↓
Switch
 ↓
Switch
 ↓
PC
```

STP 控制：

```text
SW1
 │
 │ BPDU
 ↓
SW2
```

两者是不同的东西。

---

# 十一、BPDU 长什么样？

可以粗略理解成：

```text
Ethernet Header
        ↓
STP BPDU
        ↓
BPDU Data
```

经典 STP BPDU 里面有非常重要的信息：

```text
Root Bridge ID
Root Path Cost
Sender Bridge ID
Sender Port ID
Message Age
Max Age
Hello Time
Forward Delay
```

你真正要记的是这几个：

### ① Root Bridge ID

告诉别人：

> “我认为谁是 Root。”

### ② Root Path Cost

告诉别人：

> “我到 Root 的路径成本是多少。”

### ③ Sender Bridge ID

告诉别人：

> “我是谁。”

### ④ Port ID

告诉别人：

> “我是从哪个端口发出来的。”

---

# 十二、举个实际 BPDU 的例子

假设：

```text
SW1 = Root

        SW1
       ROOT
        │
        │
       SW2
```

SW1 发 BPDU：

```text
Root ID
= SW1

Root Path Cost
= 0

Sender Bridge ID
= SW1

Sender Port ID
= G0/1
```

SW2 收到以后：

```text
Root ID = SW1
Root Cost = 0
```

然后 SW2 计算：

```text
自己到 Root 的 Cost
=
收到的 Root Cost
+
本地接口 Cost
```

假设 G0/1 是 Gigabit：

```text
0 + 4 = 4
```

于是 SW2 认为：

```text
Root = SW1
Root Path Cost = 4
```

然后 SW2 再向外发送 BPDU：

```text
Root ID = SW1
Root Cost = 4
Sender = SW2
```

这就是 STP 信息逐渐传播的过程。

---

# 十三、注意：STP BPDU 不会像普通数据包一样“被交换机转发”

这个特别重要。

普通 Ethernet：

```text
PC
 ↓
SW1
 ↓
SW2
 ↓
SW3
```

交换机根据 MAC Address Table 转发。

但是 BPDU：

```text
SW1
 ↓
BPDU
 ↓
SW2
```

**不是普通业务帧的转发逻辑。**

交换机收到 BPDU 后：

> **自己处理 BPDU，然后根据 STP 状态决定是否发送自己的 BPDU。**

所以不是：

```text
SW1 BPDU
 ↓
SW2 原封不动转发
 ↓
SW3
```

而更接近：

```text
SW1
 ↓ BPDU
SW2
 ↓
SW2理解/计算
 ↓
生成自己的BPDU
 ↓
SW3
```

---

# 十四、BPDU 的目的 MAC

经典 STP BPDU 使用一个**特殊的链路本地组播 MAC**：

```text
01:80:C2:00:00:00
```

这个地址非常值得记。

因此：

```text
正常业务：
目的 MAC = 对方设备 MAC

STP BPDU：
目的 MAC = 01:80:C2:00:00:00
```

它属于链路本地范围。

所以 STP BPDU：

> **不会被交换机像普通组播一样跨多个二层设备无限传播。**

---

# 十五、数据帧到底有没有发生变化？

现在回答你原问题最核心的一点：

假设 PC 发：

```text
PC1 → PC2
```

原始 Ethernet：

```text
┌────────┬────────┬────────┐
│Dst MAC │Src MAC │ Payload│
└────────┴────────┴────────┘
```

经过交换机：

```text
┌────────┬────────┬────────┐
│Dst MAC │Src MAC │ Payload│
└────────┴────────┴────────┘
```

**STP 不会修改它。**

但是如果链路是 Trunk：

```text
┌────────┬────────┬────────┬────────┐
│Dst MAC │Src MAC │802.1Q Tag│Payload│
└────────┴────────┴────────┴────────┘
```

这是 **VLAN Trunk 的变化**，不是 STP 本身造成的。

---

# 十六、STP 真正改变的是“端口状态”

这才是 STP 对数据转发真正的影响。

经典 802.1D 有五种端口状态：

```text
Disabled
   ↓
Blocking
   ↓
Listening
   ↓
Learning
   ↓
Forwarding
```

重点：

### Blocking

```text
不转发用户数据
不学习 MAC
但可以接收 BPDU
```

### Listening

```text
参与 STP
不转发用户数据
不学习 MAC
```

### Learning

```text
不转发用户数据
开始学习 MAC Address
```

### Forwarding

```text
正常转发
正常学习 MAC
```

---

# 十七、所以 STP 可以这样理解

STP **不是**：

```text
修改数据包
```

而是：

```text
         STP BPDU
            ↓
     交换机之间计算
            ↓
       选择最佳路径
            ↓
       决定端口状态
            ↓
 ┌──────────┴──────────┐
 ↓                     ↓
Forwarding           Blocking
 ↓                     ↓
正常转发              不转发用户数据
```

这就是 STP 的本质。

---

# 十八、你作为 CCNP 学习者一定要把这张图吃透

```text
                     Root Bridge
                         SW1
                       /     \
                     DP       DP
                    /         \
                  SW2         SW3
                   │ \       / │
                   │  \     /  │
                  RP   \   /   RP
                        X
                     Blocking
```

选举过程：

```text
① Lowest Bridge ID
        ↓
   Root Bridge

② Lowest Root Path Cost
        ↓
    Root Port

③ Lowest Designated
   Bridge ID / Port ID
        ↓
 Designated Port

④ 剩下的
        ↓
    Blocking
```

而 BPDU 里面最核心的信息：

```text
┌──────────────────────────────┐
│ Root Bridge ID               │
│ Root Path Cost               │
│ Sender Bridge ID             │
│ Sender Port ID               │
│ Timers                       │
└──────────────────────────────┘
```

---

## 最后给你一个非常重要的思维方式

你之前学 QinQ 的时候，是：

```text
数据帧
[C-VLAN 8]
      ↓
[S-VLAN 100][C-VLAN 8]
```

这是**改变/封装数据帧**。

而 STP 是：

```text
业务数据帧
[Ethernet Frame]
      ↓
基本不变

同时

SW ←── BPDU ──→ SW
       ↓
   计算拓扑
       ↓
决定哪些端口 Forwarding
决定哪些端口 Blocking
```

所以：

> **QinQ 主要关注“帧怎么封装”；STP 主要关注“二层拓扑怎么避免环路”。**

### 经典 STP感知故障和故障收敛

```
Hello Time     = 2 秒
Max Age        = 20 秒
Forward Delay  = 15 秒
```

假设一条链路突然断了：

```
S1 -------- S2
             X
```

S2 原来通过这条链路收到 BPDU。

如果 S2 **没有立即从物理层感知到链路断开**，它要等不到 BPDU：

```
Hello
  ↓ 2s
没有收到
  ↓
继续等待
  ↓
Max Age = 20s
  ↓
认为原来的 BPDU 失效
```

所以经典 STP 中经常说：

> **BPDU 超时感知大约需要 20 秒（Max Age）。**

---

### 但为什么有人说 STP 故障恢复要 30～50 秒？

因为 **20 秒只是 Max Age，不是整个收敛时间**。

例如：

```
20s
↓
发现原路径失效
↓
Listening 15s
↓
Learning 15s
↓
Forwarding
```

因此经典 STP 的典型最坏收敛时间可以达到：

```
20 + 15 + 15 = 50 秒
```

直连根桥链路丢失就是  -30s
非直连根桥链路丢失就是  -50s
有些场景会说大约 **30～50 秒**，具体取决于故障类型以及交换机是否能立即检测到链路断开。

### 你现在 CCNP 先记这个：

```
经典 STP：

Hello Time    2s
Max Age       20s   ← BPDU 超时
Forward Delay 15s

典型最坏收敛 ≈ 50s
```

而 **RSTP（802.1w）** 就是为了解决这个慢的问题，正常情况下收敛可以做到**秒级甚至更快**，不再依赖经典 STP 的 Listening/Learning 15+15 秒机制。

所以考试看到：

> **STP 故障感知是多少秒？**

如果题目指的是 **Max Age / BPDU 超时** → **20 秒**。

如果问：

> **经典 STP 最坏收敛时间？**

→ **约 50 秒**。