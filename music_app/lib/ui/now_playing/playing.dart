// import 'package:flutter/cupertino.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _imageAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
    _imageAnimationController.repeat();
    _audioPlayerManager = AudioPlayerManager(
      songUrl: widget.playingSong.source,
    );
    _audioPlayerManager.init();
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
              Text(widget.playingSong.album),
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
                    image: widget.playingSong.image,
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
                        Text(widget.playingSong.title),
                        const SizedBox(height: 8),
                        Text(
                          widget.playingSong.artist,
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
            ],
          ),
        ),
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
        );
      },
    );
  }
}
