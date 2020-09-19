// ===== コード概要 =====
//  ログイン画面のコード。
//  Googleログインとメールアドレスによるログインを実装。
//  また、新規登録へのボタンを設置し、新規登録画面へ遷移。
// ===== コード概要 =====

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'register.dart';

class SignInPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => SignInPageState();
}

class SignInPageState extends State<SignInPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("ログイン/新規登録"),
      ),
      body: Builder(builder: (BuildContext context) {
        return ListView(
          scrollDirection: Axis.vertical,
          children: <Widget>[
            _EmailLinkSignInSection(), //メールアドレスによるログイン
            _GoogleSignInSection(), //Googleアカウントによるログイン
          ],
        );
      }),
    );
  }
}

final FirebaseAuth _auth = FirebaseAuth.instance;
final GoogleSignIn _googleSignIn = GoogleSignIn();
final FirebaseMessaging _fcm = FirebaseMessaging();
final Firestore _db = Firestore.instance;

  // Googleアカウントを用いたログイン
class _GoogleSignInSection extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _GoogleSignInSectionState();
}

class _GoogleSignInSectionState extends State<_GoogleSignInSection> {

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: <Widget>[
          Container(
            child: Text(
              'Google',
              style: Theme.of(context).textTheme.headline4,
            ),
            alignment: Alignment.center,
          ),
          Container(
            child: Text('Googleアカウントを使って簡単にログインと新規登録ができます。'),
            alignment: Alignment.center,
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 15.0),
            alignment: Alignment.center,
            child: FlatButton(
              child: const Text(
                'Sign in with Google',
                style: TextStyle(color: Colors.white)
              ),
              color: Colors.blueGrey,
              onPressed: () async {
                if(await _auth.currentUser() == null){
                  _signInWithGoogle();
                } else {
                  Scaffold.of(context).showSnackBar(SnackBar(
                    content: Text('すでにログインしています。'),
                    duration: Duration(seconds: 3),
                    action: SnackBarAction(
                      textColor: Colors.white,
                      label: 'OK',
                      onPressed: () {},
                    ),
                    behavior: SnackBarBehavior.floating,
                  ));
                }
              },
            ),
          ),
        ],
      ),
      margin: EdgeInsets.all(15.0),
    );
  }
  
  void _signInWithGoogle() async {
    final GoogleSignInAccount googleUser = await _googleSignIn.signIn();
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;
    final AuthCredential credential = GoogleAuthProvider.getCredential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final FirebaseUser user =
        (await _auth.signInWithCredential(credential)).user;
    assert(user.email != null); //assertはfalseを受け取るとプログラム停止する
    assert(user.displayName != null);
    assert(!user.isAnonymous);
    assert(await user.getIdToken() != null);

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
    
    assert(user.uid == currentUser.uid);
    Navigator.of(context).pop();
  }
}

// メールアドレスによるログイン
class _EmailLinkSignInSection extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _EmailLinkSignInSectionState();
}

