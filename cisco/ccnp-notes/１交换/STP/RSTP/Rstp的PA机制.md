
先给你一句最重要的结论：PA机制发生在DP和RP之间

> **RSTP 的快速收敛核心：Proposal / Agreement（PA）机制。**  
> **传统 STP/PVST+ 的拓扑变化核心：TCN BPDU + TCA。**

你可以先把两者理解成：

```text
传统 STP / PVST+
“我发现拓扑变了 → 发 TCN → Root 再通知全网 → 大家刷新 MAC”

RSTP
“我想把这个端口变成 Forwarding → Proposal
你确认没问题 → Agreement
马上 Forwarding”
```

下面详细拆开。

---

# 一、先搞清楚：为什么 RSTP 要有 PA？

传统 STP 的问题是：

```text
Blocking
   ↓
Listening
   ↓
Learning
   ↓
Forwarding
```

默认每个状态大约：

```text
Listening  15s
Learning   15s
```

所以发生拓扑变化时，可能需要几十秒才能恢复。

RSTP 的目标就是：

> **不再傻等 Forward Delay，而是通过交换 BPDU 直接协商端口能不能立即进入 Forwarding。**

这就是：

**Proposal / Agreement**

简称：

> **PA机制**

---

# 二、Proposal / Agreement 到底是什么？

我们假设：

```
SW1 = Root Bridge

        SW1
         |
       G0/1
         |
       SW2
```

SW2 的 G0/1 是连接 Root 的端口。

RSTP 工作的时候，SW1 会通过 BPDU 告诉 SW2：

> “我是 Root，我提议你把这个端口作为我的下游路径。”

这就是：

### Proposal

可以简单理解成：

> **“你准备好了吗？我们可以让这个端口 Forwarding 吗？”**

---

# 三、Agreement 是什么？

SW2 收到 Proposal 后，并不是直接 Forwarding。

它首先要做一个非常重要的动作：

> **把自己的其他非边缘端口临时置于 Discarding。**

为什么？

为了避免形成 Layer 2 loop。

例如：

```text
        SW1
       /   \
      /     \
    SW2-----SW3
```

如果 SW1 说：

> “SW2，你 Forwarding。”

但 SW2 和 SW3 之间又同时 Forwarding：

```text
SW1
 ↓
SW2 → SW3
 ↑       ↓
 └───────┘
```

就可能形成环路。

所以 SW2 要先确保：

> **其他可能造成环路的端口已经安全。**

然后 SW2 给 SW1 回复：

### Agreement

意思就是：

> **“可以，我确认安全，可以让你的端口进入 Forwarding。”**

于是：

```text
Proposal
    ↓
检查/同步
    ↓
Agreement
    ↓
Forwarding
```

这就是 RSTP 快速收敛的核心。

---

# 四、为什么叫 Proposal / Agreement？

你可以把它理解成：

```text
SW1：

“Proposal：
我想让你这个端口 Forwarding。”

        ↓

SW2：

“先把可能产生环路的端口处理好。”

        ↓

SW2：

“Agreement：
OK，安全了。”

        ↓

SW1：

Forwarding
```

所以：

> **Proposal = 提议**

> **Agreement = 同意**

---

# 五、RSTP PA机制最重要的考试点

### ① PA主要发生在哪种端口？

重点：

> **Point-to-Point 链路**

通常就是：

```text
Switch ───── Switch
```

例如：

```text
Gi0/1 ───── Gi0/1
```

全双工 Ethernet 通常被 RSTP 认为是 point-to-point。

---

# 六、RSTP为什么能这么快？

因为它不需要：

```text
等待 15 秒 Listening
等待 15 秒 Learning
```

而是：

```text
Proposal
   ↓
Agreement
   ↓
Forwarding
```

所以：

> **RSTP 用握手机制代替传统 STP 的长时间计时。**

这句话你可以直接记。

---

# 七、但是！RSTP不是什么情况都用PA

这是 CCNP 容易考的地方。

RSTP 的快速收敛主要针对：

> **Point-to-Point 链路**

而不是所有拓扑变化都靠 Proposal / Agreement。

比如：

```text
Switch ─── Hub
```

这种共享介质环境就不是典型的 point-to-point。

所以你看到题目：

