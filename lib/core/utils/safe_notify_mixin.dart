import 'package:flutter/foundation.dart';

mixin SafeNotifyMixin on ChangeNotifier {
  void safeNotify() {
    if (hasListeners) {
      notifyListeners();
    }
  }
}
