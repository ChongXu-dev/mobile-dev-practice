import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class WordNoteApp extends StatefulWidget {
  const WordNoteApp({super.key});

  @override
  State<WordNoteApp> createState() => _WordNoteAppState();
}

class _WordNoteAppState extends State<WordNoteApp> {
  final FlutterTts tts = FlutterTts();
  final TextEditingController _controller = TextEditingController();
  List<Map<String, String>> wordList = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _controller.dispose();
    tts.stop();
    super.dispose();
  }

  // --- 核心逻辑 ---

  // 1. 自动翻译逻辑
  Future<String> translate(String text) async {
    try {
      String encodedText = Uri.encodeComponent(text);
      var url = Uri.parse("https://api.mymemory.translated.net/get?q=$encodedText&langpair=en|zh-CN");
      var response = await http.get(url);

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        return data['responseData']['translatedText'];
      }
      return "翻译服务异常";
    } catch (e) {
      return "网络错误或翻译失败";
    }
  }

  // 2. 添加单词
  Future<void> _addWord() async {
    String input = _controller.text.trim();
    if (input.isEmpty) return;

    String translation = await translate(input);

    if (!mounted) return;

    setState(() {
      wordList.insert(0, {"en": input, "zh": translation});
      _controller.clear();
    });
    _saveData();
  }

  // 3. 语音朗读
  Future<void> _speak(String text) async {
    await tts.setLanguage("en-US");
    await tts.setSpeechRate(0.5);
    await tts.speak(text);
  }

  // 4. 数据持久化 (存取)
  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('words', json.encode(wordList));
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    String? saved = prefs.getString('words');
    if (saved != null) {
      if (!mounted) return;
      setState(() {
        List<dynamic> decoded = json.decode(saved);
        wordList = decoded.map((item) => Map<String, String>.from(item)).toList();
      });
    }
  }

  // --- UI 界面区 ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text("Markdown 英语记事本"),
          elevation: 2,
          actions: [
            IconButton(
                icon: const Icon(Icons.share),
                tooltip: '导出为 Markdown',
                onPressed: _exportMarkdown
            )
          ]
      ),
      body: Column(
        children: [
          _buildInputArea(),
          Expanded(child: _buildWordList()),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                  hintText: "输入内容或从剪贴板粘贴",
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 15)
              ),
              onSubmitted: (_) => _addWord(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.content_paste, color: Colors.blueGrey),
            tooltip: '从剪贴板粘贴',
            onPressed: () async {
              ClipboardData? data = await Clipboard.getData('text/plain');
              if (data != null) _controller.text = data.text!;
            },
          ),
          ElevatedButton(
              onPressed: _addWord,
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15)
              ),
              child: const Text("添加")
          ),
        ],
      ),
    );
  }

  Widget _buildWordList() {
    if (wordList.isEmpty) {
      return const Center(child: Text("暂无记录，快去添加吧！", style: TextStyle(color: Colors.grey)));
    }

    return ListView.builder(
      itemCount: wordList.length,
      itemBuilder: (context, index) {
        return Card(
          elevation: 1,
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: ListTile(
            leading: IconButton(
                icon: const Icon(Icons.volume_up, color: Colors.blue),
                onPressed: () => _speak(wordList[index]['en']!)
            ),
            title: Text(
                wordList[index]['en']!,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)
            ),
            subtitle: Text(
                wordList[index]['zh']!,
                style: const TextStyle(fontSize: 15, color: Colors.black87)
            ),
            trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: () {
                  setState(() => wordList.removeAt(index));
                  _saveData();
                }
            ),
          ),
        );
      },
    );
  }

  void _exportMarkdown() {
    if (wordList.isEmpty) return;

    String md = "| 原文 | 翻译 |\n| --- | --- |\n";
    for (var item in wordList) {
      md += "| ${item['en']} | ${item['zh']} |\n";
    }

    Clipboard.setData(ClipboardData(text: md));

    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ 已复制 Markdown 表格到剪贴板！"),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
        )
    );
  }
}