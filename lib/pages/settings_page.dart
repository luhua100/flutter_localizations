import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../l10n/app_localizations.dart';
import '../utils/language_service.dart';

/// ============================================================================
/// 设置页面
/// ----------------------------------------------------------------------------
/// 提供语言切换功能：
///   - 跟随系统（默认）
///   - English
///   - 中文
///
/// 选择后立即生效，并通过 shared_preferences 持久化。
/// ============================================================================
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final langService = LanguageService.to;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 语言设置区域标题
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
            child: Text(
              l10n.languageSection,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),

          // 语言单选组（使用 Flutter 3.32+ 的 RadioGroup）
          Obx(() => RadioGroup<AppLang>(
                groupValue: langService.currentLang.value,
                onChanged: (value) {
                  if (value != null) {
                    langService.changeLanguage(value);
                  }
                },
                child: Column(
                  children: [
                    // --- 跟随系统 ---
                    RadioListTile<AppLang>(
                      title: Text(l10n.followSystem),
                      subtitle: Text(
                        langService.currentLocale?.languageCode ?? '',
                      ),
                      value: AppLang.system,
                    ),

                    // --- English ---
                    RadioListTile<AppLang>(
                      title: Text(l10n.english),
                      value: AppLang.english,
                    ),

                    // --- 中文 ---
                    RadioListTile<AppLang>(
                      title: Text(l10n.chinese),
                      value: AppLang.chinese,
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