class _EmailLinkSignInSectionState extends State<_EmailLinkSignInSection>
    with WidgetsBindingObserver {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              child: Text(
                'ログイン',
                style: Theme.of(context).textTheme.headline4,
              ),
              alignment: Alignment.center,
            ),
            Container(
              child: Text('Googleアカウントを使ったログインは画面下部のボタンからできます。'),
              alignment: Alignment.center,
            ),
            Container(
              child: Column(
                children: [
                  TextFormField(
                    keyboardType: TextInputType.emailAddress,
                    controller: _emailController, //入力内容を保持
                    decoration: const InputDecoration(labelText: 'メールアドレス'),
                    validator: (String value) { //フォームのバリデーション
                      if (value.isEmpty) {
                        return 'メールアドレスを入力してください。'; //テキストフィールドが空の場合
                      } else if(!value.contains(('@'))){
                        return 'メールアドレスの形式が無効なようです。'; //テキストフィールドに'@'を含まない場合
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    obscureText: true,
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'パスワード'),
                    validator: (String value) { //フォームのバリデーション
                      if (value.isEmpty) {
                        return 'パスワードを入力してください。'; //テキストフィールドが空の場合
                      }
                      return null;
                    },
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    alignment: Alignment.center,
                    child: OutlineButton(
                      onPressed: () async {
                        if(await _auth.currentUser() == null){
                          if (_formKey.currentState.validate()) { //バリデーションをチェック
                            _signInWithEmailAndPassword();
                          }
                        } else {
                          Scaffold.of(context).showSnackBar(SnackBar(
                            content: Text('すでにログインしています。'),
                            duration: Duration(seconds: 3),
                            action: SnackBarAction(
                              textColor: Colors.white,
                              label: 'OK',
                              onPressed: () {},
                            ),
                            behavior: SnackBarBehavior.floating,
                          ));
                        }
                      },
                      child: const Text('ログイン'),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              child: Column(
                children: [
                  Container(
                    child: Text(
                      '新規登録',
                      style: Theme.of(context).textTheme.headline4,
                    ),
                    alignment: Alignment.center,
                  ),
                  Container(
                    child: Text('簡単登録！'),
                  ),
                  Container(
                    padding: const EdgeInsets.only(top: 15.0),
                    child: OutlineButton( //新規登録画面への遷移
                      child: Text('新規登録'),
                      onPressed: () async{
                        final FirebaseUser user = await _auth.currentUser();
                        if(user == null){
                          Navigator.push(context, MaterialPageRoute<Null>(builder: (context) => Register(),)); //未ログインの場合
                        } else {
                          Scaffold.of(context).showSnackBar(SnackBar(
                            content: Text('すでにログイン中です。'),
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
                      },
                    ),
                  )
                ],
              ),
              alignment: Alignment.center,
            ),
          ],
        ),
      ),
      margin: EdgeInsets.all(15.0),
    );
  }

  void _signInWithEmailAndPassword() async {
    try{
      final FirebaseUser user = (await _auth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      )).user;
      if (user != null) {
          setState(() {
          Navigator.pop(context);
        });
      } else {
        return;
      }
    } catch(error) {
      switch(error.code){ //メールアドレスを使ったログイン時のエラー分岐
        case 'ERROR_INVALID_EMAIL':
          Scaffold.of(context).showSnackBar(SnackBar(
            content: Text('メールアドレスの形式が無効なようです。'),
            duration: Duration(seconds: 3),
            action: SnackBarAction(
              textColor: Colors.white,
              label: 'OK',
              onPressed: () {},
            ),
            behavior: SnackBarBehavior.floating,
          ));
          break;
        case 'ERROR_WRONG_PASSWORD':
          Scaffold.of(context).showSnackBar(SnackBar(
            content: Text('パスワードが違うようです。'),
            duration: Duration(seconds: 3),
            action: SnackBarAction(
              textColor: Colors.white,
              label: 'OK',
              onPressed: () {},
            ),
            behavior: SnackBarBehavior.floating,
          ));
          break;
        case 'ERROR_USER_NOT_FOUND':
          Scaffold.of(context).showSnackBar(SnackBar(
            content: Text('このユーザはまだ登録されていないようです。'),
            duration: Duration(seconds: 3),
            action: SnackBarAction(
              textColor: Colors.white,
              label: 'OK',
              onPressed: () {},
            ),
            behavior: SnackBarBehavior.floating,
          ));
          break;
        default:
          Scaffold.of(context).showSnackBar(SnackBar(
            content: Text('予期せぬエラーです。もう一度お試しください。'),
            duration: Duration(seconds: 3),
            action: SnackBarAction(
              textColor: Colors.white,
              label: 'OK',
              onPressed: () {},
            ),
            behavior: SnackBarBehavior.floating,
          ));
          break;
      }
    }
  }
}