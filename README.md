# IT 学习与实验仓库

网络工程方向的学习记录：华为与思科的实验配置、CCNP 学习笔记、Linux 笔记。内容以自己动手做过的实验为主，持续更新。

## 目录结构

```
IT/
├── README.md
├── huawei/            华为实验配置（eNSP）
├── cisco/
│   ├── ccnp-notes/    CCNP 学习笔记
│   └── ccnp-labs/     CCNP 实验：EVE-NG 拓扑与设备配置
└── linux/             Linux 学习笔记
```

## 各目录说明

### huawei/

华为方向的实验，使用 eNSP 模拟器完成，内容为各实验的设备配置文件。对应华为 HCIA 的学习内容，涉及交换、路由等基础技术。

### cisco/

思科方向的内容，分为笔记和实验两部分。

- **`ccnp-notes/`**：CCNP Enterprise 备考笔记，按主题整理（路由、交换、服务与安全等）。
- **`ccnp-labs/`**：CCNP 实验配置，使用 EVE-NG 搭建。每个实验一个子文件夹，计划包含：
  - EVE-NG 拓扑文件（`.unl`）
  - 各设备的配置文本
  - 实验说明和验证记录

### linux/

Linux 基础操作、网络排查和服务管理方面的学习笔记。

```

## 实验环境

| 方向 | 工具 |
|---|---|
| 华为 | eNSP |
| 思科 | EVE-NG（VMware Workstation 中运行） |

## 如何使用

```bash
git clone https://github.com/1beloved/IT-.git
```

- 配置文件是文本格式，可以直接在设备命令行里粘贴使用。
- EVE-NG 拓扑文件（`.unl`）需要在 EVE-NG 中导入，设备镜像需要自行准备。

## 说明

- 本仓库为个人学习记录，**不包含设备镜像和任何考试真题或题库**。
- 配置文件中的密码、密钥等敏感信息已替换为占位符。
- 内容如有错误，欢迎通过 Issue 指正。
