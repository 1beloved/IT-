可以。**Root Guard 是 STP 里非常重要的“防止 Root Bridge 被别人抢走”的保护机制**。你刚刚学完 BPDU Guard，正好可以把两者放在一起理解。

---

# 一、Root Guard 是干什么的？

一句话：

> **Root Guard 防止某个端口方向上的交换机成为新的 Root Bridge。**

例如：

```text
              SW1
           Root Bridge
            /      \
           /        \
         SW2        SW3
```

假设我们规定：

> SW1 永远应该是 Root。

但是有一天，SW2 下面接入了一台新的交换机 SW4：

```text
              SW1
             Root
            /    \
          SW2    SW3
           |
          SW4
```

如果 SW4 的 Bridge ID 比 SW1 更优秀，它可能发送更优 BPDU：

```text
SW4 → SW2
       "我这里有更好的 Root"
```

正常情况下，SW2 可能接受这个更优 BPDU，然后整个 STP 拓扑重新选举 Root。

这时候就可能出现：

```text
SW4
 ↓
成为 Root
 ↓
整个网络 STP 拓扑改变
```

这不是我们想要的。

所以在 SW2 面向 SW4 的接口上配置：

```text
interface Gi0/1
 spanning-tree guard root
```

这就是 **Root Guard**。

---

# 二、Root Guard 的核心机制

这是 CCNP 很喜欢考的地方。

假设：

```text
             SW1
           Root
             |
             |
            SW2
             |
             |
            SW4
```

SW2：

```text
interface Gi0/1
 spanning-tree guard root
```

Gi0/1 是连接 SW4 的端口。

正常情况下：

```text
SW1 → SW2
发送正常 BPDU
```

SW2 会正常工作。

但是如果 SW4 开始发送：

> **Superior BPDU（更优 BPDU）**

SW2 发现：

```text
"你怎么想当 Root？"
```

于是 Root Guard 触发。

---

# 三、触发之后端口变成什么？

这里一定要记住：

> **Root Guard 触发后，端口进入 `root-inconsistent` 状态。**

不是 err-disabled。

这是考试重点。

```text
Superior BPDU
      ↓
Root Guard
      ↓
root-inconsistent
      ↓
不转发数据
```

可以理解成：

> **“我暂时把你这个方向封掉，你不能通过这个端口影响 Root Bridge。”**

---

# 四、它什么时候恢复？

这是 Root Guard 很漂亮的一个机制。

假设 SW4 后来不再发送 Superior BPDU。

那么：

```text
Superior BPDU 消失
        ↓
Root Guard 条件消失
        ↓
端口自动恢复
```

**不需要 `shutdown/no shutdown`。**

这一点和你刚才的 **BPDU Guard** 是非常重要的区别。

---

# 五、Root Guard 和 BPDU Guard 的区别

这个表你建议直接记下来：

| 特性      | Root Guard                 | BPDU Guard                       |
| ------- | -------------------------- | -------------------------------- |
| 主要目的    | 防止别人抢 Root                 | 防止 PortFast 端口收到 BPDU            |
| 保护对象    | Root Bridge                | Edge/PortFast 端口                 |
| 收到 BPDU | 可以                         | 收到就触发                            |
| 特别关注    | **Superior BPDU**          | **任何 BPDU**                      |
| 触发状态    | **root-inconsistent**      | **err-disabled**                 |
| 自动恢复    | ✅ Superior BPDU消失后         | ❌ 默认不会                           |
| 典型应用    | 交换机之间的特定方向                 | 用户接入口                            |
| 命令      | `spanning-tree guard root` | `spanning-tree bpduguard enable` |

---

# 六、最容易混淆的：Root Guard vs Loop Guard

这两个名字很像，但目的完全不同。

### Root Guard

解决：

> **别人不要抢我的 Root。**

```text
Superior BPDU
       ↓
Root Guard
       ↓
root-inconsistent
```

### Loop Guard

解决：

> **BPDU 突然收不到了，不要错误地把端口放进 Forwarding，造成环路。**

例如：

```text
SW1 ───── SW2
```

本来 SW2 从 SW1 收 BPDU。

突然由于**单向链路故障**：

```text
SW1 → SW2   ❌ BPDU收不到
SW2 → SW1   ✅
```

SW2 可能误以为自己可以 Forwarding。

Loop Guard 可以把端口保持在：

```text
loop-inconsistent
```

所以：

> **Root Guard 防“抢 Root”**
> 
> **Loop Guard 防“BPDU 丢失导致环路”**
> ![[Pasted image 20260907144256.png]]

---

# 七、Root Guard 应该配置在哪里？

这是实际网络设计里非常重要的一点。

例如：

```text
                    Core
                  SW1 Root
                 /        \
                /          \
             SW2            SW3
              |
              |
           Access
```

如果你明确规定：

> Core 永远是 Root，Access 层不能影响 Core。

那么可以在**靠近 Access、朝向 Access 的端口**配置 Root Guard。

例如：

```text
SW2(config)# interface Gi0/10
SW2(config-if)# spanning-tree guard root
```

逻辑是：

```text
Core
 ↓
SW2
 ↓
Root Guard
 ↓
Access
```

如果 Access 交换机突然发送 Superior BPDU：

```text
Access
   ↓
Superior BPDU
   ↓
Root Guard
   ↓
SW2 Gi0/10
   ↓
root-inconsistent
```

这样 Access 就不能影响整个 STP Domain 的 Root。

---

# 八、一个非常关键的考试陷阱

你看到：

> **Root Guard**

不要理解成：

> “这个端口不能成为 Root Port。”

不完全是这么说。

更准确地说：

> **Root Guard 防止该端口通过接收到 Superior BPDU，使本交换机/网络朝新的 Root Bridge 方向收敛。**

触发后端口进入：

```text
root-inconsistent
```

---

# 九、把四个 STP Guard 一次性串起来

你现在学到这里，可以形成一个很完整的框架：

```text
                STP Protection
                      │
        ┌─────────────┼─────────────┐
        │             │             │
   BPDU Guard     Root Guard    Loop Guard
        │             │             │
   防止收到BPDU    防止抢Root      防止BPDU丢失
        │             │             │
 err-disabled   root-inconsistent  loop-inconsistent
```

另外还有一个 **UDLD**，主要处理：

> **单向链路故障**

所以 CCNP 里看到这些词，你脑子里应该马上对应：

```text
BPDU Guard
→ Edge/PortFast
→ 收到BPDU
→ err-disabled

Root Guard
→ 防止Superior BPDU
→ root-inconsistent

Loop Guard
→ BPDU停止接收
->角色改变但是端口状态不变
→ loop-inconsistent

UDLD
→ 单向链路
→ 防止单向通信造成问题
```

### ⭐ 最重要的三句话

**BPDU Guard：**

> “用户口不应该收到 BPDU，收到了就关掉。”

**Root Guard：**

> “这个方向不能出现新的 Root，出现 Superior BPDU 就把端口放进 root-inconsistent。”

**Loop Guard：**

> “原来能收到 BPDU，现在突然收不到了，我先别贸然 Forwarding，防止环路。”

这三个你如果能彻底区分，STP Protection 这一块基本就很稳了。