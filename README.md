# flutter_words

> Flutter 工具类与高并发场景实践 Demo 集 —— 用可运行的代码把「状态管理 / 网络 / Isolate / 国际化 / 语音房高并发消息」讲清楚。

![运行效果](https://climby-cn.oss-cn-hangzhou.aliyuncs.com/repository/f_launch_c.png)

## 简介

`flutter_words` 是一个 Flutter 演示工程：每个能力都以「首页卡片 → 独立页面」的形式呈现，代码里保留了完整的设计注释，既可以直接跑起来看效果，也适合当作实现参考。

项目重点不在 UI，而在于**把工程里容易踩坑的点做成可观测的 Demo**：Isolate 是否真的没卡主线程、消息洪峰如何被削平、礼物高并发为什么不能无限排队、FPS 到底掉了没有。

## 功能一览

| 模块 | 入口文件 | 说明 |
| --- | --- | --- |
| Dio 网络请求 | `lib/utils/dio_util.dart` | Dio + Logger 单例封装，统一 baseUrl / 超时 / 日志 |
| Provider 状态管理 | `lib/utils/state_management.dart` | `ChangeNotifier` + `Consumer` 计数器 |
| GetX 状态管理 | `lib/utils/state_management.dart` | `Obx` 响应式计数器，与 Provider 对照 |
| GetX MVVM | `lib/utils/state_management.dart` | Controller / 状态 / 视图分层，异步列表加载 |
| Isolate 多线程 | `lib/utils/isolate_util.dart` | 主线程 vs Isolate 的重计算对比（动画是否卡住） |
| 国际化 i18n | `lib/l10n/` | `gen_l10n` 方案，中英双语，支持跟随系统 |
| **语音房高并发消息** | `lib/concurrent/voice_room_page.dart` | 四层漏斗架构 + 实时水位 + FPS 监测 |
| **礼物工具类** | `lib/concurrent/gift_manager.dart` | 小礼物 xN 合并 / 大礼物独占 / 队列与背压 |

## 语音房高并发消息（核心模块）

参考文章：本地博客 `flutter-concurrent-messages`。

真实语音房里，公屏、礼物、麦位控制走同一条长连接。活动期间消息会瞬间爆发，如果「收到一条就 setState 一条」，主线程会被直接打满。本项目把解决方案拆成**四层漏斗**，把不可控的洪峰整形成可控的固定节奏：

```
长连接 / IM SDK
      │  原始 JSON（网络线程）
      ▼
① 解析层   常驻 Isolate：jsonDecode + 容错解析（不阻塞 UI）
      ▼
② 队列层   优先级队列：按 (优先级, seq) 排序 + seq 去重 + 低优额度
      ▼
③ 分发层   StreamController 分类型广播（麦位 / 礼物 / 公屏），回调里绝不 setState
      ▼
④ UI 层    公屏批量节流 + 截断 200 条；礼物合并 + 槽位上限；ListView 懒加载
```

### 各层职责

| 层 | 文件 | 关键实现 |
| --- | --- | --- |
| 0 模型 | `models.dart` | `sealed class RoomMessage` 联合类型，`MicMessage` / `GiftMessage` / `ChatMessage`，用 switch 穷尽分发 |
| ① 解析 | `parser.dart` | `ParserIsolate` 常驻 Isolate + `SendPort` 双向通信，避免高频 `compute` 反复创建销毁；脏数据返回 `null` 直接丢弃 |
| ② 队列 | `message_queue.dart` | 入队按 `(priority, seq)` 排序；`pump()` 每个 tick 给低优先 8 条额度，防止聊天刷屏把麦位饿死；`seq <= maxSeq` 判定重复并丢弃 |
| ③ 分发 | `room_bloc.dart` | 三条 `StreamController.broadcast`；公屏每 80ms 批量 flush 一次 |
| ④ UI | `widgets.dart` | 公屏 `ListView.builder` 懒加载 + 只保留最近 200 条；礼物走 `GiftManager` |
| 连接 | `connection.dart` | 断线指数退避重连（1s → 2s → 4s，上限 8s），重连后拉增量快照补位 |
| 模拟 | `simulator.dart` | 模拟长连接洪峰，按 75% 聊天 / 18% 礼物 / 7% 麦位分布，并混入重复 seq 验证去重 |
| 观测 | `stats.dart` / `funnel.dart` / `fps_meter.dart` | 漏斗实时水位 + 右上角 FPS |

### 调度节奏

| 参数 | 值 | 位置 |
| --- | --- | --- |
| 队列 pump 周期 | 60ms | `voice_room_page.dart` |
| 每 tick 低优先额度 | 8 条 | `message_queue.dart` |
| 公屏批量 flush 周期 | 80ms | `room_bloc.dart` |
| 公屏保留上限 | 200 条 | `widgets.dart` |
| 自动推送间隔 | 50ms（15% 概率追加 5~19 条小洪峰） | `simulator.dart` |
| 单次洪峰 | 150 条 | `voice_room_page.dart` |

### 实时观测

- **FunnelDiagram**：长连接 → ①解析 → ②队列 → ③分发 → ④公屏，每层显示累计量与「失败 / 丢弃」。
- **FPS 角标**：`fps_meter.dart` 位于 AppBar，用 `SchedulerBinding.addPersistentFrameCallback` 统计帧数，每 500ms 结算一次；`>=55` 绿 / `30~54` 橙 / `<30` 红。统计回调内只累加计数、不 `setState`，因此监测器本身不会影响被测页面。
- **礼物队列角标**：飘屏层右下角实时显示 `排队中 · 小 N · 大 M（丢弃 K）`。

## 礼物显示逻辑（GiftManager）

`lib/concurrent/gift_manager.dart` 是一个**纯 Dart 工具类**（不依赖 Flutter），把「怎么展示礼物」从 UI 里彻底抽离。语音房里的 `GiftOverlay` 只做两件事：把 `GiftMessage` 还原成 `Gift` 投喂给它，再渲染它广播的状态快照。

### 小礼物

1. 新礼物到达，先找**正在展示**的同 `id` 项 → 命中则 `count += combo`，只把屏幕上的 `xN` 数字变大，不新建 widget；
2. 否则找**等待队列**里的同 `id` → 同样累加；
3. 都没有则新建 `MergedGift` 入队（带进程内唯一 `uid` 作为 UI key，避免 Duplicate keys 崩溃）；
4. `_refill()` 在槽位未满（默认 3 个）时按首次出现顺序取出上屏。

单个小礼物动画 1800ms：左侧滑入 → 停留 → 向右滑出淡出。动画 `completed` 后才回调 `smallShownComplete(id)` 释放槽位并补下一个，因此不会卡屏，也一定有退场。

### 大礼物

1. 按 `id` 合并进 `_bigPending`（`LinkedHashMap`，保留首次出现顺序），连击数累加；
2. **背压**：合并后待展示总数超过 `maxBigPending = 100` 时，从最晚加入的类型开始削减，多余计入 `droppedBig`（演示「高并发要限流，而不是无限堆队列」）；
3. 大礼物位空闲时取队首开播，`_activeBigRemain = count - 1`；播完若还有剩余则 token +1、重播同一条（连击逐次展示），否则释放槽位取下一个；
4. 动画 2600ms：`0.6 → 1.0` 弹入 → 停留 → 放大淡出；积压超过 3 个时自动缩短到 **900ms** 加快消化。

> 关键点：widget 的 key 使用 `ValueKey('big-${activeBigToken}')`。每次开播 token 必变，Flutter 不会复用旧 element，`AnimationController` 每次都是全新的——这是修复「大礼物只显示第一个就卡死」的根因。

### 两条通道对照

| 维度 | 小礼物 | 大礼物 |
| --- | --- | --- |
| 同屏槽位 | 3 | 1（独占） |
| 合并方式 | 同 id → `xN` | 同 id → 累加 count |
| 连击处理 | 累加到在屏项的 count | `activeBigRemain` 顺序重播 |
| 队列背压 | 无丢弃（按类型合并天然收敛） | 上限 100，超出按最晚类型丢弃 |
| 单条时长 | 1800ms | 2600ms，积压 > 3 时 900ms |
| UI key | `MergedGift.uid`（实例唯一） | `big-${token}`（每次开播变） |

另外，`GiftManager._notify()` 会把同一事件循环内的多次变更合并成一次微任务 emit。150 条礼物洪峰只触发一次 `setState`，这是小礼物高并发不再卡顿的关键。

## 目录结构

```
flutter_words/
├── lib/
│   ├── main.dart                    # 入口 + 首页卡片 + Isolate 对比页
│   ├── l10n/
│   │   ├── app_en.arb               # 英文文案（模板）
│   │   ├── app_zh.arb               # 中文文案
│   │   └── app_localizations*.dart  # gen_l10n 生成，勿手改
│   ├── pages/
│   │   └── settings_page.dart       # 语言设置（跟随系统 / English / 中文）
│   ├── utils/
│   │   ├── dio_util.dart            # Dio + Logger 封装
│   │   ├── state_management.dart    # Provider / GetX / MVVM 示例
│   │   ├── isolate_util.dart        # 重计算：同步 vs Isolate
│   │   └── language_service.dart    # 语言状态 + 本地持久化
│   └── concurrent/                  # 语音房高并发消息
│       ├── models.dart              # RoomMessage sealed class + Priority
│       ├── parser.dart              # ① 常驻解析 Isolate
│       ├── message_queue.dart       # ② 优先级队列 + 去重
│       ├── room_bloc.dart           # ③ Stream 分发 + 公屏节流
│       ├── connection.dart          # 断线重连（指数退避）
│       ├── simulator.dart           # 消息洪峰模拟器
│       ├── stats.dart               # 统计指标
│       ├── funnel.dart              # 四层漏斗可视化
│       ├── fps_meter.dart           # 实时 FPS
│       ├── widgets.dart             # 公屏列表 / 礼物飘屏 / 麦位图
│       ├── gift_manager.dart        # 礼物工具类（纯 Dart）
│       ├── gift_demo_page.dart      # 礼物规则独立演示
│       └── voice_room_page.dart     # 语音房主页面（组装整条管道）
├── l10n.yaml                        # gen_l10n 配置
├── analysis_options.yaml
└── pubspec.yaml
```

## 技术栈

| 类别 | 选型 |
| --- | --- |
| 框架 | Flutter（Dart SDK `^3.9.2`，Material 3） |
| 状态管理 | Provider `^6.1.5` + GetX `^4.6.6` |
| 网络 | Dio `^5.7.0` + Logger `^2.0.2` |
| 国际化 | `flutter_localizations` + `gen_l10n` |
| 本地存储 | `shared_preferences` `^2.3.0` |
| 并发 | `dart:isolate`（常驻解析 Isolate） |
| 静态检查 | `flutter_lints` `^5.0.0` |

## 快速开始

环境要求：Flutter 3.35+（含 Dart 3.9+）。

```bash
# 1. 拉取依赖
flutter pub get

# 2. 生成国际化代码（pubspec 已开启 generate，但首次/改 arb 后建议显式执行）
flutter gen-l10n

# 3. 查看可用设备
flutter devices

# 4. 运行（按需替换设备 id）
flutter run
```

如果只改代码不涉及 arb，`flutter run` 会自动触发生成；改过 `lib/l10n/*.arb` 后建议先跑一次 `flutter gen-l10n`。

验证静态检查：

```bash
flutter analyze   # 期望：No issues found!
```

### 怎么玩

1. 首页点 **「语音房高并发消息」**；
2. 点 **「模拟一波洪峰」**：瞬间灌入 150 条消息。观察漏斗——「长连接」计数暴涨，但「已分发」平稳推进，公屏不会一次性刷爆；
3. 点 **「自动持续推送」**：模拟真实房间不间断消息流，观察 FPS 角标；
4. 点 **「模拟断线」**：状态变红 → 指数退避重连 → 重连后自动补增量快照；
5. 返回首页点 **「礼物工具类」**：手动验证小礼物合并、同屏 3 个、大礼物独占与排队规则。

## 国际化

- 模板文件 `lib/l10n/app_en.arb`，中文 `lib/l10n/app_zh.arb`；
- 配置见 `l10n.yaml`，生成类为 `AppLocalizations`；
- 新增文案时**两个 arb 都要加**，再执行 `flutter gen-l10n`；
- 语言由 `LanguageService` 统一管理，支持「跟随系统 / English / 中文」，选择结果持久化到本地。

## 设计取舍与已知限制

- **优先级队列**：文章使用 `dart:collection` 的 `PriorityQueue`，本项目改为 `List` + 排序（按 `优先级, seq`）。行为等价，且规避了本机环境对该类型的解析问题。
- **公屏节流位置**：文章放在 UI 层，本项目收敛到 `RoomBloc`（80ms 批量 flush），避免 UI 与业务层双重定时器耦合。
- **大礼物连击**：同一大礼物 `combo = N` 会顺序重播 N 次（积压时每次 900ms）。真实业务常采用「播一次 + 角标显示 xN」，当前实现是演示「逐次展示」的取舍。
- **各层参数**（60ms / 8 条 / 80ms / 200 条 / 100 上限）都是演示用经验值，接入真实 IM SDK 时应按业务 QPS 重新标定。
- **模拟数据**：`simulator.dart` 产生的 JSON、重复 seq、脏数据均为构造，用于验证解析容错与去重链路。

## 参考

- [Flutter 官方文档](https://docs.flutter.dev/)
- [Dart Isolate](https://dart.dev/language/concurrency)
- [gen_l10n 国际化](https://docs.flutter.dev/ui/accessibility-and-internationalization/internationalization)
