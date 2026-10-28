import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';

import '../l10n/app_localizations.dart';

/// ============================================================================
/// 状态管理对比：Provider vs GetX
/// ----------------------------------------------------------------------------
/// 本文件在同一个文件中展示了 Provider 和 GetX 两种状态管理方案的使用方式，
/// 并在最后给出了 GetX 的 MVVM 架构示例，方便对比学习。
///
/// 依赖插件：
///   - provider: ^6.1.5+1 （官方推荐的状态管理库，基于 InheritedWidget）
///   - get: ^4.6.6         （轻量且功能强大的状态管理 + 路由 + 依赖注入库）
///
/// 快速对比：
/// ┌──────────┬─────────────────────┬──────────────────────┐
/// │  特性    │      Provider       │        GetX          │
/// ├──────────┼─────────────────────┼──────────────────────┤
/// │ 学习成本 │ 较高（需要理解上下文）│ 低（API 简单直观）    │
/// │ 样板代码 │ 较多                  │ 极少                  │
/// │ 路由管理 │ 需配合 Navigator      │ 内置路由              │
/// │ 依赖注入 │ 需配合其他方案        │ 内置依赖注入          │
/// │ 响应式   │ ChangeNotifier       │ Rx 响应式变量         │
/// │ 性能     │ 良好（精确重建）      │ 良好（自动优化）      │
/// └──────────┴─────────────────────┴──────────────────────┘
/// ============================================================================

// ============================================================================
// 一、Provider 状态管理
// ============================================================================

/// --------------------------------------------------------------------------
/// Provider 的数据模型（ViewModel）
/// --------------------------------------------------------------------------
/// 继承 ChangeNotifier，调用 notifyListeners() 通知监听者重建。
///
/// 使用步骤：
///   1. 创建继承 ChangeNotifier 的类
///   2. 在 main.dart 中用 ChangeNotifierProvider 包裹
///   3. 在 Widget 中用 context.watch / context.read / Consumer 获取
/// --------------------------------------------------------------------------
class CounterProvider extends ChangeNotifier {
  int _count = 0;

  int get count => _count;

  /// 增加计数
  void increment() {
    _count++;
    notifyListeners(); // 通知所有监听者更新 UI
  }

  /// 减少计数
  void decrement() {
    _count--;
    notifyListeners();
  }

  /// 重置计数
  void reset() {
    _count = 0;
    notifyListeners();
  }
}

/// --------------------------------------------------------------------------
/// Provider 方式的页面 Widget
/// --------------------------------------------------------------------------
/// - [context.watch]：监听状态变化，状态改变时重建 Widget
/// - [context.read]：仅读取状态，不监听变化（适合在事件回调中使用）
/// - [Consumer]：精准重建，只重建 Consumer 包裹的部分
/// --------------------------------------------------------------------------
class ProviderCounterPage extends StatelessWidget {
  const ProviderCounterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.providerCounterTitle)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(l10n.currentCount),
            // 使用 context.watch 监听状态变化
            Text(
              '${context.watch<CounterProvider>().count}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            // 使用 Consumer 精准重建，避免整个页面重建
            Consumer<CounterProvider>(
              builder: (context, provider, child) {
                return ElevatedButton(
                  onPressed: provider.reset,
                  child: Text(l10n.resetConsumer),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // 使用 context.read 读取状态（不监听，适合按钮回调）
          FloatingActionButton(
            heroTag: 'provider_decrement',
            onPressed: () => context.read<CounterProvider>().decrement(),
            child: const Icon(Icons.remove),
          ),
          const SizedBox(width: 10),
          FloatingActionButton(
            heroTag: 'provider_increment',
            onPressed: () => context.read<CounterProvider>().increment(),
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 二、GetX 状态管理
// ============================================================================

/// --------------------------------------------------------------------------
/// GetX 的控制器（Controller）
/// --------------------------------------------------------------------------
/// GetX 使用 GetxController 管理状态，通过 .obs 让变量变为响应式。
///
/// 使用步骤：
///   1. 创建继承 GetxController 的类
///   2. 用 Get.put() 注册控制器
///   3. 在 Widget 中用 Obx / GetX / GetBuilder 包裹以响应变化
/// --------------------------------------------------------------------------
class CounterController extends GetxController {
  // .obs 后缀将普通变量转为响应式变量（RxInt）
  final RxInt count = 0.obs;

  /// 增加计数（直接修改 .value）
  void increment() => count.value++;

  /// 减少计数
  void decrement() => count.value--;

  /// 重置计数
  void reset() => count.value = 0;

  // --- GetX 生命周期回调（类似 StatefulWidget）---
  @override
  void onInit() {
    super.onInit();
    // 控制器初始化时调用，可做一些初始化操作
    debugPrint('CounterController 初始化');
  }

  @override
  void onClose() {
    // 控制器销毁时调用，可做资源释放
    debugPrint('CounterController 销毁');
    super.onClose();
  }
}

/// --------------------------------------------------------------------------
/// GetX 方式的页面 Widget
/// --------------------------------------------------------------------------
/// - Obx(() => Widget)：响应式重建，监听内部使用的所有 Rx 变量
/// - [GetX]：类似 Obx，但可获取控制器实例
/// - [GetBuilder]：简单状态管理，需手动调用 update()
/// --------------------------------------------------------------------------
class GetCounterPage extends StatelessWidget {
  GetCounterPage({super.key});

  // 注册控制器（依赖注入），也可在 main.dart 中全局注册
  final CounterController controller = Get.put(CounterController());

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.getCounterTitle)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(l10n.currentCount),
            // 使用 Obx 包裹，当 count 变化时自动重建
            Obx(() => Text(
                  '${controller.count.value}',
                  style: Theme.of(context).textTheme.headlineMedium,
                )),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: controller.reset,
              child: Text(l10n.reset),
            ),
          ],
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'get_decrement',
            onPressed: controller.decrement,
            child: const Icon(Icons.remove),
          ),
          const SizedBox(width: 10),
          FloatingActionButton(
            heroTag: 'get_increment',
            onPressed: controller.increment,
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 三、GetX 的 MVVM 架构示例
// ============================================================================
//
// MVVM 分层：
//   Model      —— 数据模型（纯数据类）
//   ViewModel  —— 业务逻辑 + 状态管理（GetxController）
//   View       —— UI 展示（StatelessWidget + Obx）
//
// 优势：
//   - 业务逻辑与 UI 分离，便于测试
//   - ViewModel 可独立于 UI 进行单元测试
//   - 代码结构清晰，便于维护

/// --------------------------------------------------------------------------
/// Model 层：用户数据模型
/// --------------------------------------------------------------------------
class UserModel {
  final String name;
  final int age;
  final String avatar;

  UserModel({
    required this.name,
    required this.age,
    required this.avatar,
  });

  /// 从 JSON 反序列化
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      name: json['name'] ?? '',
      age: json['age'] ?? 0,
      avatar: json['avatar'] ?? '',
    );
  }

  /// 序列化为 JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'age': age,
      'avatar': avatar,
    };
  }
}

