# Tencent Ads to WeCom Skill

这是一个可分享的 Codex Skill，用于在 Windows 上安装、测试和维护“腾讯广告新线索 → 企业微信群”自动通知。

在 Codex 中使用：`$tencent-ads-wecom-skill`

该脚本每分钟拉取腾讯广告线索，通过 `leads_id` 去重后发送至企业微信群机器人。

## 一键安装（推荐）

1. 解压 ZIP，保持所有文件在同一目录。
2. 双击 `install.cmd`。
3. 按提示依次输入腾讯广告 Token、Secret 和企业微信群机器人 Webhook；输入内容不会显示。
4. 安装程序会自动测试两个接口、安装静默计划任务并执行一次。

以后无需打开本程序。Windows 登录后，任务会在后台每分钟自动拉取一次。

辅助入口：

- `test.cmd`：发送不含客户信息的联通测试消息。
- `status.cmd`：查看最近和下次运行状态。
- `uninstall.cmd`：移除自动任务（保留本机加密凭据）。

## 分步使用

1. 在 PowerShell 中进入本目录。
2. 运行 `powershell -ExecutionPolicy Bypass -File .\setup.ps1`，按提示粘贴 Token、Secret 和 Webhook。
3. 手动测试：`powershell -ExecutionPolicy Bypass -File .\poll-leads.ps1`。
4. 测试成功后安装每分钟任务：以 PowerShell 运行 `powershell -ExecutionPolicy Bypass -File .\install-task.ps1`。

凭据加密保存在 `config.secure.json`，随机密钥存放在 `config.key`；两者和运行状态均已被 `.gitignore` 排除。请限制该目录的 Windows 访问权限，并勿复制或分享这两个配置文件。发布包不包含任何凭据或运行状态。

默认发送完整电话号码。如需脱敏，将 `config.secure.json` 中的 `maskPhone` 改为 `true`。

接口文档：https://leads.qq.com/assets/doc/api_guide.pdf
