// ===== コード概要 =====
//  新規登録画面のコード。
// ===== コード概要 =====
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;
final FirebaseMessaging _fcm = FirebaseMessaging();
final Firestore _db = Firestore.instance;

class Register extends StatefulWidget{
  @override
  State<StatefulWidget> createState() => RegisterPageState();
}

class RegisterPageState extends State<Register>{
  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  File _image;
  final picker = ImagePicker();
  String _imageURL;

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: Text('新規登録'),
      ),
      body: Container(
        child: Form(
          key: _formkey,
          child: ListView(
            children: [
              Container(
                margin: EdgeInsets.symmetric(vertical: 20.0),
                child: Column(
                  children: [
                    Container(
                      child: Column(
                        children: [
                          Text(
                            'こんにちは',
                            style: Theme.of(context).textTheme.headline4,
                          ),
                          Text('すべての情報を入力してください。'),
                          Text('プロフィール画像は画像アイコンから選択してください。'),
                        ],
                      ),
                      margin: EdgeInsets.only(bottom: 10.0),
                    ),
                    TextFormField(
                      autofocus: true,
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'ユーザ名',
                        icon: Icon(Icons.account_circle),
                      ),
                      validator: (String value) {
                        if(value.isEmpty){
                          return 'ユーザ名を入力してください。';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      keyboardType: TextInputType.emailAddress,
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'メールアドレス',
                        hintText: 'abc@abc.com',
                        icon: Icon(Icons.mail),
                      ),
                      validator: (String value) {
                        if(value.isEmpty){
                          return 'メールアドレスを入力してください。';
                        } else if(!value.contains('@')){
                          return 'メールアドレスの形式が無効なようです。';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      keyboardType: TextInputType.visiblePassword,
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: 'パスワード',
                        hintText: '英数字6文字以上',
                        icon: Icon(Icons.vpn_key),
                      ),
                      obscureText: true,
                      validator: (String value) {
                        if(value.isEmpty){
                          return 'パスワードを入力してください。';
                        } else if(value.length < 5){
                          return 'パスワードは英数字6文字以上で入力してください。';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              InkWell(
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
                ),
                onTap: getImage,
              ),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                alignment: Alignment.center,
                child: OutlineButton(
                  onPressed: () async {
                    if(_formkey.currentState.validate()){
                      if(_image == null){
                        showDialog(
                          context: context,
                          builder: (context){
                            return AlertDialog(
                              shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(16.0))),
                              title: Text('エラー'),
                              content: Text('プロフィール画像が指定されていません。'),
                              actions: <Widget>[
                                // ボタン領域
                                FlatButton( //キャンセル処理
                                  child: Text("OK"),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ],
                            );
                          }
                        );
                      } else {
                        _register();
                      }
                    }
                  },
                  child: const Text('登録'),
                ),
              ),
            ],
          ),
        ),
        margin: EdgeInsets.all(15.0),
      ),
    );
  }

  void _register() async{
    try{
      final FirebaseUser user = (await _auth.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      )).user;
      if(user != null){
        //For Device Token
        final FirebaseUser currentUser = await _auth.currentUser();
        String uid = currentUser.uid;
        // Get the token for this device
        String fcmToken = await _fcm.getToken();
        // Save it to Firestore
        if (fcmToken != null) {
          var tokens = _db
              .collection('fcmTokens')
              .document(fcmToken);

          await tokens.setData({
            'uid': uid,
          });
        }

        FirebaseUser updateUser = await _auth.currentUser();

        final StorageReference refUpload = FirebaseStorage()
        .ref()
        .child('userprofile')
        .child(user.uid);
        //print('Target: ' + _image.toString());
        final StorageUploadTask uploadTask = refUpload.putFile(
          _image,
          StorageMetadata(
            contentType: 'image/jpeg',
          ),
        );
        StorageTaskSnapshot snapshot = await uploadTask.onComplete;
        if(snapshot.error == null){
          snapshot.ref.getDownloadURL().then((fileURL) {
            setState((){
              _imageURL = fileURL;
            });
            //print('ImageUrl: ' + _imageURL);
            UserUpdateInfo updateInfo = UserUpdateInfo();
            updateInfo.displayName = _usernameController.text;
            updateInfo.photoUrl = _imageURL;
            //print('Updated image: ' + _imageURL);
            updateUser.updateProfile(updateInfo);
            Navigator.pop(context);
            Navigator.pop(context);
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
      } else {
        return;
      }
    } catch(error) {
      switch(error.code){ //メールアドレスを使ったログイン時のエラー分岐
        case 'ERROR_INVALID_EMAIL':
          showDialog(
            context: context,
            builder: (context){
              return AlertDialog(
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16.0))),
                title: Text('エラー'),
                content: Text('メールアドレスの形式が無効なようです。'),
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
          break;
        case 'ERROR_EMAIL_ALREADY_IN_USE':
          showDialog(
            context: context,
            builder: (context){
              return AlertDialog(
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16.0))),
                title: Text('エラー'),
                content: Text('メールアドレスはすでに登録されているようです。'),
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
          break;
        default:
          showDialog(
            context: context,
            builder: (context){
              return AlertDialog(
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16.0))),
                title: Text('エラー'),
                content: Text('予期せぬエラーです。もう一度お試しください。'),
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
          break;
      }
    }
  }

  getImage() async{
    final pickedFile = await picker.getImage(source: ImageSource.gallery);
    if(pickedFile != null){
      setState((){
        _image = File(pickedFile.path);
        //print('pickedFile: ' + _image.toString());
      });
    }
  }
}