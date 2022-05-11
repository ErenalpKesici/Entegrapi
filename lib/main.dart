import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'dart:io';
// import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mailto/mailto.dart';
import 'package:webview_flutter_plus/webview_flutter_plus.dart';
import 'package:get/get.dart';

String name = 'Entegrapi';
String panelUrl = 'https://msglashing.com/admin';
String siteUrl = 'https://entegrapi.com';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      home: MyHomePage(),
      theme: ThemeData(primarySwatch: Colors.purple),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late WebViewPlusController controller;
  int loadingPercentage = 0;
  String mainTitle = '',
      subtitle = '',
      drawerLogo = '',
      drawerLogoLink = '',
      theme = '';
  List drawerItems = List.empty(growable: true);
  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) WebViewPlus.platform = SurfaceAndroidWebView();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: theme == 'panel'
          ? Drawer(
              child: ListView(children: [
                drawerLogo == ''
                    ? Container()
                    : DrawerHeader(
                        child: ListTile(
                          title: Image.network(drawerLogo),
                          onTap: () {
                            controller.loadUrl(drawerLogoLink);
                          },
                        ),
                      ),
                ListTile(
                  onTap: () {},
                  leading: Icon(Icons.abc),
                  trailing: Text('asda'),
                ),
                ListTile(
                  onTap: () {},
                  leading: Icon(Icons.abc),
                ),
              ]),
            )
          : null,
      appBar: theme == 'login'
          ? AppBar(
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
          : theme == 'panel'
              ? AppBar(
                  actions: [
                    IconButton(
                        onPressed: () {
                          controller.webViewController.runJavascript(
                              "document.getElementsByClassName('btn m-btn--pill    btn-secondary m-btn m-btn--custom m-btn--label-brand m-btn--bolder')[0].click()");
                        },
                        icon: Icon(Icons.abc))
                  ],
                )
              : PreferredSize(
                  child: AppBar(),
                  preferredSize: Size.fromHeight(
                      MediaQuery.of(context).size.height * .001)),
      body: WillPopScope(
        onWillPop: () async {
          controller.webViewController.goBack();
          return false;
        },
        child: WebViewPlus(
          // gestureRecognizers: Set()
          //   ..add(Factory<VerticalDragGestureRecognizer>(
          //       () => VerticalDragGestureRecognizer()
          //         ..onDown = (DragDownDetails dragDownDetails) {
          //           print(dragDownDetails.toString());
          //           controller.webViewController.getScrollY().then((value) {
          //             if (value == 0 &&
          //                 dragDownDetails.globalPosition.direction < 1) {
          //               controller.webViewController.reload();
          //             }
          //           });
          //         }
          //         ..onCancel = () {
          //           print('e ');
          //         })),
          javascriptMode: JavascriptMode.unrestricted,
          initialUrl: panelUrl,
          onWebViewCreated: (WebViewPlusController controller) async {
            this.controller = controller;
          },
          // javascriptChannels: Set.from([
          //   JavascriptChannel(
          //       name: 'Status',
          //       onMessageReceived: (JavascriptMessage message) async {
          //         String status = message.message;
          //         await controller.webViewController.runJavascript(
          //             '''var date = new Date();date.setTime(date.getTime()+(30*24*60*60*1000));document.cookie = "status=$status; expires=" + date.toGMTString();''');
          //         print('mess: ' + status);
          //       })
          // ]),
          onPageFinished: (String url) async {
            String? title = await controller.webViewController.getTitle();
            print(title);
            if (title?.split(' - ').first == 'Sayfa Bulunamadı') {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sayfa Bulunamadı')));
              controller.webViewController
                  .loadUrl(theme == 'panel' ? panelUrl : siteUrl);
            } else if (title!.toLowerCase().endsWith('giriş')) {
              setState(() {
                theme = 'login';
              });
              mainTitle = await controller.webViewController
                  .runJavascriptReturningResult(
                      "document.getElementsByClassName('m-login__welcome')[0].textContent;");
              subtitle = await controller.webViewController
                  .runJavascriptReturningResult(
                      "document.getElementsByClassName('m-login__msg')[0].innerText;");
              mainTitle = mainTitle.replaceAll('"', '');
              subtitle = subtitle.replaceAll('"', '');
              setState(() {
                mainTitle = mainTitle == 'null' ? '' : mainTitle;
                subtitle = subtitle == 'null' ? '' : subtitle;
                ;
              });
              controller.webViewController.runJavascript(
                  "const elements = document.getElementsByClassName('m-login__content'); while (elements.length > 0) elements[0].remove();");
            } else if (title.toLowerCase().endsWith('panel')) {
              setState(() {
                theme = 'panel';
              });
              drawerLogoLink = await controller.webViewController
                  .runJavascriptReturningResult(
                      "document.getElementsByClassName('m-brand__logo-wrapper')[0].href");
              drawerLogoLink = drawerLogoLink.replaceAll('"', '');
              drawerLogo = await controller.webViewController
                  .runJavascriptReturningResult(
                      "document.getElementsByClassName('m-brand__logo-wrapper')[0].children[0].src");
              drawerLogo = drawerLogo.replaceAll('"', '');

              print(await controller.webViewController.runJavascriptReturningResult(
                  "class Tile{} let ret = ''; const items = document.getElementsByClassName('m-menu__nav  m-menu__nav--dropdown-submenu-arrow ')[0].children; for(let i = 0; i<items.length; i++){if(items[i].children[0].tagName == 'A')ret+=(items[i].children[0].href); ret;}"));
              setState(() {
                drawerLogo;
                drawerLogoLink;
              });
              controller.webViewController.runJavascript(
                  "document.getElementById('m_header').style.display = 'none';");
            }
          },
          navigationDelegate: (NavigationRequest request) async {
            if (request.url.startsWith('tel')) {
              await launch('tel:' + request.url.split(':').last);
              return NavigationDecision.prevent;
            } else if (request.url.startsWith('mailto')) {
              final mailtoLink = Mailto(
                to: [request.url.split(':').last],
                subject: '',
                body: '',
              );
              await launch('$mailtoLink');
              return NavigationDecision.prevent;
            } else if (request.url
                .startsWith('https://api.whatsapp.com/send?phone')) {
              if (await canLaunch(request.url)) {
                launch(request.url);
              }
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      ),
      floatingActionButton: Stack(
        children: [
          theme == 'site'
              ? Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                        MediaQuery.of(context).size.width * .1, 0, 0, 0),
                    child: FloatingActionButton.extended(
                        tooltip: 'Giriş Yap',
                        onPressed: () async {
                          if (controller.webViewController.currentUrl() !=
                              panelUrl)
                            await controller.webViewController
                                .loadUrl(panelUrl);
                          setState(() {
                            theme = 'login';
                          });
                          Get.changeTheme(
                              ThemeData(primarySwatch: Colors.purple));
                        },
                        label: Text('Panele Giriş Yap'),
                        icon: const Icon(Icons.login)),
                  ),
                )
              : Container(),
          theme == 'login'
              ? Align(
                  alignment: Alignment.bottomRight,
                  child: FloatingActionButton.extended(
                    tooltip: 'İncele',
                    onPressed: () {
                      controller.webViewController.loadUrl(siteUrl);
                      setState(() {
                        theme = 'site';
                      });
                      Get.changeTheme(ThemeData(primarySwatch: Colors.red));
                    },
                    label: Text('İncele'),
                    icon: const Icon(Icons.explore),
                  ))
              : Container()
        ],
      ),
      // bottomNavigationBar: theme == 'panel'
      //     ? BottomNavigationBar(
      //         onTap: (int idx) {
      //           if (idx == 1) {
      //             controller.webViewController.runJavascript(
      //                 "document.getElementsByClassName('m-nav__link m-dropdown__toggle')[1].click();");
      //           }
      //         },
      //         items: [
      //             BottomNavigationBarItem(
      //                 icon: Icon(Icons.r_mobiledata_outlined), label: 'asd'),
      //             BottomNavigationBarItem(
      //                 icon: Icon(Icons.account_circle), label: 'Hesap')
      //           ])
      //     : null,
    );
  }
}
