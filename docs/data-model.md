# 数据模型：S/theta/u/y/T/O

本项目把游戏逻辑看成一个闭合模型：

```text
(S', O) = T(S, u, y, theta)
```

源码文件只允许属于 `S`、`theta`、`u`、`y`、`T` 五类。`O` 不建目录，也不放函数；它只是 `T` 产生出来的数据、返回值或界面状态。

## 映射关系

- `S_p` 玩家进度状态：`Strength`、`Exp`、`RebirthCount`、`CurrentBarbellId`、`BodyQuality`。
- `S_r` 服务端运行时状态：`IsMoving`、`AutoAreaContacts`、`GrowthLoopActive`。
- `theta` 规则参数：自动区、杠铃、身体素质、重生、等级经验、初始状态、Remote 协议。
- `u` 输入适配：Remote、玩家生命周期、客户端移动和区域触碰声明。
- `y` 观测验证：服务端 Workspace 空间查询、角色 RootPart 状态、区域 id 合法性。
- `T` 状态转移：初始化、清理、移动更新、区域接触确认、训练结算、重生、快照生成、UI 渲染。
- `O` 输出数据：玩家数据快照、重生响应、客户端 UI 实例和文本状态。

## 所有权

- `S/PlayerProgressState.lua` 拥有 `S_p`，只提供 `Init(player, state)`、`Remove`、`Get`、`Set`。
- `S/TrainingRuntimeState.lua` 拥有 `S_r`，只提供 `Init(player, state)`、`Remove`、`Get`、`Set`。
- `S` 不读取 `theta`，不认识字段业务含义，不负责状态是否合法；它只隔离保存和复制状态。
- `theta/*.lua` 只保存参数表，不保存玩家状态，不访问 Workspace，不执行业务转移。
- `y/TrainingAreaObservation.lua` 把不可信的区域声明转成服务端观测结果，不写状态。
- `u/*.lua` 只接输入并调用 `T`，不能直接写 `S`。
- `T/*.lua` 是唯一能根据 `S`、`u`、`y`、`theta` 产生 `S'` 和 `O` 的层。
- `T` 可以创建临时局部值，但长期事实只能写回 `S`，规则参数只能来自 `theta`，观测事实只能来自 `y`。

## 派生值

这些值不作为核心状态保存：

- `Level`
- `MaxLevel`
- `MaxExp`
- `CanRebirth`
- `AutoAreaMultiplier` 从服务端确认的区域接触、自动区配置和 `RebirthCount` 推导。

这些计算都在 `T` 内部完成。`FormulaService`、`LevelService` 不再作为独立架构类别存在。
训练收益和增长决策使用直接返回值传递，不再创建 `growthContext`、`gains` 这类隐形数据模型。

## 不变量

- `Strength >= 0`
- `Exp >= 0`
- `Exp <= MaxExp(RebirthCount)`
- `RebirthCount >= 0`
- `AutoAreaContacts` 只能包含 `theta.AutoAreaTheta` 里存在的区域 id。
- 客户端 Remote 只能触发状态转移，不能直接写 `S_p` 或 `S_r`。
- 自动区倍率必须来自服务端验证过、且玩家已解锁的区域接触。
- 同时接触多个自动区时，只取已解锁区域里的最高倍率。
