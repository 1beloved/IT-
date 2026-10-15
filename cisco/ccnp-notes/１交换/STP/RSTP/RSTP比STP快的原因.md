# 一、先看最简单的场景

假设：

```
             SW1
          Root Bridge
             |
             |
             SW2
```

SW2 的 `Gi0/1` 连接 SW1。

我们希望：

```
SW2 Gi0/1
    ↓
Root Port
    ↓
Forwarding
```

传统 STP 会比较慢，因为要经过：

```
Blocking
   ↓
Listening
   ↓
Learning
   ↓
Forwarding
```

而 RSTP 会进行：

```
SW1
 │
 │ Proposal
 ↓
SW2
 │
 │ Agreement
 ↓
Forwarding
```

但这里有一个非常重要的问题：

> **SW2 为什么敢直接 Forwarding？**

因为在 Agreement 之前，它会先做一件非常重要的事：

> **把自己其他可能造成环路的端口暂时置于 Discarding。**

这就是 RSTP 快速收敛的关键。

---

# 二、Proposal 到底是什么？

Proposal 可以理解成：

> **“我认为你应该使用我作为你的上游路径，我提议你把这个端口快速变成 Forwarding。”**

例如：

```
             SW1
           Root
             |
             |
             ↓
             SW2
```

SW1 的端口是：

```
Designated Port
```

它向 SW2 发 BPDU。

这个 BPDU 的 Flag 中包含：

```
Proposal = 1
```

于是：

```
SW1 ───────→ SW2
       Proposal
```

意思就是：

> “我是这个链路上的 Designated Port，我认为你可以把连接我的端口作为 Root Port。”

---

# 三、但是 SW2 不能马上答应

这是最关键的一步。

SW2 收到 Proposal 后，会检查：

> “如果我接受这个 Proposal，会不会造成环路？”

假设拓扑是：

```
             SW1
            Root
           /    \
          /      \
        SW2------SW3
```

现在 SW1：

```
SW1 → SW2
```

发送 Proposal。

SW2 原来可能是：

```
SW2
├── Gi0/1 → Root Port
└── Gi0/2 → Alternate Port
```

如果 SW2 接受 SW1 的 Proposal，它必须确保：

```
Gi0/2
```

这个备用路径不会同时 Forwarding。

所以 SW2 会进行：

> **Sync（同步）**

---

# 四、Sync 是 Proposal/Agreement 里非常重要的隐藏步骤

你学习 CCNP 时一定要知道这个。

SW2 收到 Proposal：

```
Proposal
   ↓
SW2 检查其他端口
   ↓
把可能形成环路的端口置于 Discarding
   ↓
完成同步
   ↓
发送 Agreement
```

例如：

```
             SW1
            Root
           /    \
          /      \
        SW2------SW3
```

SW2 收到 Proposal。

它可能有：

```
Gi0/1 → Root Port
Gi0/2 → Alternate
```

SW2 会确保：

```
Gi0/2 = Discarding
```

也就是：

```
             SW1
            Root
           /    \
          /      \
        SW2------SW3
         RP       ?
                  |
             SW2 Gi0/2
             Discarding
```

这样 SW2 就可以放心地接受 Proposal。

---

# 五、然后 Agreement 出现

SW2 确认：

> “好的，我的其他端口已经同步，不会产生环路。”

于是 SW2 给 SW1 发：

```
Agreement = 1
```

于是：

```
SW1                    SW2
 │                       │
 │──── Proposal ────────→│
 │                       │
 │                       │
 │←──── Agreement ───────│
 │                       │
 ↓                       ↓
DP                      RP
Forwarding              Forwarding
```

这时候两端就可以快速进入 Forwarding。

---

# 六、为什么这样就不用等 30 秒？

因为传统 STP 的思想是：

> “我不确定网络有没有形成环路，所以我等。”

RSTP：

> “我直接把可能形成环路的端口先压住，然后和邻居确认。”

所以：

```
STP：

等待
 ↓
Listening
 ↓
等待
 ↓
Learning
 ↓
等待
 ↓
Forwarding
```

而 RSTP：

```
Proposal
   ↓
Sync
   ↓
Agreement
   ↓
Forwarding
```

这就是最大的思想变化。

---

# 七、再看一个稍微复杂的拓扑

这个更接近 CCNP。

```
              SW1
             ROOT
            /    \
           /      \
         SW2------SW3
```

假设：

```
SW1-SW2
SW1-SW3
SW2-SW3
```

三角形。

正常情况下：

