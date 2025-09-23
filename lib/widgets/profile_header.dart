// lib/widgets/profile_header.dart
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../utils/avatar_manager.dart';
// import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

class ProfileHeader extends StatefulWidget {
  final VoidCallback? onTapProfile;
  const ProfileHeader({super.key, this.onTapProfile});

  @override
  State<ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<ProfileHeader> {
  String? _avatarPath;
  Color _bgColor = Colors.transparent;
  // String userName = 'Yanto Simatupang';
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
    debugPrint(
      'ProfileHeader: loaded avatarPath=$_avatarPath bg=0x${_bgColor.value.toRadixString(16)}',
    );
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
final auth = Provider.of<AuthService>(context);
    final ownerName = auth.owner != null
        ? (auth.owner!['owner_name']?.toString() ?? 'User')
        : 'Guest';
    // branch priority: branch table -> company.branch_name -> fallback 'Bogor'
    final branchName = auth.branch != null
        ? (auth.branch!['branch_name']?.toString() ?? '')
        : (auth.company != null
            ? (auth.company!['branch_name']?.toString() ?? auth.company!['company_name']?.toString() ?? '')
            : '');

    return InkWell(
      onTap: () {
        if (widget.onTapProfile != null) widget.onTapProfile!();
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _bgColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 3,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: ClipOval(
              child: _avatarPath == null
                  ? Image.asset(
                      'assets/avatar_placeholder.png',
                      fit: BoxFit.cover,
                    )
                  : Image.file(File(_avatarPath!), fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Halo, $ownerName',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'poppins',
                    fontSize: 14,
                  ),
                ),
                // const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/iconGold.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Text(
                      membership,
                      style: const TextStyle(
                        color: Color(0xFFB11F23),
                        fontFamily: 'montserrat',
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(FontAwesomeIcons.solidClock),
            iconSize: 20,
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(FontAwesomeIcons.solidBell),
            iconSize: 20,
          ),
        ],
      ),
    );
  }
}
