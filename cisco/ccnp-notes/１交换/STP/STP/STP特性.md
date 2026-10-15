可以。你现在已经把 **STP → RSTP → MST → 多 Region → MST 与 RSTP 混合**串起来了，接下来学 **STP 特性（STP Features）**就很合适。

CCNP 里常见的 STP 特性，重点不是死记命令，而是理解它们**解决什么问题、作用在哪个端口、会不会影响 STP 选举**。

我建议你重点掌握这几个：

```text
STP Features
│
├── PortFast
├── BPDU Guard
├── BPDU Filter
├── Root Guard
├── Loop Guard
├── UDLD
├── EtherChannel + STP
└── TCN / Topology Change
```

---

# 1. PortFast

### 解决什么问题？

普通 STP 端口需要经历：

```text
Blocking
   ↓
Listening
   ↓
Learning
   ↓
Forwarding
```

所以 PC 插上交换机以后，可能需要一段时间才能真正转发。

但是接入用户的 PC：

```text
PC ─── Switch
```

通常不会产生二层环路。

所以可以让端口：

> **直接进入 Forwarding。**

这就是：

```cisco
spanning-tree portfast
```

---

## PortFast 应该用在哪里？

**只应该用在连接终端设备的端口。也就是边缘端口**
1.EP不参与生成树的计算，也不会因为生成树拓扑的变更而变更
2.EP跳过30秒的计算转发延迟，直接进入转发状态
3.EP也是可以发送BPDU防环
例如：

```text
PC
 │
 │
SW1
```

：

```cisco
interface g0/1
 spanning-tree portfast
```

不要随便在：

```text
SW1 ─── SW2
```

这种交换机之间的链路上开 PortFast。

---

# 2. BPDU Guard

这个和 PortFast 经常一起考。

逻辑是：

```text
PC
 │
 │
SW1
```

SW1 认为：

> 这个接口应该只接终端。

但是有人把交换机接进来了：

```text
        SW2
         │
         │ BPDU
         ↓
PC ─── SW1
```

SW1 收到了 BPDU。

这时候 BPDU Guard 可以：

> **把端口直接置为 err-disabled。** 那么端口直接被禁用

配置：

```cisco
interface g0/1
 spanning-tree portfast
 spanning-tree bpduguard enable
```

或者全局：

```cisco
spanning-tree portfast bpduguard default
```

---

## 一句话记忆

> **PortFast：让端口快速 Forwarding。**

> **BPDU Guard：PortFast 端口收到 BPDU → 把端口关掉。**

---

# 3. BPDU Filter

这个和 BPDU Guard **千万不要混**。

BPDU Guard：

```text
收到 BPDU
   ↓
关闭端口
```

BPDU Filter：

```text
BPDU
 ↓
过滤掉
```

也就是说：

> **BPDU Filter 是过滤 BPDU。**

例如：

```cisco
interface g0/1
 spanning-tree bpdufilter enable
```

但是这个功能要非常谨慎。

因为 STP 的基础就是 BPDU。

你把 BPDU 过滤掉：

```text
BPDU 不传播
   ↓
STP 无法正常感知拓扑
```

所以可能造成环路。

---

# 4. BPDU Guard vs BPDU Filter

这个是考试高频对比：

|特性|BPDU Guard|BPDU Filter|
|---|---|---|
|收到 BPDU|处理|过滤|
|端口状态|Err-disabled|不一定|
|目的|防止非法交换机接入|不让 BPDU 传播|
|安全性|较安全|风险较高|

记：

> **Guard = 收到就“抓住”并关闭。**

> **Filter = 直接把 BPDU“过滤掉”。**

---

# 5. Root Guard

这个特别重要。

假设：

```text
             SW1
          Root Bridge
             │
             │
            SW2
             │
             │
            SW3
```

你希望：

```text
SW1 永远是 Root
```

但是有人接了一个优先级更低的交换机：

```text
SW1
 │
SW2
 │
SW4
 │
New Switch
```

New Switch：

```text
Bridge Priority = 0
```

它可能通过 BPDU 宣布：

> “我才是 Root！”

---

## Root Guard 做什么？

在 SW2 的接口上：

```cisco
interface g0/1
 spanning-tree guard root
```

如果这个端口收到**更优的 BPDU**，说明下游设备想成为 Root。

Root Guard：

> **把该端口置于 root-inconsistent 状态。**

也就是：

```text
收到 superior BPDU
        ↓
Root Guard
        ↓
root-inconsistent
        ↓
停止转发
```

等异常 BPDU 消失：

> **端口可以自动恢复。**

---

# 6. Root Guard 应该放在哪里？

非常重要：

> **Root Guard 应该放在你“不希望它成为 Root 的方向”。**

例如：

```text
        Core
      Root Bridge
          │
          │
       Distribution
          │
          │
        Access
```

你希望 Core 永远是 Root。

那么可以在：

```text
Distribution → Access
```

方向使用 Root Guard。

意思：

> Access 层，你别想通过这个接口影响 Root。

---

# 7. Loop Guard

这个解决的问题和 Root Guard 不一样。

它主要防止：

