// ===== コード概要 =====
//  チャット画面。
//  一番大事で一番複雑になってしまっているところ。
//  大きく分けて3つの機能が実装されている。
//  1. DBからデータを取得しリスト表示する
//  2. 入力されたテキストをDBに登録する
//  3. テキストのフォントを選択/感情分析を実行
//  その他、必要機能としてチャットルームの名前変更・削除を実装。
// ===== コード概要 =====

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:googleapis/language/v1.dart' as language;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

//Google Cloud Platformを利用するために必要なキーなど
final _credentials = new ServiceAccountCredentials.fromJson(r'''
{
  "private_key_id": "#####",
  "private_key": "######",
  "client_email": "#####",
  "client_id": "#####",
  "type": "service_account"
}
''');
final scopes = [language.LanguageApi.CloudLanguageScope];
HttpClient client = new HttpClient();

final FirebaseAuth _auth = FirebaseAuth.instance;

void sb(BuildContext context, String text){ //スナックバーを表示させたいところでは表示させたいテキストを指定するだけでOK
  Scaffold.of(context).showSnackBar(SnackBar(
    content: Text(text),
    duration: Duration(seconds: 3),
    action: SnackBarAction(
      textColor: Colors.white,
      label: 'OK',
      onPressed: () {},
    ),
    behavior: SnackBarBehavior.floating,
  ));
}
void alert(BuildContext context, String text){ //ダイアログ表示させたいところで表示させたいテキストを指定するだけでOK
  showDialog(
    context: context,
    builder: (context){
      return AlertDialog(
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16.0))),
        title: Text('エラー'),
        content: Text(text),
        actions: <Widget>[
          // ボタン領域
          FlatButton(
            child: Text("OK"),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      );
    }
  );
}

class Chat extends StatefulWidget{
  final String docid;
  final String docname;
  Chat(this.docid,this.docname);
  @override
  State createState() => ChatState(docid, docname); //message_routeからチャットルームのIDと名前を取ってきている
}

class ChatState extends State<Chat>{
  final String docid;
  final String docname;
  final _dropMenu = ["チャットルームを編集", "チャットルームを削除"];
  final TextEditingController roomnameEditingController = TextEditingController(); //入力されたチャットルームの名前を保持できる
  ChatState(this.docid, this.docname);
  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: Text(docname),
        actions: <Widget>[
          PopupMenuButton<String>( //画面上部のメニューアイコンをタップするとメニュー表示される
            onSelected: (String s) => updateRoomInfo(s), //選択されたメニュー
            itemBuilder: (BuildContext context) {
              return _dropMenu.map((String s) {
                return PopupMenuItem(
                  child: Text(s),
                  value: s,
                );
              }).toList();
            },
          ),
        ],
      ),
      body: ChatList(docid,docname), //ボディ部分はChatListクラスに
    );
  }
  void updateRoomInfo(String s) async{
    final GlobalKey<FormState> _updateFormkey = GlobalKey<FormState>();
    final FirebaseUser currentUser = await _auth.currentUser();
    if(currentUser == null){
      alert(context, 'ログインしていないとこの操作はできません。');
      return;
    } else if(s == 'チャットルームを削除'){ //チャットルームを削除する
      return showDialog(
        context: context,
        builder: (context){
          return AlertDialog(
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16.0))),
            title: Text('チャットルーム削除'),
            content: Text('チャットルームを削除すると、すべてのユーザに影響します。'),
            actions: <Widget>[
              // ボタン領域
              FlatButton(
                child: Text("キャンセル"),
                onPressed: () => Navigator.pop(context),
              ),
              FlatButton(
                child: Text("削除",
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () => {
                  Firestore.instance
                    .collection('messages')
                    .document(docid)
                    .delete(), //DBからチャットルームを削除する(ドキュメント内のコレクションまでは全消去されないため注意)
                  Navigator.pop(context),
                  Navigator.pop(context),
                },
              ),
            ],
          );
        }
      );
    } else { //チャットルームの名前を変更する
      return showDialog(
        context: context,
        builder: (context){
          return AlertDialog(
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16.0)),
            ),
            title: Text("チャットルーム名変更"),
            content: Form(
              key: _updateFormkey,
              child: TextFormField(
                autofocus: true,
                style: TextStyle(color: Colors.black, fontSize: 15),
                decoration: InputDecoration(
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue),
                  ),
                  hintText: '新しい名前',
                  hintStyle: TextStyle(color: Colors.grey,),
                ),
                controller: roomnameEditingController,
                validator: (String value) {
                  if(value.isEmpty){
                    return '何も入力されていないようです。';
                  }
                  return null;
                },
              ),
            ),
            actions: <Widget>[
              // ボタン領域
              FlatButton(
                child: Text("キャンセル"),
                onPressed: () => Navigator.pop(context),
              ),
              FlatButton(
                child: Text("更新"),
                onPressed: () => {
                  if(_updateFormkey.currentState.validate()){
                    updateRoomName()
                  }
                },
              ),
            ],
          );
        }
      );
    }
  }

  void updateRoomName() async{
    final FirebaseAuth _auth = FirebaseAuth.instance;
    final FirebaseUser currentUser = await _auth.currentUser();
    if(currentUser == null){
      alert(context, 'ログインしていないとこの操作はできません。');
      return;
    } else {
      await Firestore.instance
      .collection('messages')
      .document(docid)
      .setData(
        <String, dynamic>{
          'roomName': roomnameEditingController.text, //入力された新しいチャットルームの名前
          'timestamp': DateTime.now(), //更新日時
        }
      );
      Navigator.pop(context);
    }
  }
}