> Which mechanism allows RSTP to rapidly transition a port to forwarding?

答案通常就是：

> **Proposal and Agreement**

---

# 八、现在讲传统 PVST+ 的 TCN

这个和 PA 完全是两个概念。

传统：

```text
STP / PVST+
IEEE 802.1D
```

发生拓扑变化的时候，有一个：

> **TCN = Topology Change Notification**

注意：

### TCN不是普通的 TC BPDU。

这是很多人容易混淆的地方。

---

# 九、什么时候发送 TCN？

假设：

```text
        SW1
       Root
       /   \
     SW2   SW3
```

假设 SW2 的某个端口发生拓扑变化。

例如：

```text
Port Up
Port Down
```

满足相应条件后，SW2 会向 Root 方向发送：

> **TCN BPDU**

意思：

> “Root，我这里发生拓扑变化了。”

---

# 十、TCN怎么传到Root？

例如：

```text
SW2
 ↓
SW1
```

SW2：

```text
TCN BPDU
   ↓
发送给 Root
```

Root 收到以后：

> Root 会确认收到 TCN。

这个确认叫：

### TCA

Topology Change Acknowledgment。

---

# 十一、Root收到TCN之后干什么？

这是传统 STP 的关键。

Root 会产生：

> **TC Flag**

也就是在普通 Configuration BPDU 中设置：

### TC = 1

然后把这个信息传播给整个 STP 域。

于是：

```text
SW2
 │
 │ TCN
 ↓
Root
 │
 │ TC BPDU
 ↓
所有交换机
```

所有交换机收到 TC 后：

> **缩短 MAC address aging time**

传统 STP 默认 MAC aging：

```text
300 seconds
```

收到 TC 后，会暂时缩短到：

```text
Forward Delay
```

通常：

```text
15 seconds
```

目的就是：

> **让旧的 MAC 地址快速老化，交换机重新学习新的 MAC → Port 映射。**

---

# 十二、为什么拓扑变化要刷新MAC？

举个非常重要的例子。

原来：

```text
PC-A
 |
SW1
 |
SW2
```

SW2 学到：

```text
MAC-A → Gi0/1
```

现在网络拓扑发生变化：

```text
PC-A
 |
SW1
 |
SW3
```

但是 SW2 还记得：

```text
MAC-A → Gi0/1
```

这时候数据来了：

```text
MAC-A
```

SW2 可能还会按照旧信息：

```text
→ Gi0/1
```

所以需要让旧的 MAC entry 尽快过期。

这就是 TCN 的意义之一：

> **让交换机快速清理可能过时的 MAC 学习信息。**

---

# 十三、TCN机制整个过程

你把这个流程背下来：

```text
拓扑发生变化
      ↓
非Root交换机
      ↓
发送 TCN BPDU
      ↓
Root Bridge
      ↓
TCA确认
      ↓
Root设置 TC Flag
      ↓
TC BPDU传播
      ↓
交换机缩短 MAC aging
      ↓
重新学习 MAC
```

---

# 十四、PA vs TCN：本质区别

这个是你真正应该掌握的。

||RSTP PA|PVST+ TCN|
|---|---|---|
|核心|Proposal / Agreement|TCN / TCA|
|主要目的|**快速建立 Forwarding**|**通知拓扑发生变化**|
|关注点|端口状态转换|MAC地址重新学习|
|是否用于快速收敛|⭐⭐⭐⭐⭐|⭐⭐|
|是否需要 Root参与|不一定依赖传统 TCN流程|**需要向 Root 通知**|
|机制|握手|通知|
|典型协议|RSTP|STP/PVST+|
|核心思想|“能不能马上 Forwarding？”|“网络拓扑变了！”|

---

# 十五、最容易混淆的一点

你千万不要认为：

> **RSTP没有TC。**

不是。

RSTP **也有拓扑变化处理机制**。

只是：

> **RSTP不再使用传统802.1D那种 TCN → Root → TC传播 的方式作为核心机制。**

RSTP使用自己的 TC 处理方式。

所以：

```text
传统 STP：

Topology Change
      ↓
TCN
      ↓
Root
      ↓
TC Flag
      ↓
全网
```

而：

```text
RSTP：

Topology Change
      ↓
直接快速传播 TC 信息
      ↓
相关交换机快速处理
```

