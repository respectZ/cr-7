import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:io';
import 'package:path_provider/path_provider.dart';

String getDuration(Duration duration) {
  String twoDigits(int i) => i.toString().padLeft(2, '0');
  return "${twoDigits(duration.inSeconds ~/ 60)}:${twoDigits(duration.inSeconds % 60)}:${twoDigits(duration.inMilliseconds % 1000)}";
}

Widget _lyricText(Duration? duration, Map<Duration, String> lyrics) {
  String lyric = "";
  for (var e in lyrics.entries) {
    if (e.key <= (duration ?? Duration.zero)) {
      lyric = e.value;
    } else {
      break;
    }
  }
  return Text(
    lyric,
    textAlign: TextAlign.center,
  );
}

Widget _seekBar(Duration? duration, AudioPlayer audioPlayer) {
  return Slider(
      max: audioPlayer.duration?.inSeconds.toDouble() ?? 0,
      value: duration?.inSeconds.toDouble() ?? 0,
      onChanged: (value) =>
          {audioPlayer.seek(Duration(seconds: value.toInt()))});
}

Widget _speedBar(double? speed, AudioPlayer audioPlayer) {
  return DropdownButton<double>(
      value: speed,
      items: [0.5, 1.0, 1.5, 2.0, 3.0, 4.0]
          .map<DropdownMenuItem<double>>((double value) {
        return DropdownMenuItem<double>(
          value: value,
          child: Text(value.toString() + " x"),
        );
      }).toList(),
      onChanged: (value) {
        audioPlayer.setSpeed(value ?? 1.0);
      });
}

Widget _volumeBar(
    double? volume, AudioPlayer audioPlayer, BuildContext context) {
  // icon switcher
  IconData icon = Icons.volume_up_rounded;
  if (volume != null && volume <= 0.5) icon = Icons.volume_down_rounded;
  if (volume != null && volume == 0.0) icon = Icons.volume_mute_rounded;

  // row
  return Row(
    children: [
      InkWell(
        onTap: () {
          if (volume != 0.0) {
            audioPlayer.setVolume(0.0);
          } else {
            audioPlayer.setVolume(1.0);
          }
        },
        child: Icon(
          icon,
          size: 24.0,
        ),
      ),
      SizedBox(
        width: 10,
      ),
      SizedBox(
        width: MediaQuery.of(context).size.width * 0.2 >= 225
            ? 225
            : MediaQuery.of(context).size.width * 0.2,
        child: Slider(
          max: 1,
          value: volume != null ? volume * 1 : 0,
          onChanged: (value) => audioPlayer.setVolume(value / 1),
        ),
      ),
    ],
  );
}

Widget _textPosition(Duration? duration, AudioPlayer audioPlayer) {
  return Container(
    margin: EdgeInsets.fromLTRB(12.0, 0.0, 12.0, 0.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(getDuration(duration ?? Duration.zero)),
        Text(getDuration(audioPlayer.duration ?? Duration.zero)),
      ],
    ),
  );
}

Widget _playerButton(PlayerState? playerState, AudioPlayer audioPlayer) {
  final state = playerState?.processingState;
  if (state == ProcessingState.loading) {
    return CircularProgressIndicator();
  } else if (state == ProcessingState.buffering) {
    return Row(
      children: [
        InkWell(
          customBorder: CircleBorder(),
          child: Icon(
            Icons.pause_circle_filled_rounded,
            size: 64.0,
          ),
        ),
        InkWell(
          onTap: () => {audioPlayer.pause(), audioPlayer.seek(Duration.zero)},
          customBorder: CircleBorder(),
          child: Icon(
            Icons.stop_circle_rounded,
            size: 64.0,
          ),
        ),
      ],
    );
  } else if (!audioPlayer.playing) {
    return InkWell(
      onTap: audioPlayer.play,
      customBorder: CircleBorder(),
      child: Icon(
        Icons.play_circle_fill_rounded,
        size: 64.0,
      ),
    );
  } else if (state != ProcessingState.completed) {
    return Row(
      children: [
        InkWell(
          onTap: audioPlayer.pause,
          customBorder: CircleBorder(),
          child: Icon(
            Icons.pause_circle_filled_rounded,
            size: 64.0,
          ),
        ),
        InkWell(
          onTap: () => {audioPlayer.pause(), audioPlayer.seek(Duration.zero)},
          customBorder: CircleBorder(),
          child: Icon(
            Icons.stop_circle_rounded,
            size: 64.0,
          ),
        ),
      ],
    );
  } else {
    return InkWell(
      onTap: () {
        audioPlayer.seek(Duration.zero);
      },
      customBorder: CircleBorder(),
      child: Icon(
        Icons.replay_circle_filled_rounded,
        size: 64.0,
      ),
    );
  }
}

