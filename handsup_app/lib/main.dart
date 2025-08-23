

import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
//import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:video_player/video_player.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Lock to portrait for simpler layouts.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const SignTranslatorApp());
}

class SignTranslatorApp extends StatelessWidget {
  const SignTranslatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Translator',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E4B8C)),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF4F6FB),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
      home: const RootShell(),
    );
  }
}

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;
  final HistoryStore history = HistoryStore();

  @override
  Widget build(BuildContext context) {
    final pages = [
      TranslatorScreen(history: history),
      HistoryScreen(history: history),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: SafeArea(child: pages[_index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.translate_outlined), label: ''),
          NavigationDestination(icon: Icon(Icons.history), label: ''),
          NavigationDestination(icon: Icon(Icons.person_outline), label: ''),
        ],
      ),
    );
  }
}

// =====================================================
// Models & History Store
// =====================================================

enum Mode { signToTextOrSound, textOrSoundToSign }

enum Direction { signToText, signToSound, textToSign, soundToSign }

class HistoryItem {
  HistoryItem({
    required this.direction,
    required this.input,
    required this.output,
    this.timestamp,
  });

  final Direction direction; // Conversion direction
  final String input; // Raw input (text or "[sign]" or "[audio]")
  final String output; // Output (text, tts, or path to sign video)
  final DateTime? timestamp;
}

class HistoryStore extends ChangeNotifier {
  final List<HistoryItem> _items = [];
  List<HistoryItem> get items => List.unmodifiable(_items);

  void add(HistoryItem item) {
    _items.insert(0, item);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}

// =====================================================
// Translator root with two tabs (modes)
// =====================================================

class TranslatorScreen extends StatefulWidget {
  const TranslatorScreen({super.key, required this.history});
  final HistoryStore history;

  @override
  State<TranslatorScreen> createState() => _TranslatorScreenState();
}

class _TranslatorScreenState extends State<TranslatorScreen> {
  Mode mode = Mode.signToTextOrSound;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 4),
        _TopBar(
          title: 'Translator',
          onInfo: () => _showAbout(context),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SegmentedButton<Mode>(
            segments: const [
              ButtonSegment(value: Mode.signToTextOrSound, label: Text('Sign to sound or text')),
              ButtonSegment(value: Mode.textOrSoundToSign, label: Text('Text or sound to sign')),
            ],
            selected: <Mode>{mode},
            onSelectionChanged: (s) => setState(() => mode = s.first),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: mode == Mode.signToTextOrSound
                ? SignToTextOrSoundPane(history: widget.history, key: const ValueKey('s2t'))
                : TextOrSoundToSignPane(history: widget.history, key: const ValueKey('t2s')),
          ),
        ),
      ],
    );
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const AlertDialog(
        title: Text('About'),
        content: Text('Demo UI: Sign ↔ Text/Sound.\nML is mocked for now.'),
      ),
    );
  }
}

// =====================================================
// Pane 1: Sign → Text/Sound (camera input, result below)
// =====================================================

class SignToTextOrSoundPane extends StatefulWidget {
  const SignToTextOrSoundPane({super.key, required this.history});
  final HistoryStore history;

  @override
  State<SignToTextOrSoundPane> createState() => _SignToTextOrSoundPaneState();
}

