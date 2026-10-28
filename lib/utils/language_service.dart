import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ============================================================================
/// 语言管理服务
/// ----------------------------------------------------------------------------
/// 功能：
///   - 管理应用语言（跟随系统 / English / 中文）
///   - 使用 shared_preferences 持久化用户选择
///   - 通过 GetX 响应式状态 + Get.updateLocale() 实现切换
///
/// 使用方式：
///   1. 在 main() 中初始化：await LanguageService.to.init();
///   2. 读取当前语言：LanguageService.to.currentLang
///   3. 切换语言：LanguageService.to.changeLanguage(AppLang.system);
/// ============================================================================

/// 语言选项枚举
enum AppLang {
  system,  // 跟随系统
  english, // English
  chinese, // 中文
}

class LanguageService extends GetxController {
  /// 单例获取方式
  static LanguageService get to => Get.find<LanguageService>();

  /// SharedPreferences 存储的 key
  static const String _storageKey = 'app_language';

  /// 当前选择的语言（响应式）
  final Rx<AppLang> currentLang = AppLang.system.obs;

  late SharedPreferences _prefs;

  /// --------------------------------------------------------------------------
  /// 初始化：从本地存储读取用户上次的语言选择并应用
  /// --------------------------------------------------------------------------
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final savedIndex = _prefs.getInt(_storageKey);
    if (savedIndex != null && savedIndex >= 0 && savedIndex < AppLang.values.length) {
      currentLang.value = AppLang.values[savedIndex];
    } else {
      currentLang.value = AppLang.system;
    }
    // 应用语言
    _applyLocale(currentLang.value);
  }

  /// --------------------------------------------------------------------------
  /// 切换语言
  /// --------------------------------------------------------------------------
  /// [lang] 目标语言
  /// 切换后会自动持久化并通过 Get.updateLocale 生效
  /// --------------------------------------------------------------------------
  Future<void> changeLanguage(AppLang lang) async {
    currentLang.value = lang;
    await _prefs.setInt(_storageKey, lang.index);
    _applyLocale(lang);
  }

  /// --------------------------------------------------------------------------
  /// 应用语言到 GetX / MaterialApp
  /// --------------------------------------------------------------------------
  void _applyLocale(AppLang lang) {
    switch (lang) {
      case AppLang.system:
        // 设置为 null = 跟随系统语言
        // 注意：Get.updateLocale 不接受 null，所以直接设置 Get.locale
        Get.locale = null;
        break;
      case AppLang.english:
        Get.locale = const Locale('en');
        break;
      case AppLang.chinese:
        Get.locale = const Locale('zh');
        break;
    }
    // 触发应用重建以应用新语言
    Get.forceAppUpdate();
  }

  /// 获取当前生效的 Locale（用于显示当前语言名称）
  Locale? get currentLocale {
    switch (currentLang.value) {
      case AppLang.system:
        return Get.deviceLocale;
      case AppLang.english:
        return const Locale('en');
      case AppLang.chinese:
        return const Locale('zh');
    }
  }
}
