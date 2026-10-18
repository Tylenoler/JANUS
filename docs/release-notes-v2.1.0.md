# JANUS v2.1.0

## English

JANUS v2.1.0 is a workbench and settings release. The serial transport, IPC v2 protocol, framing, templates, `.janustrace` sessions, and data formats are unchanged.

### Added

- Settings switches for the port device identity card, DTR / RTS / Break line controls, and automatic port-configuration collapse after connecting.
- The port summary turns red while disconnected and green only after a successful connection, with an animated appearance when the configuration collapses.

### Changed

- Removed the top AppBar. Session, frame definition, import, and export now live in the right rail; settings, theme, port summary, live metrics, and build identity live in the bottom bar.
- Status-bar metrics and the build identity use compact capsule pills.
- Serial parameter dropdowns are sized to their content; the custom baud-rate entry is now the bottom item of the baud-rate dropdown.
- Removed the standalone serial-parameter preset button for now; the preset code is parked for a future compact entry.
- Settings now requires an explicit Save or Cancel; clicking outside the dialog no longer discards changes silently.

### Download and run

Two packages are available:

- `JANUS-v2.1.0-portable.exe` — single-file self-extracting launcher. Run it directly; the first launch extracts the runtime to `%LOCALAPPDATA%\JANUS\<payload-hash>\` and later launches reuse that directory.
- `JANUS-v2.1.0-windows-x64.zip` — portable folder. Extract all files into one folder and start `JANUS.exe`. Keep `janus-core.exe`, `data/`, and the bundled DLL files together.

The single-file build is unsigned; SmartScreen or antivirus software may warn about self-extracting executables. Download from this repository and verify with `SHA256SUMS.txt`.

### Scope note

The package is rebuilt from a clean Flutter build, passes `flutter analyze`, the full Flutter test suite, and the Rust Core tests, and is launch-checked. It does not include a signed virtual-COM driver package; use physical COM ports in this release.

## 中文

JANUS v2.1.0 是工作台与设置更新。串口传输、IPC v2 协议、分帧、模板、`.janustrace` 会话与数据格式均未改变。

### 新增

- 设置中可关闭串口设备信息卡、DTR / RTS / Break 线路控制，以及连接成功后自动收起串口配置。
- 串口摘要未连接时显示红色，连接成功后显示绿色；配置收起时带弹出动效。

### 变更

- 移除顶部 AppBar。会话、帧定义、导入、导出移至右侧导轨；设置、主题、串口摘要、实时计数与构建身份移到底部状态栏。
- 状态栏计数与构建身份改为胶囊标签。
- 串口参数下拉框按内容收紧宽度；自定义波特率入口移到波特率下拉框底部。
- 暂时移除串口参数预设的独立按钮，预设代码保留待后续以更紧凑的入口回归。
- 设置必须显式点击“保存”或“取消”，点击对话框外部不会再静默丢弃修改。

### 下载与运行

提供两种形式：

- `JANUS-v2.1.0-portable.exe`：自解压单文件启动器。直接运行；首次启动会解压到 `%LOCALAPPDATA%\JANUS\<内容哈希>\`，后续启动直接复用。
- `JANUS-v2.1.0-windows-x64.zip`：ZIP 便携包。将全部文件解压到同一目录后运行 `JANUS.exe`，并保留同目录下的 `janus-core.exe`、`data/` 与随附 DLL。

单文件包未签名，自解压行为可能触发 SmartScreen 或杀软误报；请从本仓库下载并用 `SHA256SUMS.txt` 核对。

### 范围说明

本包已完成干净构建，通过 `flutter analyze`、完整 Flutter 测试与 Rust Core 测试，并通过启动检查。未包含签名虚拟 COM 驱动包，本版请使用物理 COM 口。
