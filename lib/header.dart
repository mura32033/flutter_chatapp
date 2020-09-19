import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Header extends StatelessWidget with PreferredSizeWidget{
  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Icon(Icons.settings),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(Icons.add),
        ),
      ],
      title: Text('Home'),
      backgroundColor: Colors.blueGrey,
      centerTitle: true,
      elevation: 0.0,
    );
  }
}