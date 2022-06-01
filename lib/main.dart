import 'dart:async';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:mailto/mailto.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

String name = 'Entegrapi';
String panelUrl = '';
String siteUrl = 'https://panel.entegrapi.com/';
String _panelImage = '';
String currTitle = '';
bool _loading = true, _error = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  _panelImage = prefs.getString('panelImage') ?? '';

  //ONESIGNAL Push
  OneSignal.shared.setLogLevel(OSLogLevel.verbose, OSLogLevel.none);
  OneSignal.shared.setAppId("b3967231-2cc2-4d1c-81db-bb3beeff74bc");
  OneSignal.shared.promptUserForPushNotificationPermission().then((accepted) {
    print("Accepted permission: $accepted");
  });
  OneSignal.shared.setNotificationWillShowInForegroundHandler(
      (OSNotificationReceivedEvent event) {
    // Will be called whenever a notification is received in foreground
    // Display Notification, pass null param for not displaying the notification
    event.complete(event.notification);
  });

  OneSignal.shared
      .setNotificationOpenedHandler((OSNotificationOpenedResult result) {
    // Will be called whenever a notification is opened/button pressed.
  });

  OneSignal.shared.setPermissionObserver((OSPermissionStateChanges changes) {
    // Will be called whenever the permission changes
    // (ie. user taps Allow on the permission prompt in iOS)
  });

  OneSignal.shared
      .setSubscriptionObserver((OSSubscriptionStateChanges changes) {
    // Will be called whenever the subscription changes
    // (ie. user gets registered with OneSignal and gets a user ID)
  });

  OneSignal.shared.setEmailSubscriptionObserver(
      (OSEmailSubscriptionStateChanges emailChanges) {
    // Will be called whenever then user's email subscription changes
    // (ie. OneSignal.setEmail(email) is called and the user gets registered
  });
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MyHomePage(),
      theme: ThemeData(primarySwatch: Colors.deepPurple),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late InAppWebViewController controller;
  String mainTitle = '', subtitle = '', theme = '';
  late PullToRefreshController pullToRefreshController;

  final GlobalKey webViewKey = GlobalKey();
  Future<void> _retry() async {
    await Future.delayed(Duration(seconds: 5));
    setState(() {
      _error = false;
    });
  }

  @override
  void initState() {
    super.initState();
    pullToRefreshController = PullToRefreshController(
      onRefresh: () async {
        if (Platform.isAndroid) {
          controller.reload();
          pullToRefreshController.endRefreshing();
        } else if (Platform.isIOS) {
          controller.loadUrl(
              urlRequest: URLRequest(url: await controller.getUrl()));
        }
      },
    );
  }

  Image? _getImage() {
    return _panelImage == ''
        ? null
        : Image(
            image: CachedNetworkImageProvider(
              _panelImage,
            ),
            fit: BoxFit.cover,
          );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: theme == 'login'
          ? AppBar(
              flexibleSpace: _getImage(),
              backgroundColor: Colors.transparent,
              centerTitle: true,
              title: mainTitle == '' ? null : Text(mainTitle),
              bottom: subtitle == ''
                  ? null
                  : PreferredSize(
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Text(
                          subtitle,
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      preferredSize: Size.zero,
                    ),
            )
          : null,
      body: WillPopScope(
          onWillPop: () async {
            controller.goBack();
            return false;
          },
          child: Container(
            decoration: _panelImage == ''
                ? null
                : BoxDecoration(
                    image: DecorationImage(
                        fit: BoxFit.cover,
                        image: CachedNetworkImageProvider(
                          _panelImage,
                        ))),
            child: SafeArea(
              child: Stack(
                children: [
                  _error == false
                      ? InAppWebView(
                          key: webViewKey,
                          initialOptions: InAppWebViewGroupOptions(
                              android: AndroidInAppWebViewOptions(
                                  useHybridComposition: true),
                              crossPlatform: InAppWebViewOptions(
                                  useOnLoadResource: true,
                                  useShouldOverrideUrlLoading: true)),
                          initialUrlRequest: URLRequest(
                              url: Uri.parse('https://panel.entegrapi.com/')),
                          pullToRefreshController: pullToRefreshController,
                          onWebViewCreated:
                              (InAppWebViewController controller) async {
                            this.controller = controller;
                          },
                          onLoadStart: (controller, url) async {
                            setState(() {
                              _loading = true;
                            });
                          },
                          onLoadError: (controller, uri, int, string) {
                            setState(() {
                              _error = true;
                            });
                            pullToRefreshController.endRefreshing();
                          },
                          onLoadStop: (controller, url) async {
                            setState(() {
                              _loading = false;
                            });
                            pullToRefreshController.endRefreshing();
                            if (_error) return;
                            String? title = await controller.getTitle();
                            if (title == currTitle) return;
                            currTitle = title!;
                            if (title.split(' - ').first ==
                                'Sayfa Bulunamadı') {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Sayfa Bulunamadı')));
                              controller.loadUrl(
                                  urlRequest:
                                      URLRequest(url: Uri.parse(panelUrl)));
                            } else if (title.toLowerCase().endsWith('giriş')) {
                              setState(() {
                                theme = 'login';
                              });
                              mainTitle = await controller.evaluateJavascript(
                                  source:
                                      "document.getElementsByClassName('m-login__welcome')[0].textContent;");
                              subtitle = await controller.evaluateJavascript(
                                  source:
                                      "document.getElementsByClassName('m-login__msg')[0].innerText;");
                              _panelImage = await controller.evaluateJavascript(
                                  source:
                                      "document.getElementsByClassName('m-grid__item m-grid__item--fluid m-grid m-grid--center m-grid--hor m-grid__item--order-tablet-and-mobile-2	m-login__content m-grid-item--center')[0].style.backgroundImage");
                              setState(() {
                                mainTitle = mainTitle == 'null'
                                    ? ''
                                    : mainTitle.replaceAll('"', '');
                                subtitle = subtitle == 'null'
                                    ? ''
                                    : subtitle.replaceAll('"', '');
                                _panelImage = _panelImage == 'null'
                                    ? ''
                                    : _panelImage
                                        .replaceAll('"', '')
                                        .split(
                                          '(',
                                        )[1]
                                        .split(')')[0]
                                        .replaceAll("\\", '');
                              });
                              if (_panelImage != '') {
                                final prefs =
                                    await SharedPreferences.getInstance();
                                prefs.setString('panelImage', _panelImage);
                              }
                              controller.evaluateJavascript(
                                  source:
                                      "const elements = document.getElementsByClassName('m-login__content'); while (elements.length > 0) elements[0].remove();");
                            } else if (title.toLowerCase().endsWith('panel')) {
                              setState(() {
                                theme = 'panel';
                              });
                            }
                          },
                          shouldOverrideUrlLoading:
                              (controller, navigationAction) async {
                            if (navigationAction.request.url != null) {
                              if (!navigationAction.request.url!
                                  .toString()
                                  .startsWith('https://panel.entegrapi.com')) {
                                await launchUrl(navigationAction.request.url!,
                                    mode: LaunchMode.externalApplication);
                                return NavigationActionPolicy.CANCEL;
                              }
                              if (navigationAction.request.url!
                                  .toString()
                                  .startsWith('tel')) {
                                await launch('tel:' +
                                    navigationAction.request.url!
                                        .toString()
                                        .split(':')
                                        .last);
                                return NavigationActionPolicy.CANCEL;
                              } else if (navigationAction.request.url!
                                  .toString()
                                  .startsWith('mailto')) {
                                final mailtoLink = Mailto(
                                  to: [
                                    navigationAction.request.url!
                                        .toString()
                                        .split(':')
                                        .last
                                  ],
                                  subject: '',
                                  body: '',
                                );
                                await launch('$mailtoLink');
                                return NavigationActionPolicy.CANCEL;
                              } else if (navigationAction.request.url!
                                  .toString()
                                  .startsWith(
                                      'https://api.whatsapp.com/send?phone')) {
                                if (await canLaunch(
                                    navigationAction.request.url!.toString())) {
                                  launch(
                                      navigationAction.request.url!.toString());
                                }
                                return NavigationActionPolicy.CANCEL;
                              }
                              return NavigationActionPolicy.ALLOW;
                            }
                          })
                      : Center(
                          child: FutureBuilder(
                            future: _retry(),
                            builder: (BuildContext context,
                                AsyncSnapshot<dynamic> snapshot) {
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: CircularProgressIndicator(
                                      color: Theme.of(context).highlightColor,
                                    ),
                                  ),
                                  Container(
                                    color: Theme.of(context).highlightColor,
                                    child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Text(
                                          'Bağlantı hatası, yeniden deneniyor...',
                                        )),
                                  )
                                ],
                              );
                            },
                          ),
                        ),
                  _loading
                      ? Stack(
                          children: [
                            Center(
                              child: Image.asset(
                                'assets/icon/icon.png',
                                width: 20,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Center(
                              child: CircularProgressIndicator(),
                            )
                          ],
                        )
                      : Stack()
                ],
              ),
            ),
          )),
    );
  }
}
