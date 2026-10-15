
实验拓扑图

![[Pasted image 20260905142935.png]]

因为生成树协议交换机自动开启所以设置其他配置就好了
# **手动配置**

```
S1:
手动配置优先级
Switch(config)#spanning-tree vlan 1 pri
Switch(config)#spanning-tree vlan 1 priority 0

S2:
手动配置优先级
Switch(config)#spanning-tree vlan 1 pri
Switch(config)#spanning-tree vlan 1 priority 4096

S3:
手动配置优先级
Switch(config)#spanning-tree vlan 1 pri
Switch(config)#spanning-tree vlan 1 priority 4096

```
### 自动指定 Root

让 S1 成为 Primary：

```
S1(config)# spanning-tree vlan 1 root primary
```

让 S2 成为 Secondary：

```
S2(config)# spanning-tree vlan 1 root secondary
```

### 查看整个 STP

```
show spanning-tree
```
![[Pasted image 20260905143934.png]]
![[Pasted image 20260905143940.png]]

![[Pasted image 20260905143944.png]]
### 查看某个 VLAN

```
show spanning-tree vlan 1
```