//チャットリスト
class ChatList extends StatefulWidget{
  final String docid;
  final String docname;
  ChatList(this.docid,this.docname);
  @override
  State createState() => ChatListState(docid, docname);
}

class ChatListState extends State<ChatList>{
  int _type = 0;
  int _content = 0;
  String docid;
  String docname;
  ChatListState(this.docid, this.docname);
  File _image;
  final picker = ImagePicker();
  String _imageURL;
 
  final ScrollController listScrollController = ScrollController();
  final TextEditingController textEditingController = TextEditingController();
  final TextEditingController fontSelectingController = TextEditingController();

  Widget _buildItem(int index, DocumentSnapshot document){
    String font = document['font'].toString(); //フォントを指定
    int contentType = document['contentType']; //画像とテキストを識別。DBから取得されたデータを使う。 0:テキスト, 1:画像
    return Container(
      child: Column(
        children: <Widget>[
          Container(
            child: Row(
              children: [
                contentType == 0  //DBから取得したデータがテキストの場合
                ? 
                Flexible(
                  child: Container(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          child: Row(
                            children: [
                              Container(
                                child: CircleAvatar( //投稿したユーザの丸型プロフィールアイコン
                                  backgroundImage: NetworkImage(document['icon']),
                                  backgroundColor: Colors.grey,
                                ),
                                margin: EdgeInsets.only(right: 15.0),
                              ),
                              Container( //投稿したユーザの名前
                                child: Text(
                                  document['name'],
                                  style: TextStyle(
                                    fontSize: 20.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Flexible(
                                child: Container( //チャットの個別削除用ボタン
                                  child: IconButton(
                                    disabledColor: Colors.grey[400],
                                    icon: Icon(Icons.delete),
                                    color: Colors.blueGrey,
                                    onPressed: () async {
                                      final FirebaseUser currentUser = await _auth.currentUser();
                                      if(currentUser != null){
                                        if(document['userid'] != currentUser.uid){ //ログイン中のユーザ以外のユーザのものは削除できない
                                          return null;
                                        } else {
                                          deleteData(document.documentID, docid);
                                        }
                                      }
                                    },
                                    tooltip: 'チャットを削除します',
                                  ),
                                  alignment: Alignment.centerRight, //右端揃え
                                )
                              ),
                            ],
                          ),
                        ),
                        Container(
                          child: Text( //チャットデータ(テキスト)
                            document['content'],
                            style: TextStyle(
                              fontFamily: "font_$font", //アプリ内でフォントデータをfont_~で登録しているため、~部分にDBから取得し文字列化した数字を入れる
                              fontSize: 18.0,
                              color: Colors.grey[700],
                              height: 1.5,
                            ),
                          ),
                          margin: EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
                        ),
                      ],
                    ),
                  ),
                )
                : //DBから取得したデータが画像の場合
                Flexible(
                  child: Container(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          child: Row(
                            children: [
                              Container(
                                child: CircleAvatar( //投稿したユーザの丸型プロフィールアイコン
                                  backgroundImage: NetworkImage(document['icon']),
                                  backgroundColor: Colors.grey,
                                ),
                                margin: EdgeInsets.only(right: 15.0),
                              ),
                              Container(
                                child: Text( //投稿したユーザの名前
                                  document['name'],
                                  style: TextStyle(
                                    fontSize: 20.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Flexible(
                                child: Container(
                                  child:  IconButton(
                                    disabledColor: Colors.grey[400],
                                    icon: Icon(Icons.delete),
                                    color: Colors.blueGrey,
                                    onPressed: () async {
                                      final FirebaseUser currentUser = await _auth.currentUser();
                                      if(currentUser != null){
                                        if(document['userid'] != currentUser.uid){ //ログイン中のユーザ以外のユーザのものは削除できない
                                          return null;
                                        } else {
                                          deleteData(document.documentID, docid);
                                        }
                                      }
                                    },
                                    tooltip: 'チャットを削除します',
                                  ),
                                  alignment: Alignment.centerRight, //右端揃え
                                )
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          child: Container(
                            child: Image.network( //チャットデータ(画像)
                              document['content'],
                              height: 200.0,
                              width: 300.0,
                              fit: BoxFit.scaleDown, //画像全体が表示されるようにサイズを縮める
                            ),
                            margin: EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
                          ),
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_){
                              return ImageScreen(document['content']);
                            }));
                          },
                        ),
                      ],
                    ),
                  ),
                )
              ]
            ),
            padding: EdgeInsets.fromLTRB(15.0, 10.0, 15.0, 10.0),
            margin: EdgeInsets.only(bottom: 1.0),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8.0)),
          ),
          Container(
            child: Text( //投稿日時をチャットの右下に表示
              DateFormat('MM/dd HH:mm').format(document['timestamp'].toDate()),
              style: TextStyle(color: Colors.white, fontSize: 12.0),
            ),
            margin: EdgeInsets.only(top: 2.0),
          ),
        ],
        crossAxisAlignment: CrossAxisAlignment.end,
      ),
      margin: EdgeInsets.only(top: 25.0),
    );
  }

  @override
  Widget build(BuildContext context){
    return Stack( //下に書かれたコードほど重なったときに上部(X軸方向)に来る。CSSのz-index相当。
      children: <Widget>[
        Container(
          color: Colors.blue,
          child: Column(
            children: <Widget>[
              _buildMessageList(), //チャットの一覧部分
              _buildInput(), //画像選択、テキスト入力部分
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageList(){
    return Expanded(
      child: StreamBuilder( //DBからテキストデータを取得する。その際にタイムスタンプを降順にして最新のものをトップに来るようにする。
        stream: Firestore.instance
          .collection('messages')
          .document(docid)
          .collection('chat')
          .orderBy('timestamp', descending: true) //並び替え。タイムスタンプを降順にする。
          .snapshots(),
        builder: (context, snapshot){
          if(!snapshot.hasData){
            return Container(
              alignment: Alignment.center,
              child: Text(
                'データを取得できなかったようです。'
              ),
            );
          } else {
            return ListView.builder( //リスト表示に必要な部分。
              padding: EdgeInsets.all(10.0),
              itemBuilder: (context, index) => _buildItem(index, snapshot.data.documents[index]),
              itemCount: snapshot.data.documents.length,
              controller: listScrollController,
              reverse: true, //リストを逆順にして最新のものが画面最下部に表示されるようにする。
            );
          }
        },
      ),
    );
  }

  Widget _buildInput(){
    return Container(
      child: Row(
        children: <Widget>[
          Container( //画像選択ボタン
            child: IconButton(
              icon: Icon(Icons.photo),
              color: Colors.blueGrey,
              onPressed: getImage,
              tooltip: '端末の画像を選択します',
            ),
          ),
          Container( //撮影ボタン
            child: IconButton(
              icon: Icon(Icons.camera_alt),
              color: Colors.blueGrey,
              onPressed: takeImage,
              tooltip: 'カメラで写真を撮ります',
            ),
          ),
          Expanded(
            child: Container(
              child: TextField( //テキスト入力部分
                keyboardType: TextInputType.multiline, //複数行の入力が可能(改行を有効化する)
                maxLines: null, //複数行の行数
                style: TextStyle(color: Colors.black, fontSize: 15),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey,),
                ),
                controller: textEditingController,
              ),
              margin: EdgeInsets.only(left: 10.0),
            ),
            flex: 4, //横幅
          ),
          Container(
            child: IconButton( //フォント選択ボタン。下からメニューが現れる。
              icon: Icon(Icons.text_format),
              color: Colors.blueGrey,
              onPressed: showTable,
              tooltip: '感情に応じてフォントを選択します',
            ),
          ),
          Container(
            child: IconButton( //送信ボタン。テキスト入力部分が空でないことを確認する。
              icon: Icon(Icons.send),
              color: Colors.blueGrey,
              onPressed: () => {
                if(textEditingController.text.isNotEmpty){
                  addToDatabase(textEditingController.text, _type, docid, _content) //入力されたテキスト、選択されたフォント、チャットルームのID、テキスト情報であることを渡す
                } else {
                  sb(context, '何も入力されていないようです。')
                }
              },
              tooltip: '送信',
            ),
          ),
        ],
      ),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.blueGrey,
            width: 0.5,
          ),
        ),
        color: Colors.white,
      ),
    );
  }

  getImage() async{ //端末内の画像を取得
    final pickedFile = await picker.getImage(source: ImageSource.gallery);
    if(pickedFile != null){
      setState((){
        _image = File(pickedFile.path);
        uploadImage(_image);
      });
    }
  }
  takeImage() async{ //画像を撮影
    final pickedFile = await picker.getImage(source: ImageSource.camera);
    if(pickedFile != null){
      setState((){
        _image = File(pickedFile.path);
        uploadImage(_image);
      });
    }
  }
  uploadImage(File file) async{ //画像をCloud Storageにアップロード
    int e = 0; //フォントの種類(デフォルト0で固定させる)
    String d = docid; //チャットルームのID
    int c = 1; //コンテンツタイプ(0：テキスト、1：画像；画像なので1で固定)
    int time = DateTime.now().millisecondsSinceEpoch; //現在時刻
    final StorageReference ref = FirebaseStorage() //Cloud Storageの保存領域を指定
      .ref()
      .child('images')
      .child(d) //チャットルームID
      .child(time.toString()); //画像ファイルの保存名を時刻
    final StorageUploadTask uploadTask = ref.putFile(
      file,
      StorageMetadata(
        contentType: 'image/jpeg',
      ));
    StorageTaskSnapshot snapshot = await uploadTask.onComplete; //アップロード完了後にデータをスナップ
    if(snapshot.error == null){
      snapshot.ref.getDownloadURL().then((fileURL) {
        setState((){
          _imageURL = fileURL; //画像のURLを取得
        });
        //print(_imageURL);
        addToDatabase(_imageURL, e, d, c); //DB登録
      });      
    } else {
      //print('error:' + snapshot.error.toString());
      sb(context, 'なにかエラーが起きました。もう一度お試しください。');
      return;
    }
  }

  void addToDatabase(String text, int e, String d, int c) async{ //DB登録処理
    final FirebaseAuth _auth = FirebaseAuth.instance;
    final FirebaseUser currentUser = await _auth.currentUser();
    final content = text;
    
    if(currentUser == null){
      sb(context, 'ログインしていません。');
      return;
    } else if(c == 0) { //コンテンツタイプ0:テキスト、1:画像
      double score;
      double magnitude;

      if(e == 0){ //選択されたフォントがデフォルトの場合
        clientViaServiceAccount(_credentials, scopes).then((client) async{ //Sentiment Analysis
          var api = new language.LanguageApi(client);
          final doc = {
            'document': {
              'content': content,
              'type': 'PLAIN_TEXT',
            },
            'encoding_type': 'UTF8',
          };
          final analyze = language.AnalyzeSentimentRequest.fromJson(doc);
          api.documents.analyzeSentiment(analyze).then((value) async{
            score = value.documentSentiment.score;
            magnitude = value.documentSentiment.magnitude;
            print('Sentiment score: ' + score.toString()); //Positive&Negativeをスコアで
            print('Magnitude: ' + magnitude.toString()); //どれだけ感情的な内容か
            print('Original font: '+ e.toString()); //選択されていたフォント(デフォルトであれば0しか返さないか確認)
            if(score < -0.25){ //Negative
              e = 3; //怒りのフォントのみ。悲しみは除外。
            } else if(-0.25 <= score && score < 0.25) { //Neutral
              e = 0;
            } else { //Positive
              e = 1;
            }
            print('Selected font: '+ e.toString()); //正しくフォントが選択されているか確認
            await Firestore.instance //Firestoreに保存
              .collection('messages')
              .document(d)
              .collection('chat')
              .document()
              .setData(
                <String, dynamic>{
                  'name': currentUser.displayName,
                  'userid': currentUser.uid,
                  'content': text, //入力されたテキスト
                  'contentType': c, //0 = text(default), 1 = image
                  'icon': currentUser.photoUrl,
                  'font': e,
                  'timestamp': DateTime.now(),
                }
              );
            }
          );
        });
      } else { //フォントがユーザによって指定されている場合(デフォルト以外が選択された)
        print('Selected font: '+ e.toString()); //選択されたフォントを確認する
        await Firestore.instance
          .collection('messages')
          .document(d)
          .collection('chat')
          .document()
          .setData(
            <String, dynamic>{
              'name': currentUser.displayName,
              'userid': currentUser.uid,
              'content': text, //入力されたテキスト
              'contentType': c, //0 = text(default), 1 = image
              'icon': currentUser.photoUrl,
              'font': e,
              'timestamp': DateTime.now(),
            }
          );
      }
      
      await Firestore.instance //チャットルームが更新されたことを反映させる
      .collection('messages')
      .document(d)
      .updateData(
        <String, dynamic>{
          'timestamp': DateTime.now(),
        }
      );
      _type = 0; //選択中のフォントを初期値に戻す(これがないと投稿後も直前の値が保持される)
      textEditingController.clear(); //テキストフィールドを空にする
    } else if(c != 0){ //画像の場合(c = 1)
      if(text == null){ //処理の途中で画像のみがアップロードされてしまう場合があったため追加
        sb(context, 'なにかエラーが起きました。もう一度お試しください');
        return;
      }
      await Firestore.instance
      .collection('messages')
      .document(d)
      .collection('chat')
      .document()
      .setData(
        <String, dynamic>{
          'name': currentUser.displayName,
          'userid': currentUser.uid,
          'content': text, //画像のURL
          'contentType': c, //0 = text(default), 1 = image
          'icon': currentUser.photoUrl,
          'font': e,
          'timestamp': DateTime.now(),
        }
      ); 
      await Firestore.instance
      .collection('messages')
      .document(d)
      .updateData(
        <String, dynamic>{
          'timestamp': DateTime.now(),
        }
      );
    }
  }

  deleteData(String id, String d) async{ //チャットを個別削除
    final FirebaseAuth _auth = FirebaseAuth.instance;
    final FirebaseUser currentUser = await _auth.currentUser();

    if(currentUser == null){ //ログイン状態を確認
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
      return;
    } else {
      showDialog(
        context: context,
        builder: (context){
          return AlertDialog(
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16.0))),
            title: Text('チャット削除'),
            content: Text('このチャットをします。'),
            actions: <Widget>[
              // ボタン領域
              FlatButton(
                child: Text("キャンセル"),
                onPressed: () => Navigator.pop(context),
              ),
              FlatButton(
                child: Text("削除",
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () async{
                  await Firestore.instance //該当のチャットデータを削除する
                    .collection('messages')
                    .document(d)
                    .collection('chat')
                    .document(id)
                    .delete();
                  
                  await Firestore.instance //チャットルームの最終更新日時を更新
                    .collection('messages')
                    .document(d)
                    .updateData(
                      <String, dynamic>{
                        'timestamp': DateTime.now(),
                      });
                  Navigator.pop(context); //画面戻る
                }
              ),
            ],
          );
        }
      );
    }
  }

  void showTable() async { //フォント選択ダイアログ。画面下から現れる。
    await showModalBottomSheet<int>(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0)
      ),
      context: context,
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container( //デフォルト。ニュートラルな感情。これが選択されると感情は自動分析される。
              child: ListTile(
                leading: Icon(Icons.sentiment_neutral),
                title: Text('普通/自動選択'),
                onTap: () => _radio(0, 1),
              ),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey,
                  )
                )
              ),
            ),
            Container( //Positive感情
              child: ListTile(
                leading: Icon(Icons.sentiment_satisfied),
                title: Text('嬉しすぎ'),
                onTap: () => _radio(1, 2),
              ),
            ),
            ListTile( //Negative。感情分析時には対象外。
              leading: Icon(Icons.sentiment_dissatisfied),
              title: Text('泣きそう'),
              onTap: () => _radio(2, 3),
            ),
            ListTile( //Negative
              leading: Icon(Icons.sentiment_very_dissatisfied),
              title: Text('ぷんぷん'),
              onTap: () => _radio(3, 4),
            ),
          ],
        );
      }
    );
  }
  void _radio(int e, int i){
    setState((){_type = e;});
    Navigator.of(context).pop(i);
  }
}

//画像をタップして全画面表示にする。
class ImageScreen extends StatelessWidget{
  final String image;
  ImageScreen(this.image); //画像URL
  @override
  Widget build(BuildContext context){
    return Scaffold(
      body: GestureDetector( //タップなどの動作を扱う
        child: Center(
          child: Image.network(image),
        ),
        onTap: (){ //画像をタップして前画面に戻る
          Navigator.pop(context);
        },
      ),
      backgroundColor: Colors.grey[300],
    );
  }
}