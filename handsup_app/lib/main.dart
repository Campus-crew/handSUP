import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const SignTranslatorApp());
}

/* ===========================
   In-memory session (auth flag)
   =========================== */

class Session extends InheritedWidget {
  final ValueNotifier<bool> authed;
  const Session({super.key, required this.authed, required super.child});
  static Session of(BuildContext c) => c.dependOnInheritedWidgetOfExactType<Session>()!;
  @override
  bool updateShouldNotify(Session old) => authed != old.authed;
}

/* ===========================
   App root
   =========================== */

class SignTranslatorApp extends StatelessWidget {
  const SignTranslatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authed = ValueNotifier<bool>(false);
    final seed = const Color(0xFF2E4B8C);

    return Session(
      authed: authed,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Translator',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: seed),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF4F6FB),
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
            filled: true,
            fillColor: Colors.white,
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              textStyle: const TextStyle(fontWeight: FontWeight.w600),
              backgroundColor: seed,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        home: ValueListenableBuilder<bool>(
          valueListenable: authed,
          builder: (_, ok, __) => ok ? const RootShell() : const AuthGate(),
        ),
      ),
    );
  }
}

/* ===========================
   AUTH: Sign In / Sign Up / Code
   =========================== */

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F2C5A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Spacer(),
            const Text('Welcome', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('Sign in to Continue', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 24),
            const _AuthTextField(hint: 'Email Address'),
            const SizedBox(height: 12),
            const _AuthTextField(hint: 'Password', obscure: true),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Session.of(context).authed.value = true,
              child: const Text('Sign In'),
            ),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              TextButton(onPressed: () {}, child: const Text('Forgot password?', style: TextStyle(color: Colors.white))),
              TextButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SignUpScreen())),
                child: const Text('Sign Up', style: TextStyle(color: Colors.white)),
              ),
            ]),
            const Spacer(),
          ]),
        ),
      ),
    );
  }
}

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: BackButton(color: const Color(0xFF2E4B8C))),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('Create Account', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          const TextField(decoration: InputDecoration(hintText: 'Name')),
          const SizedBox(height: 10),
          const TextField(decoration: InputDecoration(hintText: 'Email Address')),
          const SizedBox(height: 10),
          const TextField(obscureText: true, decoration: InputDecoration(hintText: 'Password')),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CodeScreen())),
            child: const Text('Sign Up'),
          ),
        ]),
      ),
    );
  }
}

class CodeScreen extends StatelessWidget {
  const CodeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final boxes = List<Widget>.generate(
      4,
      (_) => Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE3E7F2)),
        ),
      ),
    );
    return Scaffold(
      appBar: AppBar(leading: BackButton(color: const Color(0xFF2E4B8C))),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('Confirm the code from your Email',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 18),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: boxes),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () {
              Session.of(context).authed.value = true;
              Navigator.of(context).popUntil((r) => r.isFirst);
            },
            child: const Text('Confirm'),
          ),
        ]),
      ),
    );
  }
}

class _AuthTextField extends StatelessWidget {
  const _AuthTextField({required this.hint, this.obscure = false});
  final String hint;
  final bool obscure;
  @override
  Widget build(BuildContext context) {
    return TextField(
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: const Color(0xFF123469),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      ),
    );
  }
}

/* ===========================
   Root shell (3 tabs)
   =========================== */

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
      ProfileScreen(onLogout: () => Session.of(context).authed.value = false),
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

/* ===========================
   Models & History
   =========================== */

enum Mode { signToTextOrSound, textOrSoundToSign }
enum Direction { signToText, signToSound, textToSign, soundToSign }

class HistoryItem {
  HistoryItem({required this.direction, required this.input, required this.output, this.timestamp});
  final Direction direction;
  final String input;
  final String output;
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

/* ===========================
   Translator screen with two panes
   =========================== */

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
    return Column(children: [
      const SizedBox(height: 4),
      const _TopBar(title: 'Translator'),
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
    ]);
  }
}

