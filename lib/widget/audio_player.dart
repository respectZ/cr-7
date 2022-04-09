import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';

String getDuration(Duration duration) {
  String twoDigits(int i) => i.toString().padLeft(2, '0');
  return "${twoDigits(duration.inSeconds ~/ 60)}:${twoDigits(duration.inSeconds % 60)}";
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
  return Text(lyric);
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

Widget _volumeBar(double? volume, AudioPlayer audioPlayer) {
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
          size: 32.0,
        ),
      ),
      SizedBox(
        width: 20,
      ),
      SizedBox(
        width: 125,
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
    return InkWell(
      customBorder: CircleBorder(),
      child: Icon(
        Icons.pause_circle_filled_rounded,
        size: 64.0,
      ),
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
    return InkWell(
      onTap: audioPlayer.pause,
      customBorder: CircleBorder(),
      child: Icon(
        Icons.pause_circle_filled_rounded,
        size: 64.0,
      ),
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
    Duration(seconds: 0): 'だっだっだ だいじょばない',
    Duration(seconds: 2, milliseconds: 777): 'ちょっと蛹になって出直すわ',
    Duration(seconds: 6, milliseconds: 200): '',
    Duration(seconds: 18, milliseconds: 300): '愛とか恋とか全部くだらない',
    Duration(seconds: 19, milliseconds: 900): 'がっかりするだけ ダメを知るだけ',
    Duration(seconds: 21, milliseconds: 800): 'あたし馬鹿ね ダサい逆走じゃん',
    Duration(seconds: 24, milliseconds: 300): 'ホントのところはあなたにモテたい',
    Duration(seconds: 26, milliseconds: 0): '失敗するのにビビってるだけ',
    Duration(seconds: 27, milliseconds: 710): '加工なしの厳しめの条件じゃ',
    Duration(seconds: 30, milliseconds: 990): 'ちょっと こんな時どんな顔すればいいか教えてほしい: ',
    Duration(seconds: 37, milliseconds: 0): 'ちょっと 「愛してる」だとかそんな言葉で壊れてみたい',
    Duration(seconds: 42, milliseconds: 520): 'じれったいな ハロー残念なあたし',
    Duration(seconds: 46, milliseconds: 920): '困っちゃってイヤイヤ',
    Duration(seconds: 48, milliseconds: 900): 'じれったいな 決まんないの前髪が',
    Duration(seconds: 52, milliseconds: 820): '怒っちゃってイライラ',
    Duration(seconds: 54, milliseconds: 820): 'だっだっだ 大好きは',
    Duration(seconds: 57, milliseconds: 320): 'もっと可愛くなって 言いたいのに',
    Duration(minutes: 1, seconds: 1, milliseconds: 20): 'だっだっだ だいじょばない',
    Duration(minutes: 1, seconds: 3, milliseconds: 420): 'ちょっと蛹になって出直すわ',
    Duration(minutes: 1, seconds: 7, milliseconds: 0): 'あ...えと、いや...なんでもない',
    Duration(minutes: 1, seconds: 10, milliseconds: 110): '言いたいこと言えたことないや',
    Duration(minutes: 1, seconds: 13, milliseconds: 70): '目と目 止められないの',
    Duration(minutes: 1, seconds: 16, milliseconds: 70): '逸らしちゃって まーた自己嫌悪',
    Duration(minutes: 1, seconds: 19, milliseconds: 120): 'じれったいな ハロー残念なあたし',
    Duration(minutes: 1, seconds: 23, milliseconds: 120): '困っちゃってイヤイヤ',
    Duration(minutes: 1, seconds: 25, milliseconds: 120): 'じれったいな 入んないのこの靴が',
    Duration(minutes: 1, seconds: 29, milliseconds: 320): '怒っちゃってイライラ',
    Duration(minutes: 1, seconds: 31, milliseconds: 620): '鐘が鳴って 灰になって',
    Duration(minutes: 1, seconds: 34, milliseconds: 520): 'あたしまだ帰りたくないや',
    Duration(minutes: 1, seconds: 37, milliseconds: 420): '××コースへ 飛び込んでみたいから',
    Duration(minutes: 1, seconds: 42, milliseconds: 20): '',
    Duration(minutes: 1, seconds: 43, milliseconds: 320): 'じれったいな ハロー残念なあたし',
    Duration(minutes: 1, seconds: 47, milliseconds: 620): '困っちゃってイヤイヤ',
    Duration(minutes: 1, seconds: 49, milliseconds: 420): 'じれったいな 決まんないの前髪が',
    Duration(minutes: 1, seconds: 53, milliseconds: 620): '怒っちゃってる',
    Duration(minutes: 1, seconds: 55, milliseconds: 220): 'じれったいな 夜行前のシンデレラ',
    Duration(minutes: 2, seconds: 0, milliseconds: 20): 'ビビっちゃってフラフラ',
    Duration(minutes: 2, seconds: 1, milliseconds: 620): 'じれったいな ハローをくれたあなたと',
    Duration(minutes: 2, seconds: 5, milliseconds: 920): '踊っちゃってクラクラ',
    Duration(minutes: 2, seconds: 7, milliseconds: 720): 'だっだっだ 大好きは',
    Duration(minutes: 2, seconds: 10, milliseconds: 280): 'もっと可愛くなって 言いたいのに',
    Duration(minutes: 2, seconds: 14, milliseconds: 20): 'だっだっだ だいじょばない',
    Duration(minutes: 2, seconds: 16, milliseconds: 220): 'ちょっとお待ちになって王子様',
    Duration(minutes: 2, seconds: 19, milliseconds: 720): 'だっだっだ ダメよ 順序とか',
    Duration(minutes: 2, seconds: 22, milliseconds: 220): 'もっと仲良くなって そうじゃないの?',
    Duration(minutes: 2, seconds: 26, milliseconds: 20): 'だっだっだ まじでだいじょばない',
    Duration(minutes: 2, seconds: 28, milliseconds: 520): 'やっぱ蛹になって出直すわ',
  };
  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _audioPlayer.setAsset("assets/audio/cinderella.mp3").then((value) {
      // idk solution for init duration, so play pause
      _audioPlayer.play();
      _audioPlayer.pause();
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
          StreamBuilder<Duration>(
            stream: _audioPlayer.positionStream,
            builder: (context, snapshot) {
              return _lyricText(snapshot.data, _lyrics);
            },
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
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          SizedBox(
                            width: 20,
                          ),
                          StreamBuilder<double>(
                              stream: _audioPlayer.speedStream,
                              builder: (context, snapshot) {
                                return _speedBar(snapshot.data, _audioPlayer);
                              }),
                          _playerButton(state, _audioPlayer),
                          SizedBox(
                            width: 224,
                            child: StreamBuilder<double>(
                              stream: _audioPlayer.volumeStream,
                              builder: (context, snapshot) {
                                return _volumeBar(snapshot.data, _audioPlayer);
                              },
                            ),
                          )
                        ],
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