class _SignToTextOrSoundPaneState extends State<SignToTextOrSoundPane> {
  CameraController? _controller;
  Future<void>? _initFuture;
  String _resultText = '';
  bool _isRunning = false;
  final FlutterTts _tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _setupCamera();
  }

  Future<void> _setupCamera() async {
    // Request permissions explicitly for a smoother first-run UX.
    await [Permission.camera, Permission.microphone].request();
    final cams = await availableCameras();
    final cam = cams.isNotEmpty ? cams.first : null;
    if (cam == null) return;
    final controller = CameraController(cam, ResolutionPreset.medium, enableAudio: false);
    setState(() {
      _controller = controller;
      _initFuture = controller.initialize();
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _startProcessing() async {
    if (_controller == null) return;
    setState(() => _isRunning = true);

    // START STREAM: this is where your ML interpreter would run per-frame
    await _controller!.startImageStream((CameraImage image) {
      // TODO: Feed image. For demo, we stop after first frame and produce a mock.
    });

    // Simulate a short processing delay and a dummy translation result.
    await Future.delayed(const Duration(seconds: 2));
    await _controller!.stopImageStream();

    const mock = 'Hello'; // Replace with ML result
    setState(() {
      _resultText = mock;
      _isRunning = false;
    });

    widget.history.add(HistoryItem(
      direction: Direction.signToText,
      input: '[sign]',
      output: mock,
      timestamp: DateTime.now(),
    ));
  }

  Future<void> _speak() async {
    if (_resultText.isEmpty) return;
    await _tts.stop();
    await _tts.setLanguage('en-US');
    await _tts.speak(_resultText);
    widget.history.add(HistoryItem(
      direction: Direction.signToSound,
      input: '[sign]',
      output: 'tts:${_resultText}',
      timestamp: DateTime.now(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        children: [
          _CameraCard(initFuture: _initFuture, controller: _controller),
          const SizedBox(height: 12),
          _ResultCard(
            title: 'Text',
            child: SizedBox(
              height: 120,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Text(_resultText.isEmpty ? '—' : _resultText, style: const TextStyle(fontSize: 16)),
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.volume_up_outlined),
              onPressed: _resultText.isEmpty ? null : _speak,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isRunning ? null : _startProcessing,
              child: Text(_isRunning ? 'Processing…' : 'Start'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraCard extends StatelessWidget {
  const _CameraCard({required this.initFuture, required this.controller});
  final Future<void>? initFuture;
  final CameraController? controller;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: DecoratedBox(
          decoration: BoxDecoration(border: Border.all(color: const Color(0xFF2E4B8C), width: 3), borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: FutureBuilder(
              future: initFuture,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.done && controller != null && controller!.value.isInitialized) {
                  return CameraPreview(controller!);
                }
                return const ColoredBox(
                  color: Colors.black12,
                  child: Center(child: CircularProgressIndicator()),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.title, required this.child, this.trailing});
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              const Spacer(),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 8),
          child,
        ]),
      ),
    );
  }
}

// =====================================================
// Pane 2: Text/Sound → Sign (text or mic input, output shows a sign video)
// =====================================================

class TextOrSoundToSignPane extends StatefulWidget {
  const TextOrSoundToSignPane({super.key, required this.history});
  final HistoryStore history;

  @override
  State<TextOrSoundToSignPane> createState() => _TextOrSoundToSignPaneState();
}

class _TextOrSoundToSignPaneState extends State<TextOrSoundToSignPane> {
  final TextEditingController _text = TextEditingController();
//  late stt.SpeechToText _speech;
//  bool _listening = false;
  
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
//    _speech = stt.SpeechToText();
  }

  @override
  void dispose() {
    _text.dispose();
    _videoController?.dispose();
    super.dispose();
  }

//  Future<void> _listen() async {
//    if (!_listening) {
//      final available = await _speech.initialize();
//      if (available) {
//        setState(() => _listening = true);
//       await _speech.listen(
//          onResult: (r) => setState(() => _text.text = r.recognizedWords),
//          localeId: 'en_US',
//        );
//      }
//    } else {
//      await _speech.stop();
//      setState(() => _listening = false);
//    }
//  }

  Future<void> _start() async {
    final input = _text.text.trim();
    if (input.isEmpty) return;

    // Map the input to a mock sign video asset.
    // TODO: Replace with real sign-synthesis or video retrieval.
    final path = 'assets/sign_videos/hello.mp4';

    _videoController?.dispose();
    final controller = VideoPlayerController.asset(path);
    await controller.initialize();
    controller.setLooping(true);
    await controller.play();

    setState(() {
      _videoController = controller;
    });

    widget.history.add(HistoryItem(
      direction: Direction.textToSign,
      input: input,
      output: path,
      timestamp: DateTime.now(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ResultCard(
            title: 'Text',
            child: SizedBox(
              height: 96,
              child: TextField(
                controller: _text,
                maxLines: null,
                decoration: const InputDecoration(
                  hintText: 'Text',
                  // просто иконка, без кнопки и коллбэка
                  suffixIcon: Icon(Icons.mic_off),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          AspectRatio(
            aspectRatio: 4 / 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: DecoratedBox(
                decoration: const BoxDecoration(color: Colors.black12),
                child: _videoController != null && _videoController!.value.isInitialized
                    ? Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          VideoPlayer(_videoController!),
                          _VideoControls(controller: _videoController!),
                        ],
                      )
                    : Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.sign_language, size: 42, color: Colors.black54),
                              SizedBox(height: 8),
                              Text('Sign preview will appear here'),
                            ],
                          ),
                        ),
                      ),
              ),
            ),
          ),
          const Spacer(),
          FilledButton(
            onPressed: _start,
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }
}

class _VideoControls extends StatelessWidget {
  const _VideoControls({required this.controller});
  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(controller.value.isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white),
            onPressed: () => controller.value.isPlaying ? controller.pause() : controller.play(),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// History Screen (simple list)
// =====================================================

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, required this.history});
  final HistoryStore history;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TextEditingController _search = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final q = _search.text.toLowerCase();
    final list = widget.history.items.where((e) => e.input.toLowerCase().contains(q) || e.output.toLowerCase().contains(q)).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _TopBar(title: 'Translator'),
          const SizedBox(height: 8),
          Row(
            children: const [
              Text('History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              Spacer(),
              Icon(Icons.delete_outline, color: Colors.black38),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(hintText: 'Search'),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: list.isEmpty
                ? const Center(child: Text('No items'))
                : ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final it = list[i];
                      return _HistoryTile(item: it);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.item});
  final HistoryItem item;

  String _label(Direction d) {
    switch (d) {
      case Direction.signToText:
        return 'Sign → text';
      case Direction.signToSound:
        return 'Sign → sound';
      case Direction.textToSign:
        return 'Text → sign';
      case Direction.soundToSign:
        return 'Sound → sign';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const Icon(Icons.history, color: Colors.black38),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_label(item.direction), style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(
                'In: ${item.input}\nOut: ${item.output}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// Profile / Auth (static placeholders to match your mockups)
// =====================================================

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _TopBar(title: 'My Profile'),
          const SizedBox(height: 12),
          const CircleAvatar(radius: 40, backgroundImage: AssetImage('assets/images/placeholder_sign.png')),
          const SizedBox(height: 12),
          const TextField(decoration: InputDecoration(hintText: 'Name')),
          const SizedBox(height: 10),
          const TextField(decoration: InputDecoration(hintText: 'Email Address')),
          const SizedBox(height: 10),
          const TextField(obscureText: true, decoration: InputDecoration(hintText: 'Password')),
          const SizedBox(height: 10),
          Row(children: const [Expanded(child: TextField(decoration: InputDecoration(hintText: 'Birth Date')))]),
          const SizedBox(height: 18),
          FilledButton(onPressed: () {}, child: const Text('Save')),
          const Spacer(),
          OutlinedButton(onPressed: () {}, child: const Text('Log out')),
        ],
      ),
    );
  }
}

// =====================================================
// Small shared top bar widget
// =====================================================

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title, this.onInfo});
  final String title;
  final VoidCallback? onInfo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.public, size: 18, color: Colors.black54),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const Spacer(),
          IconButton(onPressed: onInfo, icon: const Icon(Icons.info_outline, size: 20)),
        ],
      ),
    );
  }
}
