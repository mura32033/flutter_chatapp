// ===== コード概要 =====
//  トップ画面のコード。
//  ログイン、新規登録、ドロワーメニューなど。
// ===== コード概要 =====

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../login.dart';
import 'about_route.dart';
import 'profile_route.dart';

final FirebaseAuth _auth = FirebaseAuth.instance; //ユーザ認証に必要

class Home extends StatefulWidget{
  @override
  State<StatefulWidget> createState() => HomeState();
}

class HomeState extends State<Home>{
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: Text('ホーム'),
        actions: <Widget>[ //アイコンボタンをタップしてログイン画面の遷移。ログイン中の場合にはログアウトする。
          IconButton(
            icon: Icon(
              Icons.person,
              color: Colors.white,
            ),
            onPressed: () async{
              final FirebaseUser user = await _auth.currentUser(); //ユーザがログイン中かどうか
              if(user != null){ //ログイン中の場合
                final String username = user.displayName; //ログイン中のユーザのユーザ名を取得
                _signOut(); //ログアウト
                Scaffold.of(context).showSnackBar(SnackBar(
                  content: Text(username + 'さん、さようなら。'), //ログアウトしたことをメッセージ表示
                  duration: Duration(seconds: 3),
                  action: SnackBarAction(
                    textColor: Colors.white,
                    label: 'OK',
                    onPressed: () {},
                  ),
                  behavior: SnackBarBehavior.floating,
                ));
              } else { //未ログインの場合
                _pushPage(context, SignInPage()); //ログインページへ推移
                if(user != null){
                  Scaffold.of(context).showSnackBar(SnackBar(
                    content: Text('ログインしました。'), //ログアウトしたことをメッセージ表示
                    duration: Duration(seconds: 3),
                    action: SnackBarAction(
                      textColor: Colors.white,
                      label: 'OK',
                      onPressed: () {},
                    ),
                    behavior: SnackBarBehavior.floating,
                  ));
                }
              }
            },
          ),
        ],
      ),
      body: Center( //body部分。テキストなど様々な情報をここに書いている。
        child: Column(
          children: [
            Container(
              child: Column(
                children: [
                  Container(
                    child: Text(
                      'こんにちは',
                      style: Theme.of(context).textTheme.headline3,
                    ),
                    margin: EdgeInsets.symmetric(vertical: 20.0),
                  ),
                  Container(
                    child: Image.asset('images/murasan.png',width: 250,), //pubspec.yamlに画像を登録しておかないと表示されない
                    margin: EdgeInsets.only(bottom: 20.0),
                  ),
                  Container(
                    child: Text(
                      'お楽しみください。',
                    ),
                    margin: EdgeInsets.only(bottom: 20.0),
                  ),
                ],
              ),
              margin: EdgeInsets.all(20.0),
            ),
          ],
        ),
      ),
      drawer: Drawer( //ドロワーメニュー。画面左から現れるやつ。
        child: ListView(
          children: <Widget>[
            DrawerHeader( //ドロワーの上部にあるヘッダー部分。ここではテキストがある。
              padding: EdgeInsets.zero,
              child: Stack(
                children: <Widget>[
                  Container(
                    alignment: Alignment.bottomLeft,
                    padding: EdgeInsets.fromLTRB(10, 0, 0, 10),
                    child: Text( //ヘッダー内のテキスト
                      'ChatApp',
                      style: Theme.of(context).textTheme.headline3,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColorLight, //ヘッダー背景色の指定
                    ),
                  ),
                ],
              ),
            ),
            ListTile( //ドロワーメニュー内の各メニュータイル
              leading: Icon(Icons.person_outline),
              title: const Text('プロフィール'),
              onTap: () => _pushPage(context, Profile()),
            ),
            ListTile(
              leading: Icon(Icons.info_outline),
              title: const Text('このアプリについて'),
              onTap: () => _pushPage(context, About()),
            ),
            ListTile( //コピーライト表記
              title: const Text(
                'Copyright 2020 Murasan',
                textAlign: TextAlign.end,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  //ログアウト処理
  void _signOut() async {
    await _auth.signOut();
  }
  
  //ページ遷移用
  void _pushPage(BuildContext context, Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => page),
    );
  }
}