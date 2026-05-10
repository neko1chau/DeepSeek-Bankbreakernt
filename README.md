# DeepSeek-Bankbreakernt

<img width="654" height="736" alt="Capso Screenshot 2026-05-10 at 13 07 02" src="https://github.com/user-attachments/assets/55ae361e-35d2-48b4-afb7-56f7786998cc" />



人生中开发的第一个软件。

实际上不知道干了什么，全部让 OpenCode Vibe 的。
主要用来监控 DeepSeek 余额，Swift 写的。

图标还没来得及搞，功能应该基本 OK 了。

1.0.2 更新

1，新增点击空白区域收起窗口功能，窗口交互更加顺手。

2，新增检查更新功能，当前仍在评估可用性。

3，修复金额图标垂直对齐异常。

4，修复设置中“测试连接”和“保存”按钮按下时过度放大的问题。

1.0.1 更新

安全加固：API Key 迁移到 Keychain，启用 App Sandbox，修复 Logger 隐私泄露
- CredentialsStore 改用 Keychain 存储 API Key，替换明文 UserDefaults
- 新增 KeychainStore 封装 Keychain Services 读写
- 启用 App Sandbox，添加网络客户端权限
- Logger os_log 参数从 %{public}c 改为 %{private}c 防止系统日志泄露
