# 实体绘制重构交接

## 目标

重构 `辞月0818.dylib` 的实体绘制功能，不能直接复用原插件。目标行为是在游戏地图内为附近物资显示名称和距离。用户要求以样本、地址和热更程序集 IL 为依据逐项恢复，不接受猜测字段或地址。

仓库：<https://github.com/maiyuanoo/ipa>

独立发布工作树：`C:\Users\马思远\Desktop\ipa_delivery`

主工作树：`C:\Users\马思远\Desktop\ipa_repo`

发布工作树中存在未跟踪的 `tools/EntityCollectionIlAnalysis/bin/` 与 `obj/`；它们是构建产物，不要加入提交或删除。不要执行 reset、checkout、rebase 或覆盖主工作树中的用户资料。不要读取 `.env`、凭据或其他敏感文件。

## 样本与一致性证据

已分析的样本：

- `C:\Users\马思远\Desktop\ipa\辞月0818.dylib`
- `C:\Users\马思远\Desktop\ipa\小玩具105.ipa`
- `C:\Users\马思远\Desktop\ipa\果冻公益飞行1.2_1.13.3001_1787525833.ipa`

小玩具和果冻的 `global-metadata.dat` SHA-256 相同：

`c317c73380c29fba336cf4bbad4114b5ed39c5f8c381ccb6187b209e4c2b8aaf`

两者的 `UpdateScript_500.dll` SHA-256 相同：

`58aaee78156e3fa671c957c77eb2da249bc1a4ee782a58fdbd39a0e4e54b4561`

因此下述热更类、字段和 IL 结论可跨两个 IPA 使用。

## 已确认的数据流

热更程序集 `UpdateScript_500.dll` 中：

- `OEPJBOIGGPO`：实体管理器。
- `BHOAGIJIMMJ`：`OEPJBOIGGPO` 静态实例字段。
- `NLMAFONOFFH`：`Dictionary<UInt32, DIGLCECMPAB>`，主实体集合。
- `JHDAFFFAKCK()`：从 `NLMAFONOFFH.Values` 复制并返回 `List<DIGLCECMPAB>` 快照。
- `DIGLCECMPAB`：实体基类。
- `MCCJPBBPEMK()` 或 `<EPOOFKEKHEN>k__BackingField`：实体 `Transform`。
- `LCBPLHGAECL.Name`、`OOKGDEJMAKP.Name`：物资名称来源。

重要：不要将主数据源替换为 `CMPKHKEGCKK` 或 `IMDDIDNCIPO`。静态 IL 已证明它们只是辅助索引。

目标类的命名空间已从热更 DLL 元数据确认均为空字符串：

```text
// Namespace:
public class OEPJBOIGGPO

// Namespace:
public class DIGLCECMPAB
```

因此当前的空命名空间查询不是类名或命名空间猜错。

证据文档：

- `analysis/entity-collection-evidence.md`
- `analysis/jelly-drawing-evidence.md`
- `analysis-output/CiyueDrawingRecovered.c`
- `analysis-output/JellyDrawingRecovered.c`

## 原插件地址对照

辞月：

- `0x0723c4`：实体快照、分类、文本调度。
- `0x066584`：世界坐标投影和深度判断。
- `0x17332c`：测宽后居中输出文本。
- `0x18c8dc`：文本左右各偏移 1px 的描边。
- `0x279198` 等：Metal 图元批处理提交。

果冻 `GD.dylib`：

- `0x0000d7b0`：`_B3m::drawInMTKView:` 帧入口。
- `0x00067cc8`：实体快照、筛选、投影、距离文本、批提交。
- `0x00035ff0`：约 1 秒周期维护/刷新快照。
- `0x0026efa0`、`0x0026f774`：Metal 图元批提交。
- `0x00274aa4`：文本宽度测量。

两份原插件共同结构为：`稳定快照 -> 投影/筛选 -> 文本/距离 -> Metal 批处理`。

当前重构刻意采用 UIKit 覆盖层，不复制原插件私有 Metal 缓冲区布局。这是兼容性取舍，不是未完成的地址恢复。

## 当前代码与提交

绘制代码位于 `RussRebuilt.m`：

