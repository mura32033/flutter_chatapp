// ===== コード概要 =====
//  プロフィール編集画面。
//  ログイン中のユーザの画像とユーザ名を編集する。
// ===== コード概要 =====

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ProfileEdit extends StatefulWidget{
  @override
  State<StatefulWidget> createState() => ProfileEditState();
}

class ProfileEditState extends State<ProfileEdit>{
  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController(text: '');

  File _image;
  final picker = ImagePicker();
  String _imageURL;

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: Text('プロフィール情報編集'),
      ),
      body: FutureBuilder(
        future: FirebaseAuth.instance.currentUser(), //ログイン中のユーザを取得
        builder: (context, AsyncSnapshot<FirebaseUser> snapshot) { //DBからユーザ情報を取得
          if (snapshot.hasData) {
            //print(snapshot.data.displayName);
            _usernameController.text = snapshot.data.displayName; //ユーザ名をテキストフィールドにセット
            return Form(
              key: _formkey,
              child: ListView(
                children: [
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
                    child: Column(
                      children: [
                        InkWell( //仮プロフィールアイコン
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.grey,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.photo_library,
                              color: Colors.white,
                            ),
                            width: 100,
                            height: 100,
                            margin: EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
                          ),
                          onTap: getImage,
                        ),
                        TextFormField( //ユーザ名のテキストフィールド
                          autofocus: true,
                          controller: _usernameController, //ログイン中のユーザのユーザ名をデフォルトセット
                          decoration: const InputDecoration(
                            labelText: 'ユーザ名',
                            icon: Icon(Icons.account_circle),
                          ),
                          validator: (String value) { //未入力時にエラー返す
                            if(value.isEmpty){
                              return 'ユーザ名を入力してください。';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    alignment: Alignment.center,
                    child: OutlineButton(
                      onPressed: () async {
                        if(_formkey.currentState.validate()){ //バリデーションをチェック
                          _register(); //問題なければ登録処理に移行
                        }
                      },
                      child: const Text('更新'),
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

  void _register() async{ //登録処理
    final FirebaseAuth _auth = FirebaseAuth.instance;
    try{
      FirebaseUser updateUser = await _auth.currentUser();

      if(_image != null){ //画像を変更していたとき
        //Firebase Storageにアップロードする場所を指定
        final StorageReference refUpload = FirebaseStorage()
          .ref()
          .child('userprofile')
          .child(updateUser.uid);
         //print('Target: ' + _image.toString());
          final StorageUploadTask uploadTask = refUpload.putFile( //画像のアップロード
            _image,
            StorageMetadata(
              contentType: 'image/jpeg',
            ),
          );
          StorageTaskSnapshot snapshot = await uploadTask.onComplete;
          if(snapshot.error == null){
            snapshot.ref.getDownloadURL().then((fileURL) { //アップロード成功後に画像のURLを取得
              setState((){
                _imageURL = fileURL;
              });
              //print('ImageUrl: ' + _imageURL);
              UserUpdateInfo updateInfo = UserUpdateInfo(); //ユーザ情報更新
              updateInfo.displayName = _usernameController.text; //ユーザ名をセット
              updateInfo.photoUrl = _imageURL; //プロフィール画像URLをセット
              //print('Updated image: ' + _imageURL);
              updateUser.updateProfile(updateInfo); //上記2つの情報をもとに更新実行
              Navigator.pop(context);
              Navigator.pop(context); //ドロワーメニューの画面まで戻る
            });
          } else {
            //print('error:' + snapshot.error.toString());
            Scaffold.of(context).showSnackBar(SnackBar(
              content: Text('エラーが発生しました。もう一度お試しください。'),
              duration: Duration(seconds: 3),
              action: SnackBarAction(
                textColor: Colors.white,
                label: 'OK',
                onPressed: () {},
              ),
              behavior: SnackBarBehavior.floating,
            ));
            return;
          }
      } else { //画像未選択時(=ユーザ名の変更のみ)は画像のアップロード処理を無視
        UserUpdateInfo updateInfo = UserUpdateInfo();
        updateInfo.displayName = _usernameController.text;
        updateUser.updateProfile(updateInfo);
        Navigator.pop(context);
        Navigator.pop(context);
      }
    } catch(error) {
      //print(error);
      showDialog(
        context: context,
        builder: (context){
          return SnackBar(
            content: Text('予期せぬエラーです。もう一度お試しください。'),
            duration: Duration(seconds: 3),
            action: SnackBarAction(
              textColor: Colors.white,
              label: 'OK',
              onPressed: () {},
            ),
            behavior: SnackBarBehavior.floating,
          );
        }
      );
    }
  }

  getImage() async{ //端末内の画像を取得
    final pickedFile = await picker.getImage(source: ImageSource.gallery);
    if(pickedFile != null){
      setState((){
        _image = File(pickedFile.path); //端末内の画像のパスを取得し変数にセット
      });
    }
  }
}