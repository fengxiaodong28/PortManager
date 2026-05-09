# PortManager

一个常驻在 macOS 菜单栏的轻量级端口管理工具，直观查看当前所有被占用的端口及对应进程，并支持一键结束进程。

## 功能

- 实时查看所有监听中的 TCP 端口
- 显示端口对应的进程名、PID、协议类型
- 支持按端口号、进程名或 PID 搜索过滤
- 一键结束占用端口的进程（带确认弹窗）
- 手动刷新数据
- 无 Dock 图标，纯菜单栏应用
- 右键图标可退出应用

## 系统要求

- macOS 13.0+

## 安装与运行

### 方式一：命令行

```bash
git clone https://github.com/fengxiaodong/PortManager.git
cd PortManager
swift build
swift run PortManager
```

### 方式二：Xcode

```bash
open Package.swift
```

然后按 `Cmd+R` 运行。

### 方式三：直接运行 .app

打包后的应用位于 `PortManager.app/`，双击即可运行。

## 使用说明

1. 运行后，图标会出现在屏幕右上角的菜单栏
2. **左键点击**图标展开端口列表面板
3. **右键点击**图标弹出退出菜单
4. 在面板内搜索框输入端口或进程名进行过滤
5. 鼠标悬停在某一行，点击右侧红色关闭按钮结束进程
6. 面板右上角有刷新按钮，点击手动刷新数据

## 注意事项

- 应用需要执行 `lsof` 和 `kill` 命令的权限
- 结束某些系统进程可能需要管理员权限
- 如果结束的是代理类软件（如 Clash），请注意该软件可能修改了系统代理设置。强制结束后系统代理可能仍处于开启状态，导致网络不通，需要手动关闭：
  ```bash
  networksetup -setwebproxystate "Wi-Fi" off
  networksetup -setsecurewebproxystate "Wi-Fi" off
  networksetup -setsocksfirewallproxystate "Wi-Fi" off
  ```

## 项目结构

```
PortManager/
├── Package.swift                 # Swift Package Manager 配置
├── README.md                     # 本文件
├── .gitignore                    # Git 忽略规则
└── PortManager/
    ├── PortManagerApp.swift      # 应用入口，配置 NSStatusBar
    ├── ContentView.swift         # SwiftUI 下拉面板主视图
    ├── PortManagerViewModel.swift # 业务逻辑
    ├── ProcessService.swift      # lsof / kill 命令封装
    ├── PortInfo.swift            # 数据模型
    └── Info.plist                # macOS 应用配置
```

## 技术栈

- Swift 5.7+
- SwiftUI
- AppKit (NSStatusBar)
- Swift Package Manager

## License

MIT
