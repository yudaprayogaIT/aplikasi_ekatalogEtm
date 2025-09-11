// lib/screens/avatar_picker_screen.dart
import 'dart:io';
import 'package:ekatalog_etm/utils/avatar_manager.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart'; // debugPrint

class AvatarPickerScreen extends StatefulWidget {
  const AvatarPickerScreen({super.key});
  @override
  State<AvatarPickerScreen> createState() => _AvatarPickerScreenState();
}

class _AvatarPickerScreenState extends State<AvatarPickerScreen> {
  String? _currentPath;
  int _currentBgColor = Colors.transparent.value;
  bool _busy = false;

  final List<String> builtIn = [
    'assets/avatars/avatar1.png',
    'assets/avatars/avatar2.png',
    'assets/avatars/avatar3.png',
    'assets/avatars/avatar4.png',
    'assets/avatars/avatar5.png',
    'assets/avatars/avatar6.png',
    'assets/avatars/avatar7.png',
    'assets/avatars/avatar8.png',
    'assets/avatars/avatar9.png',
  ];

  final List<Color> colors = [
    Colors.transparent,
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.grey,
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final info = await AvatarManager.loadAvatarInfo();
      if (!mounted) return;
      if (info != null) {
        setState(() {
          _currentPath = info.filePath;
          _currentBgColor = info.bgColor;
        });
        debugPrint('AvatarPicker: loaded currentPath=$_currentPath bg=0x${_currentBgColor.toRadixString(16)}');
      } else {
        debugPrint('AvatarPicker: no saved avatar');
      }
    } catch (e, st) {
      debugPrint('AvatarPicker _load error: $e\n$st');
    }
  }

  Future<void> _pickFromGallery() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final picker = ImagePicker();
      debugPrint('AvatarPicker: opening gallery...');
      final XFile? file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (file == null) {
        debugPrint('AvatarPicker: gallery pick cancelled');
        return;
      }
      debugPrint('AvatarPicker: picked file path=${file.path}');
      final saved = await AvatarManager.savePickedImage(File(file.path), _currentBgColor);
      debugPrint('AvatarPicker: saved picked image -> $saved');
      if (!mounted) return;
      setState(() {
        _currentPath = saved;
      });
    } catch (e, st) {
      debugPrint('AvatarPicker: pickFromGallery error: $e\n$st');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _chooseBuiltIn(String assetPath) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      debugPrint('AvatarPicker: choose built-in $assetPath');
      final saved = await AvatarManager.saveAssetAsAvatar(assetPath, _currentBgColor);
      debugPrint('AvatarPicker: saved built-in -> $saved');
      if (!mounted) return;
      setState(() {
        _currentPath = saved;
      });
    } catch (e, st) {
      debugPrint('AvatarPicker: chooseBuiltIn error: $e\n$st');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _removeAvatar() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      debugPrint('AvatarPicker: remove avatar requested');
      await AvatarManager.clearAvatar();
      if (!mounted) return;
      setState(() {
        _currentPath = null;
        _currentBgColor = Colors.transparent.value;
      });
    } catch (e, st) {
      debugPrint('AvatarPicker: removeAvatar error: $e\n$st');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // Save bg color (and ensure saved) then pop
  Future<void> _saveAndExit() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await AvatarManager.setBgColor(_currentBgColor);
      debugPrint('AvatarPicker: setBgColor called 0x${_currentBgColor.toRadixString(16)}');
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e, st) {
      debugPrint('AvatarPicker: saveAndExit error: $e\n$st');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _shortError(Object? e) {
    final s = e?.toString() ?? 'unknown';
    if (s.length > 100) return '${s.substring(0, 100)}...';
    return s;
  }

  @override
  Widget build(BuildContext context) {
    Widget preview = _currentPath == null
        ? Image.asset('assets/avatar_placeholder.png', width: 120, height: 120, fit: BoxFit.cover)
        : Image.file(File(_currentPath!), width: 120, height: 120, fit: BoxFit.cover);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Avatar'),
        backgroundColor: Colors.red.shade700,
        actions: [
          TextButton(
            onPressed: _busy ? null : _saveAndExit,
            child: const Text('Simpan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(color: Color(_currentBgColor), shape: BoxShape.circle),
            child: ClipOval(child: preview),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _busy ? null : _pickFromGallery,
            icon: const Icon(Icons.photo_library),
            label: const Text('Ambil dari Galeri'),
          ),
          const SizedBox(height: 12),
          const Align(alignment: Alignment.centerLeft, child: Text('Pilih Avatar Built-in')),
          const SizedBox(height: 8),
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: builtIn.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, idx) {
                final asset = builtIn[idx];
                return GestureDetector(
                  onTap: _busy ? null : () => _chooseBuiltIn(asset),
                  child: Column(
                    children: [
                      ClipOval(
                        child: Image.asset(
                          asset,
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) {
                            debugPrint('AvatarPicker: asset load error for $asset -> $e');
                            return Container(
                              width: 70,
                              height: 70,
                              color: Colors.grey[200],
                              child: const Icon(Icons.broken_image, color: Colors.grey),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text('Avatar ${idx + 1}', style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          const Align(alignment: Alignment.centerLeft, child: Text('Atur Warna Background')),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: colors.map((c) {
              return GestureDetector(
                onTap: _busy
                    ? null
                    : () {
                        setState(() {
                          _currentBgColor = c.value;
                        });
                      },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: c,
                    borderRadius: BorderRadius.circular(8),
                    border: _currentBgColor == c.value ? Border.all(width: 3, color: Colors.black) : null,
                  ),
                ),
              );
            }).toList(),
          ),
          const Spacer(),
          Row(
            children: [
              OutlinedButton(onPressed: _busy ? null : _removeAvatar, child: const Text('Hapus Avatar')),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _busy ? null : _saveAndExit,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.yellow.shade700),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Simpan', style: TextStyle(color: Colors.black)),
                  ),
                ),
              ),
            ],
          )
        ]),
      ),
    );
  }
}