所以不要简单记成：

> RSTP = 没有 TC

这是错的。

---

# 十六、RSTP里面还有一个非常重要的TC机制

RSTP BPDU 本身就带有：

> **TC flag**

RSTP 在发现拓扑变化后，可以让交换机快速通知邻居。

例如：

```text
SW1 ─── SW2 ─── SW3
```

SW2发现拓扑变化：

```text
SW2
 ↓
发送 TC BPDU
 ↓
SW1 / SW3
```

邻居收到以后：

> 清除/快速老化相关 MAC entries。

所以它不需要像传统 STP 一样：

```text
TCN
 ↓
Root
 ↓
TC
 ↓
全网
```

这也是 RSTP 更快的原因之一。

---

# 十七、PA和TCN不要混为一谈

这是我建议你建立的一个思维框架：

```text
                    RSTP/STP
                       │
          ┌────────────┴────────────┐
          ↓                         ↓
    建立端口状态                发生拓扑变化
          │                         │
          ↓                         ↓
       “我要不要                 “拓扑变了，
        Forwarding？”             怎么通知？”
          │                         │
          ↓                         ↓
     RSTP PA机制                 TC机制
          │
    ┌─────┴─────┐
    ↓           ↓
Proposal     Agreement
```

而传统 STP：

```text
拓扑变化
   ↓
TCN
   ↓
TCA
   ↓
Root
   ↓
TC Flag
   ↓
MAC aging缩短
```

---

# 十八、CCNP考试最容易出现的几个陷阱

### 陷阱1

> RSTP使用TCN BPDU来通知拓扑变化。

❌ **错误**

RSTP不使用传统802.1D意义上的 TCN BPDU。

---

### 陷阱2

> Proposal/Agreement用于通知MAC地址表发生变化。

❌ **错误**

PA主要用于：

> **快速端口状态转换 / 快速收敛。**

---

### 陷阱3

> TCN的主要作用是让端口快速进入Forwarding。

❌ **错误**

TCN：

> **通知拓扑变化。**

---

### 陷阱4

> Agreement表示拓扑发生变化。

❌ **错误**

Agreement：

> **表示接受 Proposal，并允许快速进入 Forwarding。**

---

### 陷阱5

> RSTP通过取消Forward Delay来实现快速收敛。

❌ 不准确。

RSTP仍然有 Forward Delay 这个定时器。

真正的核心是：

> **Proposal/Agreement + 快速拓扑变化处理 + 新的端口角色/状态机制。**

---

# 十九、你可以这样死记

如果考试给你：

### **Proposal**

马上想到：

> **RSTP → PA → 快速进入 Forwarding**

---

### **Agreement**

马上想到：

> **RSTP → 接受 Proposal → 安全 → Forwarding**

---

### **TCN**

马上想到：

> **802.1D / PVST+ → Topology Change Notification → 告诉 Root**

---

### **TCA**

马上想到：

> **Topology Change Acknowledgment → Root确认收到TCN**

---

### **TC Flag**

马上想到：

> **拓扑变化传播 → 缩短 MAC Aging → 快速重新学习 MAC**

---

## 最后给你一张 CCNP 速记图

```text
              STP
               │
      ┌────────┴────────┐
      │                 │
   建立路径           拓扑变化
      │                 │
      │                 │
      ↓                 ↓
   端口状态           通知变化
      │                 │
      │                 │
 ┌────┴────┐       ┌────┴────┐
 │         │       │         │
STP      RSTP     STP       RSTP
 │         │       │         │
等待      PA      TCN       快速TC处理
 │         │       │
Listening  │       TCA
Learning   │       │
Forwarding │       TC Flag
           │       │
           ↓       ↓
      快速Forwarding  MAC快速老化
```

**一句话区分：**

> **PA解决“端口怎么快速 Forwarding”；TCN解决“拓扑变了，怎么通知并让MAC快速重新学习”。**

另外，你现在学到这里，下一步非常值得把 **RSTP 的 4种 Port Role（Root / Designated / Alternate / Backup）+ 3种 Port State（Discarding / Learning / Forwarding）+ PA发生过程** 连起来。这个一旦搞懂，RSTP 的题基本就从“背命令”变成“看拓扑推答案”。