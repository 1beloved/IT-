```
STP的端口角色
1.RP根端口：通常用来接受STP的BPDU的端口
2.DP指定端口：通常用来发送STP的BPDU的端口
3.Non-DP非指定端口-AP替代/预备端口--只接受BPDU。不发送BPDU
                  AP端口是RP端口的备份

STP的端口状态
1.Disable       禁用：链路中断。或者端口关闭，不能收发STP的BPDU,也不能转发业务数据帧
2.Blocking      堵塞：当STP选举完毕后，凡是AP端口即被堵塞，只能收BPDU，不能发BPDU，,也不能转发业务数据帧
3.Listening     监听：STP初始状态,用于STP生成树的选举，即能发BPDU，也能收BPDU，监听时间为15秒(Forward Delay转发延迟15秒)
4.Learning      学习：当监听状态的15秒完毕后，此时端口状态进入学习状态,即能发BPDU，也能收BPDU，在此状态交换机会预先尽可能学习收集端口上的MAC地址， 防止过多的泛洪.学习时间为15秒(Forward Delay转发延迟15秒)
5.Forwarding    转发: 是一个RP，DP端口最终稳定的状态，必须要经历上述LIS和LRN。也就意味着一个端口最少需要30秒钟才能进入转发状态。能发BPDU，也能收BPDU，转发业务数据帧
```

