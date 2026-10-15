
# 1. RSTP 的端口角色新增了两个

STP 主要是：

```
Root Port
Designated Port
Non-designated Port
```

RSTP 把备用路径进一步明确成：

```
Root Port
Designated Port
Alternate Port   
Backup Port      ← 新
```

最重要的是：

### Alternate Port

它相当于 STP 中的 **Blocking 备用端口**。

例如：

```
        SW1
       Root
      /    \
     /      \
   SW2------SW3
```

SW2：

```
到 SW1 → Root Port
到 SW3 → Alternate Port
```

如果 Root Port 断了：

```
Root Port 失效
      ↓
Alternate Port
      ↓
快速接替
```

这就是 RSTP 快速收敛的重要基础。

### Backup Port
![[Pasted image 20260905194919.png]]
比较少见。

它是：

> 同一个交换机连接到同一个共享网段时的备用 Designated Port。

> **Alternate Port：备用 Root Port**  
> **Backup Port：备用 Designated Port**

也就是：

```
Alternate Port
→ 为 Root Port 提供备份

Backup Port
→ 为 Designated Port 提供备份
```

---

1. Backup Port 到底什么时候出现？

关键条件：

> **同一个交换机的两个端口，都连接到了同一个共享网段（shared segment）。**

例如：

```
              SW1
             /   \
            /     \
           /       \
          +---------+
          Shared LAN
```

假设 SW1 的：

```
Gi0/1
Gi0/2
```

都连接到**同一个共享网段**。

那么两个端口都可能收到来自这个网段的 BPDU。

SW1 必须决定：

```
一个端口 → Designated Port
另一个端口 → Backup Port
```

所以：

> **Backup Port 是同一台交换机上的 Designated Port 的备份。**

---

# 2. 为什么需要 Backup Port？

因为如果 SW1 的两个端口都连接同一个网段：

```
             SW1
            /   \
         Gi0/1 Gi0/2
           \     /
            \   /
          Shared Segment
```

如果两个端口都 Forwarding：

```
Gi0/1 → Forwarding
Gi0/2 → Forwarding
```

就可能产生环路。

所以 RSTP：

```
Gi0/1 → Designated Port → Forwarding
Gi0/2 → Backup Port     → Discarding
```

Backup Port 处于备用状态。

---

# 3. Backup Port 和 Alternate Port 的核心区别

这个一定要分清：

| |Alternate Port|Backup Port|
|---|---|---|
|备份谁|**Root Port**|**Designated Port**|
|产生原因|存在另一条到 Root 的路径|同一交换机多个端口连接同一共享网段|
|常见程度|很常见|很少见|
|状态|Discarding|Discarding|

可以直接记：

```
AP = 备用 RP
BP = 备用 DP
```

---

# 4. 用一个非常直观的图理解

### Alternate Port

```
             SW1
             Root
            /    \
           /      \
         SW2------SW3
         ↑
         │
       RP │
         
SW2 → SW3 的端口
        ↓
    Alternate Port
```

这里：

```
SW2
├── Root Port
└── Alternate Port
```

它们是：

> **两条不同路径通向 Root。**

所以 AP 是 **Root Port 的候补**。

---

### Backup Port

```
              SW1
             /   \
            /     \
         Gi0/1   Gi0/2
            \     /
             \   /
          Shared Segment
```

两个端口：

```
SW1
├── Designated Port
└── Backup Port
```

---

# 2. Port State 从 5 个变成 3 个

STP：

```
Blocking
Listening
Learning
Forwarding
Disabled
```

RSTP：

```
Discarding
Learning
Forwarding
```

对应关系：

```
Blocking + Listening
        ↓
    Discarding
```

所以考试看到：

```
Altn BLK
```

这是 Cisco 输出里的表现形式，本质上就是：

```
Alternate
+
Discarding
```

---

# 3. RSTP 最核心的新东西：Proposal / Agreement

这是你学习 RSTP **最值得花时间理解的地方**。

STP 很大程度依赖：

```
计时器
```

RSTP 引入了：

```
Proposal
Agreement
```

简单理解：

