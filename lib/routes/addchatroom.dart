// ===== コード概要 =====
//  チャットルーム追加画面。
//  ログインしているユーザでないと作成できないようになっている。
// ===== コード概要 =====

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddChatRoom extends StatefulWidget{
  @override
  State createState() => AddChatRoomState();
}

class AddChatRoomState extends State<AddChatRoom>{
  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();
  final TextEditingController textEditingController = TextEditingController();

  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: Text('チャットルームを作る'),
      ),
      body: Form(
        key: _formkey,
        child: ListView(
          children: [
            Container(
              margin: EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
              child: Column(
                children: [
                  Container(
                    child: Icon(
                      Icons.add_circle_outline,
                      size: 48.0,
                    ),
                    margin: EdgeInsets.only(bottom: 15.0),
                  ),
                  Text(
                    '新しいお部屋を作りましょう!',
                    style: TextStyle(
                      fontSize: 20,
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(top: 40),
                    child: TextFormField(
                      autofocus: true,
                      controller: textEditingController,
                      decoration: const InputDecoration(
                        icon: Icon(Icons.add_comment),
                        labelText: 'チャットルームの名前',
                        border: const OutlineInputBorder(),
                      ),
                      validator: (String value) { //バリデーションをチェック。
                        if(value.isEmpty){ //テキスト未入力は許さない。
                          return '何も入力されていないようです。';
                        }
                        return null;
                      },
                    ),
                  )
                ],
              ),
            ),
            Container(
              alignment: Alignment.center,
              child: OutlineButton(
                onPressed: (){
                  if(_formkey.currentState.validate()){ //バリデーション
                    createNewChatRoom(context, textEditingController.text); //
                  }
                },
                child: const Text('作成'),
                borderSide: BorderSide(color: Colors.blueGrey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void createNewChatRoom(BuildContext context, String name) async{
    final FirebaseAuth _auth = FirebaseAuth.instance;
    final FirebaseUser currentUser = await _auth.currentUser();

    if(currentUser == null){
      showDialog(
        context: context,
        builder: (context){
          return AlertDialog(
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16.0))),
            title: Text('エラー'),
            content: Text('ログインしていないとこの操作はできません。'),
            actions: <Widget>[
              // ボタン領域
              FlatButton(
                child: Text("OK"),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
              ),
            ],
          );
        }
      );
      textEditingController.clear();
      return;
    } else {
      await Firestore.instance //新しいチャットルームをDBに登録
      .collection('messages')
      .document()
      .setData(
        <String, dynamic>{
          'roomName': name,
          'timestamp': DateTime.now(),
        }
      );
      Navigator.pop(context);
    }
  }
}