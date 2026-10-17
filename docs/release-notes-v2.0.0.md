# JANUS v2.0.0

## English

JANUS is the new name of this project. The product is now positioned as the bidirectional UART/COM workbench of the **TITAN Universe**: Janus, the two-faced Roman god of gates, looks both ways — just as the workbench watches RX and TX, and the boundary between device and debugger.

This is a brand and identity release. The workbench behavior, IPC v2 protocol, framing, templates, queue, triggers, and logging remain functionally the same.

### Changed

- Product, window title, About page, README and product documents now use **JANUS**.
- The new JANUS wordmark ships as white-on-transparent and black-on-transparent variants; dark surfaces use the white mark and light surfaces use the black mark.
- The Windows executable and taskbar icon now use the rounded, black-background JANUS “J” mark.
- The bundled Noto Sans SC font is now a subset of the characters used by the UI and project documents, shrinking from 17.8 MB to about 0.5 MB. Missing glyphs fall back to the Windows system font.
- The Flutter package is `janus`; the Windows executable is `JANUS.exe`; the Rust Core is `janus-core.exe` (Core `0.4.0`).
- The virtual-COM driver moved to `driver/janus-vcom/` with the control device `\\.\JanusVcomCtl` and root enumerator `ROOT\JANUSVCOM`.
- Session files use `.janustrace`; session and queue-preset format identifiers use the `janus-` prefix.
- Build variables are `JANUS_GIT_SHA`, `JANUS_BUILD_TIME`, `JANUS_CORE_PATH`, and `JANUS_CARGO_EXECUTABLE`.

### Breaking

- Replace `HPCom.exe` with `JANUS.exe`, and `hcom-core.exe` with `janus-core.exe`; keep them in the same package folder.
- HPCom-era `.hcomtrace` sessions and `hcom-queue-preset` files are not read by this release. Frame-template JSON files remain portable.
- The renamed `janus-vcom` driver is a new binary package and must be rebuilt and signed by Microsoft before monitor mode can be distributed again.

### Download and run

Download `JANUS-v2.0.0-windows-x64.zip`, extract all files into one folder, and start `JANUS.exe`. Keep `janus-core.exe`, `data/`, and the bundled DLL files beside the executable.

### Scope note

The Windows package is rebuilt from a clean Flutter build, passes `flutter analyze`, the full Flutter test suite, and the Rust Core tests, and is launch-checked. It does not include a signed virtual-COM driver package; use physical COM ports in this release.

## 中文

JANUS 是本项目的新名字。产品现在定位为 **TITAN 宇宙** 中的双向 UART/COM 工作台：双面的罗马门神雅努斯同时看向两个方向，正如工作台同时观察 RX 与 TX，以及设备与调试者之间的边界。

本次是品牌与身份发布。工作台行为、IPC v2 协议、分帧、模板、队列、触发与日志能力保持功能一致。

### 变更

- 产品名、窗口标题、关于页、README 与产品文档统一为 **JANUS**。
- 新的 JANUS 字标提供白色与黑色两个透明底版本：深色界面使用白图，浅色界面使用黑图。
- Windows 可执行文件与任务栏图标更新为带圆角的黑底白色 “J” 标记。
- 内置 Noto Sans SC 字体改为按界面与项目文档用字生成的子集，从 17.8 MB 降至约 0.5 MB；缺失字形回退到 Windows 系统字体。
- Flutter 包名改为 `janus`；Windows 可执行文件为 `JANUS.exe`；Rust Core 为 `janus-core.exe`（Core `0.4.0`）。
- 虚拟串口驱动迁移到 `driver/janus-vcom/`，控制设备为 `\\.\JanusVcomCtl`，根枚举名为 `ROOT\JANUSVCOM`。
- 会话文件扩展名为 `.janustrace`；会话与队列预设的格式标识使用 `janus-` 前缀。
- 构建变量改为 `JANUS_GIT_SHA`、`JANUS_BUILD_TIME`、`JANUS_CORE_PATH` 与 `JANUS_CARGO_EXECUTABLE`。

### 破坏性变更

- 用 `JANUS.exe` 替代 `HPCom.exe`，用 `janus-core.exe` 替代 `hcom-core.exe`；请保持它们与 `data/`、DLL 在同一目录。
- 本版不读取 HPCom 时代的 `.hcomtrace` 会话与 `hcom-queue-preset` 队列预设。帧模板 JSON 仍可导入。
- 改名后的 `janus-vcom` 是新的驱动包，必须重新构建并通过 Microsoft 签名后才能再次分发监听模式。

### 下载与运行

下载 `JANUS-v2.0.0-windows-x64.zip`，将全部文件解压到同一目录后运行 `JANUS.exe`。请保留可执行文件旁的 `janus-core.exe`、`data/` 和随附 DLL 文件。

### 范围说明

Windows 发布包已完成干净构建，通过 `flutter analyze`、完整 Flutter 测试与 Rust Core 测试，并通过启动检查。未包含签名虚拟 COM 驱动包，本版请使用物理 COM 口。
