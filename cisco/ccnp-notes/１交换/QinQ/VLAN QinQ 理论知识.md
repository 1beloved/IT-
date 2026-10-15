QinQ（802.1Q Tunneling）属于比较典型的二层技术。Cisco 官方文档把它定义为 **802.1Q-in-802.1Q**，核心目的就是让运营商网络能够承载客户自己的 VLAN，同时保留客户原来的 VLAN ID。([Cisco](https://www.cisco.com/c/en/us/td/docs/switches/lan/c9000/lyr2-fwd/layer2-tunnels/layer2-tunnels-configuration-guide/c-configure-qinq.html?utm_source=chatgpt.com "Layer2 Tunnels Configuration Guide - Configure QinQ [Cisco IOS XE 17] - Cisco"))

## 1. 先用一句话理解 QinQ

**普通 802.1Q：一层 VLAN Tag。**

```text
Ethernet Frame
┌──────────┬──────────┬──────────┐
│   MAC    │ VLAN Tag │   Data   │
└──────────┴──────────┴──────────┘
              ↑
          Customer VLAN
```

**QinQ：再套一层 VLAN Tag。**

```text
Ethernet Frame
┌──────┬──────────┬──────────┬──────────┐
│ MAC  │ Outer Tag│ Inner Tag│   Data   │
└──────┴──────────┴──────────┴──────────┘
          ↑           ↑
        S-VLAN       C-VLAN
       运营商VLAN    客户VLAN
```

所以你可以直接记：

> **QinQ = VLAN Tag 套 VLAN Tag。**

---

# 2. 为什么需要 QinQ？

假设有两个公司：

```text
客户A
VLAN 10
VLAN 20
VLAN 30

客户B
VLAN 10
VLAN 20
VLAN 30
```

客户 A 和客户 B 都使用 VLAN 10。

如果运营商直接使用客户 VLAN：

```text
Customer A VLAN 10
        ↓
   ISP Network
        ↓
Customer B VLAN 10
```

运营商就很难单纯靠 VLAN ID 区分：

```text
VLAN 10 ← A？
VLAN 10 ← B？
```

而 QinQ 会在外面再加一个 **Service VLAN（S-VLAN）**：

```text
客户A VLAN 10
       ↓
添加 S-VLAN 100
       ↓
[S-VLAN 100][C-VLAN 10]
```

客户 B：

```text
客户B VLAN 10
       ↓
添加 S-VLAN 200
       ↓
[S-VLAN 200][C-VLAN 10]
```

于是：

```text
A：100 / 10
B：200 / 10
```

运营商只需要根据 **Outer VLAN** 区分客户。

---

# 3. C-VLAN 和 S-VLAN 是 CCNP 必须搞懂的

这是考试非常重要的概念。

### C-VLAN

**Customer VLAN**

客户自己的 VLAN。

例如：

```text
VLAN 10
VLAN 20
VLAN 30
```

这些都是 C-VLAN。

---

### S-VLAN

**Service VLAN**

运营商添加的外层 VLAN。

例如：

```text
S-VLAN 100
```

于是数据包：

```text
┌────────────┬────────────┐
│ S-VLAN 100 │ C-VLAN 10  │
└────────────┴────────────┘
       ↑            ↑
    运营商          客户
```

记忆：

> **C = Customer**
> 
> **S = Service**

---

# 4. 最重要的拓扑

你可以把 Cisco QinQ 想成这样：

```text
        Customer A
       VLAN 10/20
           │
           │ Trunk
           ↓
     ┌───────────┐
     │ Cisco PE1 │
     │ QinQ入口  │
     └─────┬─────┘
           │
           │ [S-VLAN 100]
           │ [C-VLAN 10]
           │
      Provider Network
           │
           │
     ┌─────▼─────┐
     │ Cisco PE2 │
     │ QinQ出口  │
     └─────┬─────┘
           │
           │ Trunk
           ↓
        Customer A
       VLAN 10/20
```

客户原来的：

```text
VLAN 10
```

进入运营商网络以后：

```text
S-VLAN 100
C-VLAN 10
```

到了另一端，再把外层的 S-VLAN 去掉：

```text
[S100][C10]
     ↓
   [C10]
```

所以：

> **QinQ 的本质不是修改客户 VLAN，而是在客户 VLAN 外面再套一层 VLAN。**

---

# 5. Cisco 上怎么配置？

这里要特别注意：

Cisco 不同 IOS/IOS XE 平台对 QinQ 的实现方式并不完全一样。

传统 Catalyst 的 **802.1Q Tunnel** 常见配置是：

```text
interface GigabitEthernet1/0/1
 switchport access vlan 100
 switchport mode dot1q-tunnel
```

其中：

```text
switchport mode dot1q-tunnel
```



# 6. 为什么接口叫 Tunnel Port？

这是 Cisco 的一个**很容易考**的点。

普通 trunk：

```text
switchport mode trunk
```

它是：

```text
Trunk
   ↓
携带多个 VLAN
```

而 QinQ tunnel port：

```text
switchport mode dot1q-tunnel
```

它不是普通意义上的 trunk。

Cisco 文档明确指出，**tunnel port 不是 trunk port**；配置成 tunnel port 后，普通 trunk 配置不适用于这个接口。

所以考试看到：

```text
switchport mode dot1q-tunnel
```

马上想到：

> **802.1Q Tunnel / QinQ**

---

# 7. QinQ 数据包到底发生了什么？

这是最重要的部分。

假设客户发送：

```text
VLAN 10
```

进入 PE：

```text
        PE
         │
         ↓
┌─────────────────────┐
│ S-VLAN 100          │
│ C-VLAN 10           │
│ Ethernet Payload    │
└─────────────────────┘
```

原来的：

```text
[C-VLAN 10]
```

变成：

```text
[S-VLAN 100][C-VLAN 10]
```

穿过 Provider Network：

```text
PE1
 │
 │ [100][10]
 ↓
P1
 │
 │ [100][10]
 ↓
P2
 │
 │ [100][10]
 ↓
PE2
```

到出口：

```text
[S100][C10]
      ↓
删除 S100
      ↓
[C10]
```

客户最终收到：

```text
VLAN 10
```

因此：

**客户根本不需要知道运营商内部发生了什么。**

---

# 8. QinQ 最大的价值：VLAN 空间扩展

802.1Q 的 VLAN ID 是：

```text
12 bits
```

所以理论上 VLAN ID 范围是：

```text
0 ~ 4095
```

但并不是所有 ID 都能作为普通用户 VLAN 使用。

如果运营商给每个客户都分配独立 VLAN 范围，很容易出现 VLAN 资源不足的问题。

QinQ 相当于：

```text
S-VLAN × C-VLAN
```

例如：

```text
S-VLAN 100
 ├── C-VLAN 10
 ├── C-VLAN 20
 ├── C-VLAN 30
 └── C-VLAN 40
```

所以：

> **一个 S-VLAN 可以承载一个客户的多个 C-VLAN。**

Cisco 官方也把“扩展 VLAN 空间”和“不同客户可以使用重叠 VLAN ID”作为 QinQ 的重要用途。([Cisco](https://www.cisco.com/c/en/us/td/docs/switches/lan/c9000/lyr2-fwd/layer2-tunnels/layer2-tunnels-configuration-guide/c-configure-qinq.html?utm_source=chatgpt.com "Layer2 Tunnels Configuration Guide - Configure QinQ [Cisco IOS XE 17] - Cisco"))

---

# 9. 一个非常典型的 CCNP 场景

假设：

```text
       Customer A
       VLAN 10
          │
          │
       PE1
          │
     S-VLAN 100
          │
    Provider Network
          │
       PE2
          │
          │
       Customer A
       VLAN 10
```

Customer A 两边都是：

```text
VLAN 10
```

但是运营商内部使用：

```text
S-VLAN 100
```

数据：

```text
进入 PE1：

[C-VLAN 10]

       ↓

[S-VLAN 100][C-VLAN 10]

       ↓

Provider Network

       ↓

[S-VLAN 100][C-VLAN 10]

       ↓

PE2 删除外层 Tag

       ↓

[C-VLAN 10]
```

这就是 QinQ。

---

# 10. QinQ 和 Trunk 的区别

这个你一定要区分。

||Trunk|QinQ|
|---|---|---|
|VLAN Tag|1层|2层|
|主要用途|交换机之间传多个 VLAN|运营商承载客户 VLAN|
|Tag|C-VLAN|S-VLAN + C-VLAN|
|常见命令|`switchport mode trunk`|`switchport mode dot1q-tunnel`|
|客户 VLAN|被网络直接识别|被封装在外层 VLAN 中|

最简单：

```text
Trunk：

[ VLAN 10 ]

QinQ：

[ S-VLAN 100 ][ C-VLAN 10 ]
```

---

# 11. QinQ 和 VLAN Trunking 不要混淆

很多刚学 CCNP 的人会认为：

> “QinQ 就是把 trunk 再 trunk 一下。”

这个理解不准确。

Trunk 的核心是：

> **一条链路携带多个 VLAN。**

QinQ 的核心是：

> **给已经带 VLAN Tag 的客户帧，再增加一个外层 VLAN Tag。**

所以：

```text
Trunk
= 携带多个 VLAN

QinQ
= VLAN-in-VLAN
```

---

# 12. CCNP 还要注意一个坑：MTU

因为原来：

```text
Ethernet
+ 1个 VLAN Tag
```

现在：

```text
Ethernet
+ S-VLAN
+ C-VLAN
```

帧变大了。

QinQ 是两层 Tag：

```
┌──────────────┬──────────────┐
│  S-VLAN Tag  │  C-VLAN Tag  │
│    12 bit    │    12 bit    │
└──────────────┴──────────────┘
```

因此从**理论组合空间**来说：

4096×4096=16,777,216

所以 QinQ 环境需要注意 **MTU**。Cisco 的配置指南也特别提醒了 QinQ 配置时需要考虑 MTU。([Cisco](https://www.cisco.com/c/en/us/td/docs/ios-xml/ios/layer2/configuration/xe-16-12/layer2-tunneling-config-book/layer2-config-16-12-book_chapter_00.html?utm_source=chatgpt.com "Layer 2 Protocol and 802.1Q Tunneling Guide - Configuring IEEE 802.1Q Tunneling [Cisco IOS XE 17] - Cisco"))

你可以简单记：

> **QinQ = 多加一个 4-byte VLAN Tag → 帧变大 → 注意 MTU。**

---

# 13. QinQ 还有一个容易考的东西：L2 Protocol Tunneling

如果客户两端希望自己的二层协议跨过运营商网络，例如：

```text
STP
CDP
VTP
```

Cisco 还提供 **Layer 2 Protocol Tunneling（L2PT）**。

例如：

```text
l2protocol-tunnel stp
```

它和 QinQ 是相关但不同的概念：

```text
QinQ
↓
解决 VLAN Tag 的封装

L2PT
↓
解决二层协议报文穿越运营商网络
```

Cisco 文档也将 QinQ 与 L2PT 分开描述。([Cisco](https://www.cisco.com/c/en/us/td/docs/routers/access/ISRG2/software/feature/guide/QinQ_L2PT.html?utm_source=chatgpt.com "IEEE 802.1Q Tunneling (QinQ) and L2PT on L2 - Cisco"))

---

# 14. 你现在学 CCNP，我建议你这样记

把 QinQ 压缩成 **6句话**：

### ① QinQ 是什么？

> **802.1Q-in-802.1Q**

### ② 干什么？

> **运营商承载客户 VLAN。**

### ③ 怎么实现？

> **给客户 VLAN 再增加一个外层 VLAN Tag。**

### ④ 内层叫什么？

> **C-VLAN / Customer VLAN**

### ⑤ 外层叫什么？

> **S-VLAN / Service VLAN**

### ⑥ Cisco 传统 802.1Q Tunnel 关键命令？

```text
switchport mode dot1q-tunnel
```

---

## 最后给你一张脑图

```text
                         QinQ
                           │
             ┌─────────────┴─────────────┐
             │                           │
          C-VLAN                      S-VLAN
       Customer VLAN               Service VLAN
             │                           │
             │                           │
          内层Tag                      外层Tag
             │                           │
             └──────────┬────────────────┘
                        ↓
                 [S-VLAN][C-VLAN]
                        │
                        ↓
                 Provider Network
                        │
                        ↓
                 [S-VLAN][C-VLAN]
                        │
                  去掉外层Tag
                        ↓
                    [C-VLAN]
```

**你下一步最好学的不是马上背命令，而是把 QinQ 和 `802.1Q Trunk → Access → Dot1Q Tunnel → L2PT` 串起来。** 这几个放在一起理解，CCNP 二层部分会清晰很多。