```
SW1
Root
├──── SW2
│      RP
│
└──── SW3
       RP

SW2-SW3
其中一个端口 = Alternate
```

比如：

```
SW2 Gi0/1 → Root Port
SW2 Gi0/2 → Alternate
```

---

# 八、假设 SW1-SW2 链路刚刚恢复

现在：

```
SW1 ===== SW2
```

SW1 的端口发现：

> “这是一个可以建立 RSTP 邻居的链路。”

于是 SW1：

```
发送 BPDU
Proposal = 1
```

即：

```
SW1 ─────────→ SW2
       Proposal
```

---

# 九、SW2 收到 Proposal 后干什么？

SW2 会说：

> “如果我接受这个 Proposal，那么 SW1-SW2 就成为我的 Root Port。”

但是 SW2 还有：

```
SW2 → SW3
```

这条链路。

所以 SW2 必须确保：

```
SW2 → SW3
```

不会因为这个变化而形成两个 Forwarding 路径。

于是：

```
SW2
│
├── Gi0/1
│      ↓
│    Root Port
│
└── Gi0/2
       ↓
   暂时/保持 Discarding
```

这就是 **Sync**。

---

# 十、Sync 完成之后

SW2 确认：

> “我的其他非 Edge 端口已经同步，没有形成环路。”

于是：

```
SW2 ───────→ SW1
  Agreement
```

SW1 收到 Agreement：

```
SW1 DP
   ↓
Forwarding

SW2 RP
   ↓
Forwarding
```

整个过程非常快。

---

# 十一、那如果没有 Agreement 呢？

这个问题非常重要。

假设：

```
SW1 ───── SW2
```

SW1：

```
Proposal
```

SW2：

> “我不能安全地 Agreement。”

那么 RSTP 不会简单地：

> “算了，直接 Forwarding。”

它会继续按照 RSTP 的机制处理，必要时依靠其他机制和计时器保证安全。

所以：

> **Agreement 是快速进入 Forwarding 的确认。**

---

# 十二、Edge Port 为什么这么快？

现在你就能理解 PortFast / Edge Port 为什么快了。

例如：

```
SW1
 |
 |
 PC
```

SW1 知道：

> “这是 Edge Port。”

因为 PC 不参与 STP，也不会给我提供另一条二层路径。

所以：

```
Edge Port
   ↓
不需要 Proposal/Agreement
   ↓
直接 Forwarding
```

这也是为什么：

```
spanning-tree portfast
```

只能用于连接终端的端口。

---

# 十三、Proposal/Agreement 最核心的逻辑

你可以把整个过程压缩成：

```
       RSTP快速收敛
             │
             ↓
      Designated Port
             │
             │ Proposal
             ↓
        Neighbor
             │
             ↓
      检查其他端口
             │
             ↓
           Sync
             │
             ↓
     其他端口避免环路
             │
             ↓
         Agreement
             │
             ↓
        快速Forwarding
```

---

# 十四、和 STP 做一个真正的对比

### STP

```
发现新链路
   ↓
Listening
   ↓
15s
   ↓
Learning
   ↓
15s
   ↓
Forwarding
```

核心思想：

> **“等。”**

---

### RSTP

```
发现新链路
   ↓
Proposal
   ↓
Sync
   ↓
Agreement
   ↓
Forwarding
```

核心思想：

> **“协商。”**

---

# 十五、还有一个非常关键的细节：不是任何端口都进行 Proposal

一般理解：

> **Designated Port 向邻居发送 Proposal。**

然后邻居：

```
接受 Proposal
 ↓
Sync
 ↓
Agreement
```

所以你可以记：

```
DP
 ↓
Proposal
 ↓
Neighbor
 ↓
Sync
 ↓
Agreement
 ↓
RP Forwarding
```

这条链路是 RSTP 快速收敛的核心。

---

# 十六、你现在应该形成这个 RSTP 思维

你已经懂 STP，所以现在不要再把重点放在：

```
Root Bridge 怎么选
Root Port 怎么选
Designated Port 怎么选
```

而应该重点理解：

```
RSTP
│
├── 每台交换机主动发 BPDU
│
├── Alternate Port
│
├── Edge Port
│
└── Proposal / Agreement ★★★★★
        │
        ├── Proposal
        │
        ├── Sync
        │
        │    └── 其他端口先 Discarding
        │
        └── Agreement
             ↓
          Forwarding
```

**真正的精髓就是：**

> **RSTP 不是通过“更快的 Timer”实现快速收敛，而是通过“先阻止潜在环路 + 邻居之间实时协商”实现快速收敛。**