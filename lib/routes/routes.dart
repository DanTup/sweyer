/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart' hide LicensePage, SearchDelegate;

abstract class _Routes<T extends Object> extends Equatable {
  const _Routes(this.location, [this.arguments]);

  final String location;
  final T arguments;

  /// Value key to pass in to the [Page].
  ValueKey<String> get key => ValueKey(location);

  @override
  List<Object> get props => [location];
}

class AppRoutes<T extends Object> extends _Routes<T> {
  const AppRoutes._(String location, [T arguments])
      : super(location, arguments);

  static const initial = AppRoutes<void>._('/');
  static const settings = AppRoutes<void>._('/settings');
  static const themeSettings = AppRoutes<void>._('/settings/theme');
  static const licenses = AppRoutes<void>._('/settings/licenses');
  static const dev = AppRoutes<void>._('/dev');
}

class SearchArguments {
  const SearchArguments({this.query = '', this.openKeyboard = true});

  final String query;
  final bool openKeyboard;
}

class AppRouteInformationParser extends RouteInformationParser<AppRoutes> {
  @override
  Future<AppRoutes> parseRouteInformation(
      RouteInformation routeInformation) async {
    return AppRoutes._(routeInformation.location);
  }

  @override
  RouteInformation restoreRouteInformation(AppRoutes configuration) {
    return RouteInformation(location: configuration.location);
  }
}

mixin _DelegateMixin<T extends _Routes> on RouterDelegate<T>, ChangeNotifier {
  List<T> get _routes;
  List<T> get routes => List.unmodifiable(_routes);

  /// Goes to some route.
  ///
  /// By default, if route already in the stack, removes all routes on top of it.
  ///
  /// However, if [allowStackSimilar] is `true`, then if similar route is on top,
  /// for example [HomeRoutes.album], and other one is pushed, it will be stacked on top.
  void goto(T route, [bool allowStackSimilar = false]) {
    final index = !allowStackSimilar
        ? _routes.indexOf(route)
        : _routes.lastIndexOf(route);
    if (!allowStackSimilar
        ? index > 0
        : index > 0 && index != _routes.length - 1) {
      for (int i = index + 1; i < _routes.length; i++) {
        _routes.remove(_routes[i]);
      }
    } else {
      _routes.add(route);
    }
    notifyListeners();
  }
}

class AppRouter extends RouterDelegate<AppRoutes>
    with ChangeNotifier, _DelegateMixin, PopNavigatorRouterDelegateMixin {
  AppRouter._();
  static final instance = AppRouter._();

  final List<AppRoutes> __routes = [AppRoutes.initial];
  @override
  List<AppRoutes> get _routes => __routes;

  // for web applicatiom
  @override
  AppRoutes get currentConfiguration => _routes.last;

  @override
  Future<void> setNewRoutePath(AppRoutes configuration) async {}

  @override
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (BuildContext context, setState) {
        return Navigator(
          key: navigatorKey,
          pages: <Page<void>>[
            MaterialPage(
              key: AppRoutes.initial.key,
              child: const Text('My page'),
            ),
          ],
        );
      },
    );
  }
}