> **单向链路故障导致 STP 出现环路。**

例如：

```text
SW1 ───────── SW2
  \            /
   \          /
    ─────────
```

正常情况下：

```text
一个 DP
一个 Alternate
```

Alternate 处于：

```text
Discarding
```

但是如果由于单向链路故障：

```text
SW2 收不到 BPDU
```

SW2 可能认为：

> “对面是不是已经没有 STP 了？”

然后原本阻塞的端口可能重新参与转发。

于是可能：

```text
原本的 Alternate
       ↓
变成 Forwarding
       ↓
形成环路
```

---

## Loop Guard

配置：

```cisco
interface g0/1
 spanning-tree guard loop
```

如果一个本来应该持续收到 BPDU 的端口突然收不到 BPDU：

> **Loop Guard 不让它错误地进入 Forwarding。**

它会进入：

```text
loop-inconsistent
```

---

# 8. Root Guard vs Loop Guard

这个非常重要：

||Root Guard|Loop Guard|
|---|---|---|
|防什么|非法 Root|单向链路导致环路|
|触发条件|收到 Superior BPDU|BPDU 消失|
|状态|root-inconsistent|loop-inconsistent|
|核心思想|不准你当 Root|不准阻塞端口误转发|

你可以这样记：

> **Root Guard：BPDU 太好了 → 不允许。**

> **Loop Guard：BPDU 不见了 → 小心，不要 Forwarding。**

---

# 9. UDLD

这个严格来说不是 STP 特性本身，但 CCNP 经常和 STP 放一起考。

UDLD：

> **Unidirectional Link Detection**

也就是：

> **检测单向链路。**

例如：

```text
SW1 ───────── SW2
 ↑             ↓
正常发送       无法接收
```

链路物理上可能显示：

```text
up/up
```

但实际上：

```text
SW1 → SW2  OK
SW2 → SW1  FAIL
```

这就是：

> **单向链路。**

UDLD 可以检测这种问题。

---

# 10. UDLD 和 Loop Guard 什么关系？

两者经常一起理解。

```text
UDLD
 ↓
检测单向链路
```

而：

```text
Loop Guard
 ↓
防止 STP 因 BPDU 丢失而错误恢复 Forwarding
```

所以：

> **UDLD 是检测链路问题，Loop Guard 是保护 STP 状态。**

---

# 11. EtherChannel 和 STP

这个也非常重要。

例如你有：

```text
SW1
 │
 ├──── G0/1 ──── SW2
 │
 └──── G0/2 ──── SW2
```

如果不做 EtherChannel：

STP 会认为：

```text
两条独立链路
```

所以可能：

```text
G0/1 → Forwarding
G0/2 → Blocking
```

浪费了一条链路。

---

如果配置 EtherChannel：

```text
SW1
 ║
 ║ Port-Channel
 ║
SW2
```

STP 看到的是：

> **一个逻辑端口。**

所以：

```text
STP
 ↓
Port-Channel
 ↓
Forwarding
```

而内部：

```text
G0/1
G0/2
G0/3
G0/4
```

共同承担流量。

---

# 12. TCN

最后这个和你之前问过的：

> **PVST 的 TCN**

有直接关系。

TCN：

> **Topology Change Notification**

当网络拓扑发生变化时，STP 需要通知 Root。

例如：

```text
SW1 ─── SW2 ─── PC
```

PC 接口：

```text
down
```

可能导致拓扑变化。

交换机可以产生：

```text
TCN BPDU
```

通知 Root。

然后网络中的交换机会进行相应的 MAC 地址老化处理，使旧的 MAC 表项更快失效。

---

# 13. 你现在把这些特性放在一张图里

```text
                    Core
                 Root Bridge
                    │
              Root Guard
                    │
             Distribution
               /       \
              /         \
         Loop Guard    Loop Guard
            /             \
        Access           Access
          │                 │
     PortFast           PortFast
     BPDU Guard         BPDU Guard
          │                 │
         PC                PC
```

旁边还有：

```text
UDLD
 ↓
检测单向链路

EtherChannel
 ↓
多个物理链路
 ↓
一个逻辑 Port-Channel

TCN
 ↓
拓扑变化通知
```

---

# 14. CCNP 最重要的“看到关键词就选谁”

|题目关键词|想到|
|---|---|
|接入口、PC、终端|**PortFast**|
|PortFast 收到 BPDU|**BPDU Guard**|
|过滤 BPDU|**BPDU Filter**|
|防止下游成为 Root|**Root Guard**|
|Superior BPDU|**Root Guard**|
|BPDU 突然消失|**Loop Guard**|
|单向链路|**UDLD**|
|多条链路当一条逻辑链路|**EtherChannel**|
|拓扑发生变化|**TCN**|

### 最容易混淆的三个：

```text
BPDU Guard
收到 BPDU → Err-disabled

Root Guard
收到 Superior BPDU → Root-inconsistent

Loop Guard
收不到 BPDU → Loop-inconsistent
```

这三个你一定要分清。尤其是 **Root Guard 和 Loop Guard**，CCNP 很喜欢拿它们放在一起考。