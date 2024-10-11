
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fleather/fleather.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  EditorScreenState createState() => EditorScreenState();
}

class EditorScreenState extends State<EditorScreen> {
  FleatherController? _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _loadDocument().then((document) {
      setState(() {
        _controller = FleatherController(document: document);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editor'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () => _saveDocument(context),
          ),
        ],
      ),
      body: _controller == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                FleatherToolbar.basic(controller: _controller!),
                const Divider(),
                Expanded(
                  child: FleatherEditor(
                    padding: const EdgeInsets.all(16),
                    controller: _controller!,
                    focusNode: _focusNode,
                    onLaunchUrl: _handleLaunchUrl, // リンクをタップしたときの処理
                  ),
                ),
              ],
            ),
    );
  }

  void _handleLaunchUrl(String? url) async {
    if (url == null) return; // urlがnullの場合は何もしない
    final Uri uri = Uri.parse(url);

    print('Attempting to launch: $url'); // デバッグメッセージを追加

    try {
      if (await canLaunchUrl(uri)) {
        print('Launching: $url'); // 成功した場合
        await launchUrl(uri, mode: LaunchMode.externalApplication); // 外部ブラウザで開く
      } else {
        print('Could not launch: $url'); // エラーの場合
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $url')),
        );
      }
    } catch (e) {
      print('Error launching $url: $e'); // エラーをキャッチ
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error launching $url: $e')),
      );
    }
  }

  Future<ParchmentDocument> _loadDocument() async {
    final file = File(Directory.systemTemp.path + "/quick_start.json");

    if (await file.exists()) {
      final contents = await file.readAsString();
      return ParchmentDocument.fromJson(jsonDecode(contents));
    }

    // リンクを追加したテキストのDeltaを作成
    final Delta delta = Delta()
      ..insert("Welcome to Fleather!\n")
      ..insert("Visit Flutter website", {"link": "https://youtu.be/slt_Bav8nsQ?si=Hoi_pxeKU5icd8_U"}) // リンクを追加
      ..insert("\n");

    return ParchmentDocument.fromDelta(delta);
  }

  void _saveDocument(BuildContext context) {
    final contents = jsonEncode(_controller!.document);
    final file = File('${Directory.systemTemp.path}/quick_start.json');
    file.writeAsString(contents).then(
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved.')),
        );
      },
    );
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WYSIWYG',
      home: const EditorScreen(),
      routes: {
        "/editor": (context) => const EditorScreen(),
      },
    );
  }
}