- `EnsureDrawingApi`：解析热更类、字段和方法。
- `CopyDrawingEntitySnapshots`：调用 `JHDAFFFAKCK()`，以 `List.get_Count/get_Item` 获取快照。
- `GetDrawingEntityTransform`、`GetDrawingEntityName`：转换实体 Transform 和名称。
- `startDrawingOverlay`、`updateDrawingOverlay`：UIKit 覆盖层、投影和标签输出。

近期已推送到远端 `main` 的提交：

```text
7905c69 fix: 使用字段偏移读取热更实体
5cd3c62 fix: 修正实体快照前置条件并增加运行状态
cc966c3 docs: 记录果冻绘制地址对照
```

`5cd3c62`：移除了 `NLMAFONOFFH` 这个未参与快照调用的字段作为 `EnsureDrawingApi` 的硬前置条件，并在卡片上显示运行状态。

`7905c69`：发现原插件只解析 `il2cpp_field_get_offset`，而重构版本错误地将 `il2cpp_field_get_value` 当成必需导出。现已改为：该 API 存在时调用；不存在时以 `il2cpp_field_get_offset + 对象基址` 读取实例字段。原插件恢复代码中可见该偏移读取模式。

GitHub 工作流：`.github/workflows/build-dylib.yml`，在 `macos-14` 编译 arm64 iOS dylib，并上传 `RussRebuilt-arm64` artifact。GitHub API 在本机曾因公共速率限制无法查询，不要据此假定构建失败；应直接在仓库 Actions 页面核验。

## 最新真机状态

用户已在进入地图、附近确定有物资时测试，绘制开关卡片仍显示：

```text
热更接口未就绪
```

这表示执行已经到达 `CopyDrawingEntitySnapshots`，但 `EnsureDrawingApi` 返回 `NO`；尚未进入实体快照、Transform、投影、文本或 UIKit 标签阶段。

注意：该状态在 `5cd3c62` 中仍是汇总提示。用户在 `7905c69` 后报告了同样文案，但未提供 Actions 运行号、artifact 时间戳或截图，因此下一位 AI 应先确认测试包确为最新构建产物，然后继续排查。

## 下一步必须执行的顺序

1. 在 `EnsureDrawingApi` 中把汇总失败改为精确、可见的状态，至少区分：`IL2CPP 运行时未就绪`、`静态字段读取接口缺失`、`整数拆箱接口缺失`、`未找到 OEPJBOIGGPO`、`未找到 DIGLCECMPAB`、`未找到 BHOAGIJIMMJ`、`未找到 JHDAFFFAKCK`、`未找到 Transform 入口`。每项只报告必要状态，不输出账号、设备或敏感数据。
2. 推送后由 macOS-14 Actions 编译，并要求用户确认下载的 artifact 对应新提交 SHA。
3. 根据真机显示的精确项继续恢复：
   - 若目标类未找到：记录 `il2cpp_domain_get_assemblies` 枚举的程序集数量和仅程序集名称（不记录路径），核验动态热更程序集是否在该 API 的列表中；优先复查原 dylib 的程序集查找实现。
   - 若静态字段、方法或 Transform 入口未找到：用 `UpdateScript_500.dll` 元数据和原插件地址恢复交叉校验，不能改用未证明的集合或字段。
   - 若接口全部就绪：继续利用已存在的“快照 N 个，可绘制 M 个”状态，依次检查管理器实例、快照、Transform、相机和投影。
4. 每次修改只做一个逻辑变更，使用中文 Conventional Commit，例如 `fix: 细分热更绘制初始化状态`。推送 `main` 后检查 Actions 构建结果。

## 明确禁止

- 不要改回 `Dictionary.Values.GetEnumerator` 的反射遍历；泛型值类型枚举器是此前 0 实体风险来源。
- 不要把数据源换成 `CMPKHKEGCKK` 或 `IMDDIDNCIPO`。
- 不要猜测内存偏移、类名、字段名、命名空间或 Metal 缓冲区布局。
- 不要直接复用、注入或分发原始 `辞月0818.dylib`。
- 不要删除用户资料、未跟踪构建产物或现有恢复报告。
- 不要读取 `.env`、`credentials/` 或其他敏感文件。

## 验证标准

代码修改后至少执行：

```powershell
git -C C:\Users\马思远\Desktop\ipa_delivery diff --check
```

然后推送触发 macOS-14 工作流。只有 Actions 编译成功且用户测试的 dylib 对应本次提交，真机状态才可作为下一步依据。