/// --------------------------------------------------------------------------
/// ViewModel 层：用户控制器（处理业务逻辑 + 状态管理）
/// --------------------------------------------------------------------------
class UserViewModel extends GetxController {
  // 响应式状态：用户列表
  final RxList<UserModel> userList = <UserModel>[].obs;

  // 响应式状态：加载中
  final RxBool isLoading = false.obs;

  // 响应式状态：选中的用户
  final Rx<UserModel?> selectedUser = Rx<UserModel?>(null);

  /// 模拟从网络加载用户数据
  Future<void> loadUsers() async {
    isLoading.value = true;
    try {
      // 模拟网络请求延迟
      await Future.delayed(const Duration(seconds: 1));

      // 模拟返回的数据
      final mockData = [
        {'name': '张三', 'age': 25, 'avatar': ''},
        {'name': '李四', 'age': 30, 'avatar': ''},
        {'name': '王五', 'age': 28, 'avatar': ''},
      ];

      // 将 JSON 转为 Model 并赋值给响应式列表
      userList.assignAll(mockData.map((e) => UserModel.fromJson(e)).toList());
    } finally {
      isLoading.value = false;
    }
  }

  /// 选中某个用户
  void selectUser(UserModel user) {
    selectedUser.value = user;
  }

  /// 添加用户
  void addUser(UserModel user) {
    userList.add(user);
  }

  /// 删除用户
  void removeUser(UserModel user) {
    userList.remove(user);
  }
}

/// --------------------------------------------------------------------------
/// View 层：用户列表页面（只负责 UI 展示，不包含业务逻辑）
/// --------------------------------------------------------------------------
class UserListPage extends StatelessWidget {
  UserListPage({super.key});

  // 注册 ViewModel
  final UserViewModel viewModel = Get.put(UserViewModel());

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.mvvmUserListTitle),
        actions: [
          // 加载数据按钮
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: viewModel.loadUsers,
          ),
        ],
      ),
      body: Obx(() {
        // 加载中显示 loading
        if (viewModel.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        // 空数据提示
        if (viewModel.userList.isEmpty) {
          return Center(child: Text(l10n.noDataHint));
        }

        // 显示列表
        return ListView.builder(
          itemCount: viewModel.userList.length,
          itemBuilder: (context, index) {
            final user = viewModel.userList[index];
            return ListTile(
              leading: CircleAvatar(child: Text(user.name[0])),
              title: Text(user.name),
              subtitle: Text(l10n.ageLabel(user.age)),
              onTap: () => viewModel.selectUser(user),
            );
          },
        );
      }),
    );
  }
}

// ============================================================================
// 四、对比总结
// ============================================================================
//
// Provider：
//   ✅ 优点：官方推荐，社区生态成熟，适合大型项目规范管理
//   ❌ 缺点：样板代码多，需要理解 context 概念，路由/DI 需额外配置
//   适合：大型团队、需要严格规范的项目
//
// GetX：
//   ✅ 优点：API 简洁，内置路由/DI/状态管理/国际化/主题，开发效率高
//   ❌ 缺点：非官方，学习曲线虽低但 Rx 概念需适应，调试稍复杂
//   适合：中小型项目、快速迭代、个人开发者
//
// MVVM 推荐使用 GetX，因为：
//   1. GetxController 天然适合作为 ViewModel
//   2. 响应式变量（.obs）让数据绑定非常简洁
//   3. 生命周期回调（onInit/onClose）便于资源管理
//   4. 依赖注入让 ViewModel 可复用、可测试
// ============================================================================
