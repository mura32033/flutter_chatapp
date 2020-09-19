// ===== コード概要 =====
//  チャットルーム一覧画面。
//  リストビューでDBに登録されているチャットルームを表示する。
//  最後に投稿されたチャットデータの登録日時をチャットルーム全体の最終更新日時として表示させている。
//  画面右下のボタンでチャットルーム作成画面に遷移する。
// ===== コード概要 =====

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'chat_route.dart';
import 'addchatroom.dart';

class Message extends StatelessWidget{
  final TextEditingController roomnameController = TextEditingController();
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: Text('チャットルーム'),
      ),
      body: MessageList(),
      floatingActionButton: FloatingActionButton( //画面右下のプラスアイコン
        child: Icon(Icons.add),
        onPressed: () => Navigator.push(context, MaterialPageRoute<Null>(builder: (context) => AddChatRoom(),)),
        tooltip: '新しくチャットルームを作成できます。',
      ),
    );
  }
}

class MessageList extends StatefulWidget{
  @override
  State createState() => MessageListState();
}

class MessageListState extends State<MessageList>{
  final ScrollController listScrollController = ScrollController();
  final TextEditingController textEditingController = TextEditingController();
  
  Widget _buildItem(int index, DocumentSnapshot document){
    return Container(
      child: ListTile(
        title: Text(document['roomName']),
        subtitle: Text('最終更新日時: ' + DateFormat('y/MM/dd HH:mm').format(document['timestamp'].toDate())),
        onTap: () => {
          Navigator.push(context, MaterialPageRoute<Null>(
              builder: (context) => Chat(
                document.documentID, //各チャットルームの画面に遷移するときにチャットルームIDとチャットルームの名前も渡す
                document['roomName'],
              ),
            ),
          ),
        },
      ),
      decoration: BoxDecoration(
        border: Border.all(width: 0.5, color: Colors.black),
        borderRadius: BorderRadius.circular(10),
      ),
      margin: EdgeInsets.only(bottom: 10.0),
    );
  }

  @override
  Widget build(BuildContext context){
    return WillPopScope(
      child: Stack(
        children: <Widget>[
          Column(
            children: <Widget>[
              _buildChatRoomList(),
            ],
          )
        ],
      ),
      onWillPop: null,
    );
  }

  Widget _buildChatRoomList(){
    return Expanded(
      child: StreamBuilder(
        stream: Firestore.instance.collection('messages').orderBy('timestamp', descending: true).snapshots(), //日時降順(最新がトップにくる)
        builder: (context, snapshot){
          if(!snapshot.hasData){
            return Center(
              child: CircularProgressIndicator(),
            );
          } else {
            return ListView.builder(
              padding: EdgeInsets.all(10.0),
              itemBuilder: (context, index) => _buildItem(index, snapshot.data.documents[index]),
              itemCount: snapshot.data.documents.length,
              controller: listScrollController,
            );
          }
        },
      ),
    );
  }
}