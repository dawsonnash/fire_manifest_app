import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';

class AnalyticsRouteObserver extends RouteObserver<PageRoute<dynamic>> {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _sendScreenView(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _sendScreenView(newRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _sendScreenView(previousRoute);
  }

  void _sendScreenView(Route<dynamic>? route) {
    if (route is PageRoute) {
      final screenName = route.settings.name ?? route.runtimeType.toString();
      FirebaseAnalytics.instance.logScreenView(
        screenName: screenName,
        screenClass: screenName,
      );
    }
  }
}
