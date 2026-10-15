VTPv3：

```
```
                  VTP Domain
                      │
          ┌───────────┼───────────┐
          ↓           ↓           ↓
      Primary       Server      Client
       Server
          │
          │ 可以修改
          ↓
      VLAN Database
```

**只有 Primary Server 才可以修改 VLAN database。**

普通 VTP Server：

```
VTP Server
❌ 不能修改 VLAN database
```

只有执行：

```
vtp primary vlan
```

以后：

```
VTP Primary Server
✅ 可以修改 VLAN database
```
### SW1

```
enable
configure terminal

vtp version 3
vtp domain CCNP
vtp password cisco
vtp mode server

spanning-tree mode mst

end
---------------------
如果没有这两步那么就算配置了操作也不会同步
vtp primary vlan
vtp primary mst

configure terminal

vlan 10
vlan 20
vlan 30
vlan 40

spanning-tree mst configuration
name CAMPUS
revision 10
instance 1 vlan 10,20
instance 2 vlan 30,40
exit

end
write memory
```

### SW2

```
enable
configure terminal

vtp version 3
vtp domain CCNP
vtp password cisco
vtp mode client
-------------------------------------
如果没有这一步那么同步不了mst的操纵
spanning-tree mode mst

end
write memory
```

### SW3

```
enable
configure terminal

vtp version 3
vtp domain CCNP
vtp password cisco
vtp mode client

spanning-tree mode mst

end
write memory
```

### 验证

```
show vtp status
show spanning-tree mst configuration
show spanning-tree mst
```

SW1重点看：

```
VTP Version                     3
VTP Operating Mode              Server
VTP Domain Name                 CCNP
```

SW2/SW3：

```
VTP Version                     3
VTP Operating Mode              Client
VTP Domain Name                 CCNP
```

MST 三台应该一致：

```
Name      CAMPUS
Revision  10

Instance 1 → VLAN 10,20
Instance 2 → VLAN 30,40
```