/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'dart:async';
import 'dart:isolate';

import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:nt4f04unds_widgets/nt4f04unds_widgets.dart';

import 'routes/routes.dart';

/// Builds up the error report message from the exception and stacktrace.
String buildErrorReport(dynamic ex, dynamic stack) {
  return '''
$ex

$stack''';
}

Future<void> reportError(dynamic ex, StackTrace stack) async {}

Future<void> reportFlutterError(FlutterErrorDetails details) async {}

class _WidgetsBindingObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      /// This ensures that proper UI will be applied when activity is resumed.
      ///
      /// See:
      /// * https://github.com/flutter/flutter/issues/21265
      /// * https://github.com/ryanheise/audio_service/issues/662
      ///
      /// [SystemUiOverlayStyle.statusBarBrightness] is only honored on iOS,
      /// so I can safely use that here.
      final lastUi = SystemUiStyleController.lastUi;
      SystemUiStyleController.setSystemUiOverlay(SystemUiStyleController.lastUi
          .copyWith(
              statusBarBrightness: lastUi.statusBarBrightness == null ||
                      lastUi.statusBarBrightness == Brightness.dark
                  ? Brightness.light
                  : Brightness.dark));

      /// Defensive programming if I some time later decide to add iOS support.
      SystemUiStyleController.setSystemUiOverlay(SystemUiStyleController.lastUi
          .copyWith(
              statusBarBrightness: lastUi.statusBarBrightness == Brightness.dark
                  ? Brightness.light
                  : Brightness.dark));
    }
  }
}

Future<void> main() async {
  // Disabling automatic system UI adjustment, which causes system nav bar
  // color to be reverted to black when the bottom player route is being expanded.
  //
  // Related to https://github.com/flutter/flutter/issues/40590
  final WidgetsBinding binding = WidgetsFlutterBinding.ensureInitialized();
  binding.renderView.automaticSystemUiAdjustment = false;

  Isolate.current.addErrorListener(RawReceivePort((pair) async {
    final List<dynamic> errorAndStacktrace = pair;
    await reportError(errorAndStacktrace.first, errorAndStacktrace.last);
  }).sendPort);
  FlutterError.onError = reportFlutterError;
  runZonedGuarded<Future<void>>(() async {
    WidgetsBinding.instance.addObserver(_WidgetsBindingObserver());

    runApp(const App());
  }, reportError);
}

class App extends StatefulWidget {
  const App({Key key}) : super(key: key);

  static void rebuildAllChildren() {
    void rebuild(Element el) {
      el.markNeedsBuild();
      el.visitChildren(rebuild);
    }

    (AppRouter.instance.navigatorKey.currentContext as Element)
        .visitChildren(rebuild);
  }

  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      localizationsDelegates: const [
        NFLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      routerDelegate: AppRouter.instance,
      routeInformationParser: AppRouteInformationParser(),
    );
  }
}