```
SW1                    SW2
 |                       |
 |------ Proposal ------>|
 |                       |
 |<----- Agreement ------|
 |                       |
      Forwarding
```

意思是：

> SW1 提议：“你这个端口可以快速进入 Forwarding 吗？”

SW2 确认：

> “可以。”

于是快速建立 Forwarding。

### 你要特别记住

RSTP 的快速收敛不是简单地：

> “把 STP 的 timer 调小了。”

而是通过：

> **Proposal / Agreement + 端口角色机制**

实现快速收敛。

---

# 4. RSTP 的 BPDU 机制变了

STP：

```
主要由 Root Bridge 产生 BPDU
其他交换机接收并转发
```

RSTP：

> **每台交换机都主动发送 BPDU。**

而且 RSTP 使用 BPDU 中的 Flag 携带：

```
Proposal
Agreement
Learning
Forwarding
Port Role
```

所以你看到 RSTP 的 BPDU，可以理解为：

> 不只是“告诉别人 Root Bridge 是谁”，还承担了更丰富的快速协商信息。

---

# 5. RSTP 的 Edge Port

这个概念非常重要。

STP 中你可能已经知道 Cisco 的：

```
spanning-tree portfast
```

RSTP 把这种：

> **连接终端、理论上不会形成二层环路的端口**

标准化称为：

```
Edge Port
```

例如：

```
Switch
  |
  |
 PC
```

这个端口可以直接进入：

```
Forwarding
```

而不用经历普通 STP 那种等待过程。

Cisco：

```
interface gi0/1
 spanning-tree portfast
```

所以你可以建立这个对应关系：

```
RSTP标准概念
      ↓
Edge Port

Cisco实现
      ↓
PortFast
```

---

# 6. RSTP 有一个非常重要的保护：Link Type

RSTP 会区分链路类型：

```
Point-to-Point
Shared
```

典型交换机之间的全双工链路：

```
SW1 ===== SW2
```

通常属于：

```
Point-to-Point
```

RSTP 可以利用 Point-to-Point 链路进行快速 Proposal/Agreement 协商。

Cisco 可以查看：

```
show spanning-tree interface gi0/1 detail
```

里面会看到类似：

```
Link type is point-to-point
```

---

# 7. Cisco 上你真正需要新增记住的命令

如果你已经会 STP，那么 RSTP 命令其实没多少。

### 开启 Rapid-PVST+

```
spanning-tree mode rapid-pvst
```

查看：

```
show spanning-tree summary
```

会看到：

```
Switch is in rapid-pvst mode
```

---

### 查看 RSTP 端口详细信息

```
show spanning-tree interface gi0/1 detail
```

这个特别值得记。

可以看：

```
Role
State
Link type
Edge
BPDU
```

---

### Edge Port / PortFast

```
interface gi0/1
 spanning-tree portfast
```

---

### BPDU Guard

RSTP/PortFast 实验中经常一起出现：

```
interface gi0/1
 spanning-tree bpduguard enable
```

---

# 8. 你现在可以这样理解 STP → RSTP

你已经会：

```
STP
│
├── Root Bridge
├── Root Port
├── Designated Port
├──Alternate Port
├── Path Cost
├── Bridge ID
├── Port ID
└── Timer
```

现在只补：

```
RSTP
│
├── Alternate Port       ★
├── Backup Port
├── 3种State             ★
│     ├── Discarding
│     ├── Learning
│     └── Forwarding
│
├── Proposal / Agreement ★★★
├── 每台交换机主动发送BPDU
├── Edge Port
└── Point-to-Point Link
```

其中优先级：

> **Proposal/Agreement > Alternate Port > Edge Port > BPDU变化 > Backup Port**
> **STP 快，是因为每台交换机都主动发送 BPDU，使邻居能够快速交换拓扑信息；同时通过 Proposal/Agreement、Alternate Port、Edge Port 等机制，让端口不再主要依赖 STP 的 15/15 秒定时器进行状态转换。**

其中最核心的是：

```
传统 STP
        ↓
BPDU传播 + Timer
        ↓
慢

RSTP
        ↓
主动BPDU + Proposal/Agreement
        ↓
快速协商
        ↓
快速Forwarding
```
---
