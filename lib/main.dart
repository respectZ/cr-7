import 'package:cerita_rakyat_7/widget/audio_player.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

void main() {
  runApp(MainApp());
}

class MainApp extends StatelessWidget {
  MainApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Cerita Rakyat PBM 7',
      theme: ThemeData.dark(),
      home: const Home(),
    );
  }
}

class Home extends StatelessWidget {
  const Home({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cerita Rakyat PBM 7"),
      ),
      body: Container(
        child: const CustomAudioPlayer(),
      ),
    );
  }
}
