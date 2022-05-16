import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'dart:io';
// import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mailto/mailto.dart';
import 'package:webview_flutter_plus/webview_flutter_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';

String name = 'Entegrapi';
String panelUrl = 'https://panel.entegrapi.com/';
String siteUrl = 'https://entegrapi.com';
String _panelImage = '';
bool _isLoading = true, _error = false;
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  _panelImage = prefs.getString('panelImage') ?? '';
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
  late WebViewPlusController controller;
  int loadingPercentage = 0;
  String mainTitle = '', subtitle = '', theme = '';
  Future<void> _retry() async {
    await Future.delayed(Duration(seconds: 5));
    setState(() {
      _error = false;
    });
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
          : PreferredSize(
              child: AppBar(
                flexibleSpace: _getImage(),
                backgroundColor: Colors.transparent,
              ),
              preferredSize:
                  Size.fromHeight(MediaQuery.of(context).size.height * .001)),
      body: WillPopScope(
          onWillPop: () async {
            controller.webViewController.goBack();
            return false;
          },
          child: Stack(
            children: [
              _error == false
                  ? WebViewPlus(
                      javascriptMode: JavascriptMode.unrestricted,
                      initialUrl: panelUrl,
                      onWebViewCreated:
                          (WebViewPlusController controller) async {
                        this.controller = controller;
                      },
                      onPageStarted: (String url) {
                        setState(() {
                          _isLoading = true;
                        });
                      },
                      onWebResourceError: (WebResourceError err) {
                        setState(() {
                          _error = true;
                        });
                      },
                      onPageFinished: (String url) async {
                        setState(() {
                          _isLoading = false;
                        });
                        if (_error) return;
                        String? title =
                            await controller.webViewController.getTitle();
                        if (title?.split(' - ').first == 'Sayfa Bulunamadı') {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Sayfa Bulunamadı')));
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
                          _panelImage = await controller.webViewController
                              .runJavascriptReturningResult(
                                  "document.getElementsByClassName('m-grid__item m-grid__item--fluid m-grid m-grid--center m-grid--hor m-grid__item--order-tablet-and-mobile-1	m-login__content m-grid-item--center')[0].style.backgroundImage");
                          setState(() {
                            mainTitle = mainTitle == 'null'
                                ? ''
                                : mainTitle.replaceAll('"', '');
                            subtitle = subtitle == 'null'
                                ? ''
                                : subtitle.replaceAll('"', '');
                            print(_panelImage);
                            _panelImage = _panelImage == 'null'
                                ? ''
                                : _panelImage
                                    .replaceAll('"', '')
                                    .split(
                                      '(',
                                    )[1]
                                    .split(')')[0]
                                    .replaceAll("\\", '');
                            print(_panelImage);
                          });
                          if (_panelImage != '') {
                            final prefs = await SharedPreferences.getInstance();
                            prefs.setString('panelImage', _panelImage);
                          }
                          controller.webViewController.runJavascript(
                              "const elements = document.getElementsByClassName('m-login__content'); while (elements.length > 0) elements[0].remove();");
                        } else if (title.toLowerCase().endsWith('panel')) {
                          setState(() {
                            theme = 'panel';
                          });
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
                        } else if (request.url.startsWith(
                            'https://api.whatsapp.com/send?phone')) {
                          if (await canLaunch(request.url)) {
                            launch(request.url);
                          }
                          return NavigationDecision.prevent;
                        }
                        return NavigationDecision.navigate;
                      },
                    )
                  : Center(
                      child: FutureBuilder(
                        future: _retry(),
                        builder: (BuildContext context,
                            AsyncSnapshot<dynamic> snapshot) {
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                    'Bağlantı hatası, yeniden deneniyor...'),
                              )
                            ],
                          );
                        },
                      ),
                    ),
              _isLoading
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
          )),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: _error == false && _isLoading == false
          ? (theme == 'site'
              ? FloatingActionButton.extended(
                  tooltip: 'Giriş Yap',
                  onPressed: () async {
                    if (controller.webViewController.currentUrl() != panelUrl)
                      await controller.webViewController.loadUrl(panelUrl);
                    setState(() {
                      theme = 'login';
                    });
                  },
                  label: Text('Panele Giriş Yap'),
                  icon: const Icon(Icons.login))
              : theme == 'login'
                  ? FloatingActionButton.extended(
                      tooltip: 'İncele',
                      onPressed: () {
                        controller.webViewController.loadUrl(siteUrl);
                        setState(() {
                          theme = 'site';
                        });
                      },
                      label: Text('İncele'),
                      icon: const Icon(Icons.explore),
                    )
                  : null)
          : null,
    );
  }
}
