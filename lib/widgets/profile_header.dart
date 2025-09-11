// // lib/widgets/profile_header.dart
// import 'dart:io';
// import 'dart:async';
// import 'package:flutter/material.dart';
// import '../utils/avatar_manager.dart';

// class ProfileHeader extends StatefulWidget {
//   final VoidCallback? onTapProfile;
//   const ProfileHeader({super.key, this.onTapProfile});

//   @override
//   State<ProfileHeader> createState() => _ProfileHeaderState();
// }

// class _ProfileHeaderState extends State<ProfileHeader> {
//   String? _avatarPath;
//   Color _bgColor = Colors.transparent;
//   String userName = 'Yanto Simatupang';
//   String membership = 'Gold Member';
//   StreamSubscription<void>? _sub;

//   @override
//   void initState() {
//     super.initState();
//     _loadAvatar();
//     // Subscribe ke perubahan avatar
//     _sub = AvatarManager.avatarChanges.listen((_) {
//       _loadAvatar(); // reload saat ada event
//     });
//   }

//   Future<void> _loadAvatar() async {
//     final info = await AvatarManager.loadAvatarInfo();
//     if (!mounted) return;
//     setState(() {
//       _avatarPath = info?.filePath;
//       _bgColor = info != null ? Color(info.bgColor) : Colors.transparent;
//     });
//   }

//   @override
//   void dispose() {
//     _sub?.cancel();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       onTap: () {
//         if (widget.onTapProfile != null) widget.onTapProfile!();
//       },
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Container(
//             width: 52,
//             height: 52,
//             decoration: BoxDecoration(
//               color: _bgColor,
//               shape: BoxShape.circle,
//               boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(0,2))],
//             ),
//             child: ClipOval(
//               child: _avatarPath == null
//                   ? Image.asset('assets/avatar_placeholder.png', fit: BoxFit.cover)
//                   : Image.file(File(_avatarPath!), fit: BoxFit.cover),
//             ),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text('Haloooo, $userName', style: const TextStyle(fontWeight: FontWeight.bold)),
//                 const SizedBox(height: 4),
//                 Text(membership, style: const TextStyle(color: Colors.orange)),
//               ],
//             ),
//           ),
//           IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none)),
//           IconButton(onPressed: () {}, icon: const Icon(Icons.settings)),
//         ],
//       ),
//     );
//   }
// }

// lib/widgets/profile_header.dart
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/avatar_manager.dart';
import 'package:flutter/foundation.dart';

class ProfileHeader extends StatefulWidget {
  final VoidCallback? onTapProfile;
  const ProfileHeader({super.key, this.onTapProfile});

  @override
  State<ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<ProfileHeader> {
  String? _avatarPath;
  Color _bgColor = Colors.transparent;
  String userName = 'Yanto Simatupang';
  String membership = 'Gold Member';
  StreamSubscription<void>? _sub;

  @override
  void initState() {
    super.initState();
    _loadAvatar();
    _sub = AvatarManager.avatarChanges.listen((_) {
      debugPrint('ProfileHeader: avatarChanges event received');
      _loadAvatar();
    });
  }

  Future<void> _loadAvatar() async {
    final info = await AvatarManager.loadAvatarInfo();
    if (!mounted) return;
    setState(() {
      _avatarPath = info?.filePath;
      _bgColor = info != null ? Color(info.bgColor) : Colors.transparent;
    });
    debugPrint('ProfileHeader: loaded avatarPath=$_avatarPath bg=0x${_bgColor.value.toRadixString(16)}');
    if (_avatarPath != null) {
      final exists = await File(_avatarPath!).exists();
      debugPrint('ProfileHeader: file exists? $exists (path=$_avatarPath)');
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (widget.onTapProfile != null) widget.onTapProfile!();
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _bgColor,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(0,2))],
            ),
            child: ClipOval(
              child: _avatarPath == null
                  ? Image.asset('assets/avatar_placeholder.png', fit: BoxFit.cover)
                  : Image.file(File(_avatarPath!), fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Halo, $userName', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(membership, style: const TextStyle(color: Colors.orange)),
              ],
            ),
          ),
          IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.settings)),
        ],
      ),
    );
  }
}
