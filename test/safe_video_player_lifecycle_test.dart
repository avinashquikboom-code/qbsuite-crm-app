// ignore_for_file: depend_on_referenced_packages
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickboom_app/core/widgets/app_video_progress_indicator.dart';
import 'package:video_player/video_player.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

class _FakeVideoPlayerPlatform extends VideoPlayerPlatform {
  @override
  Future<void> init() async {}

  @override
  Future<void> dispose(int textureId) async {}

  @override
  Future<int?> create(DataSource dataSource) async {
    return 1;
  }

  @override
  Future<void> setLooping(int textureId, bool looping) async {}

  @override
  Future<void> play(int textureId) async {}

  @override
  Future<void> pause(int textureId) async {}

  @override
  Future<void> setVolume(int textureId, double volume) async {}

  @override
  Future<void> seekTo(int textureId, Duration position) async {}

  @override
  Future<Duration> getPosition(int textureId) async {
    return Duration.zero;
  }

  @override
  Stream<VideoEvent> videoEventsFor(int textureId) {
    return const Stream.empty();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  VideoPlayerPlatform.instance = _FakeVideoPlayerPlatform();

  group('Safe Video Player & Progress Indicator Lifecycle Tests', () {
    late VideoPlayerController controller1;
    late VideoPlayerController controller2;

    setUp(() {
      controller1 = VideoPlayerController.networkUrl(
        Uri.parse('https://example.com/video1.mp4'),
      );
      controller2 = VideoPlayerController.networkUrl(
        Uri.parse('https://example.com/video2.mp4'),
      );
    });

    tearDown(() {
      controller1.dispose();
      controller2.dispose();
    });

    testWidgets(
      'AppVideoProgressIndicator renders correctly when initialized',
      (tester) async {
        controller1.value = const VideoPlayerValue(
          duration: Duration(seconds: 100),
          position: Duration(seconds: 30),
          isInitialized: true,
          isPlaying: true,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppVideoProgressIndicator(
                controller1,
                allowScrubbing: true,
                colors: const VideoProgressColors(
                  playedColor: Colors.blue,
                  bufferedColor: Colors.grey,
                  backgroundColor: Colors.black,
                ),
              ),
            ),
          ),
        );

        expect(find.byType(AppVideoProgressIndicator), findsOneWidget);
        expect(find.byType(LinearProgressIndicator), findsNWidgets(2));
      },
    );

    testWidgets(
      'Does NOT throw setState() or markNeedsBuild() when controller notifies during build',
      (tester) async {
        controller1.value = const VideoPlayerValue(
          duration: Duration(seconds: 60),
          position: Duration(seconds: 10),
          isInitialized: true,
        );

        // A widget that triggers controller notification DURING its build phase
        final notifyingWidget = StatefulBuilder(
          builder: (context, setState) {
            // Mutate and notify controller while in the middle of building
            if (SchedulerBinding.instance.schedulerPhase ==
                SchedulerPhase.persistentCallbacks) {
              controller1.value = controller1.value.copyWith(
                position: const Duration(seconds: 15),
              );
            }
            return AppVideoProgressIndicator(controller1, allowScrubbing: true);
          },
        );

        await tester.pumpWidget(
          MaterialApp(home: Scaffold(body: notifyingWidget)),
        );

        // Advance frames cleanly
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('Safely handles didUpdateWidget controller switch', (
      tester,
    ) async {
      controller1.value = const VideoPlayerValue(
        duration: Duration(seconds: 60),
        position: Duration(seconds: 10),
        isInitialized: true,
      );
      controller2.value = const VideoPlayerValue(
        duration: Duration(seconds: 120),
        position: Duration(seconds: 40),
        isInitialized: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppVideoProgressIndicator(controller1, allowScrubbing: false),
          ),
        ),
      );

      expect(find.byType(AppVideoProgressIndicator), findsOneWidget);

      // Rebuild with controller2
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppVideoProgressIndicator(controller2, allowScrubbing: false),
          ),
        ),
      );

      await tester.pump();
      expect(tester.takeException(), isNull);

      // Notify controller2
      controller2.value = controller2.value.copyWith(
        position: const Duration(seconds: 50),
      );

      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}
