import 'package:flutter/widgets.dart';

import 'domain/app_language.dart';

class AppLanguageScope extends InheritedWidget {
  final AppLanguage language;
  final ValueChanged<AppLanguage> onChanged;

  const AppLanguageScope({
    super.key,
    required this.language,
    required this.onChanged,
    required super.child,
  });

  static AppLanguageScope of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<AppLanguageScope>();
    assert(scope != null, 'AppLanguageScope is missing from the widget tree.');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppLanguageScope oldWidget) {
    return language != oldWidget.language;
  }
}
