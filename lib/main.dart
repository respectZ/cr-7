import 'package:cerita_rakyat_7/widget/audio_player.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

void main() {
  runApp(MainApp());
}

class SeekBar extends RoundedRectSliderTrackShape {
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double? trackHeight = sliderTheme.trackHeight;
    final double trackLeft = offset.dx;
    final double trackTop =
        offset.dy + (parentBox.size.height - trackHeight!) / 2;
    final double trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }
}

SliderThemeData _customSliderTheme() {
  const mainColor = Colors.deepPurpleAccent;
  return SliderThemeData(
    trackHeight: 1,
    thumbShape: SliderComponentShape.noThumb,
    overlayColor: mainColor.withAlpha(50),
    trackShape: SeekBar(),
    activeTrackColor: mainColor,
    inactiveTrackColor: Colors.grey[600],
  );
}

class MainApp extends StatelessWidget {
  MainApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Cerita Rakyat PBM 7',
      theme: ThemeData(
        fontFamily: 'Novecento',
        colorScheme: ThemeData.dark().colorScheme,
        sliderTheme: _customSliderTheme(),
      ),
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
