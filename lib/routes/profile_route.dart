// ===== コード概要 =====
//  プロフィール画面。
//  ログイン中のユーザの画像とユーザ名を表示。
//  アカウント削除はここで。
// ===== コード概要 =====

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'profileedit_route.dart';

class Profile extends StatefulWidget{
  @override
  State<StatefulWidget> createState() => ProfileState();
}

class ProfileState extends State<Profile>{

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: Text('プロフィール'),
      ),
      body: FutureBuilder(
        future: FirebaseAuth.instance.currentUser(), //ログイン中のユーザを取得
        builder: (context, AsyncSnapshot<FirebaseUser> snapshot) { //ユーザ情報をDBから取得
          if (snapshot.hasData) {
            //print(snapshot.data.photoUrl);
            return Container(
              alignment: Alignment.center,
              margin: EdgeInsets.all(20.0),
              child: Column(
                children: [
                  InkWell(
                    child: CircleAvatar( //プロフィール画像
                      backgroundImage: NetworkImage(snapshot.data.photoUrl),
                      backgroundColor: Colors.grey,
                      radius: 50,
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(top: 20),
                    child: Column(
                      children: [
                        Text( //ユーザ名
                          snapshot.data.displayName,
                          style: Theme.of(context).textTheme.headline3,
                        ),
                      ],
                    ),
                  ),
                  Container( //ユーザのメールアドレス
                    margin: EdgeInsets.only(top: 25),
                    child: Text(snapshot.data.email),
                  ),
                  Container(
                    margin: EdgeInsets.only(top: 30),
                    child: OutlineButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute<Null>(builder: (context) => ProfileEdit(),)), //プロフィール編集画面に遷移
                      child: Text(
                        'ユーザ情報の変更',
                      ),
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(top: 15),
                    child: Column(
                      children: [
                        OutlineButton(
                          onPressed: () => deleteAccount(context, snapshot),
                          child: Text(
                            'アカウント削除',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          borderSide: BorderSide(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          } else {
            return Container(
              alignment: Alignment.center,
              child: Text(
                'ログインしていません'
              ),
            );
          }
        },
      ),
    );
  }

  void deleteAccount(BuildContext context, AsyncSnapshot<FirebaseUser> snapshot){ //アカウント削除時の操作
    showDialog(
      context: context,
      builder: (context){
        return AlertDialog(
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16.0))),
          title: Text('アカウント削除'),
          content: Text('アカウントを削除しても、あなたのチャット記録は他のユーザから参照できます。'),
          actions: <Widget>[
            // ボタン領域
            FlatButton( //キャンセル処理
              child: Text("キャンセル"),
              onPressed: () => Navigator.pop(context),
            ),
            FlatButton( //削除ボタン
              child: Text("削除",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () => {
                snapshot.data.delete(), //ユーザ情報の消去
                Navigator.pop(context),
                Navigator.pop(context), //ドロワーメニューを表示している画面まで戻る
              },
            ),
          ],
        );
      }
    );
  }
}