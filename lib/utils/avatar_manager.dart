// lib/utils/avatar_manager.dart
import 'dart:io';
import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class AvatarInfo {
  final String filePath;
  final int bgColor;
  AvatarInfo({required this.filePath, required this.bgColor});
}

class AvatarManager {
  static const _keyPath = 'avatar_file_path';
  static const _keyBg = 'avatar_bg_color';

  static final StreamController<void> _controller = StreamController<void>.broadcast();
  static Stream<void> get avatarChanges => _controller.stream;

  static void _notify() {
    try {
      _controller.add(null);
      debugPrint('AvatarManager: notified listeners');
    } catch (e) {
      debugPrint('AvatarManager: notify error: $e');
    }
  }

  // ensure alpha channel exists unless the color is explicitly TRANSPARENT (0x00000000)
  static int _ensureOpaqueInt(int color) {
    // preserve explicit transparent value
    if (color == 0x00000000) return color;
    // if alpha bits are zero (i.e. color like 0xRRGGBB), add opaque alpha
    if ((color & 0xFF000000) == 0) {
      return color | 0xFF000000;
    }
    // otherwise keep as-is (already has alpha)
    return color;
  }

  // Load saved avatar info. Default bg = opaque white (0xFFFFFFFF) if not set.
  static Future<AvatarInfo?> loadAvatarInfo() async {
    final sp = await SharedPreferences.getInstance();
    final path = sp.getString(_keyPath);
    final bgRaw = sp.getInt(_keyBg);
    final bg = bgRaw == null ? 0xFFFFFFFF : _ensureOpaqueInt(bgRaw);
    debugPrint('AvatarManager: loadAvatarInfo() -> path=$path, bg=0x${bg.toRadixString(16)}');
    if (path == null) return null;
    final file = File(path);
    final exists = await file.exists();
    debugPrint('AvatarManager: file exists? $exists (path=$path)');
    if (!exists) return null;
    return AvatarInfo(filePath: path, bgColor: bg);
  }

  // Public method to only set bg color (use when user picks a color but not changing image)
  static Future<void> setBgColor(int colorValue) async {
    final sp = await SharedPreferences.getInstance();
    final safe = _ensureOpaqueInt(colorValue);
    await sp.setInt(_keyBg, safe);
    debugPrint('AvatarManager: setBgColor saved 0x${safe.toRadixString(16)}');
    _notify();
  }

  // Helper to read bgColor directly for debugging / immediate use
  static Future<int> getBgColor() async {
    final sp = await SharedPreferences.getInstance();
    final bgRaw = sp.getInt(_keyBg);
    return bgRaw == null ? 0xFFFFFFFF : _ensureOpaqueInt(bgRaw);
  }

  // Delete previous saved avatar file if any (only removes the file + _keyPath)
  static Future<void> _deletePreviousIfAny() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final prev = sp.getString(_keyPath);
      if (prev != null) {
        final f = File(prev);
        if (await f.exists()) {
          try {
            await f.delete();
            debugPrint('AvatarManager: deleted previous avatar file: $prev');
          } catch (e) {
            debugPrint('AvatarManager: failed to delete previous avatar file: $e');
          }
        } else {
          debugPrint('AvatarManager: previous avatar file not found (will continue): $prev');
        }
        // remove only the path key (don't remove bg color here)
        await sp.remove(_keyPath);
      }
    } catch (e, st) {
      debugPrint('AvatarManager: error deleting previous avatar: $e\n$st');
    }
  }

  // compress inputFile -> save as webp (or fallback png) in app documents, return saved path
  static Future<String> _compressAndSave(File inputFile,
      {int size = 512, int quality = 80}) async {
    final dir = await getApplicationDocumentsDirectory();
    final outPathWebp = '${dir.path}/avatar_${DateTime.now().millisecondsSinceEpoch}.webp';

    try {
      final result = await FlutterImageCompress.compressAndGetFile(
        inputFile.path,
        outPathWebp,
        format: CompressFormat.webp,
        quality: quality,
        minWidth: size,
        minHeight: size,
        keepExif: false,
      );

      if (result == null) {
        final fallbackPath = outPathWebp.replaceAll('.webp', '.png');
        final fallback = await inputFile.copy(fallbackPath);
        debugPrint('AvatarManager: compress returned null -> fallback saved ${fallback.path}');
        return fallback.path;
      }

      debugPrint('AvatarManager: compressed saved ${result.path}');
      return result.path;
    } catch (e, st) {
      debugPrint('AvatarManager: compress error: $e\n$st');
      rethrow;
    }
  }

  /// Save image picked from gallery/camera (File) as avatar.
  /// Compresses first, deletes previous avatar file (if any), saves new path and bgColor.
  static Future<String> savePickedImage(File imageFile, int bgColor) async {
    try {
      // delete previous file (if any)
      await _deletePreviousIfAny();

      // compress & save into app documents
      final savedPath = await _compressAndSave(imageFile, size: 512, quality: 80);

      final sp = await SharedPreferences.getInstance();
      final safeBg = _ensureOpaqueInt(bgColor);
      await sp.setString(_keyPath, savedPath);
      await sp.setInt(_keyBg, safeBg);
      debugPrint('AvatarManager: savePickedImage saved=$savedPath, bg=0x${safeBg.toRadixString(16)}');
      _notify();
      return savedPath;
    } catch (e, st) {
      debugPrint('AvatarManager: savePickedImage error: $e\n$st');
      rethrow;
    }
  }

  // Save asset avatar: copy asset to temp -> compress -> save. Keep bgColor unchanged if caller passes current color.
  static Future<String> saveAssetAsAvatar(String assetPath, int bgColor) async {
    try {
      await _deletePreviousIfAny();

      debugPrint('AvatarManager: saveAssetAsAvatar asset=$assetPath');
      final byteData = await rootBundle.load(assetPath);

      final dirTemp = await getTemporaryDirectory();
      final tmpFile = File('${dirTemp.path}/tmp_avatar_${DateTime.now().millisecondsSinceEpoch}.png');
      await tmpFile.writeAsBytes(byteData.buffer.asUint8List());

      final savedPath = await _compressAndSave(tmpFile, size: 512, quality: 80);

      try {
        if (await tmpFile.exists()) await tmpFile.delete();
      } catch (e) {
        debugPrint('AvatarManager: could not delete tmp file: $e');
      }

      final sp = await SharedPreferences.getInstance();
      final safeBg = _ensureOpaqueInt(bgColor);
      await sp.setString(_keyPath, savedPath);
      await sp.setInt(_keyBg, safeBg);
      debugPrint('AvatarManager: saveAssetAsAvatar saved=$savedPath, bg=0x${safeBg.toRadixString(16)}');
      _notify();
      return savedPath;
    } catch (e, st) {
      debugPrint('AvatarManager: saveAssetAsAvatar error: $e\n$st');
      rethrow;
    }
  }

  // Clears avatar file + both prefs keys (path + bg)
  static Future<void> clearAvatar() async {
    try {
      await _deletePreviousIfAny();
      final sp = await SharedPreferences.getInstance();
      await sp.remove(_keyBg);
      debugPrint('AvatarManager: clearAvatar called (both keys removed)');
      _notify();
    } catch (e, st) {
      debugPrint('AvatarManager: clearAvatar error: $e\n$st');
    }
  }
}
