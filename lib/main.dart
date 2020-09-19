// ===== コード概要 =====
//  これはアプリ実行に必要なコード。
//  通知機能に必要なコードはここに書くが、通知の内容の指定は別ファイルに。これはFirebaseとFlutterの仕様上仕方ない？
//  アプリ全体に影響するものはここに書く。例えば、アプリ全体の色など。
// ===== コード概要 =====

import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'route.dart';

void main() {
  runApp(MyApp());
  ErrorWidget.builder = (FlutterErrorDetails details) => Container( //エラー発生時の表示をデフォルトから変更。デフォルトの表示が心臓に悪いのでシンプルなものに。
    child: Text('実行時に何らかのエラーが発生しました。'),
    alignment: Alignment.center,
  );
}

class MyApp extends StatefulWidget{
  @override
  State<StatefulWidget> createState() {
    return _MyAppState();
  }
}

class _MyAppState extends State<MyApp> {
  String _message; //通知用メッセージ
  final FirebaseMessaging _fcm = FirebaseMessaging();

  //ここから通知に必要なコード
  @override
  void initState(){
    super.initState();
    getMessage();
  }

  void getMessage(){
    _fcm.configure(
      onMessage: (Map<String,dynamic> message) async {
        print('on message $_message');
        setState(() => _message = message['notification']['title']); //アプリをフォアグラウンドで実行中
      },
      onResume: (Map<String,dynamic> message) async {
        print('on resume $_message');
        setState(() => _message = message['notification']['title']); //アプリをバックグラウンドで実行中
      },
      onLaunch: (Map<String,dynamic> message) async {
        print('on launch $_message');
        setState(() => _message = message['notification']['title']); //アプリ終了中
      },
    );
  }
    //通知の中身はindex.jsにCloud Functionsとして実装
  //ここまで通知に必要なコード

  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, //デバッグ時のバナー表示を手動消去
      title: 'Chat App', //アプリ名
      theme: ThemeData(
        primaryColor: Colors.blueGrey, //アプリ全体のカラー設定
        fontFamily: 'font_0', //アプリ全体のデフォルトフォント設定
      ),
      home: RouteWidget(), //body本体はroute.dartに実装
    );
  }
}