class CustomAudioPlayer extends StatefulWidget {
  const CustomAudioPlayer({Key? key}) : super(key: key);

  @override
  State<CustomAudioPlayer> createState() => _CustomAudioPlayerState();
}

class _CustomAudioPlayerState extends State<CustomAudioPlayer> {
  late AudioPlayer _audioPlayer;
  Duration? dur;

  Map<Duration, String> _lyrics = {
    Duration(seconds: 0): 'Pada jaman dahuku kala',
    Duration(seconds: 2, milliseconds: 600):
        'Ada sebuah daerah yang damai dan sejahtera',
    Duration(seconds: 5, milliseconds: 900):
        'Daerah tersebut bernama soppeng, sulawesi selatan',
    Duration(seconds: 9, milliseconds: 600):
        'Suatu ketika daerah tersebuh kedatangan seorang nenek berambut putih',
    Duration(seconds: 14, milliseconds: 950):
        'nenek tua itu memiliki badan setengah membungkuk, memakai sarung dan kemeja batik',
    Duration(seconds: 21, milliseconds: 420):
        'Tidak disangka ternyata nenek tua tersebut adalah siluman yang suka menculik anak-anak',
    Duration(seconds: 27, milliseconds: 630):
        'maka nenek tersebut memiliki julukan pak ande yang berarti makan',
    Duration(seconds: 33, milliseconds: 580):
        'Suatu hari, ada kakak beradik yang bermain sampai malam',
    Duration(seconds: 37, milliseconds: 625):
        'sang ibu menyuruh mereka segera masuk, tetapi mereka tetap bermain',
    Duration(seconds: 43, milliseconds: 100):
        'Kedua anak itupun diculik nenek pak ande',
    Duration(seconds: 46, milliseconds: 320):
        'Sang ibu berteriak minta pertolongan kepada warga',
    Duration(seconds: 49, milliseconds: 669):
        'Nenek pak ande sudah menghilang bersama kedua anaknya',
    Duration(seconds: 54, milliseconds: 550):
        'warga terus mencari, namun tidak jua ditemukan',
    Duration(seconds: 59, milliseconds: 700):
        'Esok harinya, warga berkumpul mencari solusi',
    Duration(minutes: 1, seconds: 4, milliseconds: 250):
        'Seorang pemuda bernama La Beddu yang cerdik nan pandai',
    Duration(minutes: 1, seconds: 8, milliseconds: 220):
        'memiliki usul untuk mengalahkan nenek pak ande',
    Duration(minutes: 1, seconds: 11, milliseconds: 820):
        'La Beddu meminta warga untuk menyiapkan belut-',
    Duration(minutes: 1, seconds: 15, milliseconds: 288):
        'kura-kura, garu,busa sabun, kulit rebung, dan sebuah batu besar',
    Duration(minutes: 1, seconds: 21, milliseconds: 056):
        'semua hewan dan benda tersebut terkumpul di rumah La Beddu',
    Duration(minutes: 1, seconds: 25, milliseconds: 190): 'Malam haripun tiba',
    Duration(minutes: 1, seconds: 27, milliseconds: 280): '',
    Duration(minutes: 1, seconds: 27, milliseconds: 750):
        'seluruh warga mematikan lampu kecuali lampu rumah la beddu',
    Duration(minutes: 1, seconds: 32, milliseconds: 250):
        'nenek pak ande pun tertarik memasuki rumah tersebut',
    Duration(minutes: 1, seconds: 36, milliseconds: 320): '',
    Duration(minutes: 1, seconds: 36, milliseconds: 980):
        'Sampai di dalam rumah-',
    Duration(minutes: 1, seconds: 38, milliseconds: 350):
        'nenek pak ande bertemu dengan la beddu yang telah menyamar menjadi raksasa',
    Duration(minutes: 1, seconds: 44, milliseconds: 350): '',
    Duration(minutes: 1, seconds: 44, milliseconds: 890):
        'busa menyerupai air liur-',
    Duration(minutes: 1, seconds: 46, milliseconds: 550):
        'dan kulit rebung digunakan sebagai terompet pembesar suara',
    Duration(minutes: 1, seconds: 51, milliseconds: 150): '',
    Duration(minutes: 1, seconds: 51, milliseconds: 820):
        'Nenek pak ande ketakutan',
    Duration(minutes: 1, seconds: 53, milliseconds: 450):
        'kemudian dengan terburu-buru berlari menuruni tangga',
    Duration(minutes: 1, seconds: 56, milliseconds: 900): '',
    Duration(minutes: 1, seconds: 57, milliseconds: 350):
        'Warga telah menyiapkan belut ditangga yang membuat nenek pak ande terjatuh',
    Duration(minutes: 2, seconds: 03, milliseconds: 190):
        'dan kepalanya terantuk batu besar',
    Duration(minutes: 2, seconds: 06, milliseconds: 280): '',
    Duration(minutes: 2, seconds: 07, milliseconds: 380):
        'Seluruh warga keluar dan mengepung sang siluman',
    Duration(minutes: 2, seconds: 11, milliseconds: 280): '',
    Duration(minutes: 2, seconds: 11, milliseconds: 850):
        'Nenek pak ande pun terluka parah',
    Duration(minutes: 2, seconds: 14, milliseconds: 180):
        'dan segera menggunakan kesaktiannya yang tersisa',
    Duration(minutes: 2, seconds: 17, milliseconds: 920): '',
    Duration(minutes: 2, seconds: 18, milliseconds: 290):
        'Sejak saat itu,\nnenek pak ande sudah tidak pernah muncul kembali',
    Duration(minutes: 2, seconds: 22, milliseconds: 680): 'warga menjadi aman',
    Duration(minutes: 2, seconds: 25, milliseconds: 020):
        'dan cerita itu turun menurun menjadi pesan untuk anak-anak dan cucu',
    // Duration(minutes: 2, seconds: 5, milliseconds: 920): '',
    // Duration(minutes: 2, seconds: 7, milliseconds: 720): 'PESAN MORAL',
    // Duration(minutes: 2, seconds: 10, milliseconds: 280):
    //     'Turutilah kata kata orang tua',
    // Duration(minutes: 2, seconds: 14, milliseconds: 20):
    //     'Bermain ada waktunya, jangan berlebihan apalagi kalau sudah malam',
    // Duration(minutes: 2, seconds: 16, milliseconds: 220):
    //     'sebaiknya masuk rumah berkumpul bersama keluarga tercinta',
    // Duration(minutes: 2, seconds: 19, milliseconds: 720): 'だっだっだ ダメよ 順序とか',
    // Duration(minutes: 2, seconds: 22, milliseconds: 220): 'もっと仲良くなって そうじゃないの?',
    // Duration(minutes: 2, seconds: 26, milliseconds: 20): 'だっだっだ まじでだいじょばない',
    // Duration(minutes: 2, seconds: 28, milliseconds: 520): 'やっぱ蛹になって出直すわ',
  };
  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    // _audioPlayer.setAsset("audio/cinderella.mp3").then((value) {
    //   // idk solution for init duration, so play pause
    //   _audioPlayer.play();
    //   _audioPlayer.pause();
    // });
    // Workaround buat fix API 30 keatas, gk bisa langsung load file dari asset
    rootBundle.load("assets/audio/nenek_pak_ande.mp3").then((bytes) {
      final dir = getApplicationDocumentsDirectory().then((dir) {
        var file = File("${dir.path}/nenek_pak_ande.mp3");
        file.writeAsBytesSync(bytes.buffer.asUint8List());
        _audioPlayer.setFilePath(file.path).then((value) {
          _audioPlayer.play();
          _audioPlayer.pause();
        });
      });
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // subtitle
          Expanded(
            child: Container(
              margin: EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 0.0),
              child: Stack(
                // mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Nenek Pak Ande",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo[300],
                        ),
                      ),
                    ],
                  ),
                  Center(
                    child: StreamBuilder<Duration>(
                      stream: _audioPlayer.positionStream,
                      builder: (context, snapshot) {
                        return _lyricText(snapshot.data, _lyrics);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          // audio controls
          Column(
            children: [
              // seekbar
              StreamBuilder<Duration>(
                  stream: _audioPlayer.positionStream,
                  builder: (context, snapshot) {
                    return _seekBar(snapshot.data, _audioPlayer);
                  }),
              // audio controls
              Stack(
                children: [
                  StreamBuilder<Duration>(
                      stream: _audioPlayer.positionStream,
                      builder: (context, snapshot) {
                        return _textPosition(snapshot.data, _audioPlayer);
                      }),
                  StreamBuilder<PlayerState>(
                    stream: _audioPlayer.playerStateStream,
                    builder: (context, snapshot) {
                      final state = snapshot.data;
                      return Container(
                        margin: EdgeInsets.fromLTRB(12.0, 0.0, 12.0, 0.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            StreamBuilder<double>(
                                stream: _audioPlayer.speedStream,
                                builder: (context, snapshot) {
                                  return _speedBar(snapshot.data, _audioPlayer);
                                }),
                            SizedBox(
                              width: 15,
                            ),
                            _playerButton(state, _audioPlayer),
                            StreamBuilder<double>(
                              stream: _audioPlayer.volumeStream,
                              builder: (context, snapshot) {
                                return _volumeBar(
                                    snapshot.data, _audioPlayer, context);
                              },
                            )
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
