# 果冻绘制函数恢复证据

## 样本

- IPA: `果冻公益飞行1.2_1.13.3001_1787525833.ipa`
- 插件: `Payload/czrxd.app/Frameworks/GD.dylib`
- `GD.dylib` SHA-256: `dd84fc38531475a9508e4467f525e80c81bfeaef903f9fd87278c1aca3e33768`
- `global-metadata.dat` SHA-256: `c317c73380c29fba336cf4bbad4114b5ed39c5f8c381ccb6187b209e4c2b8aaf`
- 热更程序集 SHA-256: `58aaee78156e3fa671c957c77eb2da249bc1a4ee782a58fdbd39a0e4e54b4561`

后两项与 `小玩具105.ipa` 一致，故 `OEPJBOIGGPO`、`DIGLCECMPAB` 和 `JHDAFFFAKCK` 的 IL 结论可共同使用。

## 地址级恢复

| 样本 | 地址 | 恢复行为 | 重构映射 |
| --- | --- | --- | --- |
| 果冻 `GD.dylib` | `0x0000d7b0` | `_B3m::drawInMTKView:`，建立 Metal command buffer 后调用绘制调度 | 覆盖层帧调度 |
| 果冻 `GD.dylib` | `0x00067cc8` | 实体快照、类别筛选、投影、距离文本和批提交的主调度 | 当前快照、投影、距离和标签循环 |
| 果冻 `GD.dylib` | `0x00035ff0` | 在主调度中按约 1 秒间隔调用，维护实体数据快照 | 避免直接操作泛型枚举器 |
| 果冻 `GD.dylib` | `0x0026efa0` | 图元批提交 | 原插件私有 Metal 后端，不复用缓冲区布局 |
| 果冻 `GD.dylib` | `0x0026f774` | 图元状态和顶点提交 | 原插件私有 Metal 后端，不复用缓冲区布局 |
| 果冻 `GD.dylib` | `0x00274aa4` | 文本宽度测量 | UIKit 标签的居中对齐 |
| 辞月 `辞月0818.dylib` | `0x000723c4` | 实体快照和文本发射主调度 | 当前快照、投影、距离和标签循环 |
| 辞月 `辞月0818.dylib` | `0x0017332c` | 测量文本宽度后按中心发射 | `UILabel` 居中对齐 |
| 辞月 `辞月0818.dylib` | `0x0018c8dc` | 左右各 1px 的深色描边再绘制正文 | `RussOutlinedLabel` |

## 直接观察到的果冻绘制逻辑

`FUN_00067cc8` 内出现以下已恢复格式：

- `%s %.0fm`
- `%s %u %.0fm`
- `%.0fm`
- `%d. %s %.0fm`
- `%d. %s %s %.0fm`

同一函数中保留 `Chest`、`Item`、`Loot`、`Enemy`、`Monster` 与 `Unknown Item` 的类别证据，并在实体输入无效时跳过。该函数不是简单的每帧原始集合遍历：它在 `FUN_00035ff0` 建立的缓存基础上渲染，并通过 Metal 文字和图元批处理提交。

## 对当前重构的结论

两份原插件都采用“先获得稳定实体快照，再投影和发射文本”的结构。热更 IL 已证明 `JHDAFFFAKCK` 从 `NLMAFONOFFH.Values` 构造 `List<DIGLCECMPAB>` 快照。因此当前重构调用 `JHDAFFFAKCK` 并按 `List.get_Count/get_Item` 读取，符合三份样本的共同数据流；没有地址或 IL 证据支持替换为 `CMPKHKEGCKK` 或 `IMDDIDNCIPO`。

恢复文件：`analysis-output/JellyDrawingRecovered.c`。
