## **VTP（VLAN中继协议，VLAN Trunking Protocol）**

主要用来在交换网络中实现VLAN配置的集中管理和自动同步，它能让网络管理员**在一台交换机上配置VLAN，然后所有其他交换机都能自动学习到这些VLAN信息**，免去了逐台手动配置的繁琐工作，大大减少了管理开销并保证了配置一致性

### 核心工作机制

为了让VTP正常工作，需要了解它的几个关键组成部分：

- **VTP域 (VTP Domain)**：一个由共享相同VTP域名并通过Trunk链路互联的交换机组成的逻辑分组。只有属于同一个域的交换机才能交换VLAN信息。
    
- **VTP模式 (VTP Mode)**：决定了交换机在VTP中的角色，主要有三种：
    
    - **Server（服务器模式）**：这是交换机的默认模式。可以创建、修改和删除VLAN，并将这些变更通告给整个域。同时也会学习来自其他Server的VLAN信息，并将配置保存在NVRAM中。
        
    - **Client（客户端模式）**：被动接收来自VTP Server的VLAN信息并同步，但自身无法创建、修改或删除VLAN。虽然会转发收到的VTP通告，但配置不会保存在NVRAM中。
        
    - **Transparent（透明模式）**：相当于一个“旁观者”。它不参与VTP域的VLAN同步（既不从Server学习，也不将自己的VLAN通告给域内其他交换机），但可以**转发**收到的VTP通告。自己可以独立创建、修改、删除本地VLAN，这些更改仅影响自身，且保存在NVRAM中。
        
- **配置修订号 (Configuration Revision Number)**：这是一个关键的数字，它决定了VLAN信息的“新旧程度”。每当在VTP Server上修改VLAN配置时，修订号就会增加。当交换机收到一个修订号比自己大的VTP通告时，它就会同步更新自己的VLAN数据库。
    

### VTP的版本演进

VTP主要有三个版本，功能各有不同：

- **VTP版本1 (VTPv1)**：最基础的版本，只支持VLAN 1到1000的传播。
    
- **VTP版本2 (VTPv2)**：在v1基础上增加了一些改进，最主要的是支持了令牌环（Token Ring）VLAN。
    
- **VTP版本3 (VTPv3)**：相比前两个版本有重大增强。它支持**扩展范围的VLAN（VLAN ID 1006-4094）** 的传播，并引入了主从服务器机制以增强安全性，防止未经授权的VLAN信息覆盖整个网络。
    

### 重要注意事项与风险

VTP虽然方便，但使用不当也可能导致严重的网络故障，需要特别小心：

1. **“一击致命”的风险**：这是VTP最需要警惕的地方。因为VTP会同步整个域的VLAN配置，如果你在一台修订号更高的交换机（例如一台刚从网络取出的旧交换机）上误操作或清空VLAN数据库，它会将这个“空配置”传播给整个域内的所有交换机，导致所有交换机上的VLAN配置被清空，造成网络大面积瘫痪。
    
2. **VTP修剪 (VTP Pruning)**：这是一个用来优化网络流量的功能。它能减少不必要的广播、组播等流量在Trunk链路上的泛滥，只将流量转发给确实需要该VLAN的交换机，从而节省带宽。但默认情况下，该功能是关闭的。
    
3. **版本兼容性**：VTPv1和v2在同一个域内不兼容，必须使用相同版本。启用VTPv2前，需确保域内所有交换机都支持v2。
    

# 实验部分

VTP必须运行在trunk链路上所以先把所有接口设置为trunk

interface GigabitEthernet0/0 switchport trunk encapsulation dot1q switchport mode trunk

![image-20260803104112404](file:///C:/Users/13126/AppData/Roaming/Typora/typora-user-images/image-20260803104112404.png?lastModify=1788692012)

**show vtp status**可以查看vtp状态

![image-20260803104256195](file:///C:/Users/13126/AppData/Roaming/Typora/typora-user-images/image-20260803104256195.png?lastModify=1788692012)

**vtp version 2**更改VTP版本，而其他交换机会同步版本高的

Switch# configure terminal  
Switch(config)# vtp mode server  
Switch(config)# vtp domain cisco  
Switch(config)# vlan 10

此时其他交换机也会同步这个有这个vlan10和domain cisco

修改vtp模式

![image-20260803110638622](file:///C:/Users/13126/AppData/Roaming/Typora/typora-user-images/image-20260803110638622.png?lastModify=1788692012)

Sw2 修改为透明模式

Switch# configure terminal  
Switch(config)# vtp mode transparent

Sw3修改为客户端模式

Switch# configure terminal  
Switch(config)# vtp mode client

当S1服务端删除vlan10-12

![image-20260803111233627](file:///C:/Users/13126/AppData/Roaming/Typora/typora-user-images/image-20260803111233627.png?lastModify=1788692012)

透明端S2不受影响，但它仍会把S1的vtp报文传输给S3

![image-20260803111304413](file:///C:/Users/13126/AppData/Roaming/Typora/typora-user-images/image-20260803111304413.png?lastModify=1788692012)

而客户端S3也同步服务端

![image-20260803111339536](file:///C:/Users/13126/AppData/Roaming/Typora/typora-user-images/image-20260803111339536.png?lastModify=1788692012)

# vtp存在的危害

vtp修改是完全取决于修订号更高的交换机，无论你是client还是server,都是取决于Configuration revision

把修订号置0的方法就是修改域名，然后该回去，这样就清除了.

标准vlan的相关操作都存在vlan.dat的文件中，而vtp配置也在其中

如果要清除runing-configure需要

**write erase**

但标准vlan不在所以清除不了

要用**delete vlan文件**