/* ===========================
   Pane 1: Sign → Text/Sound
   =========================== */

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
  String? _error;
  final FlutterTts _tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _setupCamera();
  }

  Future<void> _setupCamera() async {
    setState(() => _error = null);
    final statuses = await [Permission.camera, Permission.microphone].request();
    if (statuses[Permission.camera] != PermissionStatus.granted) {
      setState(() => _error = 'Camera permission denied');
      return;
    }
    try {
      final cams = await availableCameras();
      if (cams.isEmpty) {
        setState(() => _error = 'No cameras available');
        return;
      }
      final controller = CameraController(cams.first, ResolutionPreset.medium, enableAudio: false);
      setState(() {
        _controller = controller;
        _initFuture = controller.initialize();
      });
    } catch (e) {
      setState(() => _error = 'Camera init failed: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _startProcessing() async {
    if (_controller == null || !(_controller!.value.isInitialized)) return;
    setState(() {
      _isRunning = true;
      _resultText = '';
    });

    await _controller!.startImageStream((_) {});
    await Future.delayed(const Duration(seconds: 2)); // mock processing
    await _controller!.stopImageStream();

    const mock = 'Hello';
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
      child: Column(children: [
        AspectRatio(
          aspectRatio: 4 / 3,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF2E4B8C), width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: _error != null
                    ? Center(child: Text(_error!, textAlign: TextAlign.center))
                    : FutureBuilder(
                        future: _initFuture,
                        builder: (context, snap) {
                          if (snap.connectionState == ConnectionState.done &&
                              _controller != null &&
                              _controller!.value.isInitialized) {
                            return CameraPreview(_controller!);
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
        ),
        const SizedBox(height: 12),
        _ResultCard(
          title: 'Text',
          child: SizedBox(
            height: 120,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Text(_resultText.isEmpty ? '—' : _resultText,
                  style: const TextStyle(fontSize: 16)),
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
            onPressed: (_initFuture == null || _error != null || _isRunning) ? null : _startProcessing,
            child: Text(_isRunning ? 'Processing…' : 'Start'),
          ),
        ),
      ]),
    );
  }
}

/* ===========================
   Pane 2: Text/Sound → Sign
   =========================== */

class TextOrSoundToSignPane extends StatefulWidget {
  const TextOrSoundToSignPane({super.key, required this.history});
  final HistoryStore history;

  @override
  State<TextOrSoundToSignPane> createState() => _TextOrSoundToSignPaneState();
}

class _TextOrSoundToSignPaneState extends State<TextOrSoundToSignPane> {
  final TextEditingController _text = TextEditingController();
  VideoPlayerController? _videoController;

  @override
  void dispose() {
    _text.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final input = _text.text.trim();
    if (input.isEmpty) return;

    final path = 'assets/sign_videos/hello.mp4'; // mock mapping

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
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _ResultCard(
          title: 'Text',
          child: SizedBox(
            height: 96,
            child: TextField(
              controller: _text,
              maxLines: null,
              decoration: const InputDecoration(
                hintText: 'Text',
                suffixIcon: Icon(Icons.mic_off), // placeholder
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
                  ? Stack(alignment: Alignment.bottomCenter, children: [
                      VideoPlayer(_videoController!),
                      _VideoControls(controller: _videoController!),
                    ])
                  : const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
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
        FilledButton(onPressed: _start, child: const Text('Start')),
      ]),
    );
  }
}

class _VideoControls extends StatelessWidget {
  const _VideoControls({required this.controller});
  final VideoPlayerController? controller;
  @override
  Widget build(BuildContext context) {
    if (controller == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        IconButton(
          icon: Icon(controller!.value.isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white),
          onPressed: () => controller!.value.isPlaying ? controller!.pause() : controller!.play(),
        ),
      ]),
    );
  }
}

/* ===========================
   History
   =========================== */

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
    final list = widget.history.items
        .where((e) => e.input.toLowerCase().contains(q) || e.output.toLowerCase().contains(q))
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const _TopBar(title: 'Translator'),
        const SizedBox(height: 8),
        Row(children: [
          const Text('History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.black38),
            onPressed: () => setState(() => widget.history.clear()),
            tooltip: 'Clear',
          ),
        ]),
        const SizedBox(height: 8),
        TextField(controller: _search, onChanged: (_) => setState(() {}), decoration: const InputDecoration(hintText: 'Search')),
        const SizedBox(height: 8),
        Expanded(
          child: list.isEmpty
              ? const Center(child: Text('No items'))
              : ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) => _HistoryTile(item: list[i]),
                ),
        ),
      ]),
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
      child: Row(children: [
        const Icon(Icons.history, color: Colors.black38),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_label(item.direction), style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('In: ${item.input}\nOut: ${item.output}', maxLines: 2, overflow: TextOverflow.ellipsis),
          ]),
        ),
      ]),
    );
  }
}

