
## 1. STP 是什么

- **全称**：Spanning Tree Protocol（生成树协议），核心算法 STA。
- **目标**：二层网络保留冗余链路，逻辑上阻塞部分端口，形成**无环树**；主路径故障后重新计算，启用备用路径。
- **标准**：传统 STP 源自 IEEE 802.1D（现并入 802.1Q）；Cisco 扩展为 **PVST+**（每 VLAN 一个实例）。
- **对比**：EtherChannel 解决“多条物理链路当一条逻辑链路用”；STP 解决“二层冗余如何防环”。

**为什么需要**：二层没有 TTL，环路会导致广播风暴、未知单播风暴、组播异常扩散、MAC 表震荡、重复帧、CPU 打满。

## 2. BPDU

BPDU（Bridge Protocol Data Unit）携带：当前认为的 Root、本机 Bridge ID、到 Root 的 Cost、发送端口 Port ID、Timer、拓扑变化信息。

|   |   |   |   |
|---|---|---|---|
|类型|Type 值|方向|作用|
|Configuration BPDU|0x00|从 Root 向下游扩散|维护拓扑、传递 Root 信息|
|TCN BPDU|0x80|从变化处沿 Root Port 向 Root 发送|通知拓扑变化|

**封装**：目的 MAC `01:80:c2:00:00:00`（桥协议保留组播，不会被普通交换机泛洪）；LLC DSAP/SSAP = 0x42，Control = 0x03。

**Configuration BPDU 关键字段**

| 字段                           | 长度    | 含义                                |
| ---------------------------- | ----- | --------------------------------- |
| Protocol ID / Version / Type | 2/1/1 | 传统 STP 为 0x0000 / 0x00 / 0x00     |
| Flags                        | 1     | 传统 STP 只用 TC（bit0）和 TCA（bit7）     |
| Root ID                      | 8     | 我认为谁是根桥                           |
| Root Path Cost               | 4     | 发送者到根桥的开销                         |
| Bridge ID                    | 8     | 我是谁                               |
| Port ID                      | 2     | 我从哪个端口发出                          |
| Message Age / Max Age        | 2/2   | 信息已传播时间 / 最大有效时间                  |
| Hello Time / Forward Delay   | 2/2   | BPDU 周期 / Listening、Learning 等待时间 |

> RSTP 能更快收敛，原因之一就是用 Flags 表示端口角色、Proposal、Agreement 等；传统 STP 没有。

### TCN 传播流程

1. 非根交换机在非边缘端口检测到拓扑变化。
2. 从 Root Port 向上游发 TCN BPDU。
3. 上游用带 **TCA** 的 Configuration BPDU 确认。
4. 上游继续向 Root 方向发 TCN。
5. Root 收到后，在后续 Configuration BPDU 中置 **TC** 标志。
6. 下游看到 TC 后缩短 MAC 老化时间。

注意：TCN **不是直接清空 MAC 表**，而是把老化时间临时缩短为 Forward Delay（常见 15 秒）。

## 3. 端口角色

|                 |          |            |     |                     |
| --------------- | -------- | ---------- | --- | ------------------- |
| 角色              | Cisco 显示 | 位置         | 转发  | 说明                  |
| Root Port       | Root     | 非根交换机      | 是   | 到根桥的最佳路径            |
| Designated Port | Desg     | 每个网段       | 是   | 该网段的代表端口            |
| Alternate Port  | Altn     | 冗余路径       | 否   | 经其他交换机到根的备用路径       |
| Backup Port     | Back     | 本机两端口接同一网段 | 否   | 本机另一端口已是 Designated |

要点：

- **根桥没有 Root Port**，其转发端口通常都是 Designated Port。
- 每台非根交换机只有 **1 个** Root Port；每个网段只有 **1 个** Designated Port。
- **Blocking 是端口状态，不是角色**；Cisco 输出中阻塞端口显示为 Altn 或 Back。
- Alternate vs Backup：Alternate 通过**其他交换机**仍能到根；Backup 是**本交换机自己**的另一个端口已在同一网段承担 DP。
- PortFast/Edge Port 是端口类型，Root Guard/Loop Guard 是保护特性，Master Port 属于 MST 语境，都不是 STP 角色。

## 4. 端口状态

