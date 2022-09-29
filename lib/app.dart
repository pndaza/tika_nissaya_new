import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'deep_link_handler.dart';
import 'screens/home/home_page.dart';
import 'screens/home/home_view_controller.dart';
import 'screens/nsy_list/nsy_choice.dart';
import 'utils/platform_helper.dart';

// const homeRoute = '/';
// const pageNumberRoute = '/page_number';
// const nsyListRoute = '/nsy_list';
// const readerRoute = '/reader';

class MyApp extends ConsumerStatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  ConsumerState<MyApp> createState() => MyAppState();
}

class MyAppState extends ConsumerState<MyApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late final DeepLinkHandler _mobileDeepLink;
  late final AppLinks _appLinks;
  StreamSubscription<String>? _mobilelinkSubscription;
  StreamSubscription<Uri>? _desktoplinkSubscription;

  @override
  void initState() {
    super.initState();
    if (isMobile) {
      // _mobileDeepLinkBloc = DeepLinkHandler();
      initMobileDeepLinks();
    }
    if (isDesktop) {
      initDesktopDeepLinks();
    }
  }

  @override
  void dispose() {
    _mobilelinkSubscription?.cancel();
    _desktoplinkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tika Nissaya',
      theme: ThemeData(primarySwatch: Colors.teal),
      darkTheme: ThemeData.dark(),
      themeMode: themeMode,
      navigatorKey: _navigatorKey,
      home: const Home(),
      /*
      home: Platform.isMacOS
          ? StreamBuilder<Uri>(
              stream: _appLinks.uriLinkStream,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  debugPrint(snapshot.data.toString());
                  debugPrint('opening from deep link');
                  return DeepLinkView(
                      key: Key(snapshot.data!.toString()),
                      url: snapshot.data!.toString());
                } else {
                  return const Home();
                }
              })
          : StreamBuilder<String>(
              stream: _mobileDeepLink.state,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  debugPrint(snapshot.data);
                  debugPrint('opening from deep link');
                  return DeepLinkView(
                      key: Key(snapshot.data!), url: snapshot.data!);
                } else {
                  return const Home();
                }
              }),
              */
    );
  }

  Future<void> initMobileDeepLinks() async {
    _mobileDeepLink = DeepLinkHandler();
    _mobilelinkSubscription = _mobileDeepLink.state.listen((uri) {
      debugPrint('onAppLink: $uri');
      openMobileAppLink(uri);
    });
  }

  Future<void> initDesktopDeepLinks() async {
    _appLinks = AppLinks();

    // Check initial link if app was in cold state (terminated)
    final appLink = await _appLinks.getInitialAppLink();
    if (appLink != null) {
      debugPrint('getInitialAppLink: $appLink');
      openDesktopAppLink(appLink);
    }

    // Handle link when app is in warm state (front or background)
    _desktoplinkSubscription = _appLinks.uriLinkStream.listen((uri) {
      debugPrint('onAppLink: $uri');
      openDesktopAppLink(uri);
    });
  }

  void openMobileAppLink(String url) {
    final paliBookId = parseBookId(url);
    final pageNumber = parsePageNumber(url);
    if (paliBookId != null && pageNumber != null) {
      final route = nsyChoiceRoute(
        paliBookId: paliBookId,
        pageNumber: int.parse(pageNumber),
      );
      _navigatorKey.currentState?.pushAndRemoveUntil(route, (Route<dynamic> route) => false);
    }
  }

  void openDesktopAppLink(Uri uri) {
    final url = uri.toString();
    final paliBookId = parseBookId(url);
    final pageNumber = parsePageNumber(url);
    debugPrint(paliBookId);
    debugPrint(pageNumber);
    if (paliBookId != null && pageNumber != null) {
      final route = nsyChoiceRoute(
        paliBookId: paliBookId,
        pageNumber: int.parse(pageNumber),
      );
      _navigatorKey.currentState?.pushAndRemoveUntil(route, (Route<dynamic> route) => false);
    }
  }

  MaterialPageRoute nsyChoiceRoute(
      {required String paliBookId, required int pageNumber}) {
    return MaterialPageRoute(
      builder: (_) => NsyChoice(
        paliBookID: paliBookId,
        paliBookPageNumber: pageNumber,
        isOpenFromDeepLink: true,
      ),
    );
  }

  String? parseBookId(String url) {
    RegExp regexId = RegExp(r'\w+_\w+_\d+(_\d+)?');
    final matchId = regexId.firstMatch(url);
    return matchId?.group(0);
  }

  String? parsePageNumber(String url) {
    RegExp regexPage = RegExp(r'\d+$');
    final matchPage = regexPage.firstMatch(url);
    return matchPage?.group(0);
  }
}