/* ===========================
   Profile + Account
   =========================== */

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.onLogout});
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _TopBar(
          title: 'My Profile',
          trailing: IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AccountScreen())),
            tooltip: 'Account',
          ),
        ),
        const SizedBox(height: 12),
        const CircleAvatar(radius: 40, backgroundImage: AssetImage('assets/images/placeholder_sign.png')),
        const SizedBox(height: 12),
        const TextField(decoration: InputDecoration(hintText: 'Name')),
        const SizedBox(height: 10),
        const TextField(decoration: InputDecoration(hintText: 'Email Address')),
        const SizedBox(height: 10),
        const TextField(obscureText: true, decoration: InputDecoration(hintText: 'Password')),
        const SizedBox(height: 18),
        FilledButton(onPressed: () {}, child: const Text('Save')),
        const Spacer(),
        OutlinedButton(onPressed: onLogout, child: const Text('Log out')),
      ]),
    );
  }
}

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});
  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _currentPwd = TextEditingController();
  final _newPwd = TextEditingController();
  bool _pushEnabled = true;
  String _lang = 'English';

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _currentPwd.dispose();
    _newPwd.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(color: Color(0xFF2E4B8C)),
        title: const Text('Account', style: TextStyle(color: Color(0xFF2E4B8C))),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            TextField(controller: _name, decoration: const InputDecoration(hintText: 'Name')),
            const SizedBox(height: 10),
            TextField(controller: _email, decoration: const InputDecoration(hintText: 'Email Address')),
            const SizedBox(height: 18),

            const Text('Security', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            TextField(controller: _currentPwd, obscureText: true, decoration: const InputDecoration(hintText: 'Current Password')),
            const SizedBox(height: 10),
            TextField(controller: _newPwd, obscureText: true, decoration: const InputDecoration(hintText: 'New Password')),
            const SizedBox(height: 10),
            FilledButton(onPressed: () {}, child: const Text('Change Password')),

            const SizedBox(height: 18),
            const Text('Preferences', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _lang,
              decoration: const InputDecoration(hintText: 'Language'),
              items: const [
                DropdownMenuItem(value: 'English', child: Text('English')),
                DropdownMenuItem(value: 'Kazakh', child: Text('Kazakh')),
                DropdownMenuItem(value: 'Russian', child: Text('Russian')),
              ],
              onChanged: (v) => setState(() => _lang = v ?? _lang),
            ),
            const SizedBox(height: 10),
            SwitchListTile(
              value: _pushEnabled,
              onChanged: (v) => setState(() => _pushEnabled = v),
              title: const Text('Push notifications'),
              contentPadding: EdgeInsets.zero,
            ),

            const SizedBox(height: 18),
            const Text('Danger zone', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.red)),
            const SizedBox(height: 8),
            OutlinedButton(
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Delete account?'),
                    content: const Text('This action cannot be undone.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                      FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                    ],
                  ),
                );
                if (ok == true && context.mounted) Navigator.pop(context);
              },
              child: const Text('Delete my account'),
            ),
          ],
        ),
      ),
    );
  }
}

/* ===========================
   Shared UI: Top bar & Result card
   =========================== */

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title, this.trailing});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: [
        const Icon(Icons.public, size: 18, color: Colors.black54),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const Spacer(),
        trailing ?? const Icon(Icons.info_outline, size: 20),
      ]),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.title, required this.child, this.trailing, super.key});
  final String title;      // Block title (e.g., "Text")
  final Widget child;      // Inner content
  final Widget? trailing;  // Optional action on the right

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            const Spacer(),
            if (trailing != null) trailing!,
          ]),
          const SizedBox(height: 8),
          child,
        ]),
      ),
    );
  }
}