|            |        |        |       |      |
| ---------- | ------ | ------ | ----- | ---- |
| 状态         | 收 BPDU | 发 BPDU | 学 MAC | 转发数据 |
| Disabled   | 否      | 否      | 否     | 否    |
| Blocking   | 是      | 否/受限   | 否     | 否    |
| Listening  | 是      | 是      | 否     | 否    |
| Learning   | 是      | 是      | 是     | 否    |
| Forwarding | 是      | 是      | 是     | 是    |

变化过程：Blocking → Listening（15s）→ Learning（15s）→ Forwarding。传统 STP 收敛慢，因为依赖 Timer 而不是 Proposal/Agreement 握手。

## 5. Path Cost、Bridge ID、Port ID

**短路径成本（传统值）**：10M = 100，100M = 19，1G = 4，10G = 2。现代平台可能用 long path cost，数值不同，原则不变：总 Cost 最小者优。

**Root Path Cost 累加规则**：

```
本交换机到 Root 的 Cost = 收到的 BPDU 中的 Root Path Cost + 本地接收端口的 Port Cost
```

例：SW2 收到 Root Path Cost = 0，本地入端口 Cost = 4 → 到 Root = 4；SW2 向下游发 BPDU 时携带 4，SW3 再加自己的入端口 Cost 4 → 8。

**Bridge ID**

- 传统：`Bridge Priority + MAC`
- PVST+：`Priority + VLAN ID（Extended System ID）+ MAC`
- 默认优先级 32768，越小越优；按 4096 递增。

**Port ID** = `Port Priority + Port Number`，默认 Priority 128，Cisco 按 16 递增（0、16、32…240），越小越优。

## 6. 选举向量（核心）

比较 BPDU 时依次比较，**越小越优**：

1. Root Bridge ID
2. Root Path Cost
3. Sender Bridge ID
4. Sender Port ID
5. Receiver Port ID

收到**更优 BPDU** → 更新本地信息并向其他端口传播；收到**更差 BPDU** → 忽略，保留当前信息。STP 的所有选择本质上都是在比“谁的 BPDU 更优”。

## 7. 计算四步

1. **选 Root Bridge**：开始都认为自己是根；Bridge ID 最小者胜。
2. **每台非根交换机选 Root Port**：收到最优 BPDU 的端口。
3. **每个网段选 Designated Port**：Root 的所有转发端口都是 DP；其余网段按向量比较。
4. **剩余端口** → Alternate / Backup → Blocking。

## 8. 调整选举结果

|   |   |   |   |
|---|---|---|---|
|目标|调整项|命令示例|影响|
|指定根桥|Bridge Priority|`spanning-tree vlan 10 priority 24576` / `root primary` / `root secondary`|根桥选举|
|改变到根路径|Port Cost|`spanning-tree vlan 10 cost 100`（接口下）|Root Port / DP 选择|
|控制并行链路|Port Priority|`spanning-tree vlan 10 port-priority 64`（接口下）|Sender/Receiver Port ID 比较|
|优化收敛|RSTP / PortFast / 合理根桥规划|—|不建议盲目改 Timer|

要点：

- 需要让某条冗余链路成为备用，**调 Cost 比调 Port Priority 更直接**。
- Port Priority 只在 Root ID、Cost、Sender Bridge ID 都相同时才起作用（典型：同一对交换机间的并行链路）。
- PVST+ 中不同 VLAN 设置不同 Root，可做 VLAN 级负载分担。

## 9. 完整案例

**拓扑**：SW1–SW2（e0/0–e0/0），SW1–SW3（e0/1–e0/0），SW2–SW3 两条并行链路（e0/1–e0/1、e0/2–e0/2）。优先级相同、链路速率相同（单条 Cost = C）。基础 MAC：SW1 `aabb.cc00.0100` < SW2 `...0200` < SW3 `...0300`。

**推导**：

1. **Root Bridge**：优先级相同 → 比 MAC → **SW1**。
2. **Root Port**：SW2 e0/0 直连根，Cost = C（绕 SW3 是 2C）；SW3 e0/0 同理。
3. **Designated Port**：SW1 所有端口为 DP；SW2–SW3 两条链路上，Root、Cost 相同，比 Sender Bridge ID，SW2 更小 → SW2 e0/1、e0/2 为 DP。
4. **剩余**：SW3 e0/1、e0/2 为 Alternate → Blocking。

