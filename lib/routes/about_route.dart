// ===== コード概要 =====
//  このアプリの説明をする画面のコード。
//  文字ばかり。
// ===== コード概要 =====

import 'package:flutter/material.dart';

class About extends StatelessWidget{
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: Text('このアプリについて'),
      ),
      body: Column(
        children: [
          Container(
            child: Column(
              children: [
                Container(
                  child: Text(
                    'チャットアプリ',
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  margin: EdgeInsets.symmetric(vertical: 20.0),
                ),
                Text(
                  'このチャットアプリではその時の感情をフォントで表現することができます。',
                  style: TextStyle(
                    fontSize: 18.0,
                    height: 1.5,
                  ),
                ),
                Container(
                  child: Column(
                    children: [
                      Text(
                        '普通の気分です。',
                        style: TextStyle(
                          fontSize: 24.0,
                          fontFamily: 'font_0',
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                      ),
                      Text(
                        'とても嬉しいです。',
                        style: TextStyle(
                          fontSize: 24.0,
                          fontFamily: 'font_1',
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                      ),
                      Text(
                        'なんだかとても悲しい気持ちです。',
                        style: TextStyle(
                          fontSize: 24.0,
                          fontFamily: 'font_2',
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                      ),
                      Text(
                        'とても怒っています。',
                        style: TextStyle(
                          fontSize: 24.0,
                          fontFamily: 'font_3',
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                  margin: EdgeInsets.symmetric(vertical: 20.0),
                ),
                Text(
                  'フォントは以下から利用させていただきました。ありがとうございます。',
                  style: TextStyle(
                    fontSize: 18.0,
                    height: 1.5,
                  ),
                ),
                Container(
                  child: Column(
                    children: [
                      Text(
                        'http://honya.nyanta.jp',
                        style: TextStyle(height: 1.5,),
                      ),
                      Text(
                        'http://pm85122.onamae.jp/851Gkktt.html',
                        style: TextStyle(height: 1.5,),
                      ),
                      Text(
                        'http://jikasei.me/font/genshin/',
                        style: TextStyle(height: 1.5,),
                      ),
                    ],
                    crossAxisAlignment: CrossAxisAlignment.start,
                  ),
                  margin: EdgeInsets.symmetric(vertical: 20.0),
                ),
              ],
            ),
            margin: EdgeInsets.all(10.0),
          ),
        ],
      ),
    );
  }
}