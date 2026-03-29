import 'package:flutter/material.dart';

import 'exercises/week_four.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '移动开发练习合集',
      debugShowCheckedModeBanner: false, // 隐藏右上角的 Debug 贴纸
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // 2. 这里是关键！把“首页”指定为你引用的那个 WordNoteApp
      home: const WordNoteApp(),
    );
  }
}