import 'package:flutter/material.dart';

class HomeProvider extends ChangeNotifier {
  HomeProvider();

  String getGreetingKey() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'greeting_morning';
    if (hour < 15) return 'greeting_afternoon';
    if (hour < 18) return 'greeting_evening';
    return 'greeting_night';
  }
}