**最终结果**

|   |   |   |   |
|---|---|---|---|
|设备|接口|角色|状态|
|SW1|e0/0、e0/1|Designated|Forwarding|
|SW2|e0/0|Root|Forwarding|
|SW2|e0/1、e0/2|Designated|Forwarding|
|SW3|e0/0|Root|Forwarding|
|SW3|e0/1、e0/2|Alternate|Blocking|

**故障推演**：若 SW3 e0/0 故障，SW3 在 e0/1、e0/2 间重选 Root Port。两条路径 Root ID、Cost、Sender Bridge ID 都相同 → 比 Sender Port ID，SW2 e0/1 < e0/2，所以 **SW3 e0/1 成为新 Root Port**，e0/2 继续 Blocking。直接故障约需 15 + 15 = 30 秒。

验证命令：`show spanning-tree vlan 1`、`show spanning-tree interface ethernet 0/1 detail`。

## 10. Timer 与收敛时间

|   |   |   |
|---|---|---|
|Timer|默认值|作用|
|Hello Time|2 秒|Root 周期发送 BPDU|
|Max Age|20 秒|BPDU 信息最大有效时间|
|Forward Delay|15 秒|Listening、Learning 各等待一次|

- **直接故障**：Listening 15s + Learning 15s ≈ **30s**。
- **间接故障**：Max Age 20s + 15s + 15s = 最坏 **50s**。
- Timer 由 Root Bridge 决定并下发；生产网络不要随意调整。

## 11. PVST+

- 每个 VLAN 独立一个 STP 实例，Root 可不同 → 实现 VLAN 级负载分担。
- 缺点：VLAN 多时实例多，状态、BPDU、CPU 压力增大 → 这也是引入 **MST** 的原因之一。
- 排障时注意：当前看的是**哪一个 VLAN** 的生成树。

## 12. 排障命令

|   |   |
|---|---|
|命令|用途|
|`show spanning-tree vlan 10`|看 Root ID、Bridge ID、Port Role/State、Cost|
|`show spanning-tree root`|根桥摘要|
|`show spanning-tree interface g1/0/1 detail`|角色、状态、Cost、Port ID、BPDU 收发计数|
|`show spanning-tree summary`|STP 摘要|
|`show spanning-tree inconsistentports`|排查 Root Guard、Loop Guard、EtherChannel Guard 导致的不一致|

## 13. 常见故障

|   |   |   |
|---|---|---|
|现象|常见原因|排查方向|
|根桥不是预期设备|没规划 Priority 或 MAC 更小|`show spanning-tree root`，配 root primary/secondary|
|某 VLAN 不通|Trunk 未放行、STP 阻塞、VLAN 不存在|`show interfaces trunk` + `show spanning-tree vlan X`|
|有冗余但只有一条链路转发|STP 正常阻塞冗余路径|用 EtherChannel 或三层链路|
|MAC 表震荡|二层环路、错误接线、STP 被关闭|查 STP 状态、日志、MAC 表|
|接入口被误当拓扑端口|终端口未启用 PortFast 或误接交换机|查 BPDU、PortFast、BPDU Guard|

## 14. 生产建议

- **根桥规划**：主动配置 Root Primary/Secondary，不依赖默认 MAC。
- **接入口**：PortFast + BPDU Guard。
- **互联口**：不启用 PortFast，保持 STP 保护。
- **冗余交换机互联**：优先 EtherChannel 或三层链路。
- **VLAN 很多**：考虑 MST。
- **不要随意关闭 STP**。

## 15. 速记小结

- STP 通过 BPDU 比较 **Root ID → Cost → Sender Bridge ID → Sender Port ID → Receiver Port ID**，越小越优。
- Root Path Cost 逐跳累加：**收到的 Cost + 本地接收端口 Cost**。
- 想换根桥调 Bridge Priority；想改路径调 Port Cost；想选并行链路调 Port Priority。
- Blocking 是状态，Alternate/Backup 才是角色。
- 收敛：直接故障约 30s，间接故障最坏 50s；RSTP/PortFast 才是优化方向。
- Configuration BPDU 维护拓扑，TCN BPDU 通知变化；PVST+ 每 VLAN 一棵树。