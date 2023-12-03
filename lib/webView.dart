// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pusher_beams/pusher_beams.dart';

class MainScreen extends StatefulWidget {
  // final String authToken;
  const MainScreen({
    Key? key,
    // required this.authToken,
  }) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  WebViewController? _webViewController;
  String authToken = '';
  String currentURL = "https://app.gbpn.com/login";
  bool? isSubcribed;
  late SharedPreferences sharedPreferences;
  @override
  void initState() {
    super.initState();
    // Enable virtual display.
    // PusherBeams.instance.clearAllState();

    if (Platform.isAndroid) WebView.platform = AndroidWebView();
    SharedPreferences.getInstance().then((value) async {
      sharedPreferences = value;
      isSubcribed = sharedPreferences.getBool('isSubscribed') ?? false;
      print(isSubcribed);
      setState(() {});
      var status = await Permission.notification.status;
      if (status.isDenied) {
        status = await Permission.notification.request();
        print(status.isGranted);
      }

// You can also directly ask permission about its status.
      // if (await Permission.location.isRestricted) {
      // The OS restricts access, for example, because of parental controls.
      // }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: WebView(
        initialUrl: 'about:blank',
        // onPageStarted: (url) => print(url),
        javascriptMode: JavascriptMode.unrestricted,
        onWebViewCreated: (controller) {
          print("This is token");

          _webViewController = controller;
          _webViewController!.loadUrl(currentURL,
              headers: {'needs_subscription': (!isSubcribed!).toString()});
        },
        // onPageFinished: (p) {
        //   if (p != currentURL) {
        //     currentURL = p;
        //     _webViewController!.loadUrl(currentURL,
        //         headers: {'Authorization': "Bearer ${widget.authToken}"});
        //     print(currentURL);
        //   }
        // },
        javascriptChannels: <JavascriptChannel>{
          JavascriptChannel(
            name: 'mobileApp',
            onMessageReceived: (JavascriptMessage message) async {
              print("Log in");
              print(message.message);
              print(message.toString());
              Map myMsg = jsonDecode(message.message);
              if (myMsg['action'] == 'setBearerToken') {
                print(myMsg['payload']);
                Map payload = myMsg['payload'];
                getSecure(
                    payload['user_id'].toString(), payload['token'], context);
              } else if (myMsg['action'] == 'logout') {
                print("Logout");
                PusherBeams.instance.clearAllState();
              }
              // getSecure('userID', 'token', context);
              _webViewController!.runJavascript("console.log('SUCCESS')");
              // getSecure(message.message);
            },
          ),
        },
      ),
    );
  }

  getSecure(String userId, String token, BuildContext context) async {
    print(token);

    final BeamsAuthProvider provider = BeamsAuthProvider()
      ..authUrl = 'https://app.gbpn.com/pusher/beams-auth'
      ..headers = {
        'Content-Type': 'application/json',
        'Authorization': "Bearer $token",
      }
      ..queryParams = {
        'page': '1',
      }
      ..credentials = 'omit';
    await PusherBeams.instance.setUserId(userId, provider, (error) {
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              backgroundColor: Colors.red, content: Text("Login error:$error")),
        );
      }
      print("YOOO");
    });
  }
}
