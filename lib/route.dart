// ===== コード概要 =====
//  これはトップ画面とチャットルーム一覧を表示するためのコード。
//  ボタンによる画面遷移だと推移がスタックされていくため、単純に画面を切り替えるためにナビゲーションバーを使った画面遷移にしている。
//  そのため、タブの切替が伴い現在開いているメニュー・切り替え機能などをここに書いている。
// ===== コード概要 =====

import 'package:flutter/material.dart';

import 'routes/home_route.dart';
import 'routes/message_route.dart';

class RouteWidget extends StatefulWidget{ //ステートを扱うために必要なクラス
  RouteWidget({Key key}) : super(key: key);

  @override
  _RouteWidgetState createState() => _RouteWidgetState();
}

class _RouteWidgetState extends State{ //ステートを扱うクラス
  //ここから画面下部のタブの切り替えに必要なコード
  int _selectedIndex = 0;
  var _routes = [
    Home(),  //トップページの内容->home_route.dart
    Message(), //チャットルーム一覧->message_route.dart
  ];
  void _onItemTapped(int index){ //タップされたメニューをセット
    setState(() {
      _selectedIndex = index;
    });
  }
  //ここまで画面下部のタブの切り替えに必要なコード
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _routes.elementAt(_selectedIndex), //homeとmessageをタップされたメニューに応じてその内容を表示する
      bottomNavigationBar: BottomNavigationBar( //画面下部のタブメニュー
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home), //メニューのアイコン設定
            title: Text('ホーム'), //メニューのテキスト
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            title: Text('チャットルーム'),
          ),
        ],
        currentIndex: _selectedIndex, //選択中のメニュー番号
        selectedItemColor: Colors.amber, //選択中のタブを強調表示
        onTap: _onItemTapped, //タップ時のイベント
      ),
    );
  }
}