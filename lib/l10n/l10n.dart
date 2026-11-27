import 'package:flutter/widgets.dart';

import 'generated/app_l10n.dart';

export 'generated/app_l10n.dart';

extension AppL10nContext on BuildContext {
  /// The app's texts in the current language.
  AppL10n get l10n => AppL10n.of(this);
}
