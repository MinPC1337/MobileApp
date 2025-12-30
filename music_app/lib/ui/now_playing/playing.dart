// import 'package:flutter/cupertino.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_app/data/model/song.dart';
import 'package:music_app/ui/now_playing/audio_player_manager.dart';

class NowPlaying extends StatelessWidget {
  const NowPlaying({super.key, required this.songs, required this.playingSong});
  final List<Song> songs;
  final Song playingSong;

  @override
  Widget build(BuildContext context) {
    return NowPlayingPage(songs: songs, playingSong: playingSong);
  }
}

class NowPlayingPage extends StatefulWidget {
  const NowPlayingPage({
    super.key,
    required this.songs,
    required this.playingSong,
  });
  final List<Song> songs;
  final Song playingSong;

  @override
  State<NowPlayingPage> createState() => _NowPlayingPageState();
}

class _NowPlayingPageState extends State<NowPlayingPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _imageAnimationController;
  late AudioPlayerManager _audioPlayerManager;
  late int _selectedItemIndex;
  late Song _song;
  late double _currentAnimationPosition;

  @override
  void initState() {
    super.initState();
    _currentAnimationPosition = 0.0;
    _song = widget.playingSong;
    _imageAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
    // _imageAnimationController.repeat();
    _audioPlayerManager = AudioPlayerManager(songUrl: _song.source);
    _audioPlayerManager.init();
    _selectedItemIndex = widget.songs.indexOf(widget.playingSong);
  }

  @override
  void dispose() {
    _imageAnimationController.dispose();
    _audioPlayerManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    //final screenHeight = MediaQuery.of(context).size.height;
    const delta = 64;
    final radious = (screenWidth - delta) / 2;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Now Playing'),
        trailing: IconButton(onPressed: () {}, icon: Icon(Icons.more_horiz)),
      ),
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_song.album),
              const SizedBox(height: 16),
              const Text('_ ___ _'),
              const SizedBox(height: 48),
              RotationTransition(
                turns: Tween(
                  begin: 0.0,
                  end: 1.0,
                ).animate(_imageAnimationController),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(radious),
                  child: FadeInImage.assetNetwork(
                    placeholder: 'assets/image.png',
                    image: _song.image,
                    width: radious * 2,
                    height: radious * 2,
                    fit: BoxFit.cover,
                    imageErrorBuilder: (context, error, stackTrace) =>
                        Image.asset(
                          'assets/image.png',
                          width: radious * 2,
                          height: radious * 2,
                        ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 64, bottom: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.share_outlined),
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    Column(
                      children: [
                        Text(
                          _song.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _song.artist,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.favorite_outline),
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: _progressBar(),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 36,
                  vertical: 16,
                ),
                child: _mediaButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mediaButton() {
    return SizedBox(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          MediaButtonControl(
            funtion: null,
            icon: Icons.shuffle,
            color: Theme.of(context).colorScheme.secondary,
            size: 24,
          ),
          MediaButtonControl(
            funtion: _setPreviousSong,
            icon: Icons.skip_previous,
            color: Theme.of(context).colorScheme.secondary,
            size: 36,
          ),
          _playButton(),
          MediaButtonControl(
            funtion: _setNextSong,
            icon: Icons.skip_next,
            color: Theme.of(context).colorScheme.secondary,
            size: 36,
          ),
          MediaButtonControl(
            funtion: null,
            icon: Icons.repeat,
            color: Theme.of(context).colorScheme.secondary,
            size: 24,
          ),
        ],
      ),
    );
  }

  StreamBuilder<DurationState> _progressBar() {
    return StreamBuilder<DurationState>(
      stream: _audioPlayerManager.durationState,
      builder: (context, snapshot) {
        final durationState = snapshot.data;
        final progress = durationState?.progress ?? Duration.zero;
        final buffered = durationState?.buffered ?? Duration.zero;
        final total = durationState?.total ?? Duration.zero;
        return ProgressBar(
          progress: progress,
          total: total,
          buffered: buffered,
          onSeek: _audioPlayerManager.player.seek,
          barHeight: 5.0,
          // baseBarColor: Colors.deepPurple,
          thumbColor: Colors.deepPurple,
          thumbRadius: 10.0,
          bufferedBarColor: Colors.grey,
          barCapShape: BarCapShape.round,
        );
      },
    );
  }

  StreamBuilder<PlayerState> _playButton() {
    return StreamBuilder(
      stream: _audioPlayerManager.player.playerStateStream,
      builder: (context, snapshot) {
        final playerState = snapshot.data;
        final processingState = playerState?.processingState;
        final playing = playerState?.playing;
        if (processingState == ProcessingState.loading ||
            processingState == ProcessingState.buffering) {
          return Container(
            margin: const EdgeInsets.all(8.0),
            width: 64.0,
            height: 64.0,
            child: const CircularProgressIndicator(),
          );
        } else if (playing != true) {
          return MediaButtonControl(
            funtion: () {
              _audioPlayerManager.player.play();
              _imageAnimationController.forward(
                from: _currentAnimationPosition,
              );
              _imageAnimationController.repeat();
            },
            icon: Icons.play_arrow,
            color: Colors.deepPurple,
            size: 48,
          );
        } else if (processingState != ProcessingState.completed) {
          return MediaButtonControl(
            funtion: () {
              _audioPlayerManager.player.pause();
              _imageAnimationController.stop();
              _currentAnimationPosition = _imageAnimationController.value;
            },
            icon: Icons.pause,
            color: Colors.deepPurple,
            size: 48,
          );
        } else {
          if (processingState == ProcessingState.completed) {
            _imageAnimationController.stop();
            _currentAnimationPosition = 0.0;
          }
          return MediaButtonControl(
            funtion: () {
              _imageAnimationController.forward(
                from: _currentAnimationPosition,
              );
              _imageAnimationController.repeat();
              _audioPlayerManager.player.seek(Duration.zero);
            },
            icon: Icons.replay,
            color: Colors.deepPurple,
            size: 48,
          );
        }
      },
    );
  }

  void _setNextSong() {
    ++_selectedItemIndex;
    final nextSong = widget.songs[_selectedItemIndex];
    _audioPlayerManager.updateSongUrl(nextSong.source);
    setState(() {
      _song = nextSong;
    });
  }

  void _setPreviousSong() {
    --_selectedItemIndex;
    final prevSong = widget.songs[_selectedItemIndex];
    _audioPlayerManager.updateSongUrl(prevSong.source);
    setState(() {
      _song = prevSong;
    });
  }
}

class MediaButtonControl extends StatefulWidget {
  const MediaButtonControl({
    super.key,
    required this.funtion,
    required this.icon,
    required this.color,
    required this.size,
  });
  final void Function()? funtion;
  final IconData icon;
  final Color color;
  final double size;

  @override
  State<StatefulWidget> createState() => _MediaButtonControlState();
}

class _MediaButtonControlState extends State<MediaButtonControl> {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: widget.funtion,
      icon: Icon(widget.icon),
      color: widget.color,
      iconSize: widget.size,
    );
  }
}
